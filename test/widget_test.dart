import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:farmadose/shared/widgets/app_button.dart';

void main() {
  testWidgets('AppButton renders provided label', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AppButton(
            label: 'Continuar',
            onPressed: null,
          ),
        ),
      ),
    );

    expect(find.text('Continuar'), findsOneWidget);
  });
}
