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
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

import '../../lib/mocks.dart';

void main() {
  setUp(() async {
    await DotEnv.load(fileName: ".env");

    when(mockTripModel.pickUpAddress).thenReturn(mockAddress);
    when(mockTripModel.dropOffAddress).thenReturn(mockAddress);
    when(mockAddress.latitude).thenReturn(-17);
    when(mockAddress.longitude).thenReturn(-42);
    when(mockUserModel.geocoding).thenReturn(mockUserGeocoding);
    when(mockUserGeocoding.latitude).thenReturn(-43.0);
    when(mockUserGeocoding.longitude).thenReturn(-17.0);
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
    );
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
        "starts as enabled if chosenDropOffAddress is not null and PlacePicker is displayed",
        (WidgetTester tester) async {
      // this causes googleMapsEnabled to be true
      when(mockTripModel.dropOffAddress).thenReturn(mockAddress);
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
      when(mockTripModel.dropOffAddress).thenReturn(null);
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

    testWidgets(
        "is enabled if we tap 'Definir destino no mapa' and disable if we tap 'Para Onde'",
        (WidgetTester tester) async {
      // this causes googleMapsEnabled to be false
      when(mockTripModel.dropOffAddress).thenReturn(null);
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
      final whereToFinder = find.widgetWithText(
        AppInputText,
        "Insira o endereço de destino.",
      );
      expect(whereToFinder, findsOneWidget);
      await tester.tap(whereToFinder);
      await tester.pump();

      // expect disabled PlacePicker and enabled 'Definir destino no mapa'
      expect(defineDropOffState.googleMapsEnabled, false);
      expect(find.byType(PlacePicker), findsNothing);
      expect(defineDestinationFinder, findsOneWidget);
    });
  });

  group("addressPredictions", () {
    testWidgets(
        "updates TripModel and returns to previous screen if pick an address from predictions",
        (WidgetTester tester) async {
      // add DefineRoute to the UI
      await tester.pumpWidget(
        MultiProvider(
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

      // tap on 'Insira o endereço de destino.' AppInputText
      final insertDestinationFinder =
          find.widgetWithText(AppInputText, "Para onde?");
      expect(insertDestinationFinder, findsOneWidget);
      await tester.tap(insertDestinationFinder);
      await tester.pump();

      // verify that DefineDropOff was pushed
      verify(mockNavigatorObserver.didPush(any, any));
      await tester.pump();
      expect(find.byType(DefineDropOff), findsOneWidget);

      // // tap "Insira o endereço de destino." AppInputText and insert text
      final whereToFinder =
          find.widgetWithText(AppInputText, "Insira o endereço de destino.");
      await tester.tap(whereToFinder.last);
      await tester.enterText(whereToFinder.last, "Rua Presb");
      await tester.pumpAndSettle();

      // expect to find address prediction
      final addressPredictionFinder =
          find.widgetWithText(BorderlessButton, "Rua Presbiteriana");
      expect(addressPredictionFinder, findsOneWidget);

      // before tapping addressPrediction, TripModel hasn't been updated
      verifyNever(mockTripModel.updateDropOffAddres(any));

      // tap on addressPrediction
      await tester.tap(addressPredictionFinder);
      await tester.pumpAndSettle();

      // after tapping on addressPrediction, TripModel is updated
      expect(
        verify(mockTripModel.updateDropOffAddres(any)).callCount,
        equals(1),
      );

      // expect to return to DefineRoute screen
      verify(mockNavigatorObserver.didPop(any, any));
      expect(find.byType(DefineRoute), findsOneWidget);
    });
  });
}
