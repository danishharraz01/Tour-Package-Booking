import 'package:flutter/foundation.dart';

/// Runtime configuration.
///
/// Override the API URL at build time:
/// `flutter run --dart-define=API_BASE_URL=https://api.example.com`
class AppConfig {
  AppConfig._();

  static const _override = String.fromEnvironment('API_BASE_URL');

  /// Shows the "Use demo account" shortcut on the sign-in screen. Off in release builds, because
  /// production has no demo accounts. Enable for a demo build with `--dart-define=SHOW_DEMO_LOGIN=true`.
  static const showDemoLogin = bool.fromEnvironment('SHOW_DEMO_LOGIN', defaultValue: !kReleaseMode);

  static String get apiBaseUrl {
    if (_override.isNotEmpty) return _override;
    // The Android emulator reaches the host machine through 10.0.2.2.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:4000';
    }
    return 'http://localhost:4000';
  }
}
