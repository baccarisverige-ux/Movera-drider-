import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/presentation/driver/auth/create%20acc/create_acc.dart';
import 'package:movera/presentation/driver/auth/create%20acc/create_acc_phone.dart';
import 'package:movera/presentation/driver/auth/phone%20verification/phone_verify.dart';
import 'package:movera/widgets/custom_btn.dart';

void main() {
  final screens = <String, Widget>{
    'create account': const DriverCreateAccount(),
    'create account phone': const DriverCreateAccountPhone(),
    'verification': const DriverPhoneVerification(),
  };
  for (final entry in screens.entries) {
    for (final size in [const Size(320, 568), const Size(568, 320)]) {
      testWidgets(
        '${entry.key} keeps growing buttons reachable at 200% in $size',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          await tester.pumpWidget(
            ScreenUtilInit(
              designSize: const Size(375, 812),
              builder: (_, _) => MaterialApp(
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: TextScaler.linear(2)),
                  child: child!,
                ),
                home: entry.value,
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(find.byType(CustomButton).hitTestable(), findsOneWidget);
          final rect = tester.getRect(find.byType(CustomButton));
          expect(rect.bottom, lessThanOrEqualTo(size.height));
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
