import 'package:flutter/material.dart';
class DemoModeBanner extends StatelessWidget {
 const DemoModeBanner({super.key});
 @override
 Widget build(BuildContext context) => SafeArea(bottom: false,
 child: Semantics(label: 'Demo mode — no account', child: ColoredBox(
 color: Color(0xFFF4F6F7), child: Padding(padding: EdgeInsets.all(4),
 child: Center(child: Text('Demo mode — no account', style: TextStyle(fontSize: 12, color: Color(0xFF252E3A))))))));
}
