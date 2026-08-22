import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'device_identity.dart';
import 'entitlement_token.dart';
import 'license_state.dart';
import 'secure_store.dart';

/// Snapshot of the current licensing state for UI consumption.
class LicensingSnapshot {
  final EntitlementState state;
  final ParsedToken? parsedToken;
  final DateTime? lastVerifiedAt;

  const LicensingSnapshot({
    required this.state,
    this.parsedToken,
    this.lastVerifiedAt,
  });

  static const uninitialized = LicensingSnapshot(
    state: EntitlementState.uninitialized,
  );
}

/// Central licensing service per T3-2 §22, §23.
///
/// Orchestrates:
/// - Entitlement verification on startup
/// - Deterministic state resolution
/// - Enforcement boundary checks
/// - Activation flow
/// - Deactivation / transfer
///
/// This is the single source of truth for licensing state.
/// UI and business layers consult this service, never make their own decisions.
class LicensingService {
  static final LicensingService _instance = LicensingService._();
  factory LicensingService() => _instance;
  LicensingService._();

  /// Convenience accessor for the singleton.
  static LicensingService get instance => _instance;

  /// Phase K (D7): platform-resolved protected store — Windows keeps DPAPI;
  /// Android receives the Keystore-backed implementation (never XOR).
  final ProtectedActivationStore _secureStore =
      createDefaultProtectedActivationStore();
  final EntitlementVerifier _verifier = EntitlementVerifier();
  final ActivationClient _activationClient = ActivationClient();

  EntitlementState _currentState = EntitlementState.uninitialized;
  ParsedToken? _currentParsedToken;
  String? _currentBusinessId;
  DateTime? _lastVerifiedAt;
  bool _initialized = false;

  /// Current entitlement state.
  EntitlementState get currentState => _currentState;

  /// Current parsed entitlement token (null if not ACTIVE).
  ParsedToken? get currentParsedToken => _currentParsedToken;

  /// Current business ID from the entitlement.
  String? get currentBusinessId => _currentBusinessId;

  /// When was the last successful verification.
  DateTime? get lastVerifiedAt => _lastVerifiedAt;

  /// Whether the service has been initialized.
  bool get isInitialized => _initialized;

  /// Current licensing snapshot for UI consumption.
  LicensingSnapshot get current => LicensingSnapshot(
        state: _currentState,
        parsedToken: _currentParsedToken,
        lastVerifiedAt: _lastVerifiedAt,
      );

  /// Initialize the licensing state on app startup.
  ///
  /// Reads the DPAPI-protected file, verifies the token,
  /// and resolves the entitlement state.
  /// This is the startup verification per T3-2 §21.
  Future<EntitlementState> initialize() async {
    try {
      final state = await _secureStore.read();

      if (state == null) {
        _currentState = EntitlementState.uninitialized;
        _currentParsedToken = null;
        _currentBusinessId = null;
        _initialized = true;
        return _currentState;
      }

      // Verify signature
      final deviceHash = await DeviceIdentity.computeFingerprint();
      final result = await _verifier.verify(
        signedBytes: state.tokenBytes,
        expectedBusinessId: state.businessId,
        expectedDeviceIdHash: deviceHash,
      );

      if (result.isValid && result.token != null) {
        _currentState = EntitlementState.active;
        _currentParsedToken = EntitlementToken.parseSigned(state.tokenBytes);
        _currentBusinessId = state.businessId;
        _lastVerifiedAt = DateTime.now();
      } else {
        // Determine specific failure state
        _currentState = _determineFailureState(result);
        _currentParsedToken = null;
        _currentBusinessId = state.businessId;
      }

      _initialized = true;
      return _currentState;
    } on CorruptStateException {
      _currentState = EntitlementState.localStateCorrupt;
      _currentParsedToken = null;
      _initialized = true;
      return _currentState;
    } catch (e) {
      _currentState = EntitlementState.localStateCorrupt;
      _currentParsedToken = null;
      _initialized = true;
      return _currentState;
    }
  }

  /// Determine the specific failure state from a verification result.
  EntitlementState _determineFailureState(TokenVerificationResult result) {
    switch (result.errorCode) {
      case 'INVALID_SIGNATURE':
        return EntitlementState.invalidSignature;
      case 'BUSINESS_MISMATCH':
        return EntitlementState.businessMismatch;
      case 'DEVICE_MISMATCH':
        return EntitlementState.deviceMismatch;
      case 'UNSUPPORTED_TOKEN_VERSION':
        return EntitlementState.unsupportedTokenVersion;
      case 'UNKNOWN_KEY_ID':
        return EntitlementState.invalidSignature;
      default:
        return EntitlementState.localStateCorrupt;
    }
  }

