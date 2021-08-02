import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';

const String _TIMESTAMP = "timestamp";
const String _TRIP_DISTANCE = "trip_distance";
const String _TRIP_PRICE = "trip_price";
const String _TRIP_PAYMENT_METHOD = "trip_payment_method";
const String _RATE = "rate";

extension AppFirebaseAnalytics on FirebaseAnalytics {
  Future<void> logLogout() {
    return this.logEvent(
      name: "logout",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> setClientUserProperty() {
    return this.setUserProperty(name: "user_type", value: "client");
  }

  // distance should be in meters and price in cents
  Future<void> logClientConfirmTrip({
    @required int distance,
    @required int price,
    @required PaymentMethodType paymentMethod,
  }) {
    return this.logEvent(
      name: "client_confirm_trip",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
        _TRIP_DISTANCE: distance.toString(),
        _TRIP_PRICE: (price / 100).toStringAsFixed(2),
        _TRIP_PAYMENT_METHOD: paymentMethod.getString(),
      },
    );
  }

  Future<void> logClientCancelTrip() {
    return this.logEvent(
      name: "client_cancel_trip",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logPartnerNotFound() {
    return this.logEvent(
      name: "partner_not_found",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logPartnerFound() {
    return this.logEvent(
      name: "partner_found",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logCreditCardPaymentFailed() {
    return this.logEvent(
      name: "credit_card_payment_failed",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
      },
    );
  }

  Future<void> logClientRatePartner(int rate) {
    return this.logEvent(
      name: "client_rate_partner",
      parameters: {
        _TIMESTAMP: DateTime.now().millisecondsSinceEpoch.toString(),
        _RATE: rate.toString(),
      },
    );
  }
}
