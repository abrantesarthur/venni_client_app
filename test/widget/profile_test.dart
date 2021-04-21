import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/editEmail.dart';
import 'package:rider_frontend/screens/editPhone.dart';
import 'package:rider_frontend/screens/insertNewPassword.dart';
import 'package:rider_frontend/screens/profile.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/utils/utils.dart';

import '../../lib/mocks.dart';

void main() {
  // define mocks behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.emailVerified).thenReturn(true);
  });

  Future<void> pumpProfile(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<TripModel>(
            create: (context) => mockTripModel,
          )
        ],
        builder: (context, child) => MaterialApp(
          home: Profile(),
          routes: {
            EditPhone.routeName: (context) => EditPhone(),
            EditEmail.routeName: (context) => EditEmail(),
            InsertNewPassword.routeName: (context) => InsertNewPassword(),
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  testWidgets("displays name, phone and email correctly",
      (WidgetTester tester) async {
    // define email, name and phone
    String email = "example@provider.com";
    String name = "Fulano de tal";
    String phone = "+5538999999999";

    // set mocks so email, phone and name are displayed
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(name);
    when(mockUser.phoneNumber).thenReturn(phone);

    // set mocks so that email is not confirmed
    when(mockUser.emailVerified).thenReturn(false);

    // add Profile widget to the UI
    await pumpProfile(tester);

    final borderlessButtonFinders = find.byType(BorderlessButton);
    final nameFinder = borderlessButtonFinders.first;
    final phoneFinder = borderlessButtonFinders.at(1);
    final emailFinder = borderlessButtonFinders.at(2);
    final nameWidget = tester.widget(nameFinder);
    final emailWidget = tester.widget(emailFinder);
    final phoneWidget = tester.widget(phoneFinder);

    // expect to see name, email and phone correctly displayed
    expect(
        nameWidget,
        isA<BorderlessButton>()
            .having((b) => b.secondaryText, "secondaryText", equals(name)));
    expect(
        emailWidget,
        isA<BorderlessButton>()
            .having((b) => b.secondaryText, "secondaryText", equals(email)));
    expect(
        phoneWidget,
        isA<BorderlessButton>().having((b) => b.secondaryText, "secondaryText",
            equals(phone.withoutCountryCode())));
  });

  testWidgets("displays 'não confirmado' when email is not verified",
      (WidgetTester tester) async {
    // define email, name and phone
    String email = "example@provider.com";
    String name = "Fulano de tal";
    String phone = "+5538999999999";

    // set mocks so email, phone and name are displayed
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(name);
    when(mockUser.phoneNumber).thenReturn(phone);

    // set mocks so that email is not confirmed
    when(mockUser.emailVerified).thenReturn(false);

    // add Profile widget to the UI
    await pumpProfile(tester);

    final borderlessButtonFinders = find.byType(BorderlessButton);
    final emailFinder = borderlessButtonFinders.at(2);
    final emailWidget = tester.widget(emailFinder);

    // expect to see 'não confirmado'
    expect(
        emailWidget,
        isA<BorderlessButton>()
            .having((b) => b.label, "secondaryText", equals("Não confirmado")));
  });

  testWidgets("displays 'confirmado' when email is verified",
      (WidgetTester tester) async {
    // define email, name and phone
    String email = "example@provider.com";
    String name = "Fulano de tal";
    String phone = "+5538999999999";

    // set mocks so email, phone and name are displayed
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(name);
    when(mockUser.phoneNumber).thenReturn(phone);

    // set mocks so that email is confirmed
    when(mockUser.emailVerified).thenReturn(true);

    // add Profile widget to the UI
    await pumpProfile(tester);

    final borderlessButtonFinders = find.byType(BorderlessButton);
    final emailFinder = borderlessButtonFinders.at(2);
    final emailWidget = tester.widget(emailFinder);

    // expect to see 'confirmado'
    expect(
        emailWidget,
        isA<BorderlessButton>()
            .having((b) => b.label, "secondaryText", equals("Confirmado")));
  });

  testWidgets("pushes EditPhone screen", (WidgetTester tester) async {
    // define email, name and phone
    String email = "example@provider.com";
    String name = "Fulano de tal";
    String phone = "+5538999999999";

    // set mocks so email, phone and name are displayed
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(name);
    when(mockUser.phoneNumber).thenReturn(phone);

    // set mocks so that email is not confirmed
    when(mockUser.emailVerified).thenReturn(false);

    // add Profile widget to the UI
    await pumpProfile(tester);

    // verify that Profile screen is displayed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsOneWidget);
    expect(find.byType(EditPhone), findsNothing);

    final borderlessButtonFinders = find.byType(BorderlessButton);
    final phoneFinder = borderlessButtonFinders.at(1);

    // tap on phone
    await tester.tap(phoneFinder);
    await tester.pumpAndSettle();

    // verify that EditPhone screen is displayed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsNothing);
    expect(find.byType(EditPhone), findsOneWidget);
  });

  testWidgets("pushes EditEmail screen", (WidgetTester tester) async {
    // define email, name and phone
    String email = "example@provider.com";
    String name = "Fulano de tal";
    String phone = "+5538999999999";

    // set mocks so email, phone and name are displayed
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(name);
    when(mockUser.phoneNumber).thenReturn(phone);

    // set mocks so that email is not confirmed
    when(mockUser.emailVerified).thenReturn(false);

    // add Profile widget to the UI
    await pumpProfile(tester);

    // verify that Profile screen is displayed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsOneWidget);
    expect(find.byType(EditPhone), findsNothing);

    final borderlessButtonFinders = find.byType(BorderlessButton);
    final emailFinder = borderlessButtonFinders.at(2);

    // tap on email
    await tester.tap(emailFinder);
    await tester.pumpAndSettle();

    // verify that EditPhone screen is displayed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsNothing);
    expect(find.byType(EditEmail), findsOneWidget);
  });

  testWidgets("pushes InsertNewPassword screen", (WidgetTester tester) async {
    // define email, name and phone
    String email = "example@provider.com";
    String name = "Fulano de tal";
    String phone = "+5538999999999";

    // set mocks so email, phone and name are displayed
    when(mockUser.email).thenReturn(email);
    when(mockUser.displayName).thenReturn(name);
    when(mockUser.phoneNumber).thenReturn(phone);

    // set mocks so that email is not confirmed
    when(mockUser.emailVerified).thenReturn(false);

    // add Profile widget to the UI
    await pumpProfile(tester);

    // verify that Profile screen is displayed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsOneWidget);
    expect(find.byType(EditPhone), findsNothing);

    final borderlessButtonFinders = find.byType(BorderlessButton);
    final passwordFinder = borderlessButtonFinders.last;

    // tap on password
    await tester.tap(passwordFinder);
    await tester.pumpAndSettle();

    // verify that EditPhone screen is displayed
    verify(mockNavigatorObserver.didPush(any, any));
    expect(find.byType(Profile), findsNothing);
    expect(find.byType(InsertNewPassword), findsOneWidget);
  });
}
