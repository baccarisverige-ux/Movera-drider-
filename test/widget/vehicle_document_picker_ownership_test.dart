import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';
import 'package:movera/presentation/driver/auth/additional detail/screens/vehicle_insurance.dart';
import 'package:movera/presentation/driver/auth/additional detail/screens/vehicle_registeration.dart';

class _DelayedPhoto extends XFile {
  _DelayedPhoto() : super('photo.jpg');
  final bytes = Completer<Uint8List>();
  @override
  Future<Uint8List> readAsBytes() => bytes.future;
}

Future<void> _open(WidgetTester tester, Widget child) async {
  tester.view.physicalSize = const Size(430, 1000);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

VoidCallback _tap(WidgetTester tester, String label) => tester
    .widget<TextButton>(
      find
          .ancestor(of: find.text(label), matching: find.byType(TextButton))
          .first,
    )
    .onPressed!;

void main() {
  for (final insurance in [false, true]) {
    Widget screen(
      Future<PlatformFile?> Function() file,
      Future<XFile?> Function() camera,
    ) => insurance
        ? AdditionDetailVehicleInsurance(
            circleProgress: (_, _) => const SizedBox(),
            selectFile: file,
            capturePhoto: camera,
          )
        : AdditionDetailVehicleRegisteration(
            circleProgress: (_, _) => const SizedBox(),
            selectFile: file,
            capturePhoto: camera,
          );

    testWidgets(
      '${insurance ? 'insurance' : 'registration'} file and camera share one pending lock',
      (tester) async {
        var picks = 0;
        var photos = 0;
        final file = Completer<PlatformFile?>();
        await _open(
          tester,
          screen(
            () {
              picks++;
              return file.future;
            },
            () async {
              photos++;
              return null;
            },
          ),
        );
        final upload = _tap(tester, 'Tap to upload');
        final camera = _tap(tester, 'Open Camera');
        upload();
        upload();
        camera();
        await tester.pump();
        expect(picks, 1);
        expect(photos, 0);
        file.complete(
          PlatformFile(
            name: 'document.pdf',
            size: 3,
            bytes: Uint8List.fromList([1, 2, 3]),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('document.pdf'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${insurance ? 'insurance' : 'registration'} late picker result after disposal is safe',
      (tester) async {
        final file = Completer<PlatformFile?>();
        await _open(tester, screen(() => file.future, () async => null));
        final upload = _tap(tester, 'Tap to upload');
        upload();
        await tester.pumpWidget(const SizedBox());
        file.completeError(StateError('Late picker failure'));
        upload();
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${insurance ? 'insurance' : 'registration'} disposal during photo byte read is safe',
      (tester) async {
        final photo = _DelayedPhoto();
        await _open(tester, screen(() async => null, () async => photo));
        _tap(tester, 'Open Camera')();
        await tester.pump();
        await tester.pumpWidget(const SizedBox());
        photo.bytes.complete(Uint8List.fromList([1, 2, 3]));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      '${insurance ? 'insurance' : 'registration'} unreadable file reports an error and allows retry',
      (tester) async {
        var picks = 0;
        await _open(
          tester,
          screen(() async {
            picks++;
            return PlatformFile(name: 'empty.pdf', size: 0);
          }, () async => null),
        );
        _tap(tester, 'Tap to upload')();
        await tester.pumpAndSettle();
        expect(find.text('empty.pdf'), findsNothing);
        expect(
          find.text('Could not read the selected file. Please try again.'),
          findsOneWidget,
        );
        _tap(tester, 'Tap to upload')();
        await tester.pumpAndSettle();
        expect(picks, 2);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
