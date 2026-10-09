import 'package:flutter/widgets.dart';

/// Close only the route that owns this callback. Outgoing widgets stay mounted
/// during reverse transitions, but must never pop the newly exposed route.
bool popOwned<T extends Object?>(BuildContext context, [T? result]) {
  if (!context.mounted || ModalRoute.of(context)?.isCurrent != true) {
    return false;
  }
  Navigator.of(context).pop<T>(result);
  return true;
}
