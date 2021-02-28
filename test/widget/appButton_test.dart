import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rider_frontend/widgets/appButton.dart';

void main() {
  testWidgets("appButton has textData", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton(textData: "T", onTapCallBack: null),
      ),
    ));

    final textDataFinder = find.text("T");

    expect(textDataFinder, findsOneWidget);
  });

  testWidgets("appButton doesn't have icon", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton(textData: "T", onTapCallBack: null),
      ),
    ));

    final iconFinder = find.byType(Icon);

    expect(iconFinder, findsNothing);
  });

  testWidgets("appButton has an icon", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton(
            textData: "T", iconRight: Icons.arrow_forward, onTapCallBack: null),
      ),
    ));

    final iconFinder = find.byIcon(Icons.arrow_forward);

    expect(iconFinder, findsOneWidget);
  });

  testWidgets("appButton has an onTapCallback", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton(textData: "T", onTapCallBack: () {}),
      ),
    ));

    final onTapCallbackFinder = find.byType(GestureDetector);
    final gestureDetectorWidget =
        tester.firstWidget<GestureDetector>(onTapCallbackFinder);

    expect(gestureDetectorWidget,
        isA<GestureDetector>().having((g) => g.onTap, "onTap", isNotNull));
  });

  testWidgets("appButton has no onTapCallback", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton(textData: "T", onTapCallBack: null),
      ),
    ));

    final onTapCallbackFinder = find.byType(GestureDetector);
    final gestureDetectorWidget =
        tester.firstWidget<GestureDetector>(onTapCallbackFinder);

    expect(gestureDetectorWidget,
        isA<GestureDetector>().having((g) => g.onTap, "onTap", isNull));
  });

  testWidgets("appButton has correct height", (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: AppButton(textData: "T", onTapCallBack: null),
      ),
    ));

    final containerFinder = find
        .descendant(
            of: find.byType(GestureDetector), matching: find.byType(Container))
        .first;
    final containerSize = tester.getSize(containerFinder);
    expect(containerSize.height, 80);
  });
}
