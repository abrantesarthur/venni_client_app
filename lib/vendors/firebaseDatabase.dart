import 'dart:async';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';

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

  // TODO: make sure this still works correctly. Print results and write tests
  Future<ClientInterface> getClientData(FirebaseModel firebase) async {
    String uid = firebase.auth.currentUser.uid;
    ClientInterface result;
    try {
      DataSnapshot snapshot =
          await this.reference().child("clients").child(uid).once();
      result = ClientInterface.fromJson(snapshot.value);

      // if pilot has upaid trip
      if (result.unpaidTripID != null && result.unpaidTripID.isNotEmpty) {
        // download unpaid trip and add it to result
        Trip unpaidTrip =
            await firebase.functions.getPastTrip(result.unpaidTripID);
        result.setUnpaidTrip(unpaidTrip);
      }
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

  Future<String> getPilotID(String userUID) async {
    try {
      DataSnapshot snapshot = await this
          .reference()
          .child("trip-requests")
          .child(userUID)
          .child("pilot_id")
          .once();
      return snapshot.value;
    } catch (_) {}
    return null;
  }

  Future<Map<dynamic, dynamic>> getPilotFromID(String pilotID) async {
    try {
      DataSnapshot snapshot =
          await this.reference().child("pilots").child(pilotID).once();
      return snapshot.value;
    } catch (_) {}
    return null;
  }

  // onPilotUpdate subscribes onData to handle changes in the pilot with uid pilotID
  StreamSubscription onPilotUpdate(
    String pilotID,
    void Function(Event) onData,
  ) {
    return this
        .reference()
        .child("pilots")
        .child(pilotID)
        .onValue
        .listen(onData);
  }

  // onPilotUpdate subscribes onData to handle changes in the trip status of the
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

enum DeleteReason {
  badTripExperience,
  badAppExperience,
  hasAnotherAccount,
  doesntUseService,
  another,
}

enum PaymentMethodType {
  credit_card,
  cash,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  static PaymentMethodType fromString(String s) {
    switch (s) {
      case "credit_card":
        return PaymentMethodType.credit_card;
      case "cash":
        return PaymentMethodType.cash;
      default:
        return null;
    }
  }
}

class ClientPaymentMethod {
  final PaymentMethodType type;
  final String creditCardID;

  ClientPaymentMethod({@required this.type, this.creditCardID});

  factory ClientPaymentMethod.fromJson(Map json) {
    return json != null
        ? ClientPaymentMethod(
            type: PaymentMethodTypeExtension.fromString(json["default"]),
            creditCardID: json["card_id"],
          )
        : null;
  }
}

enum CardBrand {
  mastercard,
  visa,
  elo,
  amex,
  discover,
  aura,
  jcb,
  hipercard,
  diners,
}

extension CardBrandExtension on CardBrand {
  static CardBrand fromString(String brand) {
    switch (brand) {
      case "mastercard":
        return CardBrand.mastercard;
      case "visa":
        return CardBrand.visa;
      case "elo":
        return CardBrand.elo;
      case "amex":
        return CardBrand.amex;
      case "discover":
        return CardBrand.discover;
      case "aura":
        return CardBrand.aura;
      case "jcb":
        return CardBrand.jcb;
      case "hipercard":
        return CardBrand.hipercard;
      case "diners":
        return CardBrand.diners;
      default:
        return null;
    }
  }

  String getString() {
    if (this != null) {
      return this.toString().substring(10);
    }
    return "";
  }
}

class CreditCard {
  final String id;
  final String holderName;
  final String firstDigits;
  final String lastDigits;
  final String expirationDate;
  final CardBrand brand;

  CreditCard({
    @required this.id,
    @required this.holderName,
    @required this.firstDigits,
    @required this.lastDigits,
    @required this.expirationDate,
    @required this.brand,
  });

  factory CreditCard.fromJson(Map json) {
    return json != null
        ? CreditCard(
            id: json["id"],
            holderName: json["holder_name"],
            firstDigits: json["first_digits"],
            lastDigits: json["last_digits"],
            expirationDate: json["expiration_date"],
            brand: CardBrandExtension.fromString(json["brand"]),
          )
        : null;
  }
}

class ClientInterface {
  final String rating;
  final ClientPaymentMethod defaultPaymentMethod;
  final List<CreditCard> creditCards;
  final String unpaidTripID;
  Trip unpaidTrip;
  ClientInterface({
    @required this.rating,
    @required this.defaultPaymentMethod,
    @required this.creditCards,
    @required this.unpaidTripID,
  });

  void setUnpaidTrip(Trip unpaidTrip) {
    this.unpaidTrip = unpaidTrip;
  }

  factory ClientInterface.fromJson(Map json) {
    if (json == null) {
      return null;
    }

    List<CreditCard> creditCards = [];
    if (json["cards"] != null) {
      json["cards"].keys.forEach((cardID) {
        CreditCard card = CreditCard.fromJson(json["cards"][cardID]);
        creditCards.add(card);
      });
    }

    return ClientInterface(
      rating: json["rating"],
      defaultPaymentMethod:
          ClientPaymentMethod.fromJson(json["payment_method"]),
      creditCards: creditCards,
      unpaidTripID: json["unpaid_past_trip_id"],
    );
  }
}