  /// Enforcement boundary check per T3-2 §23.
  /// Throws [LicenseActivationRequiredException] if state blocks writes.
  /// Called by [DatabaseHelper._enforceLicensing] before every business write.
  Future<void> enforceActive() async {
    final decision = checkOperation(OperationCategory.licensedWrite);
    if (!decision.allowed) {
      throw LicenseActivationRequiredException();
    }
  }

  /// Request activation from the server.
  ///
  /// This is the online activation per T3-2 §16.
  /// Requires internet connection.
  Future<ActivationResult> activate({
    required String activationCode,
  }) async {
    _currentState = EntitlementState.activating;

    try {
      final deviceHashBase64 = await DeviceIdentity.getDeviceIdHashBase64();
      final result = await _activationClient.activate(
        activationCode: activationCode,
        deviceIdHashBase64: deviceHashBase64,
      );

      if (result.success && result.entitlementTokenBytes != null) {
        // Verify the received token
        final deviceHash = await DeviceIdentity.computeFingerprint();
        final verification = await _verifier.verify(
          signedBytes: result.entitlementTokenBytes!,
          expectedBusinessId: result.businessId,
          expectedDeviceIdHash: deviceHash,
        );

        if (verification.isValid && verification.token != null) {
          // Store the activation
          await _secureStore.write(SecureActivationState(
            businessId: result.businessId!,
            deviceHash: deviceHash,
            tokenBytes: result.entitlementTokenBytes!,
            activationGeneration: result.activationGeneration ?? 1,
            createdAt: DateTime.now().millisecondsSinceEpoch,
          ));

          _currentState = EntitlementState.active;
          _currentParsedToken = verification.token != null
              ? EntitlementToken.parseSigned(result.entitlementTokenBytes!)
              : null;
          _currentBusinessId = result.businessId;
          _lastVerifiedAt = DateTime.now();

          return ActivationResult.succeeded(
            businessId: result.businessId!,
            activationGeneration: result.activationGeneration ?? 1,
          );
        } else {
          _currentState = _determineFailureState(verification);
          return ActivationResult.failure(
            'Token verification failed: ${verification.error}',
            verification.errorCode ?? 'VERIFICATION_FAILED',
          );
        }
      } else {
        _currentState = EntitlementState.activationRequired;
        return ActivationResult.failure(
          result.error ?? 'Activation failed',
          result.errorCode ?? 'ACTIVATION_FAILED',
        );
      }
    } on SocketException {
      _currentState = EntitlementState.serverUnavailable;
      return ActivationResult.failure(
        'تعذر الاتصال بخادم التفعيل',
        'SERVER_UNAVAILABLE',
      );
    } on TimeoutException {
      _currentState = EntitlementState.serverUnavailable;
      return ActivationResult.failure(
        'انتهت مهلة الاتصال بالخادم',
        'SERVER_UNAVAILABLE',
      );
    } catch (e) {
      _currentState = EntitlementState.activationRequired;
      return ActivationResult.failure(
        'خطأ غير متوقع: $e',
        'UNKNOWN_ERROR',
      );
    }
  }

