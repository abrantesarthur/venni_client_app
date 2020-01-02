import 'package:flutter/material.dart';
import 'package:flutter_maps_place_picker/flutter_maps_place_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/vendors/places.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';

import 'insertPassword_test.dart';
import 'insertPhone_test.dart';

class MockAddress extends Mock implements Address {}

class MockPlaces extends Mock implements Places {}

void main() {
  MockGeocodingResult mockUserGeocoding;
  MockAddress mockAddress;
  MockPlaces mockPlaces;
  MockRouteModel mockRouteModel;
  MockNavigatorObserver mockNavigatorObserver;
  MockUserPositionModel mockUserPositionModel;

  setUp(() {
    mockUserGeocoding = MockGeocodingResult();
    mockAddress = MockAddress();
    mockPlaces = MockPlaces();
    mockRouteModel = MockRouteModel();
    mockNavigatorObserver = MockNavigatorObserver();
    mockUserPositionModel = MockUserPositionModel();

    when(mockUserGeocoding.latitude).thenReturn(-43.0);
    when(mockUserGeocoding.longitude).thenReturn(-17.0);
    when(mockRouteModel.pickUpAddress).thenReturn(mockAddress);
    when(mockRouteModel.pickUpAddress).thenReturn(mockAddress);
    when(mockAddress.latitude).thenReturn(-17);
    when(mockAddress.longitude).thenReturn(-42);
    when(mockUserPositionModel.geocoding).thenReturn(mockUserGeocoding);
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
  });

  Future<void> pumpWidget(
    WidgetTester tester, {
    bool nullPickUpAddress = false,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DefinePickUp(
          userGeocoding: mockUserGeocoding,
          chosenPickUpAddress: nullPickUpAddress ? null : mockAddress,
          places: mockPlaces,
        ),
      ),
    );
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

        // expect not null adressPredictions and not empty text
        expect(definePickUpState.addressPredictions, isNotNull);
        expect(definePickUpState.addressPredictions.length, equals(5));
        expect(definePickUpState.addressPredictions.first.mainText,
            "Rua Presbiteriana");
        expect(definePickUpState.addressPredictions.last.mainText,
            "Rua Presbiterista");
        expect(
          definePickUpState.pickUpTextEditingController.text,
          equals("Rua Presb"),
        );

        // expect to find address predictions in the UI
        expect(addressPredictionFinder, findsOneWidget);
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
      // add widget to the UI
      await pumpWidget(tester, nullPickUpAddress: false);

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      // expect enabled PlacePicker and disabled 'Definir destino no mapa'
      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir destino no mapa",
      );
      expect(definePickUpState.googleMapsEnabled, true);
      expect(find.byType(PlacePicker), findsOneWidget);
      expect(defineDestinationFinder, findsNothing);
    });

    testWidgets(
        "starts as disabled if chosenPickUpAddress is null and a PlacePicker is not displayed",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester, nullPickUpAddress: true);

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      // expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(definePickUpState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir destino no mapa",
      );
      expect(defineDestinationFinder, findsOneWidget);
    });

    testWidgets(
        "is enabled if we tap 'Definir destino no mapa' and disable if we tap 'Para Onde'",
        (WidgetTester tester) async {
      // add widget to the UI
      await pumpWidget(tester, nullPickUpAddress: true);

      // get DefinePickUpState
      final definePickUpFinder = find.byType(DefinePickUp);
      final definePickUpState =
          tester.state(definePickUpFinder) as DefinePickUpState;

      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir destino no mapa",
      );

      /// expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(definePickUpState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);

      // tap 'Definir destino no Mapa'
      await tester.tap(defineDestinationFinder);
      await tester.pump();

      // expect enabled PlacePicker and disabled 'Definir destino no mapa'
      expect(definePickUpState.googleMapsEnabled, true);
      expect(find.byType(PlacePicker), findsOneWidget);
      expect(defineDestinationFinder, findsNothing);

      // tap 'De Onde'
      await tester.tap(find.widgetWithText(
        AppInputText,
        "De onde?",
      ));
      await tester.pump();

      // expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(definePickUpState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);
    });
  });

  group("addressPredictions", () {
    testWidgets(
        "updates routeModel and returns to previous screen if pick an address from predictions",
        (WidgetTester tester) async {
      // add DefineRoute to the UI
      await tester.pumpWidget(MultiProvider(
        providers: [
          ChangeNotifierProvider<UserPositionModel>(
            create: (context) => mockUserPositionModel,
          ),
          ChangeNotifierProvider<RouteModel>(
            create: (context) => mockRouteModel,
          ),
        ],
        builder: (context, child) {
          return MaterialApp(
            home: DefineRoute(
              routeModel: mockRouteModel,
              userGeocoding: mockUserGeocoding,
            ),
            onGenerateRoute: (RouteSettings settings) {
              DefinePickUpArguments args = settings.arguments;
              return MaterialPageRoute(builder: (context) {
                return DefinePickUp(
                  userGeocoding: args.userGeocoding,
                  chosenPickUpAddress: null,
                  places: mockPlaces,
                );
              });
            },
            navigatorObservers: [mockNavigatorObserver],
          );
        },
      ));

      // assert that DefineRoute was added to the UI
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);

      // tap on 'Localização atual' AppInputText
      await tester.tap(find.widgetWithText(AppInputText, "Localização atual"));
      await tester.pumpAndSettle();

      // verify that DefinePickUp was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(DefinePickUp), findsOneWidget);

      // tap "Para onde?" AppInputText and insert text
      final whereToFinder = find.byType(AppInputText);
      expect(whereToFinder, findsOneWidget);
      await tester.tap(whereToFinder);
      await tester.enterText(whereToFinder, "Rua Presb");
      await tester.pumpAndSettle();

      // expect to find address prediction
      final addressPredictionFinder =
          find.widgetWithText(BorderlessButton, "Rua Presbiteriana");
      expect(addressPredictionFinder, findsOneWidget);

      // before tapping addressPrediction, routeModel hasn't been updated
      verifyNever(mockRouteModel.updatePickUpAddres(any));

      // tap on addressPrediction
      await tester.tap(addressPredictionFinder);
      await tester.pumpAndSettle();

      // after tapping on addressPrediction, routeModel is updated
      expect(
        verify(mockRouteModel.updatePickUpAddres(any)).callCount,
        equals(1),
      );

      // expect to return to DefineRoute screen
      verify(mockNavigatorObserver.didPop(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);
    });
  });
}
