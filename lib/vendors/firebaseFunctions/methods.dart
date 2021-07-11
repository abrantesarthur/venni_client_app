import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/ratePartner.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';

extension AppFirebaseFunctions on FirebaseFunctions {
  Future<Trip> _doTrip({
    @required String functionName,
    dynamic args,
  }) async {
    Map<String, String> data;
    if (args is RequestTripArguments || args is EditTripArguments) {
      data = {
        "origin_place_id": args.originPlaceID,
        "destination_place_id": args.destinationPlaceID,
      };
    }

    HttpsCallable callable = this.httpsCallable(functionName);
    HttpsCallableResult result = await callable.call(data);
    if (result != null && result.data != null) {
      return Trip.fromJson(result.data);
    }
    return null;
  }

  Future<Trip> requestTrip(RequestTripArguments args) async {
    return this._doTrip(
      functionName: "trip-request",
      args: args,
    );
  }

  Future<Trip> editTrip(EditTripArguments args) async {
    return this._doTrip(
      functionName: "trip-edit",
      args: args,
    );
  }

  Future<Trip> cancelTrip() async {
    return this._doTrip(functionName: "trip-client_cancel");
  }

  Future<ConfirmTripResult> confirmTrip({String cardID}) async {
    Map data = {};
    if (cardID != null) {
      data["card_id"] = cardID;
    }
    HttpsCallableResult result =
        await this.httpsCallable("trip-confirm").call(data);
    if (result != null && result.data != null) {
      return ConfirmTripResult.fromJson(result.data);
    }
    return null;
  }

  Future<bool> captureUnpaidTrip(String cardID) async {
    Map data = {"card_id": cardID};
    HttpsCallableResult result =
        await this.httpsCallable("payment-capture_unpaid_trip").call(data);
    if (result != null && result.data != null) {
      return result.data["success"];
    }
    return false;
  }

  Future<Trips> getPastTrips({GetPastTripsArguments args}) async {
    Map<String, int> data = {};
    if (args != null) {
      if (args.pageSize != null) {
        data["page_size"] = args.pageSize;
      }
      if (args.maxRequestTime != null) {
        data["max_request_time"] = args.maxRequestTime;
      }
    }

    HttpsCallableResult result =
        await this.httpsCallable("trip-client_get_past_trips").call(data);
    if (result != null && result.data != null) {
      return Trips.fromJson(result.data);
    }
    return null;
  }

  Future<Trip> getPastTrip(String pastTripID) async {
    Map data = {"past_trip_id": pastTripID};
    HttpsCallableResult result =
        await this.httpsCallable("trip-client_get_past_trip").call(data);
    if (result != null && result.data != null) {
      return Trip.fromJson(result.data);
    }
    return null;
  }

  Future<Trip> getCurrentTrip() async {
    HttpsCallableResult result =
        await this.httpsCallable("trip-client_get_current_trip").call();
    if (result != null && result.data != null) {
      return Trip.fromJson(result.data);
    }
    return null;
  }

  Future<int> partnerGetTripRating(PartnerGetTripRatingArguments args) async {
    Map<String, String> data = {};
    data["partner_id"] = args.partnerID;
    data["past_trip_ref_key"] = args.pastTripRefKey;
    HttpsCallableResult result =
        await this.httpsCallable("trip-partner_get_trip_rating").call(data);
    if (result != null &&
        result.data != null &&
        result.data["partner_rating"] != null) {
      return result.data["partner_rating"];
    }
    return null;
  }

  Future<void> ratePartner({
    @required String partnerID,
    @required int score,
    Map<FeedbackComponent, bool> feedbackComponents,
    String feedbackMessage,
  }) async {
    // build argument
    Map<String, dynamic> args = {
      "partner_id": partnerID,
      "score": score,
    };
    if (feedbackComponents != null) {
      feedbackComponents.forEach((key, value) {
        if (key == FeedbackComponent.cleanliness_went_well) {
          args["cleanliness_went_well"] = value;
        }
        if (key == FeedbackComponent.safety_went_well) {
          args["safety_went_well"] = value;
        }
        if (key == FeedbackComponent.waiting_time_went_well) {
          args["waiting_time_went_well"] = value;
        }
      });
    }
    if (feedbackMessage != null && feedbackMessage.length > 0) {
      args["feedback"] = feedbackMessage;
    }
    try {
      await this.httpsCallable("trip-rate_partner").call(args);
    } catch (_) {}
  }

  Future<HashKey> getCardHashKey() async {
    HttpsCallableResult result =
        await this.httpsCallable("payment-get_card_hash_key").call();
    if (result != null && result.data != null) {
      return HashKey.fromJson(result.data);
    }
    return null;
  }

  // TODO: add tests to fromJson and wherever else appropriate
  Future<CreditCard> createCard(CreateCardArguments args) async {
    // build cardHash
    HashKey hashKey = await getCardHashKey();
    final cardHash = await args.calculateCardHash(hashKey);

    // build data
    Map<String, dynamic> data = {};
    data["card_number"] = args.cardNumber;
    data["card_expiration_date"] = args.cardExpirationDate;
    data["card_holder_name"] = args.cardHolderName;
    data["card_hash"] = cardHash;
    data["cpf_number"] = args.cpfNumber;
    data["phone_number"] = args.phoneNumber;
    data["email"] = args.email;
    Map<String, String> billingAddress = {};
    billingAddress["country"] = args.billingAddress.country;
    billingAddress["state"] = args.billingAddress.state;
    billingAddress["city"] = args.billingAddress.city;
    billingAddress["street"] = args.billingAddress.street;
    billingAddress["street_number"] = args.billingAddress.streetNumber;
    billingAddress["zipcode"] = args.billingAddress.zipcode;
    data["billing_address"] = billingAddress;

    HttpsCallableResult result =
        await this.httpsCallable("payment-create_card").call(data);
    if (result != null && result.data != null) {
      return CreditCard.fromJson(result.data);
    }
    return null;
  }

  Future<void> deleteCard(String cardID) async {
    await this.httpsCallable("payment-delete_card").call({"card_id": cardID});
  }

  Future<void> setDefaultPaymentMethod({String cardID}) async {
    Map<String, dynamic> data = {};
    if (cardID != null) {
      data["card_id"] = cardID;
    }
    await this.httpsCallable("payment-set_default_payment_method").call(data);
  }

  Future<void> deleteAccount() async {
    await this.httpsCallable("account-delete_client").call();
  }

  Future<Partner> getPartner(String id) async {
    print("getPartner");
    Map<String, String> data = {"partner_id": id};
    HttpsCallableResult result =
        await this.httpsCallable("partner-get_by_id").call(data);
    if (result != null && result.data != null) {
      print(result.data);
      return Partner.fromJson(result.data);
    }
    return null;
  }
}
