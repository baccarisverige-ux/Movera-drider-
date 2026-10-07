import 'package:flutter/material.dart';

/// One push per navigator while its entry animation owns the transition.
/// Stale callbacks from an obscured page cannot add another route.
final _entries = Expando<Object>();
Future<T?> pushSingle<T extends Object?>(
  BuildContext context,
  Route<T> route, {
  bool rootNavigator = false,
}) {
  if (!context.mounted || ModalRoute.of(context)?.isCurrent == false) {
    return Future<T?>.value();
  }
  final navigator = Navigator.of(context, rootNavigator: rootNavigator);
  if (_entries[navigator] != null) return Future<T?>.value();
  final token = Object();
  _entries[navigator] = token;
  Animation<double>? animation;
  late AnimationStatusListener listener;
  void release() {
    animation?.removeStatusListener(listener);
    if (identical(_entries[navigator], token)) _entries[navigator] = null;
  }

  listener = (status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      release();
    }
  };
  try {
    final result = navigator.push<T>(route);
    animation = route is TransitionRoute<T> ? route.animation : null;
    animation?.addStatusListener(listener);
    if (animation == null || animation.isCompleted) {
      WidgetsBinding.instance.addPostFrameCallback((_) => release());
    }
    result.then(
      (_) => release(),
      onError: (Object _, StackTrace __) => release(),
    );
    return result;
  } catch (_) {
    release();
    rethrow;
  }
}
