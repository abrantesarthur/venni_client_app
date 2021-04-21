import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_frontend/widgets/appInputText.dart';

void main() {
  testWidgets("AppInputText has hintText", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(
          hintText: "H",
        ),
      ),
    ));

    final textFieldFinder = find.byType(TextField);
    final textFieldWidget = tester.firstWidget(textFieldFinder);

    expect(
        textFieldWidget,
        isA<TextField>().having(
            (t) => t.decoration.hintText, "decoration.hintText", equals("H")));
  });

  testWidgets("AppInputText has no hintText", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(),
      ),
    ));

    final textFieldFinder = find.byType(TextField);
    final textFieldWidget = tester.firstWidget(textFieldFinder);

    expect(
        textFieldWidget,
        isA<TextField>().having(
            (t) => t.decoration.hintText, "decoration.hintText", isNull));
  });

  testWidgets("AppInputText has iconData", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(
          iconData: Icons.arrow_back,
        ),
      ),
    ));

    final iconFinder = find.byIcon(Icons.arrow_back);
    expect(iconFinder, findsOneWidget);
  });

  testWidgets("AppInputText has no iconData", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(),
      ),
    ));

    final iconFinder = find.byIcon(Icons.arrow_back);
    expect(iconFinder, findsNothing);
  });

  testWidgets("AppInputText has no onSubmittedCallback",
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(),
      ),
    ));

    final textFieldFinder = find.byType(TextField);
    final textFieldWidget = tester.firstWidget<TextField>(textFieldFinder);

    expect(textFieldWidget,
        isA<TextField>().having((t) => t.onSubmitted, "onSubmitted", isNull));
  });

  testWidgets("AppInputText has no inputFormatters",
      (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(),
      ),
    ));

    final textFieldFinder = find.byType(TextField);
    final textFieldWidget = tester.firstWidget<TextField>(textFieldFinder);

    expect(
        textFieldWidget,
        isA<TextField>()
            .having((t) => t.inputFormatters, "inputFormatters", isNull));
  });

  testWidgets("AppInputText has no controller", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppInputText(),
      ),
    ));

    final textFieldFinder = find.byType(TextField);
    final textFieldWidget = tester.firstWidget<TextField>(textFieldFinder);

    expect(textFieldWidget,
        isA<TextField>().having((t) => t.controller, "controller", isNull));
  });

  testWidgets("AppInputText correclty displays inserted text", (
    WidgetTester tester,
  ) async {
    // build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInputText(),
        ),
      ),
    );

    // Enter 'hi' into the TextField.
    await tester.enterText(find.byType(TextField), 'hi');

    final textFinder = find.text("hi");

    expect(textFinder, findsOneWidget);
  });

  testWidgets("AppInputText shows keyboard when tapping widget", (
    WidgetTester tester,
  ) async {
    // build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInputText(),
        ),
      ),
    );

    // Tap widget
    await tester.tap(find.byType(AppInputText));

    expect(true, tester.testTextInput.isVisible);
  });

  testWidgets("AppInputText correctly calls onSubmittedCallback", (
    WidgetTester tester,
  ) async {
    // define the callback function
    void callback(String param) {
      print("hi");
    }

    // build the widget
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppInputText(
            onSubmittedCallback: callback,
          ),
        ),
      ),
    );

    // Enter 'hi' into the TextField
    await tester.enterText(find.byType(TextField), "hi");

    // Expect 'hi' to be printed
    expectLater(() => tester.testTextInput.receiveAction(TextInputAction.done),
        prints("hi\n"));
  });
}
