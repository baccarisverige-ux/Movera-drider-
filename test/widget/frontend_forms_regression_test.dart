import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/core/settings/settings_repository.dart';
import 'package:movera/core/vehicle/vehicle_year_policy.dart';
import 'package:movera/presentation/driver/settings/emergency_contacts.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/presentation/driver/settings/sound%20%26%20voice/sound_voice.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FailedContacts extends SettingsRepository {
  bool fail = true;
  @override
  Future<Map<String, dynamic>> read(String section) async {
    if (fail) throw StateError('Storage unavailable');
    return {'rows': []};
  }
}

Widget app(Widget page) => ScreenUtilInit(
  designSize: const Size(375, 812),
  builder: (_, __) => MaterialApp(home: page),
);
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('025 year rollover supports next model year and saved older values', () {
    expect(
      VehicleYearPolicy.choices(now: DateTime(2026, 12, 31)).first,
      '2027',
    );
    expect(VehicleYearPolicy.choices(now: DateTime(2027, 1, 1)).first, '2028');
    expect(
      VehicleYearPolicy.choices(now: DateTime(2027), selected: '1970'),
      contains('1970'),
    );
  });
  testWidgets('016 support blank submission explains both missing fields', (
    tester,
  ) async {
    await tester.pumpWidget(app(const SupportInboxScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft local ticket'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save draft in demo'));
    await tester.tap(find.text('Save draft in demo'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a subject'), findsOneWidget);
    expect(find.text('Enter a message'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('016/018 contact validation survives a short keyboard viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetViewInsets);
    await tester.pumpWidget(app(const EmergencyContactsScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-emergency-contact')));
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 220);
    await tester.pump();
    await tester.ensureVisible(find.text('Save contact'));
    await tester.tap(find.text('Save contact'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
  });
  testWidgets('017 restore failure disables Add and exposes retry', (
    tester,
  ) async {
    final repo = FailedContacts();
    await tester.pumpWidget(app(EmergencyContactsScreen(repository: repo)));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('add-emergency-contact')),
          )
          .onPressed,
      isNull,
    );
    repo.fail = false;
    await tester.tap(find.text('Could not load trusted contacts — Retry'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<IconButton>(
            find.byKey(const ValueKey('add-emergency-contact')),
          )
          .onPressed,
      isNotNull,
    );
  });
  testWidgets('019 voice switches have independent semantic labels', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    try {
      await tester.pumpWidget(app(const SoundAndVoice()));
      await tester.pumpAndSettle();
      expect(find.bySemanticsLabel('Voice navigation'), findsOneWidget);
      expect(find.bySemanticsLabel('Read rider messages'), findsOneWidget);
    } finally {
      semantics.dispose();
    }
  });
}
