import 'package:flutter/foundation.dart';

/// A small centralized logging helper to control debug output across the app.
/// Use LogService.debug / info / error instead of calling `debugPrint` directly.
class LogService {
  /// Toggle this to enable/disable logs at runtime (defaults to build-time kDebugMode).
  static bool enabled = kDebugMode;

  static void debug(String message) {
    if (enabled) {
      // ignore: avoid_print
      // Use debugPrint under the hood to avoid polluting release logs.
      // Kept simple so it can later be extended to route logs to an in-app debug panel.
      // Using debugPrint directly preserves existing behavior while centralizing control.
      // ignore: avoid_print
      debugPrint(message);
    }
  }

  static void info(String message) {
    if (enabled) debugPrint(message);
  }

  static void error(String message) {
    // Errors are useful even in some non-debug scenarios; respect enabled flag for now.
    if (enabled) debugPrint('ERROR: $message');
  }
}
