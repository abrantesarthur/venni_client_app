import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_frontend/widgets/inputPhone.dart';

void main() {
  testWidgets("InputPhone correclty formats entered number",
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InputPhone(),
      ),
    ));

    // enter phone number
    await tester.enterText(find.byType(InputPhone), "38123456789");

    // expect number to be correctly formatted
    final phoneFinder = find.text("(38) 12345-6789");

    expect(phoneFinder, findsOneWidget);
  });

  testWidgets("InputPhone only allows numbers", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: InputPhone(),
      ),
    ));

    // enter phone number
    await tester.enterText(find.byType(InputPhone), "a");

    // expect number to be correctly formatted
    final phoneFinder = find.text("a");

    expect(phoneFinder, findsNothing);
  });
}
