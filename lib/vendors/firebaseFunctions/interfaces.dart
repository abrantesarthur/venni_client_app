import 'dart:io' as io;

import 'package:encrypt/encrypt.dart';
import 'package:encrypt/encrypt_io.dart';
import 'package:flutter/material.dart';
import 'package:pointycastle/asymmetric/api.dart';
import 'package:path_provider/path_provider.dart' as pp;
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';

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
