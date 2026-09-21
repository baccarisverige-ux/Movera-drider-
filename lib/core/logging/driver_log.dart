import 'package:flutter/foundation.dart';

/// Single structured log seam for Driver. Swap for crash reporting later.
class DriverLog {
  const DriverLog._();

  static void info(String message, {String name = 'movera'}) {
    debugPrint('[$name] $message');
  }

  static void warn(String message, {String name = 'movera'}) {
    debugPrint('[$name] WARN $message');
  }

  static void error(
    String message, [
    Object? error,
    StackTrace? stack,
    String name = 'movera',
  ]) {
    final detail = error == null ? message : '$message: $error';
    debugPrint('[$name] ERROR $detail');
    if (stack != null) debugPrint('$stack');
  }
}
