import 'dart:io' as io;

import 'package:cloud_functions/cloud_functions.dart';
import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/ratePartner.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:rider_frontend/vendors/firebaseDatabase.dart';

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
    try {
      HttpsCallableResult result = await callable.call(data);
      if (result != null && result.data != null) {
        return Trip.fromJson(result.data);
      }
    } catch (e) {
      throw e;
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
    try {
      HttpsCallableResult result =
          await this.httpsCallable("trip-confirm").call(data);
      if (result != null && result.data != null) {
        return ConfirmTripResult.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<bool> captureUnpaidTrip(String cardID) async {
    Map data = {"card_id": cardID};
    try {
      HttpsCallableResult result =
          await this.httpsCallable("payment-capture_unpaid_trip").call(data);
      if (result != null) {
        return result.data;
      }
    } catch (e) {
      throw e;
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

    try {
      HttpsCallableResult result =
          await this.httpsCallable("trip-client_get_past_trips").call(data);
      if (result != null && result.data != null) {
        return Trips.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<Trip> getPastTrip(String pastTripID) async {
    Map data = {"past_trip_id": pastTripID};
    try {
      HttpsCallableResult result =
          await this.httpsCallable("trip-client_get_past_trip").call(data);
      if (result != null && result.data != null) {
        return Trip.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<int> partnerGetTripRating(PartnerGetTripRatingArguments args) async {
    Map<String, String> data = {};
    data["partner_id"] = args.partnerID;
    data["past_trip_ref_key"] = args.pastTripRefKey;
    try {
      HttpsCallableResult result =
          await this.httpsCallable("trip-partner_get_trip_rating").call(data);
      if (result != null &&
          result.data != null &&
          result.data["partner_rating"] != null) {
        return result.data["partner_rating"];
      }
    } catch (e) {
      throw e;
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
    try {
      HttpsCallableResult result =
          await this.httpsCallable("payment-get_card_hash_key").call();
      if (result != null && result.data != null) {
        return HashKey.fromJson(result.data);
      }
    } catch (e) {
      throw e;
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

    try {
      HttpsCallableResult result =
          await this.httpsCallable("payment-create_card").call(data);
      if (result != null && result.data != null) {
        return CreditCard.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<void> deleteCard(String cardID) async {
    try {
      await this.httpsCallable("payment-delete_card").call({"card_id": cardID});
    } catch (e) {
      throw e;
    }
  }

  Future<void> setDefaultPaymentMethod({String cardID}) async {
    Map<String, dynamic> data = {};
    if (cardID != null) {
      data["card_id"] = cardID;
    }
    try {
      await this.httpsCallable("payment-set_default_payment_method").call(data);
    } catch (e) {
      throw e;
    }
  }
}

class HashKey {
  final String dateCreated;
  final int id;
  final String ip;
  final String publicKey;

  HashKey({
    @required this.dateCreated,
    @required this.id,
    @required this.ip,
    @required this.publicKey,
  });

  factory HashKey.fromJson(Map json) {
    return json != null
        ? HashKey(
            dateCreated: json["date_created"],
            id: json["id"],
            ip: json["ip"],
            publicKey: json["public_key"],
          )
        : null;
  }
}

class BillingAddress {
  final String country;
  final String state;
  final String city;
  final String street;
  final String streetNumber;
  final String zipcode;

  BillingAddress({
    @required this.country,
    @required this.state,
    @required this.city,
    @required this.street,
    @required this.streetNumber,
    @required this.zipcode,
  });
}

class CreateCardArguments {
  final String cardNumber;
  final String cardExpirationDate;
  final String cardHolderName;
  final String cardCvv;

  final String cpfNumber;
  final String phoneNumber;
  final String email;
  final BillingAddress billingAddress;

  CreateCardArguments({
    @required this.cardNumber,
    @required this.cardExpirationDate,
    @required this.cardHolderName,
    @required this.cpfNumber,
    @required this.phoneNumber,
    @required this.email,
    @required this.cardCvv,
    @required this.billingAddress,
  });

  Future<String> calculateCardHash(HashKey hashKey) async {
    String queryString = "card_number=" +
        this.cardNumber +
        "&card_holder_name=" +
        this.cardHolderName.replaceAll(RegExp(' +'), "%20") +
        "&card_expiration_date" +
        this.cardExpirationDate +
        "&card_cvv=" +
        this.cardCvv;

    // TODO: can I use this strategy to create a cache?
    // store public key in '.pem' file in cache
    final dir = await pp.getTemporaryDirectory();
    final pkFile = await io.File(dir.path + "/public.pem")
        .writeAsString(hashKey.publicKey);

    // read publiKey from file
    final publicKey =
        await parseKeyFromFile<RSAPublicKey>(dir.path + "/public.pem");

    final encrypter = Encrypter(RSA(publicKey: publicKey));

    final encrypted = encrypter.encrypt(queryString);

    final cardHash = hashKey.id.toString() + "_" + encrypted.base64;

    // delete created file
    await pkFile.delete();

    return cardHash;
  }
}

class PartnerGetTripRatingArguments {
  String partnerID;
  String pastTripRefKey;

  PartnerGetTripRatingArguments({
    @required this.partnerID,
    @required this.pastTripRefKey,
  });
}

class GetPastTripsArguments {
  int pageSize;
  int maxRequestTime;

  GetPastTripsArguments({
    this.pageSize,
    this.maxRequestTime,
  });
}

class Trips {
  final List<Trip> items;

  Trips({@required this.items});

  factory Trips.fromJson(List<dynamic> json) {
    List<Trip> pastTrips = json.map((pt) => Trip.fromJson(pt)).toList();
    return Trips(items: pastTrips);
  }
}

class Trip {
  final String uid;
  final TripStatus tripStatus;
  final String originPlaceID;
  final String destinationPlaceID;
  final num farePrice;
  final num distanceMeters;
  final String distanceText;
  final num durationSeconds;
  final String durationText;
  final String encodedPoints;
  final num requestTime;
  final String originAddress;
  final String destinationAddress;
  final String partnerPastTripRefKey;
  final String partnerID;
  final PaymentMethodType paymentMethod;
  final CreditCard creditCard;
  final String transactionID;
  Trip({
    @required this.uid,
    @required this.tripStatus,
    @required this.originPlaceID,
    @required this.destinationPlaceID,
    @required this.farePrice,
    @required this.distanceMeters,
    @required this.distanceText,
    @required this.durationSeconds,
    @required this.durationText,
    @required this.encodedPoints,
    @required this.requestTime,
    @required this.originAddress,
    @required this.destinationAddress,
    @required this.partnerPastTripRefKey,
    @required this.partnerID,
    this.paymentMethod,
    this.creditCard,
    this.transactionID,
  });

  // TODO: test the shit out of this and all other fromJson functions!!!
  factory Trip.fromJson(Map<dynamic, dynamic> json) {
    if (json == null || json.isEmpty) return null;
    TripStatus status = getTripStatusFromString(json["trip_status"]);
    PaymentMethodType paymentMethod = json["payment_method"] != null
        ? PaymentMethodTypeExtension.fromString(json["payment_method"])
        : null;
    CreditCard creditCard = json["credit_card"] != null
        ? CreditCard.fromJson(json["credit_card"])
        : null;
    return Trip(
      uid: json["uid"],
      tripStatus: status,
      originPlaceID: json["origin_place_id"],
      destinationPlaceID: json["destination_place_id"],
      farePrice: json["fare_price"],
      distanceMeters: int.parse(json["distance_meters"]),
      distanceText: json["distance_text"],
      durationSeconds: int.parse(json["duration_seconds"]),
      durationText: json["duration_text"],
      encodedPoints: json["encoded_points"],
      requestTime: int.parse(json["request_time"]),
      originAddress: json["origin_address"],
      destinationAddress: json["destination_address"],
      partnerPastTripRefKey: json["partner_past_trip_ref_key"],
      partnerID: json["partner_id"],
      paymentMethod: paymentMethod,
      creditCard: creditCard,
      transactionID: json["transaction_id"],
    );
  }
}

class Vehicle {
  String brand;
  String model;
  int year;
  String plate;

  Vehicle({
    @required this.brand,
    @required this.model,
    @required this.year,
    @required this.plate,
  });

  factory Vehicle.fromJson(Map<dynamic, dynamic> json) {
    return json != null
        ? Vehicle(
            brand: json["brand"],
            model: json["model"],
            year: json["year"],
            plate: json["plate"])
        : null;
  }
}

class ConfirmTripResult {
  final String partnerID;
  final String partnerName;
  final String partnerLastName;
  final int partnerTotalTrips;
  final int partnerMemberSince;
  final String partnerPhoneNumber;
  final String partnerCurrentClientID;
  final double partnerCurrentLatitude;
  final double partnerCurrentLongitude;
  final String partnerCurrentZone;
  final PartnerStatus partnerStatus;
  final TripStatus tripStatus;
  final Vehicle partnerVehicle;
  final int partnerIdleSince;
  final double partnerRating;

  ConfirmTripResult({
    @required this.partnerID,
    @required this.partnerName,
    @required this.partnerLastName,
    @required this.partnerTotalTrips,
    @required this.partnerMemberSince,
    @required this.partnerPhoneNumber,
    @required this.partnerCurrentClientID,
    @required this.partnerCurrentLatitude,
    @required this.partnerCurrentLongitude,
    @required this.partnerCurrentZone,
    @required this.partnerStatus,
    @required this.tripStatus,
    @required this.partnerVehicle,
    @required this.partnerIdleSince,
    @required this.partnerRating,
  });

  factory ConfirmTripResult.fromJson(Map<dynamic, dynamic> json) {
    if (json == null || json.isEmpty) return null;
    PartnerStatus partnerStatus =
        getPartnerStatusFromString(json["partner_status"]);
    TripStatus tripStatus = getTripStatusFromString(json["trip_status"]);
    return ConfirmTripResult(
      partnerID: json["partner_id"],
      partnerName: json["partner_name"],
      partnerLastName: json["partner_last_name"],
      partnerTotalTrips: int.parse(json["partner_total_trips"]),
      partnerMemberSince: int.parse(json["partner_member_since"]),
      partnerPhoneNumber: json["partner_phone_number"],
      partnerCurrentClientID: json["current_client_uid"],
      partnerCurrentLatitude: double.parse(json["partner_current_latitude"]),
      partnerCurrentLongitude: double.parse(json["partner_current_longitude"]),
      partnerCurrentZone: json["partner_current_zone"],
      partnerStatus: partnerStatus,
      tripStatus: tripStatus,
      partnerVehicle: Vehicle.fromJson(json["partner_vehicle"]),
      partnerIdleSince: int.parse(json["partner_idle_since"]),
      partnerRating:
          double.parse(double.parse(json["partner_rating"]).toStringAsFixed(2)),
    );
  }
}

class RequestTripArguments {
  final String originPlaceID;
  final String destinationPlaceID;

  RequestTripArguments({
    @required this.originPlaceID,
    @required this.destinationPlaceID,
  });
}

class EditTripArguments extends RequestTripArguments {
  EditTripArguments({
    @required String originPlaceID,
    @required String destinationPlaceID,
  }) : super(
          originPlaceID: originPlaceID,
          destinationPlaceID: destinationPlaceID,
        );
}

enum PartnerStatus {
  available,
  unavailable,
  requested,
  busy,
  offline,
}

PartnerStatus getPartnerStatusFromString(String status) {
  if (status == "available") {
    return PartnerStatus.available;
  }
  if (status == "unavailable") {
    return PartnerStatus.unavailable;
  }
  if (status == "requested") {
    return PartnerStatus.requested;
  }
  if (status == "busy") {
    return PartnerStatus.busy;
  }
  if (status == "offline") {
    return PartnerStatus.offline;
  }
  return null;
}

enum TripStatus {
  waitingConfirmation,
  waitingPayment,
  waitingPartner,
  lookingForPartner,
  noPartnersAvailable,
  inProgress,
  completed,
  canceledByPartner,
  canceledByClient,
  paymentFailed,
  off,
}

TripStatus getTripStatusFromString(String status) {
  if (status == "waiting-confirmation") {
    return TripStatus.waitingConfirmation;
  }
  if (status == "waiting-payment") {
    return TripStatus.waitingPayment;
  }
  if (status == "waiting-partner") {
    return TripStatus.waitingPartner;
  }
  if (status == "looking-for-partner") {
    return TripStatus.lookingForPartner;
  }
  if (status == "no-partners-available") {
    return TripStatus.noPartnersAvailable;
  }
  if (status == "in-progress") {
    return TripStatus.inProgress;
  }
  if (status == "completed") {
    return TripStatus.completed;
  }
  if (status == "cancelled-by-partner") {
    return TripStatus.canceledByPartner;
  }
  if (status == "cancelled-by-client") {
    return TripStatus.canceledByClient;
  }
  if (status == "payment-failed") {
    return TripStatus.paymentFailed;
  }
  return null;
}
