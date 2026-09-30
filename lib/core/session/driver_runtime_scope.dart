import 'package:flutter/widgets.dart';
import 'package:movera/core/session/driver_session_controller.dart';

class DriverRuntimeScope extends InheritedWidget {
  const DriverRuntimeScope({
    super.key,
    required this.session,
    required this.homeBuilder,
    required super.child,
  });
  final DriverSessionController session;
  final Widget Function() homeBuilder;
  static DriverRuntimeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DriverRuntimeScope>();
  @override
  bool updateShouldNotify(DriverRuntimeScope oldWidget) =>
      oldWidget.session != session;
}
