import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/mocks.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/addCreditCard.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/warning.dart';

void main() {
  setUp(() async {});

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>(
          create: (context) => mockUserModel,
        ),
      ],
      builder: (context, child) {
        return MaterialApp(
          home: AddCreditCard(),
          navigatorObservers: [mockNavigatorObserver],
        );
      },
    ));
  }

  group("Input Texts", () {
    testWidgets(
      "tapping a field highlights its title",
      (WidgetTester tester) async {
        await pumpWidget(tester);

        // get field widgets
        final fieldFinders = find.byType(AppInputText);
        expect(fieldFinders, findsNWidgets(9));
        final cardNumberWidget = tester.widget(fieldFinders.at(0));
        final cardNameWidget = tester.widget(fieldFinders.at(1));
        final expirationDateWidget = tester.widget(fieldFinders.at(2));
        final cvvWidget = tester.widget(fieldFinders.at(3));
        final cpfWidget = tester.widget(fieldFinders.at(4));
        final streetNameWidget = tester.widget(fieldFinders.at(5));
        final streetNumberWidget = tester.widget(fieldFinders.at(6));
        final cityWidget = tester.widget(fieldFinders.at(7));
        final cepWidget = tester.widget(fieldFinders.at(8));

        void testNoHighlight(Widget widget, String title) {
          expect(
            widget,
            isA<AppInputText>()
                .having((c) => c.title, "title", title)
                .having((c) => c.titleStyle, "titleStyle", isNull),
          );
        }

        // expect all widgets not to have highlighted titles
        testNoHighlight(cardNumberWidget, "Número do cartão");
        testNoHighlight(cardNameWidget, "Nome (como está no cartão)");
        testNoHighlight(expirationDateWidget, "Data de expiração");
        testNoHighlight(cvvWidget, "Código de segurança");
        testNoHighlight(cpfWidget, "CPF do titular");
        testNoHighlight(streetNameWidget, "Rua");
        testNoHighlight(streetNumberWidget, "Número");
        testNoHighlight(cityWidget, "Cidade");
        testNoHighlight(cepWidget, "CEP");

        Future<void> testHighlight(Finder finder, String title) async {
          await tester.tap(finder);
          await tester.pumpAndSettle();

          expect(
            tester.widget(finder),
            isA<AppInputText>()
                .having((c) => c.title, "title", title)
                .having((c) => c.focusNode.hasFocus, "hasFocus", isTrue)
                .having((c) => c.titleStyle, "titleStyle", isNotNull)
                .having((c) => c.titleStyle.color, "titleStyle",
                    AppColor.primaryPink),
          );
        }

        // tapping widgets highlights them
        await testHighlight(fieldFinders.at(0), "Número do cartão");
        await testHighlight(fieldFinders.at(1), "Nome (como está no cartão)");
        await testHighlight(fieldFinders.at(2), "Data de expiração");
        await testHighlight(fieldFinders.at(3), "Código de segurança");
        await testHighlight(fieldFinders.at(4), "CPF do titular");
      },
    );
  });

  group("warnings", () {
    testWidgets(
      "empty warning is shown if field is left empty",
      (WidgetTester tester) async {
        await pumpWidget(tester);

        // get warning finders
        final warnings = find.byType(Warning);

        // get field finders
        final fieldFinders = find.byType(AppInputText);
        expect(fieldFinders, findsNWidgets(9));

        // no warnings are shown at first
        expect(warnings, findsNothing);

        Future<void> testEmptyWarnings(
          int thisWidgetAt,
          int nextWidgetAt,
          int expectedWarningCount,
          String expectedWarningMessage,
        ) async {
          // tapping into a field and then into another displays warning in first
          await tester.tap(fieldFinders.at(thisWidgetAt));
          await tester.pumpAndSettle();
          await tester.tap(fieldFinders.at(nextWidgetAt));
          await tester.pumpAndSettle();
          expect(warnings, findsNWidgets(expectedWarningCount));
          final warningWidget = tester.widget(
            expectedWarningCount == 1 ? warnings : warnings.at(thisWidgetAt),
          );
          expect(
              warningWidget,
              isA<Warning>()
                  .having((w) => w.message, "message", expectedWarningMessage));
        }

        await testEmptyWarnings(
            0, 1, 1, "insira um número de cartão de crédito");
        await testEmptyWarnings(1, 2, 2, "insira o nome do titular");
        await testEmptyWarnings(2, 3, 3, "insira uma data");
        await testEmptyWarnings(3, 4, 4, "insira um cvv");
      },
    );
  });
}

/**
 * warning
 *    empty warning is shown if use taps field and leaves it empty
 *    invalid warning is shown if field is invalid
 * screen lock
 *    locks screen
 * button
 *    is activated if all fields are valid
 *    is inactivated if at least one field is invalid
 *    locks and unlocks screen before returning
 *    displays dialog on error
 */
