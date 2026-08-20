import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Possible outcomes of a cloud authentication attempt.
enum CloudAuthResultType {
  success,
  invalidCredentials,
  emailAlreadyRegistered,
  networkUnavailable,
  emailNotConfirmed,
  unknownError,
}

/// Result of a cloud authentication attempt.
class CloudAuthResult {
  CloudAuthResult._({
    required this.type,
    this.session,
    this.errorMessage,
  });

  factory CloudAuthResult.success(Session session) =>
      CloudAuthResult._(type: CloudAuthResultType.success, session: session);

  factory CloudAuthResult.invalidCredentials() =>
      CloudAuthResult._(type: CloudAuthResultType.invalidCredentials);

  factory CloudAuthResult.emailAlreadyRegistered() =>
      CloudAuthResult._(type: CloudAuthResultType.emailAlreadyRegistered);

  factory CloudAuthResult.networkUnavailable() =>
      CloudAuthResult._(type: CloudAuthResultType.networkUnavailable);

  factory CloudAuthResult.emailNotConfirmed() =>
      CloudAuthResult._(type: CloudAuthResultType.emailNotConfirmed);

  factory CloudAuthResult.unknownError(String message) => CloudAuthResult._(
      type: CloudAuthResultType.unknownError, errorMessage: message);

  final CloudAuthResultType type;
  final Session? session;
  final String? errorMessage;

  bool get isSuccess => type == CloudAuthResultType.success;
}

/// Possible outcomes of a cloud sign-up attempt.
enum CloudSignUpResultType {
  success,
  emailAlreadyRegistered,
  networkUnavailable,
  unknownError,
}

class CloudSignUpResult {
  CloudSignUpResult._({
    required this.type,
    this.session,
    this.errorMessage,
  });

  factory CloudSignUpResult.success(Session session) => CloudSignUpResult._(
      type: CloudSignUpResultType.success, session: session);

  factory CloudSignUpResult.emailAlreadyRegistered() =>
      CloudSignUpResult._(type: CloudSignUpResultType.emailAlreadyRegistered);

  factory CloudSignUpResult.networkUnavailable() =>
      CloudSignUpResult._(type: CloudSignUpResultType.networkUnavailable);

  factory CloudSignUpResult.unknownError(String message) => CloudSignUpResult._(
      type: CloudSignUpResultType.unknownError, errorMessage: message);

  final CloudSignUpResultType type;
  final Session? session;
  final String? errorMessage;

  bool get isSuccess => type == CloudSignUpResultType.success;
}

/// Wraps Supabase Auth operations for the I Tech Store Management Application.
///
/// Architecture:
///   CloudAuthService accepts injectable [GoTrueClient] and [SupabaseClient]
///   for testability. The default singletons come from [Supabase.instance].
///
/// This service is the ONLY place that calls Supabase Auth directly.
/// All other services delegate authentication to this class.
class CloudAuthService {
  CloudAuthService({
    GoTrueClient? authClient,
    SupabaseClient? client,
  })  : _auth = authClient ?? Supabase.instance.client.auth,
        _client = client ?? Supabase.instance.client;

  final GoTrueClient _auth;
  final SupabaseClient _client;

  /// The currently authenticated user, if any.
  User? get currentUser => _auth.currentUser;

  /// The current persisted session, if any.
  Session? get currentSession => _auth.currentSession;

  /// Stream of auth state changes.
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  bool get isSignedIn => _auth.currentSession != null;

  /// Sign in with email and password.
  Future<CloudAuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      if (response.session != null) {
        return CloudAuthResult.success(response.session!);
      }
      return CloudAuthResult.invalidCredentials();
    } on AuthException catch (e) {
      return _mapAuthError(e);
    } catch (e) {
      if (_isNetworkError(e)) {
        return CloudAuthResult.networkUnavailable();
      }
      return CloudAuthResult.unknownError(e.toString());
    }
  }

  /// Create a new cloud account via sign-up.
  Future<CloudSignUpResult> signUp({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email.trim(),
        password: password,
      );
      if (response.session != null) {
        return CloudSignUpResult.success(response.session!);
      }
      // In dev mode (no email confirmation), signUp returns a session.
      // If no session, it means email confirmation is required.
      if (response.user != null) {
        return CloudSignUpResult.unknownError(
          'يرجى تأكيد البريد الإلكتروني قبل تسجيل الدخول',
        );
      }
      return CloudSignUpResult.unknownError('فشل إنشاء الحساب');
    } on AuthException catch (e) {
      return _mapSignUpError(e);
    } catch (e) {
      if (_isNetworkError(e)) {
        return CloudSignUpResult.networkUnavailable();
      }
      return CloudSignUpResult.unknownError(e.toString());
    }
  }

  /// Sign out — invalidates the JWT and refresh token server-side.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (_) {
      // Best-effort sign out; local state will still be cleared by caller.
    }
  }

  /// Get user shops via the `get_user_shops()` RPC.
  Future<List<Map<String, dynamic>>> getUserShops() async {
    final response = await _client.rpc('get_user_shops');
    return List<Map<String, dynamic>>.from(response as List);
  }

  /// Create a shop via the `create_shop_with_owner()` RPC.
  Future<String> createShopWithOwner(String shopName) async {
    final response = await _client.rpc('create_shop_with_owner', params: {
      'p_name': shopName,
    });
    return response as String;
  }

  /// Accept a pending invitation via the `accept_invitation()` RPC.
  Future<bool> acceptInvitation({
    required String shopId,
    required String userId,
  }) async {
    final response = await _client.rpc('accept_invitation', params: {
      'p_shop_id': shopId,
      'p_user_id': userId,
    });
    final result = Map<String, dynamic>.from(response as Map);
    return result['success'] == true;
  }

  /// Listen for auth state changes.
  void onAuthStateChange(void Function(AuthState) callback) {
    _auth.onAuthStateChange.listen(callback);
  }

  CloudAuthResult _mapAuthError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('invalid login credentials') ||
        message.contains('invalid grant')) {
      return CloudAuthResult.invalidCredentials();
    }
    if (message.contains('email not confirmed')) {
      return CloudAuthResult.emailNotConfirmed();
    }
    if (message.contains('already registered') ||
        message.contains('user already')) {
      return CloudAuthResult.emailAlreadyRegistered();
    }
    return CloudAuthResult.unknownError(e.message);
  }

  CloudSignUpResult _mapSignUpError(AuthException e) {
    final message = e.message.toLowerCase();
    if (message.contains('already registered') ||
        message.contains('user already')) {
      return CloudSignUpResult.emailAlreadyRegistered();
    }
    return CloudSignUpResult.unknownError(e.message);
  }

  bool _isNetworkError(Object e) {
    final text = e.toString().toLowerCase();
    return text.contains('socket') ||
        text.contains('connection') ||
        text.contains('network') ||
        text.contains('timeout') ||
        text.contains('host') ||
        text.contains('getaddrinfo');
  }
}
