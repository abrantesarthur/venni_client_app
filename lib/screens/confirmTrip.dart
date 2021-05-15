import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/pilot.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/styles.dart';
import "package:rider_frontend/vendors/firebaseFunctions.dart";
import "package:rider_frontend/vendors/firebaseDatabase.dart";
import 'package:rider_frontend/vendors/geocoding.dart';

// TODO: test
class ConfirmTripArguments {
  final FirebaseModel firebase;
  final TripModel trip;
  final UserModel user;
  ConfirmTripArguments({
    @required this.firebase,
    @required this.trip,
    @required this.user,
  });
}

class ConfirmTrip extends StatefulWidget {
  static String routeName = "ConfirmTrip";
  final FirebaseModel firebase;
  final TripModel trip;
  final UserModel user;

  ConfirmTrip({
    @required this.firebase,
    @required this.trip,
    @required this.user,
  });

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
    if (tripStatus == TripStatus.lookingForPilot) {
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

    // call confirmTrip with cardID if payment method is credit_card
    String cardID;
    if (widget.user.defaultPaymentMethod.type ==
        PaymentMethodType.credit_card) {
      cardID = widget.user.defaultPaymentMethod.creditCardID;
    }
    return await widget.firebase.functions.confirmTrip(cardID: cardID);
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
          //    waitingConfirmation - very unlikely. Happens only if
          //      request is unauthenticated (not the case) or there's no active
          //      trip request (not the case). In those cases, confirmTrip returns
          //      null.
          //    waitingPilot - request succeded! We should start listening for
          //      updates in pilot position
          //    paymentFailed, noPilotsAvailable - error was thrown
          //    lookingForPilots - timed out looking for pilots and threw error
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
  // paymentFailed, noPilotsAvailable - error was thrown
  // waitingConfirmation - very unlikely. Will only throw if
  //      request is unauthenticated (not the case) or there's no active
  //      trip request (not the case)
  // waitingPilot - request succeded! We should start listening for
  //      updates in pilot position
  // lookingForPilots - timed out looking for pilots and threw error
  Future<void> finishConfirmation(
    BuildContext context,
    ConfirmTripResult result,
  ) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PilotModel pilot = Provider.of<PilotModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // check for null result, which happens when confirmTrip throws an exception.
    if (result == null) {
      TripStatus tripStatus =
          await firebase.database.getTripStatus(firebase.auth.currentUser.uid);
      if (tripStatus == TripStatus.waitingConfirmation) {
        //if status is waitingConfirmation, which is very unlikely
        // cancel trip and show failure message . Otherwise, we would
        // rebuild the tree the same way as it was when we tapped confirmar.
        firebase.functions.cancelTrip();
        trip.clear();
        pilot.clear();
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Algo deu errado."),
              content: Text(
                "Tente novamente!",
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
      } else {
        trip.updateStatus(tripStatus);
      }
      return;
    }

    if (result.tripStatus == TripStatus.waitingPilot) {
      // populate PilotModel with information returned by confirmTrip
      await pilot.fromConfirmTripResult(context, result);
    }

    // update trip status
    trip.updateStatus(result.tripStatus);
  }
}
