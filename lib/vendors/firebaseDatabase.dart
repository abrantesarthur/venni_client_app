import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';

enum DeleteReason {
  badTripExperience,
  badAppExperience,
  hasAnotherAccount,
  doesntUseService,
  another,
}

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
            .child("delete-reasons")
            .child(reasonString)
            .child(uid)
            .set({
          "timestamp": DateTime.now().millisecondsSinceEpoch,
        });
      } catch (e) {}
      return;
    });
  }

  Future<double> getUserRating(String uid) async {
    double result;
    try {
      DataSnapshot snapshot = await this
          .reference()
          .child("clients")
          .child(uid)
          .child("rating")
          .once();
      // typecast to double if integer
      result = double.parse(snapshot.value);
    } catch (_) {}
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

  Future<String> getDriverID(String userUID) async {
    try {
      DataSnapshot snapshot = await this
          .reference()
          .child("trip-requests")
          .child(userUID)
          .child("driver_id")
          .once();
      return snapshot.value;
    } catch (_) {}
    return null;
  }

  Future<Map<dynamic, dynamic>> getDriverFromID(String driverID) async {
    try {
      DataSnapshot snapshot =
          await this.reference().child("pilots").child(driverID).once();
      return snapshot.value;
    } catch (_) {}
    return null;
  }

  // onDriverUpdate subscribes onData to handle changes in the driver with uid driverID
  StreamSubscription onDriverUpdate(
    String driverID,
    void Function(Event) onData,
  ) {
    return this
        .reference()
        .child("pilots")
        .child(driverID)
        .onValue
        .listen(onData);
  }

  // onDriverUpdate subscribes onData to handle changes in the trip status of the
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
