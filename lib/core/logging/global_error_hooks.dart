import 'package:flutter/foundation.dart';
import 'package:movera/core/logging/driver_log.dart';

/// Routes framework and uncaught asynchronous errors into [DriverLog], so a
/// future crash-reporting sink sees them. Previous handlers keep running.
void installGlobalErrorHooks() {
  final previousFlutter = FlutterError.onError;
  FlutterError.onError = (details) {
    DriverLog.error(
      'Flutter framework error',
      details.exception,
      details.stack,
    );
    previousFlutter?.call(details);
  };
  final previousPlatform = PlatformDispatcher.instance.onError;
  PlatformDispatcher.instance.onError = (error, stack) {
    DriverLog.error('Uncaught async error', error, stack);
    return previousPlatform?.call(error, stack) ?? true;
  };
}
