import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/mocks.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertPhone.dart';
import 'package:rider_frontend/screens/insertSmsCode.dart';
import 'package:rider_frontend/screens/insertEmail.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseAuth.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/inputPhone.dart';
import 'package:rider_frontend/widgets/warning.dart';

void main() {
  // define mockers behaviors
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    when(mockFirebaseModel.auth).thenReturn(mockFirebaseAuth);
    when(mockFirebaseAuth.currentUser).thenReturn(mockUser);
    when(mockUser.displayName).thenReturn("Fulano");
    when(mockFirebaseModel.database).thenReturn(mockFirebaseDatabase);
    when(mockFirebaseModel.isRegistered).thenReturn(true);
    when(mockUserModel.geocoding).thenReturn(mockGeocodingResult);
    when(mockGeocodingResult.latitude).thenReturn(0);
    when(mockGeocodingResult.longitude).thenReturn(0);
    when(mockGoogleMapsModel.initialCameraLatLng).thenReturn(LatLng(10, 10));
    when(mockGoogleMapsModel.initialZoom).thenReturn(30);
    when(mockGoogleMapsModel.polylines).thenReturn({});
  });

  void setupFirebaseMocks({
    @required WidgetTester tester,
    @required String verifyPhoneNumberCallbackName,
    bool userIsRegistered,
    bool signInSucceeds,
    FirebaseAuthException firebaseAuthException,
  }) {
    when(mockUserCredential.user).thenReturn(mockUser);

    if (userIsRegistered != null && userIsRegistered) {
      when(mockFirebaseModel.isRegistered).thenReturn(true);
    } else {
      when(mockFirebaseModel.isRegistered).thenReturn(false);
    }

    // mock FirebaseAuth's signInWithCredential to return mockUserCredential
    if (signInSucceeds != null && signInSucceeds) {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => Future.value(mockUserCredential),
      );
    } else {
      when(mockFirebaseAuth.signInWithCredential(any)).thenAnswer(
        (_) => throw FirebaseAuthException(
          message: "error message",
          code: "error code",
        ),
      );
    }

    // get InsertPhoneNumberState
    final insertPhoneState =
        tester.state(find.byType(InsertPhone)) as InsertPhoneNumberState;

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
            mockFirebaseAuth.verificationCompletedCallback(
              context: insertPhoneState.context,
              credential: credential,
              firebaseDatabase: mockFirebaseDatabase,
              firebaseAuth: mockFirebaseAuth,
              onExceptionCallback: (FirebaseAuthException e) =>
                  insertPhoneState.setInactiveState(
                      message: "Algo deu errado. Tente novamente."),
            );
          }
          break;
        case "verificationFailed":
          {
            String errorMsg = mockFirebaseAuth
                .verificationFailedCallback(firebaseAuthException);
            insertPhoneState.setInactiveState(message: errorMsg);
          }
          break;
        case "codeSent":
          {
            insertPhoneState.codeSentCallback(
              insertPhoneState.context,
              "verificationId123",
              123,
            );
          }
          break;
        case "codeAutoRetrievalTimeout":
        default:
          PhoneAuthCredential credential;
          mockFirebaseAuth.verificationCompletedCallback(
            context: insertPhoneState.context,
            credential: credential,
            firebaseDatabase: mockFirebaseDatabase,
            firebaseAuth: mockFirebaseAuth,
            onExceptionCallback: () => insertPhoneState.setInactiveState(
                message: "Algo deu errado. Tente novamente."),
          );
          break;
      }
    });
  }

  group("state ", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<TripModel>(
            create: (context) => mockTripModel,
          )
        ],
        builder: (context, child) => MaterialApp(home: InsertPhone()),
      ));
    }

    testWidgets("inits as disabled", (
      WidgetTester tester,
    ) async {
      await pumpWidget(tester);

      // expect no warning message
      expect(find.byType(Warning), findsNothing);

      // expect disabled state
      stateIsDisabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );
      // expect autoFocus
      final inputText = tester.firstWidget(find.byType(AppInputText));
      expect(inputText,
          isA<AppInputText>().having((i) => i.autoFocus, "autoFocus", isTrue));
    });

    testWidgets("is disabled when phone is invalid", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // enter incomplete phone number into the text field
      await tester.enterText(find.byType(InputPhone), "389");

      // find InsertPhone state
      final insertPhoneState =
          tester.state(find.byType(InsertPhone)) as InsertPhoneNumberState;

      // expect incomplete phone number to show up in controller
      expect(
          insertPhoneState.phoneTextEditingController.text, equals("(38) 9"));

      // expect disabled state
      stateIsDisabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );

      // expect no warning message
      expect(find.byType(Warning), findsNothing);
    });

    testWidgets("is enabled when phone is valid", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // enter complete phone number into the text field
      await tester.enterText(find.byType(InputPhone), "38998601275");

      // find InsertPhone state
      final insertPhoneState =
          tester.state(find.byType(InsertPhone)) as InsertPhoneNumberState;

      // expect complete phone number to show up in controller
      expect(
        insertPhoneState.phoneTextEditingController.text,
        equals("(38) 99860-1275"),
      );

      // settle state
      await tester.pump();

      // expect enabled state
      stateIsEnabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );

      // expect a warning message
      final warningMessageFinder = find.byType(Warning);
      final warningMessageWidget = tester.firstWidget(warningMessageFinder);
      expect(warningMessageFinder, findsOneWidget);
      expect(
          warningMessageWidget,
          isA<Warning>().having(
              (w) => w.message,
              "message",
              equals(
                  "O seu navegador pode se abrir para efetuar verificações :)")));

      // enter incomplete phone number into the text field
      await tester.enterText(find.byType(InputPhone), "3899860127");

      // expect incomplete phone number to show up in controller
      expect(
        insertPhoneState.phoneTextEditingController.text,
        equals("(38) 99860-127"),
      );

      // settle state
      await tester.pump();

      // expect disabled state
      stateIsDisabled(
        tester,
        tester.state(find.byType(InsertPhone)),
        find.byType(CircularButton),
      );

      // expect no warning message
      expect(warningMessageFinder, findsNothing);
    });
  });

  group("verificationCompleted ", () {
    Future<void> pumpWidget(WidgetTester tester) async {
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
              create: (context) => mockFirebaseModel),
          ChangeNotifierProvider<UserModel>(create: (context) => mockUserModel),
          ChangeNotifierProvider<TripModel>(create: (context) => mockTripModel),
          ChangeNotifierProvider<GoogleMapsModel>(
              create: (context) => mockGoogleMapsModel)
        ],
        builder: (context, child) => MaterialApp(
          home: InsertPhone(),
          routes: {
            Home.routeName: (context) => Home(
                  firebase: mockFirebaseModel,
                  user: mockUserModel,
                  trip: mockTripModel,
                  googleMaps: mockGoogleMapsModel,
                ),
            InsertEmail.routeName: (context) => InsertEmail(
                  userCredential: mockUserCredential,
                ),
          },
          // mockNavigatorObserver will receive all navigation events
          navigatorObservers: [mockNavigatorObserver],
        ),
      ));
    }

    testWidgets("pushes Home when user is registered and sign in succeeds", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // tester.pumpWidget() built our widget and triggered the
      // pushObserver method on the mockNavigatorObserver once.
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; userIsRegisteredreturns true
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        userIsRegistered: true,
        signInSucceeds: true,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // before tapping button, we are still in InsertPhoneScreen
      expect(find.byType(InsertPhone), findsOneWidget);
      expect(find.byType(Home), findsNothing);

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we are go to Home
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertPhone), findsNothing);
      expect(find.byType(Home), findsOneWidget);
    });

    testWidgets("displays warning when sign in fails", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // verifyPhoneNumber calls verificationCompleted
      // userIsRegisteredreturns true
      // user successfully signs in to firebase
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        signInSucceeds: false,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber,
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pump();

      // after tapping button, there is a Warning about failed sign in
      final warningFinder =
          find.widgetWithText(Warning, "Algo deu errado. Tente novamente.");
      expect(warningFinder, findsOneWidget);

      // final warningFinder = find.byType(Warning);
      // expect(warningFinder, findsOneWidget);
      // expect(
      //   tester.firstWidget(warningFinder),
      //   isA<Warning>().having(
      //     (w) => w.message,
      //     "message",
      //     equals("Algo deu errado. Tente novamente."),
      //   ),
      // );
    });

    testWidgets(
        "pushes InsertEmail when sign in succeeds and user is not registered", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await pumpWidget(tester);

      // tester.pumpWidget() built our widget and triggered the
      // pushObserver method on the mockNavigatorObserver once.
      verify(mockNavigatorObserver.didPush(any, any));

      // verifyPhoneNumber calls verificationCompleted; userIsRegistered is false
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "verificationCompleted",
        userIsRegistered: false,
        signInSucceeds: true,
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
      // calling verificationCompletedCallback
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we go to InsertEmail screen
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertPhone), findsNothing);
      expect(find.byType(InsertEmail), findsOneWidget);
    });
  });

  group("verificationFailed ", () {
    void testVerificationFailed({
      @required String errorCode,
      @required String warningMessage,
    }) {
      testWidgets("called with " + errorCode, (
        WidgetTester tester,
      ) async {
        // add InsertPhone to the UI
        await tester.pumpWidget(MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
                create: (context) => mockFirebaseModel)
          ],
          builder: (context, child) => MaterialApp(
            home: InsertPhone(),
          ),
        ));
        // verifyPhoneNumber calls verificationFailed with exception
        final e = FirebaseAuthException(
          message: "m",
          code: errorCode,
        );
        setupFirebaseMocks(
          tester: tester,
          verifyPhoneNumberCallbackName: "verificationFailed",
          firebaseAuthException: e,
        );

        // enter valid phone number to enable circular button callback
        await tester.enterText(find.byType(InputPhone), "38998601275");
        await tester.pumpAndSettle();

        // tapping button triggers buttonCallback, calling mocked verifyPhoneNumber
        // calling verificationFailed
        await tester.tap(find.byType(CircularButton));
        await tester.pump();

        // after tapping button, we receive a warnign about invalid phone number
        final warningFinder = find.byType(Warning);
        expect(
            tester.firstWidget(warningFinder),
            isA<Warning>().having(
              (w) => w.message,
              "message",
              equals(warningMessage),
            ));
      });
    }

    testVerificationFailed(
      errorCode: "invalid-phone-number",
      warningMessage: "Número de telefone inválido. Por favor, tente outro.",
    );

    testVerificationFailed(
      errorCode: "too-many-requests",
      warningMessage:
          "Ops, número de tentativas excedidas. Tente novamente em alguns minutos.",
    );

    testVerificationFailed(
      errorCode: "any other error code",
      warningMessage: "Ops, algo deu errado. Tente novamente mais tarde.",
    );
  });

  group("codeSent", () {
    testWidgets("redirects to InsertSmsCode screen", (
      WidgetTester tester,
    ) async {
      // add InsertPhone to the UI
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<FirebaseModel>(
                create: (context) => mockFirebaseModel),
          ],
          child: MaterialApp(
            home: InsertPhone(),
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == InsertSmsCode.routeName) {
                final InsertSmsCodeArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return InsertSmsCode(
                    verificationId: args.verificationId,
                    resendToken: args.resendToken,
                    phoneNumber: args.phoneNumber,
                    mode: args.mode,
                  );
                });
              }
              assert(false, 'Need to implement ${settings.name}');
              return null;
            },
            navigatorObservers: [mockNavigatorObserver],
          ),
        ),
      );

      // verifyPhoneNumber calls codeSent
      setupFirebaseMocks(
        tester: tester,
        verifyPhoneNumberCallbackName: "codeSent",
      );

      // enter valid phone number to enable circular button callback
      await tester.enterText(find.byType(InputPhone), "38998601275");
      await tester.pumpAndSettle();

      // tapping button triggers buttonCallback, calling codeSent
      await tester.tap(find.byType(CircularButton));
      await tester.pumpAndSettle();

      // after tapping button, we go to the InsertSmsCode screen
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(InsertPhone), findsNothing);
      final insertSmsCodeFinder = find.byType(InsertSmsCode);
      final insertSmsCodeWidget = tester.firstWidget(insertSmsCodeFinder);
      expect(insertSmsCodeFinder, findsOneWidget);
      expect(
        insertSmsCodeWidget,
        isA<InsertSmsCode>()
            .having(
              (i) => i.verificationId,
              "verificationId",
              equals("verificationId123"),
            )
            .having((i) => i.resendToken, "resendToken", 123),
      );
    });
  });
}

