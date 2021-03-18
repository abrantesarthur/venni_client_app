import 'package:flutter/material.dart';
import 'package:flutter_maps_place_picker/flutter_maps_place_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
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
    when(mockRouteModel.dropOffAddress).thenReturn(mockAddress);
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
          isDropOff: true,
          mainText: "Rua Presbiteriana",
          placeID: "firstplaceid",
        ),
        Address(
          isDropOff: true,
          mainText: "Rua Presbita",
          placeID: "secondplaceid",
        ),
        Address(
          isDropOff: true,
          mainText: "Rua Prebitera",
          placeID: "thirdplaceid",
        ),
        Address(
          isDropOff: true,
          mainText: "Rua Presbispo",
          placeID: "fourthplaceid",
        ),
        Address(
          isDropOff: true,
          mainText: "Rua Presbiterista",
          placeID: "fifthplaceid",
        ),
      ]);
    });

    AppConfig(
      flavor: Flavor.DEV,
      values: ConfigValues(
        directionsBaseURL: "",
        geocodingBaseURL: "",
        autocompleteBaseURL: "",
        cloudFunctionsBaseURL: "",
        googleApiKey: "",
      ),
    );
  });

  Future<void> pumpWidget(WidgetTester tester) async {
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
          home: DefineDropOff(
            places: mockPlaces,
          ),
          navigatorObservers: [mockNavigatorObserver],
        );
      },
    ));
  }

  group("dropOffTestEditingController", () {
    testWidgets(
      "listener returns addressPredictions when user types",
      (WidgetTester tester) async {
        // add widget to the UI
        await pumpWidget(tester);

        // get DropOffState
        final defineDropOffFinder = find.byType(DefineDropOff);
        expect(defineDropOffFinder, findsOneWidget);
        final defineDropOffState =
            tester.state(defineDropOffFinder) as DefineDropOffState;

        // expect null addressPredictions and empty text
        expect(defineDropOffState.addressPredictions, isNull);
        expect(
          defineDropOffState.dropOffTextEditingController.text,
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
        expect(defineDropOffState.addressPredictions, isNotNull);
        expect(defineDropOffState.addressPredictions.length, equals(5));
        expect(defineDropOffState.addressPredictions.first.mainText,
            "Rua Presbiteriana");
        expect(defineDropOffState.addressPredictions.last.mainText,
            "Rua Presbiterista");
        expect(
          defineDropOffState.dropOffTextEditingController.text,
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

      // get DefineDropOffState
      final defineDropOffFinder = find.byType(DefineDropOff);
      final defineDropOffState =
          tester.state(defineDropOffFinder) as DefineDropOffState;

      // expect not null initial sessionToken
      String initialSessionToken = defineDropOffState.sessionToken;
      expect(initialSessionToken, isNotNull);
      expect(initialSessionToken.length, greaterThan(0));

      // tap "Para Onde" input text
      await tester.tap(find.byType(AppInputText));
      await tester.pump();

      // expect sessionToken to be renewed
      expect(defineDropOffState.sessionToken, isNotNull);
      expect(
        defineDropOffState.sessionToken,
        isNot(equals(initialSessionToken)),
      );
    });
  });

  group("googleMapsEnabled", () {
    testWidgets(
        "is enabled if we tap 'Definir destino no mapa' and disable if we tap 'Para Onde'",
        (WidgetTester tester) async {
      // this causes googleMapsEnabled to be false
      when(mockRouteModel.dropOffAddress).thenReturn(null);
      // add widget to the UI
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // get DefineDropOffState
      final defineDropOffFinder = find.byType(DefineDropOff);
      final defineDropOffState =
          tester.state(defineDropOffFinder) as DefineDropOffState;

      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir destino no mapa",
      );

      /// expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(defineDropOffState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);

      // tap 'Definir destino no Mapa'
      await tester.tap(defineDestinationFinder);
      await tester.pump();

      // expect enabled PlacePicker and disabled 'Definir destino no mapa'
      expect(defineDropOffState.googleMapsEnabled, true);
      expect(find.byType(PlacePicker), findsOneWidget);
      expect(defineDestinationFinder, findsNothing);

      // tap 'Para Onde'
      await tester.tap(find.widgetWithText(
        AppInputText,
        "Para onde?",
      ));
      await tester.pump();

      // expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(defineDropOffState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);
    });

    testWidgets(
        "starts as enabled if chosenDropOffAddress is not null and PlacePicker is displayed",
        (WidgetTester tester) async {
      // this causes googleMapsEnabled to be true
      when(mockRouteModel.dropOffAddress).thenReturn(mockAddress);
      // add widget to the UI
      await pumpWidget(tester);

      // get DefineDropOffState
      final defineDropOffFinder = find.byType(DefineDropOff);
      final defineDropOffState =
          tester.state(defineDropOffFinder) as DefineDropOffState;

      // expect enabled PlacePicker and disabled 'Definir destino no mapa'
      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir destino no mapa",
      );
      expect(defineDropOffState.googleMapsEnabled, true);
      expect(find.byType(PlacePicker), findsOneWidget);
      expect(defineDestinationFinder, findsNothing);
    });

    testWidgets(
        "starts as disabled if chosenDropOffAddress is null and a PlacePicker is not displayed",
        (WidgetTester tester) async {
      // this causes googleMapsEnabled to be false
      when(mockRouteModel.dropOffAddress).thenReturn(null);
      // add widget to the UI
      await pumpWidget(tester);
      await tester.pumpAndSettle();

      // get DefineDropOffState
      final defineDropOffFinder = find.byType(DefineDropOff);
      final defineDropOffState =
          tester.state(defineDropOffFinder) as DefineDropOffState;

      // expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(defineDropOffState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      final defineDestinationFinder = find.widgetWithText(
        BorderlessButton,
        "Definir destino no mapa",
      );
      expect(defineDestinationFinder, findsOneWidget);
    });
  });

  group("addressPredictions", () {
    testWidgets(
        "updates routeModel and returns to previous screen if pick an address from predictions",
        (WidgetTester tester) async {
      // add DefineRoute to the UI
      await tester.pumpWidget(
        MultiProvider(
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
              home: DefineRoute(mode: DefineRouteMode.request),
              onGenerateRoute: (RouteSettings settings) {
                return MaterialPageRoute(builder: (context) {
                  return DefineDropOff(
                    places: mockPlaces,
                  );
                });
              },
              navigatorObservers: [mockNavigatorObserver],
            );
          },
        ),
      );

      // assert that DefineRoute was added to the UI
      verify(mockNavigatorObserver.didPush(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);

      // tap on 'Para onde?' AppInputText
      await tester.tap(find.widgetWithText(AppInputText, "Para onde?"));
      await tester.pump();

      // verify that DefineDropOff was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      await tester.pump();
      expect(find.byType(DefineDropOff), findsOneWidget);

      // // tap "Para onde?" AppInputText and insert text
      final whereToFinder = find.widgetWithText(AppInputText, "Para onde?");
      await tester.tap(whereToFinder.last);
      await tester.enterText(whereToFinder.last, "Rua Presb");
      await tester.pumpAndSettle();

      // expect to find address prediction
      final addressPredictionFinder =
          find.widgetWithText(BorderlessButton, "Rua Presbiteriana");
      expect(addressPredictionFinder, findsOneWidget);

      // before tapping addressPrediction, routeModel hasn't been updated
      verifyNever(mockRouteModel.updateDropOffAddres(any));

      // tap on addressPrediction
      await tester.tap(addressPredictionFinder);
      await tester.pumpAndSettle();

      // after tapping on addressPrediction, routeModel is updated
      expect(
        verify(mockRouteModel.updateDropOffAddres(any)).callCount,
        equals(1),
      );

      // expect to return to DefineRoute screen
      verify(mockNavigatorObserver.didPop(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);
    });
  });
}
