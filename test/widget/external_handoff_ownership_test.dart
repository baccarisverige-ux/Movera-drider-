import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/presentation/driver/settings/emergency_contacts.dart';
import 'package:movera/widgets/owned_external_action.dart';

class _Settings extends SettingsRepository {
  @override
  Future<Map<String, dynamic>> read(String section) async => {};
}

Future<GlobalKey<NavigatorState>> _open(
  WidgetTester tester,
  Future<bool> Function(Uri) launch,
) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        navigatorKey: navigator,
        home: EmergencyContactsScreen(
          repository: _Settings(),
          launchDialer: launch,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return navigator;
}

VoidCallback _call(WidgetTester tester) => tester
    .widget<IconButton>(
      find.byWidgetPredicate(
        (widget) =>
            widget is IconButton &&
            widget.tooltip == 'Call Emergency services — 112',
      ),
    )
    .onPressed!;

void main() {
  testWidgets(
    'trusted-contact dialer handoff is single flight and failed handoff can retry',
    (tester) async {
      var calls = 0;
      final pending = Completer<bool>();
      await _open(tester, (uri) {
        expect(uri.toString(), 'tel:112');
        calls++;
        return pending.future;
      });
      final call = _call(tester);
      call();
      call();
      await tester.pump();
      expect(calls, 1);
      pending.complete(false);
      await tester.pumpAndSettle();
      expect(find.text('Dialer is unavailable.'), findsOneWidget);
      call();
      await tester.pumpAndSettle();
      expect(calls, 2);
      expect(tester.takeException(), isNull);
    },
  );

  for (final disposed in [false, true]) {
    testWidgets(
      'late dialer error and stale callbacks are ignored after ${disposed ? 'disposal' : 'covering'}',
      (tester) async {
        var calls = 0;
        final pending = Completer<bool>();
        final navigator = await _open(tester, (_) {
          calls++;
          return pending.future;
        });
        final call = _call(tester);
        call();
        if (disposed) {
          await tester.pumpWidget(const SizedBox());
        } else {
          navigator.currentState!.push(
            MaterialPageRoute<void>(
              builder: (_) => const Scaffold(body: Text('Covering owner')),
            ),
          );
        }
        await tester.pumpAndSettle();
        call();
        pending.completeError(StateError('Dialer unavailable'));
        await tester.pumpAndSettle();
        expect(calls, 1);
        expect(find.byType(SnackBar), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'shared external-action handler catches launch exceptions and releases its lock',
    (tester) async {
      late BuildContext owner;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              owner = context;
              return const Scaffold();
            },
          ),
        ),
      );
      final action = OwnedExternalAction();
      final failure = action.run(
        owner,
        () async => throw StateError('Platform failure'),
      );
      await tester.pump();
      expect(await failure, isFalse);
      final retry = action.run(owner, () async => true);
      await tester.pump();
      expect(await retry, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
}
