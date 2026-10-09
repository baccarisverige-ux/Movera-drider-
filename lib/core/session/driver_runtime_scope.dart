import 'package:flutter/widgets.dart';
import 'package:movera/core/session/driver_session_controller.dart';

class DriverRuntimeScope extends InheritedWidget {
  const DriverRuntimeScope({
    super.key,
    required this.session,
    required this.homeBuilder,
    this.logout,
    required super.child,
  });
  final DriverSessionController session;
  final Widget Function() homeBuilder;

  /// App-level logout: drains storage, clears local data and resets every
  /// long-lived demo service owned by the composition root.
  final Future<void> Function()? logout;
  static DriverRuntimeScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DriverRuntimeScope>();
  @override
  bool updateShouldNotify(DriverRuntimeScope oldWidget) =>
      oldWidget.session != session ||
      oldWidget.homeBuilder != homeBuilder ||
      oldWidget.logout != logout;
}
