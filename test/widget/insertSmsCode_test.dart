import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertSmsCode.dart';
import 'package:rider_frontend/screens/insertEmail.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseAuth.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/warning.dart';

import 'insertPassword_test.dart';
import 'insertPhone_test.dart';

void main() {
  MockFirebaseModel mockFirebaseModel;
  MockFirebaseAuth mockFirebaseAuth;
  MockFirebaseDatabase mockFirebaseDatabase;
  MockNavigatorObserver mockNavigatorObserver;
  MockUserCredential mockUserCredential;
  MockUser mockUser;
  MockUserPositionModel mockUserPositionModel;
  MockRouteModel mockRouteModel;
  MockGeocodingResult mockGeocodingResult;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    mockFirebaseModel = MockFirebaseModel();
    mockFirebaseAuth = MockFirebaseAuth();
    mockFirebaseDatabase = MockFirebaseDatabase();
    mockNavigatorObserver = MockNavigatorObserver();
    mockUserCredential = MockUserCredential();
    mockUser = MockUser();
    mockUserPositionModel = MockUserPositionModel();
    mockRouteModel = MockRouteModel();
    mockGeocodingResult = MockGeocodingResult();

    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockFirebaseModel.isRegistered).thenReturn(true);
    when(mockUserPositionModel.geocoding).thenReturn(mockGeocodingResult);
    when(mockGeocodingResult.latitude).thenReturn(0);
    when(mockGeocodingResult.longitude).thenReturn(0);
  });

  void setupFirebaseMocks({
    @required WidgetTester tester,
    String verifyPhoneNumberCallbackName,
    bool userIsRegistered,
    bool signInSucceeds,
    FirebaseAuthException verificationCompletedException,
    Function verificationCompletedOnExceptionCallback,
    FirebaseAuthException verificationFailedException,
  }) {
    when(mockUserCredential.user).thenReturn(mockUser);

    if (userIsRegistered != null && userIsRegistered) {
      when(mockFirebaseModel.isRegistered).thenReturn(true);
    } else {
      when(mockFirebaseModel.isRegistered).thenReturn(false);
    }

    // mock FirebaseAuth's signInWithCredential to return mockUserCredential
    if (signInSucceeds != null &&
        signInSucceeds &&
        verificationCompletedException == null) {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => Future.value(mockUserCredential),
      );
    } else if (verificationCompletedException != null) {
      when(mockFirebaseAuth.signInWithCredential(any))
          .thenAnswer((_) => throw verificationCompletedException);
    } else {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => throw FirebaseAuthException(
          message: "error message",
          code: "error code",
        ),
      );
    }

    final insertSmsCodeState =
        tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

    // mock FirebaseAuth's verifyPhoneNumber to call verifyPhoneNumberCallbackName
    when(
      mockFirebaseAuth.verifyPhoneNumber(
        phoneNumber: anyNamed("phoneNumber"),
        verificationCompleted: anyNamed("verificationCompleted"),
        verificationFailed: anyNamed("verificationFailed"),
        codeSent: anyNamed("codeSent"),
        codeAutoRetrievalTimeout: anyNamed("codeAutoRetrievalTimeout"),
        timeout: anyNamed("timeout"),
        forceResendingToken: anyNamed("forceResendingToken"),
      ),
    ).thenAnswer((_) async {
      switch (verifyPhoneNumberCallbackName) {
        case "verificationCompleted":
          {
            PhoneAuthCredential credential;
            verificationCompletedCallback(
                context: insertSmsCodeState.context,
                credential: credential,
                firebaseDatabase: mockFirebaseDatabase,
                firebaseAuth: mockFirebaseAuth,
                onExceptionCallback: verificationCompletedOnExceptionCallback);
          }
          break;
        case "verificationFailed":
          {
            insertSmsCodeState.resendCodeVerificationFailedCallback(
                verificationFailedException);
          }
          break;
        case "codeSent":
          {
            insertSmsCodeState.codeSentCallback("verificationId", 123);
          }
          break;
        case "codeAutoRetrievalTimeout":
        default:
          PhoneAuthCredential credential;
          verificationCompletedCallback(
            context: insertSmsCodeState.context,
            credential: credential,
            firebaseDatabase: mockFirebaseDatabase,
            firebaseAuth: mockFirebaseAuth,
            onExceptionCallback: () => insertSmsCodeState.setState(() {
              insertSmsCodeState.warningMessage =
                  Warning(message: "Algo deu errado. Tente novamente");
            }),
          );
          break;
      }
    });
  }

  group("state ", () {
    Future<void> pumpInsertSmsCodeWidget(WidgetTester tester) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
                create: (context) => mockFirebaseModel)
          ],
          child: MaterialApp(
            home: InsertSmsCode(
              verificationId: "verificationId",
              resendToken: 123,
              phoneNumber: "+55 (38) 99999-9999",
            ),
          ),
        ),
      );
    }

    testWidgets("inits as disabled", (WidgetTester tester) async {
      await pumpInsertSmsCodeWidget(tester);

      // expect resendCodewarning and editPhoneWarning messages
      final warningFinder = find.byType(Warning);
      final warningWidgets = tester.widgetList(warningFinder);
      expect(warningFinder, findsNWidgets(2));
      expect(
          warningWidgets.elementAt(0),
          isA<Warning>().having(
              (w) => w.message, "message", contains("Reenviar o código em")));
      expect(
          warningWidgets.elementAt(1),
          isA<Warning>().having((w) => w.message, "message",
              equals("Editar o número do meu celular")));

      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      // expect disabled state
      stateIsDisabled(tester.state(insertSmsCodeFinder));
      // expect autoFocus
      final inputText = tester.firstWidget(find.byType(AppInputText));
      expect(inputText,
          isA<AppInputText>().having((i) => i.autoFocus, "autoFocus", isTrue));
    });

    testWidgets("is disabled if incomplete code is entered",
        (WidgetTester tester) async {
      await pumpInsertSmsCodeWidget(tester);

      // insert incomplete sms code
      await tester.enterText(find.byType(AppInputText), "12345");

      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeState =
          tester.state(insertSmsCodeFinder) as InsertSmsCodeState;

      // expect incomplete number to show up in controller
      expect(insertSmsCodeState.smsCodeTextEditingController.text,
          equals("12345"));

      // expect disabled state
      stateIsDisabled(insertSmsCodeState);
    });

    testWidgets("is enabled if complete code is entered",
        (WidgetTester tester) async {
      await pumpInsertSmsCodeWidget(tester);

      // insert complete sms code
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);

      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeState =
          tester.state(insertSmsCodeFinder) as InsertSmsCodeState;

      stateIsEnabled(insertSmsCodeState, completeCode);

      // insert incomplete sms code again
      await tester.enterText(find.byType(AppInputText), "12345");

      // expect disabled state
      stateIsDisabled(insertSmsCodeState);
    });
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<UserPositionModel>(
              create: (context) => mockUserPositionModel),
          ChangeNotifierProvider<RouteModel>(
              create: (context) => mockRouteModel)
        ],
        child: MaterialApp(
          home: InsertSmsCode(
            verificationId: "verificationId",
            resendToken: 123,
            phoneNumber: "+55 (38) 99999-9999",
          ),
          routes: {
            Home.routeName: (context) => Home(),
            Start.routeName: (context) => Start(),
            InsertEmail.routeName: (context) => InsertEmail(
                  userCredential: mockUserCredential,
                )
          },
          navigatorObservers: [mockNavigatorObserver],
        ),
      ),
    );
  }

  group("verifySmsCode ", () {
    testWidgets(
        "disables warning, callback and displays CircularProgressIndicator",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // code verification succeeds and user is registered
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: true,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(Home), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // before tapping button, there is the following state
      final insertSmsState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      expect(insertSmsState.circularButtonCallback, isNotNull);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      // tap circular button and update state once
      await tester.tap(find.byType(CircularButton));
      await tester.pump();

      // after tapping button, verifySmsCode is called and sets the following state
      expect(insertSmsState.circularButtonCallback, isNull);
      expect(insertSmsState.warningMessage, isNull);
    });

    testWidgets(
        "pushes Home screen when user is registered and sign in succeeds",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // code verification succeeds and user is registered
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: true,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Home screen
      expect(find.byType(Home), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, Home screen is pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "ends in InsertEmail screen if firebaseModel.isRegistered returns false",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // code verification succeeds and user is not registered
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: false,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no Start screen
      expect(find.byType(InsertEmail), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, Start screen is pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertEmail), findsOneWidget);
      expect(find.byType(Home), findsNothing);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "pushes InsertEmail screen when sign in succeeds and phone is not registered",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      verify(mockNavigatorObserver.didPush(any, any));

      // code verification succeeds and phone is not registered
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: false,
        signInSucceeds: true,
      );

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no InsertEmail screen
      expect(find.byType(InsertEmail), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, InsertEmail screen is pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertEmail), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "displays right warning when userIsRegistered but 'invalid-verification-code' exception happens",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // user is registered but sign in throws exception
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "invalid-verification-code",
      );
      setupFirebaseMocks(
          tester: tester,
          userIsRegistered: true,
          verificationCompletedException: e,
          verificationCompletedOnExceptionCallback: (e) => insertSmsCodeState
              .displayErrorMessage(insertSmsCodeState.context, e));

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no 'Código inválido' warning
      expect(
        find.widgetWithText(Warning, "Código inválido. Tente outro."),
        findsNothing,
      );

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, there is 'Código inválido" warning
      expect(
        find.widgetWithText(Warning, "Código inválido. Tente outro."),
        findsOneWidget,
      );
    });

    testWidgets(
        "displays right warning when userIsRegistered and other exceptions happen",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // user is registered but sign in throws exception
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: "any other code",
      );
      setupFirebaseMocks(
          tester: tester,
          userIsRegistered: true,
          verificationCompletedException: e,
          verificationCompletedOnExceptionCallback: (e) => insertSmsCodeState
              .displayErrorMessage(insertSmsCodeState.context, e));

      // insert complete smsCode to enabled callback
      String completeCode = "123456";
      await tester.enterText(find.byType(AppInputText), completeCode);
      await tester.pump();

      stateIsEnabled(tester.state(find.byType(InsertSmsCode)), completeCode);

      // before tapping the button, there is no 'Algo deu errado' warning
      expect(
        find.widgetWithText(Warning, "Algo deu errado. Tente mais tarde."),
        findsNothing,
      );

      // tap circular button
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, there is 'Algo deu errado" warning
      expect(
        find.widgetWithText(Warning, "Algo deu errado. Tente mais tarde."),
        findsOneWidget,
      );
    });
  });

  group("resendCode ", () {
    Future<void> pumpInsertSmsCodeWidget(
      WidgetTester tester, {
      String routeName,
      Widget route,
    }) async {
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
                create: (context) => mockFirebaseModel),
            ChangeNotifierProvider<UserPositionModel>(
                create: (context) => mockUserPositionModel),
            ChangeNotifierProvider<RouteModel>(
                create: (context) => mockRouteModel)
          ],
          child: MaterialApp(
            home: InsertSmsCode(
              verificationId: "verificationId",
              resendToken: 123,
              phoneNumber: "+55 (38) 99999-9999",
            ),
            routes: {
              routeName: (context) => route,
            },
            navigatorObservers: [mockNavigatorObserver],
          ),
        ),
      );
    }

    testWidgets(
        "pushes Home when it triggers verificationCompleted, user is registered and code is verified",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpInsertSmsCodeWidget(
        tester,
        routeName: Home.routeName,
        route: Home(),
      );

      // InsertSmsCode was pushed
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber triggers verificationCompleted when user is registered
      // and code is verified
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: true,
        signInSucceeds: true,
        verifyPhoneNumberCallbackName: "verificationCompleted",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, there is no Home screen
      expect(find.byType(Home), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap on warning to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // expect Home page to be pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(Home), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "pushes InsertEmail when it triggers verificationCompleted, sign in succeeds but phone is not registered",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpInsertSmsCodeWidget(tester,
          routeName: InsertEmail.routeName,
          route: InsertEmail(
            userCredential: mockUserCredential,
          ));

      // InsertSmsCode was pushed
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber triggers verificationCompleted when user is registered
      // and code is verified
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: false,
        signInSucceeds: true,
        verifyPhoneNumberCallbackName: "verificationCompleted",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, there is no InsertEmail screen
      expect(find.byType(InsertEmail), findsNothing);
      expect(find.byType(InsertSmsCode), findsOneWidget);

      // tap on warning to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // expect InsertEmail page to be pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertEmail), findsOneWidget);
      expect(find.byType(InsertSmsCode), findsNothing);
    });

    testWidgets(
        "displays warning when it triggers verificationCompleted, userIsRegistered and an exception happens",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpInsertSmsCodeWidget(tester);

      // InsertSmsCode was pushed
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber triggers verificationCompleted when user is registered
      // and sign in triggers exception
      FirebaseAuthException e =
          FirebaseAuthException(message: "message", code: "any code");
      setupFirebaseMocks(
        tester: tester,
        userIsRegistered: true,
        verificationCompletedException: e,
        verificationCompletedOnExceptionCallback: (FirebaseAuthException e) {
          final insertSmsCodeState =
              tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
          insertSmsCodeState.setState(() {
            insertSmsCodeState.remainingSeconds = 15;
            insertSmsCodeState.timer = insertSmsCodeState.kickOffTimer();
            insertSmsCodeState.warningMessage =
                Warning(message: "Algo deu errado. Tente novamente");
          });
        },
        verifyPhoneNumberCallbackName: "verificationCompleted",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, there is no 'Algo deu errado' warning
      final somethingWrongWarningFinder =
          find.widgetWithText(Warning, "Algo deu errado. Tente novamente");
      expect(somethingWrongWarningFinder, findsNothing);

      // tap to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // after tapping the button, there is 'Algo deu errado' warning
      expect(somethingWrongWarningFinder, findsOneWidget);
    });

    void verificationFailedTest(
      WidgetTester tester, {
      String exceptionCode,
      String expectedWarningMessage,
    }) async {
      // add insertSmsCode widget to the UI
      await pumpInsertSmsCodeWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // verifyPhoneNumber triggers verificationFailed with 'invalid-phone-number' exception
      // verificationFailed calls resendCodeVerificationFailedCallback just like
      // InsertSmsCodeState does
      FirebaseAuthException e = FirebaseAuthException(
        message: "message",
        code: exceptionCode,
      );
      setupFirebaseMocks(
        tester: tester,
        verificationFailedException: e,
        verifyPhoneNumberCallbackName: "verificationFailed",
      );

      // expect not to find a warning allowing to resendCode
      // tap on warning to resendCode
      final resendCodeWidgetFinder =
          find.widgetWithText(Warning, "Reenviar o código para meu celular");
      expect(resendCodeWidgetFinder, findsNothing);

      // set remainingSeconds to 0 so resendCode callback is activated
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // when remainingSeconds hits 0, find a warning allowing to resendCode
      expect(resendCodeWidgetFinder, findsOneWidget);

      // before tapping the button, warning is null
      expect(insertSmsCodeState.warningMessage, isNull);

      // tap to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // after tapping the button, warning is not null and has correct mesage
      expect(insertSmsCodeState.warningMessage, isNotNull);
      expect(
          insertSmsCodeState.warningMessage,
          isA<Warning>().having(
            (w) => w.message,
            "message",
            equals(expectedWarningMessage),
          ));
    }

    testWidgets(
        "displays right warning when it triggers verificationFailed with 'invalid-phone-number' exception",
        (WidgetTester tester) async {
      verificationFailedTest(
        tester,
        exceptionCode: "invalid-phone-number",
        expectedWarningMessage:
            "Número de telefone inválido. Por favor, tente outro.",
      );
    });

    testWidgets(
        "displays right warning when it triggers verificationFailed with generic exception",
        (WidgetTester tester) async {
      verificationFailedTest(
        tester,
        exceptionCode: "generic",
        expectedWarningMessage:
            "Ops, algo deu errado. Tente novamente mais tarde.",
      );
    });

    testWidgets("removes warning and resets timer when it triggers codeSent",
        (WidgetTester tester) async {
      // add insertSmsCode widget to the UI
      await pumpInsertSmsCodeWidget(tester);

      final insertSmsCodeState =
          tester.state(find.byType(InsertSmsCode)) as InsertSmsCodeState;

      // verifyPhoneNumber triggers codeSent
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "codeSent",
      );

      // set remainingSeconds to 0 so resendCode callback is activated
      insertSmsCodeState.setState(() {
        insertSmsCodeState.remainingSeconds = 0;
      });
      await tester.pump();

      // before tapping the button, warning is null and timer is off
      expect(insertSmsCodeState.warningMessage, isNull);

      // tap to resendCode
      await tester.tap(find.text("Reenviar o código para meu celular"));
      await tester.pumpAndSettle();

      // after tapping the button, warning is null and timer is reset
      expect(insertSmsCodeState.warningMessage, isNull);
      expect(insertSmsCodeState.remainingSeconds, equals(15));
    });
  });
}

void stateIsEnabled(InsertSmsCodeState insertSmsCodeState, String code) {
  // expect code to show up in controller
  expect(insertSmsCodeState.smsCodeTextEditingController.text, equals(code));
  // expect smsCode to equal entered code
  expect(insertSmsCodeState.smsCode, equals(code));
  // expect not null circularButtonCallback
  expect(insertSmsCodeState.circularButtonCallback, isNotNull);
  // expect enabled circularButtonColor
  expect(insertSmsCodeState.circularButtonColor, equals(AppColor.primaryPink));
  // expect autorenew_sharp icon
  expect(find.byIcon(Icons.autorenew_sharp), findsOneWidget);
}

void stateIsDisabled(
  InsertSmsCodeState insertSmsCodeState,
) {
  //expect null smsCode
  expect(insertSmsCodeState.smsCode, isNull);
  // expect null circularButtonCallback
  expect(insertSmsCodeState.circularButtonCallback, isNull);
  // expect disabled circularButtonCollor
  expect(insertSmsCodeState.circularButtonColor, equals(AppColor.disabled));
  // expect autorenew_sharp icon
  expect(find.byIcon(Icons.autorenew_sharp), findsOneWidget);
}
