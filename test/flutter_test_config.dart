import 'dart:async';

import 'package:movera/core/session/driver_runtime_config.dart';

/// Widget tests run without GPS hardware, network routing or an activated
/// demo account. These are explicit test policies, not binding detection.
const testRuntimeConfig = DriverRuntimeConfig(
  simulatedArrival: true,
  externalRouting: false,
  skipAccountActivation: true,
  liveMapTicker: false,
  reservationPopup: false,
  islandHint: false,
);

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  DriverRuntimeConfig.current = testRuntimeConfig;
  await testMain();
}
