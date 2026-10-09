import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/admin/driver_home_admin_content.dart';
import 'package:movera/presentation/driver/home/components/app_update_sheet.dart';

AppUpdateAdminConfig _config({
  bool mandatory = false,
  String? url = 'https://example.com/update',
}) => AppUpdateAdminConfig(
  enabled: true,
  latestVersion: '2.0.0',
  minimumVersion: '1.0.0',
  title: 'Update available',
  message: 'Install the latest version.',
  actionLabel: 'Update now',
  dismissLabel: 'Later',
  mandatory: mandatory,
  updateUrl: url,
);

Future<GlobalKey<NavigatorState>> _open(
  WidgetTester tester,
  AppUpdateAdminConfig config,
  Future<bool> Function(Uri) launch,
) async {
  final navigator = GlobalKey<NavigatorState>();
  await tester.pumpWidget(
    MaterialApp(
      navigatorKey: navigator,
      home: const Scaffold(body: Text('Home owner')),
    ),
  );
  showModalBottomSheet<void>(
    context: navigator.currentContext!,
    isDismissible: !config.mandatory,
    enableDrag: !config.mandatory,
    builder: (_) => AppUpdateSheet(update: config, launchUpdate: launch),
  );
  await tester.pumpAndSettle();
  return navigator;
}

VoidCallback _update(WidgetTester tester) =>
    tester.widget<FilledButton>(find.byType(FilledButton)).onPressed!;

void main() {
  for (final throws in [false, true]) {
    testWidgets(
      'update ${throws ? 'exception' : 'false result'} remains visible and can retry',
      (tester) async {
        var launches = 0;
        await _open(tester, _config(mandatory: true), (_) async {
          launches++;
          if (launches == 1) {
            if (throws) throw StateError('Launcher unavailable');
            return false;
          }
          return true;
        });
        _update(tester)();
        await tester.pumpAndSettle();
        expect(find.byKey(const ValueKey('app-update-error')), findsOneWidget);
        expect(find.byType(AppUpdateSheet), findsOneWidget);
        _update(tester)();
        await tester.pumpAndSettle();
        expect(launches, 2);
        expect(find.byKey(const ValueKey('app-update-error')), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('mandatory prompt blocks system Back even with no update URL', (
    tester,
  ) async {
    var launches = 0;
    final navigator = await _open(tester, _config(mandatory: true, url: null), (
      _,
    ) async {
      launches++;
      return true;
    });
    _update(tester)();
    await tester.pumpAndSettle();
    expect(launches, 0);
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateSheet), findsOneWidget);
    expect(find.byKey(const ValueKey('app-update-error')), findsOneWidget);
    expect(find.text('Later'), findsNothing);
  });

  testWidgets(
    'update handoff is single flight and late completion after dismissal is safe',
    (tester) async {
      var launches = 0;
      final pending = Completer<bool>();
      await _open(tester, _config(), (_) {
        launches++;
        return pending.future;
      });
      final update = _update(tester);
      update();
      update();
      await tester.pumpAndSettle();
      expect(launches, 1);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      pending.completeError(StateError('Late failure'));
      update();
      await tester.pumpAndSettle();
      expect(find.byType(AppUpdateSheet), findsNothing);
      expect(launches, 1);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('optional prompt supports system Back and readable action text', (
    tester,
  ) async {
    final navigator = await _open(tester, _config(), (_) async => true);
    final style = tester.widget<FilledButton>(find.byType(FilledButton)).style!;
    expect(style.foregroundColor!.resolve({}), Colors.white);
    await navigator.currentState!.maybePop();
    await tester.pumpAndSettle();
    expect(find.byType(AppUpdateSheet), findsNothing);
  });
}
