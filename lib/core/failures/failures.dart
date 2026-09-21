/// Typed failures for driver-facing flows.
///
/// Presentation maps these to safe copy. Diagnostics may log [cause].
sealed class MoveraFailure implements Exception {
  const MoveraFailure(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class LocationFailure extends MoveraFailure {
  const LocationFailure(super.message, {super.cause});
}

class RouteFailure extends MoveraFailure {
  const RouteFailure(super.message, {super.cause});
}

class DispatchFailure extends MoveraFailure {
  const DispatchFailure(super.message, {super.cause});
}

class ClaimFailure extends MoveraFailure {
  const ClaimFailure(super.message, {super.cause});
}

class WaybillFailure extends MoveraFailure {
  const WaybillFailure(super.message, {super.cause});
}
