import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:movera/widgets/custom_btn.dart';
import 'package:movera/widgets/custom_textfield.dart';
import 'package:movera/widgets/dropdown.dart';

Future<void> open(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, _) => MaterialApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'R17 controller edits update dropdown selection without parent rebuild',
    (tester) async {
      final controller = TextEditingController(text: 'A');
      await open(
        tester,
        AppDropdownField(controller: controller, items: const ['A', 'B']),
      );
      controller.text = 'B';
      await tester.pump();
      final state = tester.state<FormFieldState<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(state.value, 'B');
      controller.clear();
      await tester.pump();
      expect(state.value, isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'R18 duplicate dropdown options do not assert or duplicate choices',
    (tester) async {
      final controller = TextEditingController(text: 'A');
      await open(
        tester,
        AppDropdownField(controller: controller, items: const ['A', 'A', 'B']),
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .items,
        hasLength(2),
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
    },
  );
  testWidgets(
    'R19 captured dropdown callback cannot access disposed controller',
    (tester) async {
      final controller = TextEditingController(text: 'A');
      var calls = 0;
      await open(
        tester,
        AppDropdownField(
          controller: controller,
          items: const ['A', 'B'],
          onChanged: (_) => calls++,
        ),
      );
      final callback = tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!;
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      callback('B');
      expect(calls, 0);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'R20 shared input delivers onChanged without a second enable flag',
    (tester) async {
      String? changed;
      await open(
        tester,
        customTextfield(onChanged: (String value) => changed = value),
      );
      await tester.enterText(find.byType(TextFormField), 'draft');
      expect(changed, 'draft');
      await open(tester, customTextfield(onChangedbool: true));
      await tester.enterText(find.byType(TextFormField), 'safe');
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('R21 nullable obscure setting behaves as an ordinary field', (
    tester,
  ) async {
    await open(tester, customTextfield(isobscure: null));
    expect(
      tester.widget<TextField>(find.byType(TextField)).obscureText,
      isFalse,
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'R22 obscured field ignores incompatible multiline configuration',
    (tester) async {
      await open(tester, customTextfield(isobscure: true, maxline: 4));
      final input = tester.widget<TextField>(find.byType(TextField));
      expect(input.maxLines, 1);
      expect(input.obscureText, isTrue);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('R23 loading shared button cannot reenter pending action', (
    tester,
  ) async {
    var calls = 0;
    await open(
      tester,
      CustomButton(
        centerContent: 'Save',
        isLoading: true,
        loader: const Text('Saving'),
        onPressed: () => calls++,
      ),
    );
    expect(
      tester.widget<MaterialButton>(find.byType(MaterialButton)).onPressed,
      isNull,
    );
    await tester.tap(find.text('Saving'));
    expect(calls, 0);
    expect(tester.takeException(), isNull);
  });
}
