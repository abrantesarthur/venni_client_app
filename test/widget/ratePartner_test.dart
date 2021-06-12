import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import '../mocks.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/ratePartner.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/appInputText.dart';

void main() {
  // define mocks behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockPartnerModel.name).thenReturn("Fulano");
    when(mockTripModel.farePrice).thenReturn(500);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
    when(mockUserModel.defaultPaymentMethod)
        .thenReturn(mockClientPaymentMethod);
    when(mockClientPaymentMethod.type).thenReturn(PaymentMethodType.cash);
  });

  Future<void> pumpRatePartner(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<PartnerModel>(
              create: (context) => mockPartnerModel),
          ChangeNotifierProvider<TripModel>(create: (context) => mockTripModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<ConnectivityModel>(create: (context) => mockConnectivityModel),
        ],
        builder: (context, child) => MaterialApp(
          home: RatePartner(),
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group(
      "state",
      () => {
            testWidgets("inits as expected", (WidgetTester tester) async {
              // pump RatePartner to the UI
              await pumpRatePartner(tester);

              verify(mockNavigatorObserver.didPush(any, any));
              expect(find.byType(RatePartner), findsOneWidget);

              // rate description starts as "nota geral"
              expect(find.textContaining("nota geral"), findsOneWidget);

              // feedback components are not shown
              expect(find.textContaining("Limpeza"), findsNothing);
              expect(find.textContaining("Segurança"), findsNothing);
              expect(find.textContaining("Tempo"), findsNothing);
              expect(find.textContaining("Outro"), findsNothing);
              expect(find.byType(AppInputText), findsNothing);

              // all star icons are unfilled
              expect(
                  find.widgetWithIcon(GestureDetector, Icons.star_border_sharp),
                  findsNWidgets(5));
              expect(find.widgetWithIcon(GestureDetector, Icons.star_sharp),
                  findsNothing);

              // there is no thank you mesage
              expect(
                  find.textContaining("Obrigado pela avaliação"), findsNothing);
            }),
          });

  group(
      "ratePartner",
      () => {
            testWidgets("displays warning if payment is cash",
                (WidgetTester tester) async {
              // add rate partner to the UI (mockUser retur)
              await pumpRatePartner(tester);

              // mockUser returns payment in cash by default
              // so we expect to find the following warning
              final textFinder = find.text("Efetue o pagamento em dinheiro");
              expect(textFinder, findsOneWidget);
            }),
            testWidgets("correctly updates the UI",
                (WidgetTester tester) async {
              // add rate partner to the UI
              await pumpRatePartner(tester);

              // get state
              final state =
                  tester.state(find.byType(RatePartner)) as RatePartnerState;

              // expect to find 0 filled and 5 empty stars
              final filledStarFinders =
                  find.widgetWithIcon(GestureDetector, Icons.star_sharp);
              expect(filledStarFinders, findsNothing);
              final emptyStarFinders =
                  find.widgetWithIcon(GestureDetector, Icons.star_border_sharp);
              expect(emptyStarFinders, findsNWidgets(5));

              // tap into the 5th star icon
              await tester.tap(emptyStarFinders.last);
              await tester.pump();

              // feedback components are shown
              expect(find.textContaining("Limpeza"), findsOneWidget);
              expect(find.textContaining("Segurança"), findsOneWidget);
              expect(find.textContaining("Tempo"), findsOneWidget);
              expect(find.textContaining("Outro"), findsOneWidget);
              expect(find.byType(AppInputText), findsNothing);

              // expect that button to be active
              expect(state.activateButton, isTrue);

              // expect to find 'excelente' text, but not 'nota geral'
              expect(find.text("excelente"), findsOneWidget);
              expect(find.text("O que foi excelente?"), findsOneWidget);
              expect(find.textContaining("nota geral"), findsNothing);

              // expect that, now, there are 5 filled and 0 empty stars
              expect(filledStarFinders, findsNWidgets(5));
              expect(emptyStarFinders, findsNothing);

              // tap into the 4th star icon
              await tester.tap(filledStarFinders.at(3));
              await tester.pump();

              // expect that button to be active
              expect(state.activateButton, isTrue);

              // expect to find 'bom' text, but not 'excelente'
              expect(find.text("boa"), findsOneWidget);
              expect(find.text("Como podemos melhorar?"), findsOneWidget);
              expect(find.textContaining("excelente"), findsNothing);

              // expect that, now, there are 4 filled and 1 empty stars
              expect(filledStarFinders, findsNWidgets(4));
              expect(emptyStarFinders, findsOneWidget);

              // tap into the 3rd star icon
              await tester.tap(filledStarFinders.at(2));
              await tester.pump();

              // expect that button to be active
              expect(state.activateButton, isTrue);

              // expect to find 'regular' text, but not 'boa'
              expect(find.text("regular"), findsOneWidget);
              expect(find.text("Como podemos melhorar?"), findsOneWidget);
              expect(find.textContaining("boa"), findsNothing);

              // expect that, now, there are 3 filled and 2 empty stars
              expect(filledStarFinders, findsNWidgets(3));
              expect(emptyStarFinders, findsNWidgets(2));

              // tap into the 2nd star icon
              await tester.tap(filledStarFinders.at(1));
              await tester.pump();

              // expect that button to be active
              expect(state.activateButton, isTrue);

              // expect to find 'ruim' text, but not 'regular'
              expect(find.text("ruim"), findsOneWidget);
              expect(find.text("Como podemos melhorar?"), findsOneWidget);
              expect(find.textContaining("regular"), findsNothing);

              // expect that, now, there are 2 filled and 3 empty stars
              expect(filledStarFinders, findsNWidgets(2));
              expect(emptyStarFinders, findsNWidgets(3));

              // tap into the 1st star icon
              await tester.tap(filledStarFinders.first);
              await tester.pump();

              // expect that button to be active
              expect(state.activateButton, isTrue);

              // expect to find 'péssima' text, but not 'ruim'
              expect(find.text("péssima"), findsOneWidget);
              expect(find.text("Como podemos melhorar?"), findsOneWidget);
              expect(find.textContaining("ruim"), findsNothing);

              // expect that, now, there are 1 filled and 4 empty stars
              expect(filledStarFinders, findsOneWidget);
              expect(emptyStarFinders, findsNWidgets(4));
            })
          });

  group(
      "selectFeedback",
      () => {
            testWidgets(
                "sets selected feedback components to true when user gives 5-star rating",
                (WidgetTester tester) async {
              // add rate partner to the UI
              await pumpRatePartner(tester);

              // get state
              final state =
                  tester.state(find.byType(RatePartner)) as RatePartnerState;

              // get start findes
              final emptyStarFinders =
                  find.widgetWithIcon(GestureDetector, Icons.star_border_sharp);

              // before tapping into a star, no feedback component is shown
              final emptyFeedbackFinders =
                  find.byIcon(Icons.check_box_outline_blank);
              final filledFeedbackFinders =
                  find.byIcon(Icons.check_box_rounded);
              expect(emptyFeedbackFinders, findsNothing);
              expect(filledFeedbackFinders, findsNothing);

              // feedbackComponents object is empty
              expect(state.feedbackComponents, isEmpty);

              // tap into the 5th star icon
              await tester.tap(emptyStarFinders.last);
              await tester.pump();

              // feedback components are shown all empty
              expect(emptyFeedbackFinders, findsNWidgets(4));
              expect(filledFeedbackFinders, findsNothing);

              // tap into "cleanliness" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // expect 3 empty and 1 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(3));
              expect(filledFeedbackFinders, findsOneWidget);

              // feedback components is populated with true 'cleanliness' option
              expect(state.feedbackComponents.length, equals(1));
              expect(
                  state.feedbackComponents[
                      FeedbackComponent.cleanliness_went_well],
                  isTrue);

              // tap into "safety" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // expect 2 empty and 2 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(2));
              expect(filledFeedbackFinders, findsNWidgets(2));

              // feedback components is populated with true 'safety' option
              expect(state.feedbackComponents.length, equals(2));
              expect(
                  state.feedbackComponents[FeedbackComponent.safety_went_well],
                  isTrue);

              // tap into "waiting time" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // expect 1 empty and 3 filled feedback icons
              expect(emptyFeedbackFinders, findsOneWidget);
              expect(filledFeedbackFinders, findsNWidgets(3));

              // feedback components is populated with true 'waiting time' option
              expect(state.feedbackComponents.length, equals(3));
              expect(
                  state.feedbackComponents[
                      FeedbackComponent.waiting_time_went_well],
                  isTrue);

              // before tapping into 'another' there is no AppInputText
              expect(find.byType(AppInputText), findsNothing);

              // tap into "waiting time" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // after tapping into 'another' there is AppInputText
              expect(find.byType(AppInputText), findsOneWidget);

              // expect 0 empty and 4 filled feedback icons
              expect(emptyFeedbackFinders, findsNothing);
              expect(filledFeedbackFinders, findsNWidgets(4));

              // feedback components are stil populated with 3 components
              expect(state.feedbackComponents.length, equals(3));

              // tap into selected "cleanliness" feedback option again
              await tester.tap(filledFeedbackFinders.first);
              await tester.pump();

              // expect 1 empty and 3 filled feedback icons
              expect(emptyFeedbackFinders, findsOneWidget);
              expect(filledFeedbackFinders, findsNWidgets(3));

              // 'cleanliness' is removed from feedbackComponents object
              expect(state.feedbackComponents.length, equals(2));
              expect(
                  state.feedbackComponents[
                      FeedbackComponent.cleanliness_went_well],
                  isNull);

              // tap into selected "safety" feedback option again
              await tester.tap(filledFeedbackFinders.first);
              await tester.pump();

              // expect 2 empty and 2 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(2));
              expect(filledFeedbackFinders, findsNWidgets(2));

              // 'safety' is removed from feedbackComponents object
              expect(state.feedbackComponents.length, equals(1));
              expect(
                  state.feedbackComponents[FeedbackComponent.safety_went_well],
                  isNull);

              // tap into selected "waiting time" feedback option again
              await tester.tap(filledFeedbackFinders.first);
              await tester.pump();

              // expect 3 empty and 1 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(3));
              expect(filledFeedbackFinders, findsOneWidget);

              // 'waiting time' is removed from feedbackComponents object
              expect(state.feedbackComponents, isEmpty);
            }),
            testWidgets(
                "sets selected feedback components to false when user gives below 5-star rating",
                (WidgetTester tester) async {
              // add rate partner to the UI
              await pumpRatePartner(tester);

              // get state
              final state =
                  tester.state(find.byType(RatePartner)) as RatePartnerState;

              // get start findes
              final emptyStarFinders =
                  find.widgetWithIcon(GestureDetector, Icons.star_border_sharp);

              // before tapping into a star, no feedback component is shown
              final emptyFeedbackFinders =
                  find.byIcon(Icons.check_box_outline_blank);
              final filledFeedbackFinders =
                  find.byIcon(Icons.check_box_rounded);
              expect(emptyFeedbackFinders, findsNothing);
              expect(filledFeedbackFinders, findsNothing);

              // feedbackComponents object is empty
              expect(state.feedbackComponents, isEmpty);

              // tap into the 1st star icon
              await tester.tap(emptyStarFinders.first);
              await tester.pump();

              // feedback components are shown all empty
              expect(emptyFeedbackFinders, findsNWidgets(4));
              expect(filledFeedbackFinders, findsNothing);

              // tap into "cleanliness" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // expect 3 empty and 1 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(3));
              expect(filledFeedbackFinders, findsOneWidget);

              // feedback components is populated with false 'cleanliness' option
              expect(state.feedbackComponents.length, equals(1));
              expect(
                  state.feedbackComponents[
                      FeedbackComponent.cleanliness_went_well],
                  isFalse);

              // tap into "safety" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // expect 2 empty and 2 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(2));
              expect(filledFeedbackFinders, findsNWidgets(2));

              // feedback components is populated with false 'safety' option
              expect(state.feedbackComponents.length, equals(2));
              expect(
                  state.feedbackComponents[FeedbackComponent.safety_went_well],
                  isFalse);

              // tap into "waiting time" feedback otion selecting it
              await tester.tap(emptyFeedbackFinders.first);
              await tester.pump();

              // expect 1 empty and 3 filled feedback icons
              expect(emptyFeedbackFinders, findsOneWidget);
              expect(filledFeedbackFinders, findsNWidgets(3));

              // feedback components is populated with false 'waiting time' option
              expect(state.feedbackComponents.length, equals(3));
              expect(
                  state.feedbackComponents[
                      FeedbackComponent.waiting_time_went_well],
                  isFalse);

              // tap into selected "cleanliness" feedback option again
              await tester.tap(filledFeedbackFinders.first);
              await tester.pump();

              // expect 2 empty and 2 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(2));
              expect(filledFeedbackFinders, findsNWidgets(2));

              // 'cleanliness' is removed from feedbackComponents object
              expect(state.feedbackComponents.length, equals(2));
              expect(
                  state.feedbackComponents[
                      FeedbackComponent.cleanliness_went_well],
                  isNull);

              // tap into selected "safety" feedback option again
              await tester.tap(filledFeedbackFinders.first);
              await tester.pump();

              // expect 3 empty and 1 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(3));
              expect(filledFeedbackFinders, findsOneWidget);

              // 'safety' is removed from feedbackComponents object
              expect(state.feedbackComponents.length, equals(1));
              expect(
                  state.feedbackComponents[FeedbackComponent.safety_went_well],
                  isNull);

              // tap into selected "waiting time" feedback option again
              await tester.tap(filledFeedbackFinders.first);
              await tester.pump();

              // expect 4 empty and 0 filled feedback icons
              expect(emptyFeedbackFinders, findsNWidgets(4));
              expect(filledFeedbackFinders, findsNothing);

              // 'waiting time' is removed from feedbackComponents object
              expect(state.feedbackComponents, isEmpty);
            })
          });
}
