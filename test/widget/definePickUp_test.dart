import 'package:flutter/material.dart';
import 'package:flutter_maps_place_picker/flutter_maps_place_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import '../../lib/mocks.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

void main() {
  setUp(() async {
    await DotEnv.load(fileName: ".env");
    mockUserGeocoding = MockGeocodingResult();
    mockAddress = MockAddress();
    mockPlaces = MockPlaces();
    mockTripModel = MockTripModel();
    mockNavigatorObserver = MockNavigatorObserver();
    mockUserModel = MockUserModel();

    when(mockUserGeocoding.latitude).thenReturn(-43.0);
    when(mockUserGeocoding.longitude).thenReturn(-17.0);
    when(mockTripModel.pickUpAddress).thenReturn(mockAddress);
    when(mockTripModel.pickUpAddress).thenReturn(mockAddress);
    when(mockAddress.latitude).thenReturn(-17);
    when(mockAddress.longitude).thenReturn(-42);
    when(mockUserModel.geocoding).thenReturn(mockUserGeocoding);
    when(mockUserModel.position).thenReturn(mockUserPosition);
    when(mockUserPosition.latitude).thenReturn(-17);
    when(mockUserPosition.longitude).thenReturn(-42);
    when(mockConnectivityModel.hasConnection).thenReturn(true);
    when(mockPlaces.findAddressPredictions(
      placeName: anyNamed("placeName"),
      latitude: anyNamed("latitude"),
      longitude: anyNamed("longitude"),
      sessionToken: anyNamed("sessionToken"),
      isDropOff: anyNamed("isDropOff"),
    )).thenAnswer((_) async {
      return Future.value([
        Address(
          isDropOff: false,
          mainText: "Rua Presbiteriana",
          placeID: "firstplaceid",
        ),
        Address(
          isDropOff: false,
          mainText: "Rua Presbita",
          placeID: "secondplaceid",
        ),
        Address(
          isDropOff: false,
          mainText: "Rua Prebitera",
          placeID: "thirdplaceid",
        ),
        Address(
          isDropOff: false,
          mainText: "Rua Presbispo",
          placeID: "fourthplaceid",
        ),
        Address(
          isDropOff: false,
          mainText: "Rua Presbiterista",
          placeID: "fifthplaceid",
        ),
      ]);
    });
    AppConfig(flavor: Flavor.DEV);
  });

  Future<void> pumpWidget(WidgetTester tester) async {
    await tester.pumpWidget(MultiProvider(
      providers: [
        ChangeNotifierProvider<UserModel>(
          create: (context) => mockUserModel,
        ),
        ChangeNotifierProvider<TripModel>(
          create: (context) => mockTripModel,
        ),
      ],
      builder: (context, child) {
        return MaterialApp(
          home: DefinePickUp(places: mockPlaces),
          navigatorObservers: [mockNavigatorObserver],
        );
      },
    ));
  }

  group("pickUpTextEditingController", () {
    testWidgets(
      "listener returns addressPredictions when user types",
      (WidgetTester tester) async {
        // add widget to the UI
        await pumpWidget(tester);

        // get PickUpState
        final definePickUpFinder = find.byType(DefinePickUp);
        expect(definePickUpFinder, findsOneWidget);
        final definePickUpState =
            tester.state(definePickUpFinder) as DefinePickUpState;

        // expect null addressPredictions and empty text
        expect(definePickUpState.addressPredictions, isNull);
        expect(
          definePickUpState.pickUpTextEditingController.text,
          equals(''),
        );

        // expect not to find address predictions in the UI
        final addressPredictionFinder =
            find.widgetWithText(BorderlessButton, "Rua Presbiteriana");
        expect(addressPredictionFinder, findsNothing);

        // add text to input text
        final appInputTextFinder = find.byType(AppInputText);
        expect(appInputTextFinder, findsOneWidget);
        await tester.tap(appInputTextFinder);
        await tester.enterText(appInputTextFinder, "Rua Presb");
        await tester.pumpAndSettle();

        // // expect not null adressPredictions and not empty text
        // expect(definePickUpState.addressPredictions, isNotNull);
        // expect(definePickUpState.addressPredictions.length, equals(5));
        // expect(definePickUpState.addressPredictions.first.mainText,
        //     "Rua Presbiteriana");
        // expect(definePickUpState.addressPredictions.last.mainText,
        //     "Rua Presbiterista");
        // expect(
        //   definePickUpState.pickUpTextEditingController.text,
        //   equals("Rua Presb"),
        // );

        // // expect to find address predictions in the UI
        // expect(addressPredictionFinder, findsOneWidget);
      },
    );
  });

  group("sessionToken", () {
    testWidgets("is renewed when user taps 'Para Onde",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester);

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      // expect not null initial sessionToken
      String initialSessionToken = definePickUpState.sessionToken;
      expect(initialSessionToken, isNotNull);
      expect(initialSessionToken.length, greaterThan(0));

      // tap "Para Onde" input text
      await tester.tap(find.byType(AppInputText));
      await tester.pump();

      // expect sessionToken to be renewed
      expect(definePickUpState.sessionToken, isNotNull);
      expect(
        definePickUpState.sessionToken,
        isNot(equals(initialSessionToken)),
      );
    });
  });

  group("googleMapsEnabled", () {
    testWidgets(
        "starts as enabled if chosenPickUpAddress is not null and PlacePicker is displayed",
        (WidgetTester tester) async {
      // this results in googleMapsEnabled equal true
      when(mockTripModel.pickUpAddress).thenReturn(mockAddress);
      // add widget to the UI
      await pumpWidget(tester);
      // await tester.pumpAndSettle();

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      // expect enabled PlacePicker and disabled 'Definir origem no mapa'
      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir origem no mapa",
      );
      expect(definePickUpState.googleMapsEnabled, true);
      expect(find.byType(PlacePicker), findsOneWidget);
      expect(defineDestinationFinder, findsNothing);
    });

    testWidgets(
        "starts as disabled if chosenPickUpAddress is null and a PlacePicker is not displayed",
        (WidgetTester tester) async {
      // this results in googleMapsEnabled equal false
      when(mockTripModel.pickUpAddress).thenReturn(null);
      // add widget to the UI
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      // expect disabled PlacePicker and enabled 'Definir origem no mapa'
      expect(definePickUpState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir origem no mapa",
      );
      expect(defineDestinationFinder, findsOneWidget);
    });

    testWidgets(
        "is enabled if we tap 'Definir origem no mapa' and disable if we tap 'Para Onde'",
        (WidgetTester tester) async {
      // this results in googleMapsEnabled equal false
      when(mockTripModel.pickUpAddress).thenReturn(null);
      // add widget to the UI
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir origem no mapa",
      );

      /// expect disabled PlacePicker and enabled 'Definir origem no mapa'
      expect(definePickUpState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);

      // tap 'Definir origem no mapa'
      await tester.tap(defineDestinationFinder);
      await tester.pump();

      // expect enabled PlacePicker and disabled 'Definir origem no mapa'
      expect(definePickUpState.googleMapsEnabled, true);
      expect(find.byType(PlacePicker), findsOneWidget);
      expect(defineDestinationFinder, findsNothing);

      // tap 'Insira endereço de partida.'
      await tester.tap(find.widgetWithText(
        AppInputText,
        "Insira endereço de partida.",
      ));
      await tester.pump();

      // expect disabled PlacePicker and enabled 'Definir origem no mapa'
      expect(definePickUpState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);
    });
  });

  group("addressPredictions", () {
    testWidgets(
        "updates TripModel and returns to previous screen if pick an address from predictions",
        (WidgetTester tester) async {
      // add DefineRoute to the UI
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<UserModel>(
            create: (context) => mockUserModel,
          ),
          ChangeNotifierProvider<TripModel>(
            create: (context) => mockTripModel,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => mockConnectivityModel,
          ),
        ],
        builder: (context, child) {
          return MaterialApp(
            home: DefineRoute(mode: DefineRouteMode.request),
            onGenerateRoute: (RouteSettings settings) {
              return MaterialPageRoute(builder: (context) {
                return DefinePickUp(places: mockPlaces);
              });
            },
            navigatorObservers: [mockNavigatorObserver],
          );
        },
      ));

      // assert that DefineRoute was added to the UI
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);

      // tap on 'Localização atual selecionada' AppInputText
      await tester.tap(
          find.widgetWithText(AppInputText, "Localização atual selecionada"));
      await tester.pump();

      // verify that DefinePickUp was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      await tester.pump();
      expect(find.byType(DefinePickUp), findsOneWidget);

      // tap "Para onde?" AppInputText and insert text
      final whereToFinder = find.byType(AppInputText);
      expect(whereToFinder.last, findsOneWidget);
      await tester.tap(whereToFinder.last);
      await tester.enterText(whereToFinder.last, "Rua Presb");
      await tester.pumpAndSettle();

      // expect to find address prediction
      final addressPredictionFinder =
          find.widgetWithText(BorderlessButton, "Rua Presbiteriana");
      expect(addressPredictionFinder, findsOneWidget);

      // before tapping addressPrediction, TripModel hasn't been updated
      verifyNever(mockTripModel.updatePickUpAddres(any));

      // tap on addressPrediction
      await tester.tap(addressPredictionFinder);
      await tester.pumpAndSettle();

      // after tapping on addressPrediction, TripModel is updated
      expect(
        verify(mockTripModel.updatePickUpAddres(any)).callCount,
        equals(1),
      );

      // expect to return to DefineRoute screen
      verify(mockNavigatorObserver.didPop(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);
    });
  });
}
