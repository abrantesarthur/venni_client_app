import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/insertName.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import '../../lib/mocks.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: InsertName(
        userCredential: mockUserCredential,
        userEmail: "valid@domain.com",
      ),
    ));
  }

  group("state", () {
    testWidgets("starts inactive", (WidgetTester tester) async {
      // add InsertName widget to the UI
      await pumpWidget(tester);

      // expect inactive state
      final InsertNameState insertNameState =
          tester.state(find.byType(InsertName));
      expect(insertNameState.circularButtonCallback, isNull);
      expect(insertNameState.circularButtonColor, equals(AppColor.disabled));

      // expect focus to start on name input
      final nameInputWidget = tester.firstWidget(find.byType(AppInputText));
      expect(
          nameInputWidget,
          isA<AppInputText>()
              .having((i) => i.hintText, "hintText", "nome")
              .having((i) => i.autoFocus, "autoFocus", true));
    });

    testWidgets(
        "is activated when both name and surname have at least two characters",
        (WidgetTester tester) async {
      // add InsertName widget to the UI
      await pumpWidget(tester);

      final InsertNameState insertNameState =
          tester.state(find.byType(InsertName));
      final nameFinder = find.byType(AppInputText).first;
      final surnameFinder = find.byType(AppInputText).last;

      // insert valid name but not insert valid surname
      await tester.enterText(nameFinder, "Fulano");
      await tester.pumpAndSettle();

      // expect inactive state
      expect(insertNameState.circularButtonCallback, isNull);
      expect(insertNameState.circularButtonColor, equals(AppColor.disabled));

      // insert valid surname but not insert valid name
      await tester.enterText(surnameFinder, "de Tal");
      await tester.enterText(nameFinder, "");
      await tester.pumpAndSettle();

      // expect inactive state
      expect(insertNameState.circularButtonCallback, isNull);
      expect(insertNameState.circularButtonColor, equals(AppColor.disabled));

      // insert valid name and valid surname
      await tester.enterText(surnameFinder, "de Tal");
      await tester.enterText(nameFinder, "Fulano");
      await tester.pumpAndSettle();

      // expect active state
      expect(insertNameState.circularButtonCallback, isNotNull);
      expect(insertNameState.circularButtonColor, equals(AppColor.primaryPink));

      // insert invalid name again
      await tester.enterText(nameFinder, "");
      await tester.pumpAndSettle();

      // expect active state
      expect(insertNameState.circularButtonCallback, isNull);
      expect(insertNameState.circularButtonColor, equals(AppColor.disabled));
    });
  });

  group("focusNode", () {
    testWidgets("passes from name to surname when name is submitted",
        (WidgetTester tester) async {
      // add InsertName widget to the UI
      await pumpWidget(tester);

      final InsertNameState insertNameState =
          tester.state(find.byType(InsertName));
      final nameFinder = find.byType(AppInputText).first;
      final surnameFinder = find.byType(AppInputText).last;
      final nameWidget = tester.widget(nameFinder);
      final surnameWidget = tester.widget<AppInputText>(surnameFinder);

      // expect focus to be on name and not on surname
      expect(
          nameWidget,
          isA<AppInputText>().having(
              (a) => a.focusNode.hasFocus, "focusNode.hasFocus", isTrue));
      expect(
          surnameWidget,
          isA<AppInputText>().having(
              (a) => a.focusNode.hasFocus, "focusNode.hasFocus", isFalse));

      // insert valid name and valid surname
      await tester.enterText(nameFinder, "Fulano");
      await tester.pumpAndSettle();

      // tap 'enter' key
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      // expect focus to move from name to surname
      expect(
          surnameWidget,
          isA<AppInputText>().having(
              (a) => a.focusNode.hasFocus, "focusNode.hasFocus", isTrue));
      expect(
          nameWidget,
          isA<AppInputText>().having(
              (a) => a.focusNode.hasFocus, "focusNode.hasFocus", isFalse));
    });
  });

  group("buttonCallback", () {
    testWidgets("pushes InsertPassword when pressed",
        (WidgetTester tester) async {
      // add InsertName widget to the UI
      String userEmail = "valid@domain.com";
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<TripModel>(create: (context) => mockTripModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<GoogleMapsModel>(
              create: (context) => mockGoogleMapsModel),
          ChangeNotifierProvider<ConnectivityModel>(
              create: (context) => mockConnectivityModel),
        ],
        child: MaterialApp(
          home: InsertName(
            userCredential: mockUserCredential,
            userEmail: userEmail,
          ),
          navigatorObservers: [mockNavigatorObserver],
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == InsertPassword.routeName) {
              final InsertPasswordArguments args = settings.arguments;
              return MaterialPageRoute(builder: (context) {
                return InsertPassword(
                  userCredential: args.userCredential,
                  userEmail: args.userEmail,
                  surname: args.surname,
                  name: args.name,
                );
              });
            }
          },
        ),
      ));

      verify(mockNavigatorObserver.didPush(any, any));

      final nameFinder = find.byType(AppInputText).first;
      final surnameFinder = find.byType(AppInputText).last;

      // insert valid name and valid surname
      String name = "Fulano";
      String surname = "de tal";
      await tester.enterText(surnameFinder, surname);
      await tester.enterText(nameFinder, name);
      await tester.pumpAndSettle();

      // before tapping, we have InsertPassword screen
      expect(find.byType(InsertName), findsOneWidget);
      expect(find.byType(InsertPassword), findsNothing);

      // tap on CircularButton
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping, we are redirected to InsertPassword screen
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertName), findsNothing);
      expect(find.byType(InsertPassword), findsOneWidget);

      // InsertPassword screen receives correct arguments
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.widget.userCredential,
          equals(mockUserCredential));
      expect(insertPasswordState.widget.userEmail, equals(userEmail));
      expect(insertPasswordState.widget.name, equals(name));
      expect(insertPasswordState.widget.surname, equals(surname));
    });
  });
}
