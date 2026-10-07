import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/support/local_support_repository.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/presentation/driver/sheets/movera_snap_sheet_controller.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DelayedDraft extends LocalSupportRepository {
  int reads = 0;
  final response = Completer<Map<String, dynamic>>();
  @override
  Future<Map<String, dynamic>> read() {
    reads++;
    return reads == 1 ? Future.value({}) : response.future;
  }

  @override
  Future<void> update(String field, Object value) async {}
}

class SnapHarness extends StatefulWidget {
  const SnapHarness({super.key});
  @override
  State<SnapHarness> createState() => SnapHarnessState();
}

class SnapHarnessState extends State<SnapHarness>
    with TickerProviderStateMixin {
  final panel = PanelController();
  late final snap = MoveraSnapSheetController(panel: panel, vsync: this);
  @override
  Widget build(BuildContext context) => Scaffold(
    body: SlidingUpPanel(
      controller: panel,
      minHeight: 50,
      maxHeight: 300,
      panelSnapping: false,
      panel: const Text('Panel'),
    ),
  );
  @override
  void dispose() {
    snap.dispose();
    super.dispose();
  }
}

void main() {
  testWidgets('011 delayed double tap opens one draft composer', (
    tester,
  ) async {
    final repo = DelayedDraft();
    await tester.pumpWidget(
      MaterialApp(home: SupportInboxScreen(repository: repo)),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft local ticket'));
    await tester.tap(find.text('Draft local ticket'));
    expect(repo.reads, 2);
    repo.response.complete({});
    await tester.pumpAndSettle();
    expect(find.text('Local ticket draft'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('013 snap to current position cancels the previous spring', (
    tester,
  ) async {
    final key = GlobalKey<SnapHarnessState>();
    await tester.pumpWidget(MaterialApp(home: SnapHarness(key: key)));
    await tester.pumpAndSettle();
    final state = key.currentState!;
    final old = state.snap.springTo(.9);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 70));
    final target = state.panel.panelPosition;
    await state.snap.springTo(target);
    expect(state.snap.isSpringing, false);
    await tester.pump(const Duration(seconds: 2));
    await old;
    expect(state.panel.panelPosition, closeTo(target, .003));
    await tester.pumpWidget(const SizedBox());
  });
}
