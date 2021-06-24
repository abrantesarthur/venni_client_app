import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import '../mocks.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/warning.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();

    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.displayName).thenReturn("Fulano");
    when(mockUser.email).thenReturn("example@provider.com");
    when(mockUser.emailVerified).thenReturn(true);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockFirebaseModel.isRegistered).thenReturn(false);
    when(mockFirebaseDatabase.reference()).thenReturn(mockDatabaseReference);
    when(mockDatabaseReference.child(any)).thenReturn(mockDatabaseReference);
    when(mockDatabaseReference.remove()).thenAnswer((_) => Future.value());
    when(mockUserModel.geocoding).thenReturn(mockGeocodingResult);
    when(mockGeocodingResult.latitude).thenReturn(0);
    when(mockGeocodingResult.longitude).thenReturn(0);
    when(mockGoogleMapsModel.initialCameraLatLng).thenReturn(LatLng(10, 10));
    when(mockGoogleMapsModel.initialZoom).thenReturn(30);
    when(mockGoogleMapsModel.polylines).thenReturn({});
    when(mockConnectivityModel.hasConnection).thenReturn(true);
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<TripModel>(create: (context) => mockTripModel),
          ChangeNotifierProvider<GoogleMapsModel>(
              create: (context) => mockGoogleMapsModel),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
        ],
        builder: (context, child) => MaterialApp(
          home: InsertPassword(
            userCredential: mockUserCredential,
            userEmail: "valid@domain.com",
            name: "Fulano",
            surname: "de Tal",
          ),
          routes: {
            Home.routeName: (context) => Home(
                  firebase: mockFirebaseModel,
                  user: mockUserModel,
                  trip: mockTripModel,
                  googleMaps: mockGoogleMapsModel,
                  connectivity: mockConnectivityModel,
                ),
            Start.routeName: (context) => Start(),
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group("state", () {
    testWidgets("CircularButton starts as inactive",
        (WidgetTester tester) async {
      // add InsertPassword widget to the screen
      await pumpWidget(tester);

      // expect inactive state
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.circularButtonCallback, isNull);
      expect(
          insertPasswordState.circularButtonColor, equals(AppColor.disabled));
      expect(insertPasswordState.obscurePassword, isTrue);
      expect(insertPasswordState.passwordChecks[0], isFalse);
      expect(insertPasswordState.passwordChecks[1], isFalse);
      expect(insertPasswordState.passwordChecks[2], isFalse);

      // expect passwordTextFieldEnabled to be true
      expect(insertPasswordState.passwordTextFieldEnabled, isTrue);

      // preventNavigateBack starts as false
      expect(insertPasswordState.preventNavigateBack, isFalse);

      // displayPasswordWarnings starts as true
      expect(insertPasswordState.displayPasswordWarnings, isTrue);

      // expect registrationErrorWarnings starts as null
      expect(insertPasswordState.registrationErrorWarnings, isNull);
    });

    testWidgets("correctly activates password length warning",
        (WidgetTester tester) async {
      // add InsertPassword widget to the screen
      await pumpWidget(tester);

      // password length warning is not active
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.passwordChecks[0], isFalse);

      // add password with length 8
      await tester.enterText(find.byType(AppInputText), "password");

      // password length warning becomes active
      expect(insertPasswordState.passwordChecks[0], isTrue);

      // add password with length 7
      await tester.enterText(find.byType(AppInputText), "passwor");

      // password length warning becomes inactive again
      expect(insertPasswordState.passwordChecks[0], isFalse);
    });

    testWidgets("correctly activates at least one character warning",
        (WidgetTester tester) async {
      // add InsertPassword widget to the screen
      await pumpWidget(tester);

      // password character warning is not active
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.passwordChecks[1], isFalse);

      // add password with at least one character
      await tester.enterText(find.byType(AppInputText), "123a45");

      // password character warning becomes active
      expect(insertPasswordState.passwordChecks[1], isTrue);

      // add password with no character
      await tester.enterText(find.byType(AppInputText), "123456");

      // password character becomes inactive again
      expect(insertPasswordState.passwordChecks[0], isFalse);
    });

    testWidgets("correctly activates at least one number warning",
        (WidgetTester tester) async {
      // add InsertPassword widget to the screen
      await pumpWidget(tester);

      // password number warning is not active
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.passwordChecks[2], isFalse);

      // add password with at least one number
      await tester.enterText(find.byType(AppInputText), "abcd1e");

      // password number warning becomes active
      expect(insertPasswordState.passwordChecks[2], isTrue);

      // add password with no numbers
      await tester.enterText(find.byType(AppInputText), "abcdef");

      // password number warning becomes inactive again
      expect(insertPasswordState.passwordChecks[2], isFalse);
    });

    testWidgets("shows password when eye button is tapped",
        (WidgetTester tester) async {
      // add InsertPassword widget to the screen
      await pumpWidget(tester);

      // add password with at least one number
      await tester.enterText(find.byType(AppInputText), "abcd1e");

      // before tapping eye button, it is inactive and password is not visible
      final iconFinder = find.byIcon(Icons.remove_red_eye_outlined);
      expect(iconFinder, findsOneWidget);
      expect(tester.firstWidget(find.byType(TextField)),
          isA<TextField>().having((t) => t.obscureText, "obscureText", isTrue));

      // tap eye button
      await tester.tap(iconFinder);
      await tester.pumpAndSettle();

      // after tapping eye button, password becomes visible and eye is activated
      expect(
          tester.firstWidget(find.byType(TextField)),
          isA<TextField>()
              .having((t) => t.obscureText, "obscureText", isFalse));
      expect(iconFinder, findsNothing);
      expect(find.byIcon(Icons.remove_red_eye), findsOneWidget);
    });

    testWidgets("activates CircularButton when all password criteria are met",
        (WidgetTester tester) async {
      // add InsertPassword widget to the screen
      await pumpWidget(tester);

      // CircularButton is not active
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.circularButtonCallback, isNull);
      expect(
          insertPasswordState.circularButtonColor, equals(AppColor.disabled));

      // add password with at least one number
      await tester.enterText(find.byType(AppInputText), "1");
      await tester.pumpAndSettle();

      // CircularButton is still not active
      expect(insertPasswordState.circularButtonCallback, isNull);
      expect(
          insertPasswordState.circularButtonColor, equals(AppColor.disabled));

      // add password with at least one character and at least one number
      await tester.enterText(find.byType(AppInputText), "1a");
      await tester.pumpAndSettle();

      // CircularButton is still not active
      expect(insertPasswordState.circularButtonCallback, isNull);
      expect(
          insertPasswordState.circularButtonColor, equals(AppColor.disabled));

      // add password with at least one character, at least one number and length > 8
      await tester.enterText(find.byType(AppInputText), "1apassword");
      await tester.pumpAndSettle();

      // CircularButton becomes active
      expect(insertPasswordState.circularButtonCallback, isNotNull);
      expect(insertPasswordState.circularButtonColor,
          equals(AppColor.primaryPink));

      // add password without all criteria
      await tester.enterText(find.byType(AppInputText), "1a");
      await tester.pumpAndSettle();

      // CircularButton becomes inactive
      expect(insertPasswordState.circularButtonCallback, isNull);
      expect(
          insertPasswordState.circularButtonColor, equals(AppColor.disabled));
    });
  });

  group("buttonCallback", () {
    Future<void> testErrosWhenisRegistered(
      WidgetTester tester,
      String code,
      String expectedWarning,
    ) async {
      // add widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // insert valid password to activate circular button
      final appInputTextFinder = find.byType(AppInputText);
      await tester.enterText(appInputTextFinder, "avalidpassword123");
      await tester.pumpAndSettle();

      // expect callback to be activated state
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.circularButtonCallback, isNotNull);

      // set mocks to throw 'wrong-password' error
      when(mockFirebaseModel.isRegistered).thenReturn(true);
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: code,
      );
      when(mockUser.reauthenticateWithCredential(any))
          .thenAnswer((_) async => throw e);

      // expect registrationErrorWarnings to be null
      expect(insertPasswordState.registrationErrorWarnings, isNull);

      // simulate tapping button to register the user
      await tester.tap(find.byType(CircularButton));
      await tester.pump();

      // expect registrationErrorWarnings not to be null
      expect(insertPasswordState.registrationErrorWarnings, isNotNull);

      await tester.pumpAndSettle();

      // expect to find warning
      final warningFinder = find.widgetWithText(Warning, expectedWarning);
      expect(warningFinder, findsOneWidget);
    }

    testWidgets("correctly handles 'wrong-password' error",
        (WidgetTester tester) async {
      await testErrosWhenisRegistered(
        tester,
        'wrong-password',
        "Senha incorreta. Tente novamente.",
      );
    });

    testWidgets("correctly handles 'too-many-requests' error",
        (WidgetTester tester) async {
      await testErrosWhenisRegistered(
        tester,
        'too-many-requests',
        "Muitas tentativas sucessivas. Tente novamente mais tarde.",
      );
    });

    testWidgets("correctly handles 'anything-else' error",
        (WidgetTester tester) async {
      await testErrosWhenisRegistered(
        tester,
        'anything-else',
        "Algo deu errado. Tente novamente mais tarde.",
      );
    });

    testWidgets(
        "pushes Home when user has partner account and inserts correct password",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // insert valid password to activate circular button
      final appInputTextFinder = find.byType(AppInputText);
      await tester.enterText(appInputTextFinder, "avalidpassword123");
      await tester.pumpAndSettle();

      // expect callback to be activated state
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.circularButtonCallback, isNotNull);

      // set mocks so user has partner account and typed right password
      when(mockFirebaseModel.isRegistered).thenReturn(true);
      when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
      when(mockUser.reauthenticateWithCredential(any)).thenAnswer(
        (_) async => Future.value(mockUserCredential),
      );

      // before tapping, expect successfullyRegisteredUser to be null
      expect(insertPasswordState.successfullyRegisteredUser, isNull);

      // tap button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect successfullyRegisteredUser to be a future  bool
      expect(
          insertPasswordState.successfullyRegisteredUser, isA<Future<bool>>());

      // expect Home to be pushed
      await tester.pumpAndSettle();
      expect(find.byType(Home), findsOneWidget);
    });

    testWidgets("pushes Home screen when user doesn't have partner account",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // expect to have pasword text input
      final appInputTextFinder = find.byType(AppInputText);
      final appInputTextWidget = tester.firstWidget(appInputTextFinder);
      expect(find.byType(AppInputText), findsOneWidget);
      expect(
          appInputTextWidget,
          isA<AppInputText>()
              .having((a) => a.hintText, "hintText", equals("senha")));

      // insert valid password to activate circular button
      await tester.enterText(appInputTextFinder, "avalidpassword123");
      await tester.pumpAndSettle();

      // expect callback to be activated state
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.circularButtonCallback, isNotNull);

      // set mocks so user doesn't have partner account and registers successfully
      when(mockFirebaseModel.isRegistered).thenReturn(false);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.updateEmail(any)).thenAnswer(
        (_) async => Future.value(),
      );
      when(mockUser.updatePassword(any)).thenAnswer(
        (_) async => Future.value(),
      );
      when(mockUser.updateProfile(displayName: anyNamed("displayName")))
          .thenAnswer(
        (_) async => Future.value(),
      );

      // before tapping, expect successfullyRegisteredUser to be null
      expect(insertPasswordState.successfullyRegisteredUser, isNull);

      // tap button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // expect successfullyRegisteredUser to be a future  bool
      expect(
        insertPasswordState.successfullyRegisteredUser,
        isA<Future<bool>>(),
      );

      // expect Home to be pushed
      await tester.pumpAndSettle();
      expect(find.byType(Home), findsOneWidget);
    });

    testWidgets("correctly handles 'requires-recent-login' error",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // insert valid password to activate circular button
      final appInputTextFinder = find.byType(AppInputText);
      await tester.enterText(appInputTextFinder, "avalidpassword123");
      await tester.pumpAndSettle();

      // expect callback to be activated state
      final InsertPasswordState insertPasswordState =
          tester.state(find.byType(InsertPassword));
      expect(insertPasswordState.circularButtonCallback, isNotNull);

      // set mocks to throw 'requires-recent-login' error
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "requires-recent-login",
      );
      when(mockFirebaseModel.isRegistered).thenReturn(false);
      when(mockUserCredential.user).thenReturn(mockUser);
      when(mockUser.updateEmail(any)).thenAnswer((_) async => throw e);
      when(mockUser.updatePassword(any)).thenAnswer(
        (_) async => Future.value(),
      );
      when(mockUser.updateProfile(displayName: anyNamed("displayName")))
          .thenAnswer(
        (_) async => Future.value(),
      );

      // before tapping, expect successfullyRegisteredUser to be null
      expect(insertPasswordState.successfullyRegisteredUser, isNull);

      // verify that user was not deleted yet
      verifyNever(mockUser.delete());

      // simulate tapping button to register the user
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // verify that user was deleted
      verify(mockUser.delete()).called(1);

      // expect successfullyRegisteredUser to be a future bool
      expect(
          insertPasswordState.successfullyRegisteredUser, isA<Future<bool>>());
      await tester.pumpAndSettle();

      // expect displayPasswordWarnings to be false
      expect(insertPasswordState.displayPasswordWarnings, isFalse);

      // expect registrationErrorWarnings not to be null
      expect(insertPasswordState.registrationErrorWarnings, isNotNull);

      // expect passwordTextFieldEnabled to still be false
      expect(insertPasswordState.passwordTextFieldEnabled, isFalse);

      // expect preventNavigateBack to still be true
      expect(insertPasswordState.preventNavigateBack, isTrue);

      // registration error warnings are displayed
      final sessionExpiredWarningFinder = find.widgetWithText(
        Warning,
        "Infelizmente a sua sessão expirou devido à demora.",
      );
      final restartWarningFinder = find.widgetWithText(
        Warning,
        "Clique aqui para recomeçar o cadastro.",
      );
      final restartWarningWidget = tester.firstWidget(restartWarningFinder);
      expect(sessionExpiredWarningFinder, findsOneWidget);
      expect(restartWarningFinder, findsOneWidget);
      expect(
          restartWarningWidget,
          isA<Warning>().having(
            (w) => w.onTapCallback,
            "onTapCallback",
            isNotNull,
          ));

      // tap to insert a new password
      await tester.tap(find.byType(AppInputText));
      await tester.pumpAndSettle();

      // expect displayPasswordWarnings to still be false
      expect(insertPasswordState.displayPasswordWarnings, isFalse);

      // expect registrationErrorWarnings to still be not null
      expect(insertPasswordState.registrationErrorWarnings, isNotNull);

      // tap to restart registration
      await tester.tap(restartWarningFinder);
      await tester.pumpAndSettle();

      // expect to be redirected to Start screen
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(Start), findsOneWidget);
    });
  });
}
