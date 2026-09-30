import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:movera/presentation/driver/documents/documents.dart';
import 'package:movera/presentation/driver/profile/profile.dart';
import 'package:movera/presentation/driver/settings/settings.dart';
import 'package:movera/presentation/driver/preferences/preferences.dart';
import 'package:movera/presentation/driver/settings/accessibility/accessibility.dart';
import 'package:movera/presentation/driver/settings/sound%20&%20voice/sound_voice.dart';
import 'package:movera/presentation/driver/scheduled%20rides/scheduled_rides.dart';
import 'package:movera/presentation/driver/support/support_inbox.dart';
import 'package:movera/presentation/driver/my%20bank/my_bank.dart';
import 'package:movera/presentation/driver/my%20bank/add%20new%20account/add_new_account.dart';
import 'package:movera/presentation/driver/vehicles/vehicles.dart';
import 'package:movera/presentation/driver/driving%20logs/driving_logs.dart';
import 'package:movera/presentation/driver/settings/emergency_contacts.dart';
import 'package:movera/presentation/driver/destination%20mode/destination_picker.dart';
import 'package:movera/presentation/driver/ride%20history/ride_history.dart';
import 'package:movera/presentation/driver/analytics/analytics.dart';
import 'package:movera/presentation/driver/documents/document_preview.dart';
void main() {
 setUp(() => SharedPreferences.setMockInitialValues({}));
 final screens=<String,Widget>{
'DriverDocuments': const DriverDocuments(),
'DriverProfile': const DriverProfile(),
'Settings': const Settings(),
'Preferences': const Preferences(),
'Accessibility': const Accessibility(),
'SoundAndVoice': const SoundAndVoice(),
'ScheduledRidesScreen': const ScheduledRidesScreen(),
'SupportInboxScreen': const SupportInboxScreen(),
'MyBank': const MyBank(),
'AddNewAccount': const AddNewAccount(),
'DriverVehicles': const DriverVehicles(),
'DrivingLogs': const DrivingLogs(),
'EmergencyContactsScreen': const EmergencyContactsScreen(),
'DriverDestinationPicker': const DriverDestinationPicker(),
'DriverRideHistory': const DriverRideHistory(),
'Analytics': const Analytics(),
'DocumentPreview': const DocumentPreview(title: 'Driver’s License'),
 };
 for(final size in [const Size(320,700),const Size(375,812),const Size(430,932)]) {
  for(final screen in screens.entries) {
   testWidgets('${screen.key} navigation and 200% layout at $size',(tester) async {
    await tester.binding.setSurfaceSize(size);addTearDown(()=>tester.binding.setSurfaceSize(null));
    final nav=GlobalKey<NavigatorState>();
    await tester.pumpWidget(ScreenUtilInit(designSize:const Size(375,812),builder:(_,__)=>MaterialApp(
      navigatorKey:nav,builder:(context,child)=>MediaQuery(data:MediaQuery.of(context).copyWith(textScaler:TextScaler.linear(2)),child:child!),
      home:const Scaffold(body:Text('Crawl root')))));
    nav.currentState!.push(MaterialPageRoute<void>(builder:(_)=>screen.value));
    for(var i=0;i<12;i++) { await tester.pump(const Duration(milliseconds:40)); }
    final exception=tester.takeException();expect(exception,isNull,reason:'${screen.key} $size: $exception');
    nav.currentState!.pop();await tester.pumpAndSettle();
    expect(find.text('Crawl root'),findsOneWidget);expect(tester.takeException(),isNull);
   });
  }
 }
 testWidgets('document preview screenshot smoke produces a PNG',(tester) async {
  final key=GlobalKey();
  await tester.pumpWidget(MaterialApp(home:RepaintBoundary(key:key,child:const DocumentPreview(title:'License'))));
  await tester.pumpAndSettle();
  final boundary=key.currentContext!.findRenderObject() as RenderRepaintBoundary;
  await tester.runAsync(() async {
    final image=await boundary.toImage(pixelRatio:1);final bytes=await image.toByteData(format:ui.ImageByteFormat.png);
    expect(bytes,isNotNull);expect(bytes!.lengthInBytes,greaterThan(100));
    Directory('build/test-evidence').createSync(recursive:true);
    File('build/test-evidence/document-preview.png').writeAsBytesSync(bytes.buffer.asUint8List());image.dispose();
  });
 });
}
