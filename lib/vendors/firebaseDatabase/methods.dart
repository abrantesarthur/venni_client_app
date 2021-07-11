import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';

extension AppFirebaseDatabase on FirebaseDatabase {
  Future<void> submitDeleteReasons({
    @required Map<DeleteReason, bool> reasons,
    @required String uid,
  }) async {
    if (reasons == null) {
      return Future.value();
    }

    // iterate over reasons, adding them to database
    reasons.keys.forEach((key) async {
      String reasonString;

      // if user didn't select this reason, don't add it to database
      if (reasons[key] == false) {
        return;
      }

      switch (key) {
        case DeleteReason.badAppExperience:
          reasonString = "bad-app-experience";
          break;
        case DeleteReason.badTripExperience:
          reasonString = "bad-trip-experience";
          break;
        case DeleteReason.doesntUseService:
          reasonString = "doesnt-use-service";
          break;
        case DeleteReason.hasAnotherAccount:
          reasonString = "has-another-account";
          break;
        case DeleteReason.another:
          reasonString = "something-else";
          break;
      }

      try {
        await this
            .reference()
            .child("client-delete-reasons")
            .child(reasonString)
            .child(uid)
            .set({
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {}
      return;
    });
  }

  // TODO: make sure this still works correctly. Print results and write tests
  Future<ClientInterface> getClientData(FirebaseModel firebase) async {
    ClientInterface result;
    String uid = firebase.auth.currentUser?.uid ?? "";
    DataSnapshot snapshot =
        await this.reference().child("clients").child(uid).once();
    result = ClientInterface.fromJson(snapshot.value);
    // if client has upaid trip
    if (result != null &&
        result.unpaidTripID != null &&
        result.unpaidTripID.isNotEmpty) {
      // download unpaid trip and add it to result
      Trip unpaidTrip = await firebase.functions.getPastTrip(
        result.unpaidTripID,
      );
      result.setUnpaidTrip(unpaidTrip);
    }
    return result;
  }

  Future<TripStatus> getTripStatus(String uid) async {
    try {
      DataSnapshot snapshot = await this
          .reference()
          .child("trip-requests")
          .child(uid)
          .child("trip_status")
          .once();
      return getTripStatusFromString(snapshot.value);
    } catch (_) {}
    return null;
  }

  Future<String> getPartnerID(String userUID) async {
    try {
      DataSnapshot snapshot = await this
          .reference()
          .child("trip-requests")
          .child(userUID)
          .child("partner_id")
          .once();
      return snapshot.value;
    } catch (_) {}
    return null;
  }

  Future<void> createClient(User user) async {
    return await this.reference().child("clients").child(user.uid).set({
      "uid": user.uid,
      "payment_method": {
        "default": "cash",
      },
      "rating": "5",
    });
  }

  Future<void> deleteClient(String uid) async {
    return await this.reference().child("clients").child(uid).remove();
  }

  Future<Map<dynamic, dynamic>> getPartnerFromID(String partnerID) async {
    try {
      DataSnapshot snapshot =
          await this.reference().child("partners").child(partnerID).once();
      return snapshot.value;
    } catch (_) {}
    return null;
  }

  // onPartnerUpdate subscribes onData to handle changes in the partner with uid partnerID
  StreamSubscription onPartnerUpdate(
    String partnerID,
    void Function(Event) onData,
  ) {
    return this
        .reference()
        .child("partners")
        .child(partnerID)
        .onValue
        .listen(onData);
  }

  // onPartnerUpdate subscribes onData to handle changes in the trip status of the
  // trip of user with id userID.
  StreamSubscription onTripStatusUpdate(
    String userID,
    void Function(Event) onData,
  ) {
    return this
        .reference()
        .child("trip-requests")
        .child(userID)
        .child("trip_status")
        .onValue
        .listen(onData);
  }
}
