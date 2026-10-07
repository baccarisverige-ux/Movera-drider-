import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/widgets/single_route_entry.dart';

class Entries extends NavigatorObserver {
  int pushes = 0;
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    pushes++;
  }
}

void main() {
  testWidgets(
    'two immediate pushes create one route and back permits reopening',
    (tester) async {
      final observer = Entries();
      late BuildContext source;
      await tester.pumpWidget(
        MaterialApp(
          navigatorObservers: [observer],
          home: Builder(
            builder: (context) {
              source = context;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );
      void open() {
        pushSingle(
          source,
          MaterialPageRoute<void>(
            builder: (_) => const Scaffold(body: Text('Details')),
          ),
        );
      }

      open();
      open();
      await tester.pumpAndSettle();
      expect(observer.pushes, 2);
      expect(find.text('Details'), findsOneWidget);
      Navigator.of(tester.element(find.text('Details'))).pop();
      await tester.pumpAndSettle();
      open();
      await tester.pumpAndSettle();
      expect(observer.pushes, 3);
    },
  );
}
