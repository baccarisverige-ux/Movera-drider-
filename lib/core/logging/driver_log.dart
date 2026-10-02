import 'package:flutter/foundation.dart';

enum DriverLogLevel { info, warn, error }

/// One structured log record. Messages must not contain rider names, phone
/// numbers or free text; trip IDs and status names are allowed.
class DriverLogRecord {
  const DriverLogRecord({
    required this.level,
    required this.name,
    required this.message,
    this.error,
    this.stack,
  });

  final DriverLogLevel level;
  final String name;
  final String message;
  final Object? error;
  final StackTrace? stack;
}

/// Destination for log records. A crash-reporting adapter (with user consent
/// and PII scrubbing) implements this later; the default prints to console.
typedef DriverLogSink = void Function(DriverLogRecord record);

/// Single structured log seam for Driver.
class DriverLog {
  const DriverLog._();

  static DriverLogSink sink = _debugSink;

  static void _debugSink(DriverLogRecord record) {
    final prefix = switch (record.level) {
      DriverLogLevel.info => '',
      DriverLogLevel.warn => 'WARN ',
      DriverLogLevel.error => 'ERROR ',
    };
    final detail = record.error == null
        ? record.message
        : '${record.message}: ${record.error}';
    debugPrint('[${record.name}] $prefix$detail');
    if (record.stack != null) { debugPrint('${record.stack}'); }
  }

  static void info(String message, {String name = 'movera'}) {
    sink(DriverLogRecord(level: DriverLogLevel.info, name: name, message: message));
  }

  static void warn(String message, {String name = 'movera'}) {
    sink(DriverLogRecord(level: DriverLogLevel.warn, name: name, message: message));
  }

  static void error(
    String message, [
    Object? error,
    StackTrace? stack,
    String name = 'movera',
  ]) {
    sink(DriverLogRecord(
      level: DriverLogLevel.error,
      name: name,
      message: message,
      error: error,
      stack: stack,
    ));
  }
}
