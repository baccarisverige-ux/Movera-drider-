import 'package:flutter/widgets.dart';

/// One external handoff at a time; null means the callback no longer owns UI.
class OwnedExternalAction {
  bool _running = false;

  Future<bool?> run(
    BuildContext context,
    Future<bool> Function() action,
  ) async {
    if (!context.mounted || _running) return null;
    final owner = ModalRoute.of(context);
    if (owner == null || !owner.isCurrent) return null;
    _running = true;
    var succeeded = false;
    try {
      succeeded = await action();
    } catch (_) {
      succeeded = false;
    } finally {
      _running = false;
    }
    if (!context.mounted ||
        !owner.isCurrent ||
        ModalRoute.of(context) != owner) {
      return null;
    }
    return succeeded;
  }
}
