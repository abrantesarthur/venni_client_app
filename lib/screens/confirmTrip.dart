import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/vendors/geocoding.dart';

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
    if (tripStatus == TripStatus.lookingForPartner) {
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
          //    waitingPartner - request succeded! We should start listening for
          //      updates in partner position
          //    paymentFailed, noPartnersAvailable - error was thrown
          //    lookingForPartners - timed out looking for partners and threw error
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
  // paymentFailed, noPartnersAvailable - error was thrown
  // waitingConfirmation - very unlikely. Will only throw if
  //      request is unauthenticated (not the case) or there's no active
  //      trip request (not the case)
  // waitingPartner - request succeded! We should start listening for
  //      updates in partner position
  // lookingForPartners - timed out looking for partners and threw error
  Future<void> finishConfirmation(
    BuildContext context,
    ConfirmTripResult result,
  ) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // check for null result, which happens when confirmTrip throws an exception.
    if (result == null) {
      try {
        TripStatus tripStatus = await firebase.database
            .getTripStatus(firebase.auth.currentUser.uid);
        if (tripStatus == TripStatus.waitingConfirmation) {
          //if status is waitingConfirmation, which is very unlikely
          // cancel trip and show failure message . Otherwise, we would
          // rebuild the tree the same way as it was when we tapped confirmar.
          try {
            firebase.functions.cancelTrip();
          } catch (_) {}
          trip.clear();
          partner.clear();
          await showOkDialog(
            context: context,
            title: "Algo deu errado",
            content: "Tente novamente",
          );
        } else {
          trip.updateStatus(tripStatus);
        }
      } catch (_) {}

      return;
    }

    if (result.tripStatus == TripStatus.waitingPartner) {
      // populate PartnerModel with information returned by confirmTrip
      await partner.fromConfirmTripResult(context, result);

      // download partner profile picture
      if (partner.id != null) {
        ProfileImage img = await firebase.storage.getPartnerProfilePicture(
          partner.id,
        );
        partner.updateProfileImage(img, notify: false);
      }
    }

    // update trip status
    trip.updateStatus(result.tripStatus);
  }
}
