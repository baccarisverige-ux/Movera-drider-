import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/session/driver_runtime_scope.dart';
import 'package:movera/core/session/driver_session_controller.dart';

class _Consumer extends StatelessWidget {
  const _Consumer();
  @override
  Widget build(BuildContext context) {
    final scope = DriverRuntimeScope.maybeOf(context)!;
    return Column(
      children: [
        scope.homeBuilder(),
        TextButton(onPressed: scope.logout, child: const Text('Logout')),
      ],
    );
  }
}

void main() {
  testWidgets(
    'replacing home and logout with the same session updates dependent consumers',
    (tester) async {
      final session = DriverSessionController();
      addTearDown(session.dispose);
      var oldLogouts = 0;
      var newLogouts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: DriverRuntimeScope(
            session: session,
            homeBuilder: () => const Text('Old home'),
            logout: () async {
              oldLogouts++;
            },
            child: const Scaffold(body: _Consumer()),
          ),
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: DriverRuntimeScope(
            session: session,
            homeBuilder: () => const Text('New home'),
            logout: () async {
              newLogouts++;
            },
            child: const Scaffold(body: _Consumer()),
          ),
        ),
      );
      expect(find.text('Old home'), findsNothing);
      expect(find.text('New home'), findsOneWidget);
      await tester.tap(find.text('Logout'));
      await tester.pump();
      expect(oldLogouts, 0);
      expect(newLogouts, 1);
    },
  );

  testWidgets(
    'adding logout without replacing session enables the current action',
    (tester) async {
      final session = DriverSessionController();
      addTearDown(session.dispose);
      Widget home() => const Text('Home');
      Widget root(Future<void> Function()? logout) => MaterialApp(
        home: DriverRuntimeScope(
          session: session,
          homeBuilder: home,
          logout: logout,
          child: const Scaffold(body: _Consumer()),
        ),
      );
      await tester.pumpWidget(root(null));
      expect(
        tester.widget<TextButton>(find.byType(TextButton)).onPressed,
        isNull,
      );
      var logouts = 0;
      await tester.pumpWidget(
        root(() async {
          logouts++;
        }),
      );
      await tester.tap(find.text('Logout'));
      await tester.pump();
      expect(logouts, 1);
    },
  );
}
