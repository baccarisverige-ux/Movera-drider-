import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/common/chat/chat.dart';

void main() {
  testWidgets('chat disposes its message controller', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (_, __) => MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const Chat(riderDisplayName: 'Maya'),
                      ),
                    );
                  },
                  child: const Text('Open chat'),
                ),
              );
            },
          ),
        ),
      ),
    );

    for (var i = 0; i < 8; i++) {
      await tester.tap(find.text('Open chat'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField), 'On my way');
      await tester.pump();
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(tester.takeException(), isNull);
    }
    expect(find.byType(Chat), findsNothing);
  });
}
