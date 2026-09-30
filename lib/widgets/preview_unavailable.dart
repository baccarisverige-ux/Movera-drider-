import 'package:flutter/material.dart';
class PreviewUnavailable extends StatelessWidget {
 const PreviewUnavailable({super.key, required this.label, required this.child});
 final String label;
 final Widget child;
 @override
 Widget build(BuildContext context) => Semantics(enabled: false, label: '$label — unavailable in demo',
 child: Tooltip(message: '$label — unavailable in demo', child: AbsorbPointer(child: child)));
}
