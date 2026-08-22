import 'dart:io';

import 'package:flutter/foundation.dart';

/// Centralized, truthful platform identity (Phase K D6/D8).
///
/// Single source of truth for "which platform is the app actually running
/// on" so business and UI code never scatter `Platform.isAndroid` checks.
/// Reporting through this seam must reflect reality: an Android client never
/// reports as Windows and vice versa. Desktop behavior remains byte-identical
/// to the pre-Phase-K application.
class PlatformCapabilities {
  const PlatformCapabilities._();

  /// True only when running on a real Android target.
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;

  /// True only when running on a real Windows desktop target.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  /// True for desktop-class targets where the historical Windows filesystem
  /// semantics (native file dialogs, arbitrary user-selected paths) apply.
  static bool get supportsDesktopFilesystem =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
}
