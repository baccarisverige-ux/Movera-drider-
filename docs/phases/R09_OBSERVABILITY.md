# R09 - Error routing seam

Source: deep re-audit of 2 October 2026 (N22).

- `DriverLog` emits `DriverLogRecord`s to a replaceable `DriverLog.sink`. The default still prints to the console.
- `installGlobalErrorHooks()` (called in `main`) routes `FlutterError.onError` and `PlatformDispatcher.onError` into `DriverLog` and keeps any previous handler.

## Not done

No crash-reporting vendor (Sentry, Crashlytics) is added. That needs an account, a DSN secret, a consent decision and a privacy notice update. Write the vendor adapter as a `DriverLogSink` that scrubs rider names, phones and addresses, and enable it only after consent.
