import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/rateDriver.dart';

extension AppFirebaseFunctions on FirebaseFunctions {
  Future<RequestTripResult> _doTrip({
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

    // TODO: should I add a timeout?
    HttpsCallable callable = this.httpsCallable(functionName);
    try {
      HttpsCallableResult result = await callable.call(data);
      if (result != null && result.data != null) {
        return RequestTripResult.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<RequestTripResult> requestTrip(RequestTripArguments args) async {
    return this._doTrip(
      functionName: "trip-request",
      args: args,
    );
  }

  Future<RequestTripResult> editTrip(EditTripArguments args) async {
    return this._doTrip(
      functionName: "trip-edit",
      args: args,
    );
  }

  Future<RequestTripResult> cancelTrip() async {
    return this._doTrip(functionName: "trip-client_cancel");
  }

  Future<ConfirmTripResult> confirmTrip() async {
    try {
      HttpsCallableResult result =
          await this.httpsCallable("trip-confirm").call();
      if (result != null && result.data != null) {
        return ConfirmTripResult.fromJson(result.data);
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<void> rateDriver({
    @required String driverID,
    @required int score,
    Map<FeedbackComponent, bool> feedbackComponents,
    String feedbackMessage,
  }) async {
    // build argument
    Map<String, dynamic> args = {
      "driver_id": driverID,
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
      await this.httpsCallable("trip-rate_driver").call(args);
    } catch (_) {}
  }
}

enum DriverStatus {
  available,
  unavailable,
  requested,
  busy,
  offline,
}

DriverStatus getDriverStatusFromString(String status) {
  if (status == "available") {
    return DriverStatus.available;
  }
  if (status == "unavailable") {
    return DriverStatus.unavailable;
  }
  if (status == "requested") {
    return DriverStatus.requested;
  }
  if (status == "busy") {
    return DriverStatus.busy;
  }
  if (status == "offline") {
    return DriverStatus.offline;
  }
  return null;
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
  final String uid;
  final String name;
  final String lastName;
  final int totalTrips;
  final int memberSince;
  final String phoneNumber;
  final String currentClientID;
  final double currentLatitude;
  final double currentLongitude;
  final String currentZone;
  final DriverStatus driverStatus;
  final TripStatus tripStatus;
  final Vehicle vehicle;
  final int idleSince;
  final double rating;

  ConfirmTripResult({
    @required this.uid,
    @required this.name,
    @required this.lastName,
    @required this.totalTrips,
    @required this.memberSince,
    @required this.phoneNumber,
    @required this.currentClientID,
    @required this.currentLatitude,
    @required this.currentLongitude,
    @required this.currentZone,
    @required this.driverStatus,
    @required this.tripStatus,
    @required this.vehicle,
    @required this.idleSince,
    @required this.rating,
  });

  factory ConfirmTripResult.fromJson(Map<dynamic, dynamic> json) {
    if (json == null || json.isEmpty) return null;
    DriverStatus driverStatus = getDriverStatusFromString(json["status"]);
    TripStatus tripStatus = getTripStatusFromString(json["trip_status"]);
    return ConfirmTripResult(
      uid: json["uid"],
      name: json["name"],
      lastName: json["last_name"],
      totalTrips: int.parse(json["total_trips"]),
      memberSince: int.parse(json["member_since"]),
      phoneNumber: json["phone_number"],
      currentClientID: json["current_client_uid"],
      currentLatitude: double.parse(json["current_latitude"]),
      currentLongitude: double.parse(json["current_longitude"]),
      currentZone: json["current_zone"],
      driverStatus: driverStatus,
      tripStatus: tripStatus,
      vehicle: Vehicle.fromJson(json["vehicle"]),
      idleSince: int.parse(json["idle_since"]),
      rating: double.parse(double.parse(json["rating"]).toStringAsFixed(2)),
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

enum TripStatus {
  waitingConfirmation,
  waitingPayment,
  waitingDriver,
  lookingForDriver,
  noDriversAvailable,
  inProgress,
  completed,
  canceledByDriver,
  canceledByClient,
  paymentFailed,
  off,
}

class RequestTripResult {
  final String uid;
  final TripStatus tripStatus;
  final String originPlaceID;
  final String destinationPlaceID;
  final double farePrice;
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String encodedPoints;

  RequestTripResult({
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
  });

  factory RequestTripResult.fromJson(Map<dynamic, dynamic> json) {
    if (json == null || json.isEmpty) return null;
    TripStatus status = getTripStatusFromString(json["trip_status"]);
    return RequestTripResult(
      uid: json["uid"],
      tripStatus: status,
      originPlaceID: json["origin_place_id"],
      destinationPlaceID: json["destination_place_id"],
      farePrice: double.parse(json["fare_price"]),
      distanceMeters: int.parse(json["distance_meters"]),
      distanceText: json["distance_text"],
      durationSeconds: int.parse(json["duration_seconds"]),
      durationText: json["duration_text"],
      encodedPoints: json["encoded_points"],
    );
  }
}

TripStatus getTripStatusFromString(String status) {
  if (status == "waiting-confirmation") {
    return TripStatus.waitingConfirmation;
  }
  if (status == "waiting-payment") {
    return TripStatus.waitingPayment;
  }
  if (status == "waiting-driver") {
    return TripStatus.waitingDriver;
  }
  if (status == "looking-for-driver") {
    return TripStatus.lookingForDriver;
  }
  if (status == "no-drivers-available") {
    return TripStatus.noDriversAvailable;
  }
  if (status == "in-progress") {
    return TripStatus.inProgress;
  }
  if (status == "completed") {
    return TripStatus.completed;
  }
  if (status == "cancelled-by-driver") {
    return TripStatus.canceledByDriver;
  }
  if (status == "cancelled-by-client") {
    return TripStatus.canceledByClient;
  }
  if (status == "payment-failed") {
    return TripStatus.paymentFailed;
  }
  return null;
}