void stateIsEnabled(
  WidgetTester tester,
  InsertPhoneNumberState insertPhoneState,
  Finder circularButtonFinder,
) {
  // find CircularButton widget
  final circularButtonWidget = tester.firstWidget(circularButtonFinder);

  // expect not null phoneNumber
  expect(insertPhoneState.phoneNumber, isNotNull);

  // expect not null circularButtonCallback
  expect(insertPhoneState.circularButtonCallback, isNotNull);

  // expect primaryPink as button color
  expect(
      circularButtonWidget,
      isA<CircularButton>().having(
          (c) => c.buttonColor, "ButtonColor", equals(AppColor.primaryPink)));
}

void stateIsDisabled(
  WidgetTester tester,
  InsertPhoneNumberState insertPhoneState,
  Finder circularButtonFinder,
) {
  // find CircularButton widget
  final circularButtonWidget = tester.firstWidget(circularButtonFinder);

  // expect null phoneNumber
  expect(insertPhoneState.phoneNumber, isNull);

  // expect null circularButtonCallback
  expect(insertPhoneState.circularButtonCallback, isNull);

  // expect disabled color
  expect(
      circularButtonWidget,
      isA<CircularButton>().having(
          (c) => c.buttonColor, "ButtonColor", equals(AppColor.disabled)));
}
