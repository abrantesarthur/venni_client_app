import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/driver.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/styles.dart';
import "package:rider_frontend/vendors/firebaseFunctions.dart";
import "package:rider_frontend/vendors/firebaseDatabase.dart";
import 'package:rider_frontend/vendors/geocoding.dart';

// TODO: test
class ConfirmTripArguments {
  final FirebaseModel firebase;
  final TripModel trip;
  ConfirmTripArguments({@required this.firebase, @required this.trip});
}

class ConfirmTrip extends StatefulWidget {
  static String routeName = "ConfirmTrip";
  final FirebaseModel firebase;
  final TripModel trip;

  ConfirmTrip({@required this.firebase, @required this.trip});

  @override
  ConfirmTripState createState() => ConfirmTripState();
}

class ConfirmTripState extends State<ConfirmTrip> {
  StreamSubscription tripStatusSubscription;
  String splashMessage;
  TripStatus tripStatus;
  Future<ConfirmTripResult> confirmTripResult;

  @override
  void initState() {
    splashMessage = "Calculando rota...";
    // start listening for trip status updates
    tripStatusSubscription = widget.firebase.database
        .reference()
        .child("trip-requests")
        .child(widget.firebase.auth.currentUser.uid)
        .child("trip_status")
        .onValue
        .listen(tripStatusListener);

    confirmTripResult = confirmTrip();
    super.initState();
  }

  // tripStatusListener updates the tripStatus variable with the value it receives
  void tripStatusListener(Event e) {
    tripStatus = getTripStatusFromString(e.snapshot.value);
    if (tripStatus == TripStatus.waitingConfirmation) {
      setState(() {
        splashMessage = "Confirmando pedido...";
      });
    }
    if (tripStatus == TripStatus.waitingPayment) {
      setState(() {
        splashMessage = "Processando pagamento...";
      });
    }
    if (tripStatus == TripStatus.lookingForDriver) {
      setState(() {
        splashMessage = "Encontrando o melhor piloto...";
      });
    }
  }

  Future<ConfirmTripResult> confirmTrip() async {
    GeocodingResponse geocoding;
    Address address;
    // make sure that latitude and longitude are set for pick up point
    if (widget.trip.pickUpAddress.latitude == null ||
        widget.trip.pickUpAddress.longitude == null) {
      geocoding = await Geocoding().searchByPlaceID(
        widget.trip.pickUpAddress.placeID,
      );
      if (geocoding != null && geocoding.isOkay) {
        address = Address.fromGeocodingResult(
          geocodingResult: geocoding.results[0],
          dropOff: false,
        );
        widget.trip.updatePickUpAddres(address);
      }
    }
    // make sure that latitude and longitude are set for drop off point
    if (widget.trip.dropOffAddress.latitude == null ||
        widget.trip.dropOffAddress.longitude == null) {
      geocoding = await Geocoding().searchByPlaceID(
        widget.trip.dropOffAddress.placeID,
      );
      if (geocoding != null && geocoding.isOkay) {
        address = Address.fromGeocodingResult(
          geocodingResult: geocoding.results[0],
          dropOff: true,
        );
        widget.trip.updateDropOffAddres(address);
      }
    }

    return await widget.firebase.functions.confirmTrip();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ConfirmTripResult>(
        future: confirmTripResult,
        builder: (
          BuildContext context,
          AsyncSnapshot<ConfirmTripResult> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // show Splash screen while waiting for confirmTrip to finish
            return Splash(text: splashMessage);
          }

          // regardless of whether request failed or not, we go back Home once
          // it finishes. trip-request will have one of the following statuses:
          //    waitingConfirmation - very unlikely. Will only throw if
          //      request is unauthenticated (not the case) or there's no active
          //      trip request (not the case)
          //    waitingDriver - request succeded! We should start listening for
          //      updates in driver position
          //    paymentFailed, noDriversAvailable - error was thrown
          //    lookingForDrivers - timed out looking for drivers and threw error
          SchedulerBinding.instance.addPostFrameCallback((_) async {
            // cancel stream subscription
            tripStatusSubscription.cancel();

            // try confirming the trip (success depends on trip status)
            await finishConfirmation(context, snapshot.data);

            // navigate back
            Navigator.pop(context);
          });

          // this is irrelevant
          return Splash(text: splashMessage);
        });
  }

  // when _tripConfirming is called, status will be one of the following:
  // paymentFailed, noDriversAvailable - error was thrown
  // waitingConfirmation - very unlikely. Will only throw if
  //      request is unauthenticated (not the case) or there's no active
  //      trip request (not the case)
  // waitingDriver - request succeded! We should start listening for
  //      updates in driver position
  // lookingForDrivers - timed out looking for drivers and threw error
  Future<void> finishConfirmation(
    BuildContext context,
    ConfirmTripResult result,
  ) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    DriverModel driver = Provider.of<DriverModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    TripStatus tripStatus;

    // check for null result, which happens when confirmTrip throws an exception.
    // In this case, there will obviously be no trip_status in result, so
    // we retrieve it from the backend.
    if (result == null) {
      String uid = firebase.auth.currentUser.uid;
      tripStatus = await firebase.database.getTripStatus(uid);
    } else {
      tripStatus = result.tripStatus;
    }

    //if status is waitingConfirmation, which is very unlikely
    // show failure message and cancel trip. Otherwise, we will
    // rebuild the tree the same way as it was when we tapped confirmar.
    if (tripStatus == TripStatus.waitingConfirmation) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Algo deu errado."),
            content: Text(
              "Tente novamente",
              style: TextStyle(color: AppColor.disabled),
            ),
            actions: [
              TextButton(
                child: Text(
                  "ok",
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
      firebase.functions.cancelTrip();
      trip.clear();
      return;
    }

    if (tripStatus == TripStatus.waitingDriver) {
      // populate DriverModel with information returned by confirmTrip
      driver.fromConfirmTripResult(context, result);
    }

    // update trip status
    trip.updateStatus(tripStatus);
  }
}