  /// Deactivate the current activation (for transfer).
  Future<bool> deactivate() async {
    if (_currentBusinessId == null) return false;

    try {
      final deviceHashBase64 = await DeviceIdentity.getDeviceIdHashBase64();
      final success = await _activationClient.deactivate(
        businessId: _currentBusinessId!,
        deviceIdHashBase64: deviceHashBase64,
      );

      if (success) {
        await _secureStore.delete();
        _currentState = EntitlementState.uninitialized;
        _currentParsedToken = null;
        _currentBusinessId = null;
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Check if a given operation category is allowed in the current state.
  ///
  /// This is the enforcement boundary per T3-2 §23.
  EnforcementDecision checkOperation(OperationCategory category) {
    if (category == OperationCategory.read) {
      return EnforcementDecision.allow;
    }
    if (category == OperationCategory.backupExport) {
      return EnforcementDecision.allow;
    }
    if (category == OperationCategory.licenseRecovery) {
      return EnforcementDecision.allow;
    }
    if (category == OperationCategory.nonBusinessAdmin) {
      return EnforcementDecision.allow;
    }

    // For licensedWrite operations, check state
    if (_currentState.blocksWrites) {
      return EnforcementDecision.denied(
        _currentState,
        reason: _getBlockReason(_currentState),
      );
    }

    return EnforcementDecision.allow;
  }

  /// Get a user-facing reason for the block.
  String _getBlockReason(EntitlementState state) {
    switch (state) {
      case EntitlementState.uninitialized:
      case EntitlementState.activationRequired:
        return 'يرجى تفعيل الرخصة أولاً';
      case EntitlementState.invalidSignature:
        return 'بيانات الرخصة غير صالحة. يرجى إعادة التفعيل';
      case EntitlementState.localStateCorrupt:
        return 'بيانات الرخصة تالفة. يرجى إعادة التفعيل';
      case EntitlementState.businessMismatch:
        return 'هذه الرخصة تنتمي لعمل آخر. اتصل بالدعم الفني';
      case EntitlementState.deviceMismatch:
        return 'هذا الجهاز مختلف عن الجهاز المسجل. يرجى نقل الرخصة';
      case EntitlementState.transferRequired:
        return 'الرخصة نشطة على جهاز آخر. يرجى نقل الرخصة';
      case EntitlementState.revoked:
        return 'تم إلغاء الرخصة. اتصل بالدعم الفني';
      case EntitlementState.unsupportedTokenVersion:
        return 'يرجى تحديث التطبيق إلى أحدث إصدار';
      case EntitlementState.serverUnavailable:
        return 'تعذر الاتصال بخادم التفعيل';
      case EntitlementState.activating:
        return 'جاري التفعيل...';
      case EntitlementState.active:
        return '';
      case EntitlementState.activeRestricted:
        return 'الرخصة في وضع محدود';
    }
  }

  /// Get a human-readable status description in Arabic.
  String get statusDescription {
    switch (_currentState) {
      case EntitlementState.uninitialized:
        return 'غير مفعل';
      case EntitlementState.activationRequired:
        return 'يتطلب تفعيل';
      case EntitlementState.active:
        return 'نشطة';
      case EntitlementState.activeRestricted:
        return 'نشطة (وضع محدود)';
      case EntitlementState.invalidSignature:
        return 'رخصة غير صالحة';
      case EntitlementState.localStateCorrupt:
        return 'بيانات الرخصة تالفة';
      case EntitlementState.businessMismatch:
        return 'ISMATCHbusiness مختلف';
      case EntitlementState.deviceMismatch:
        return 'جهاز مختلف';
      case EntitlementState.transferRequired:
        return 'نقل مطلوب';
      case EntitlementState.revoked:
        return 'ملغاة';
      case EntitlementState.unsupportedTokenVersion:
        return 'إصدار غير مدعوم';
      case EntitlementState.activating:
        return 'جاري التفعيل';
      case EntitlementState.serverUnavailable:
        return 'الخادم غير متاح';
    }
  }
}

/// Result of an activation request.
class ActivationResult {
  final bool success;
  final String? businessId;
  final int? activationGeneration;
  final String? error;
  final String? errorCode;

  const ActivationResult({
    required this.success,
    this.businessId,
    this.activationGeneration,
    this.error,
    this.errorCode,
  });

  static ActivationResult succeeded({
    required String businessId,
    required int activationGeneration,
  }) {
    return ActivationResult(
      success: true,
      businessId: businessId,
      activationGeneration: activationGeneration,
    );
  }

  static ActivationResult failure(String error, String code) {
    return ActivationResult(
      success: false,
      error: error,
      errorCode: code,
    );
  }
}

/// HTTP client for the activation server.
///
/// Per T3-2 §16, §33.
/// The server contract is defined; the actual server is NOT deployed.
/// This client implements the protocol boundary.
class ActivationClient {
  final String? serverBaseUrl;

  ActivationClient({this.serverBaseUrl});

  /// Send activation request to the server.
  Future<ActivationServerResponse> activate({
    required String activationCode,
    required String deviceIdHashBase64,
  }) async {
    if (serverBaseUrl == null || serverBaseUrl!.isEmpty) {
      throw const SocketException('No activation server configured');
    }

    // TODO: Implement actual HTTP call when server is deployed
    // POST /api/v1/activate
    // Body: { activation_code, device_id_hash, token_version, client_version,
    //         idempotency_key, nonce, timestamp }
    throw const SocketException('Activation server not yet deployed');
  }

  /// Send deactivation request to the server.
  Future<bool> deactivate({
    required String businessId,
    required String deviceIdHashBase64,
  }) async {
    if (serverBaseUrl == null || serverBaseUrl!.isEmpty) {
      throw const SocketException('No activation server configured');
    }

    // TODO: Implement actual HTTP call when server is deployed
    // POST /api/v1/deactivate
    throw const SocketException('Activation server not yet deployed');
  }
}

/// Server response for activation.
class ActivationServerResponse {
  final bool success;
  final Uint8List? entitlementTokenBytes;
  final String? businessId;
  final String? licenseId;
  final int? activationGeneration;
  final int? keyId;
  final String? error;
  final String? errorCode;

  const ActivationServerResponse({
    required this.success,
    this.entitlementTokenBytes,
    this.businessId,
    this.licenseId,
    this.activationGeneration,
    this.keyId,
    this.error,
    this.errorCode,
  });
}
