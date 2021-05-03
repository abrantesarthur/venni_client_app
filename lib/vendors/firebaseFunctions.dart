import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/ratePilot.dart';
import 'package:rider_frontend/screens/ratePilot.dart';

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

    // TODO: should I add a timeout?
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

  Future<int> pilotGetTripRating(PilotGetTripRatingArguments args) async {
    Map<String, String> data = {};
    data["pilot_id"] = args.pilotID;
    data["past_trip_ref_key"] = args.pastTripRefKey;
    try {
      HttpsCallableResult result =
          await this.httpsCallable("trip-pilot_get_trip_rating").call(data);
      if (result != null &&
          result.data != null &&
          result.data["pilot_rating"] != null) {
        return result.data["pilot_rating"];
      }
    } catch (e) {
      throw e;
    }
    return null;
  }

  Future<void> ratePilot({
    @required String pilotID,
    @required int score,
    Map<FeedbackComponent, bool> feedbackComponents,
    String feedbackMessage,
  }) async {
    // build argument
    Map<String, dynamic> args = {
      "pilot_id": pilotID,
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
      await this.httpsCallable("trip-rate_pilot").call(args);
    } catch (_) {}
  }
}

class PilotGetTripRatingArguments {
  String pilotID;
  String pastTripRefKey;

  PilotGetTripRatingArguments({
    @required this.pilotID,
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
  final String farePrice;
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String encodedPoints;
  final int requestTime;
  final String originAddress;
  final String destinationAddress;
  final String pilotPastTripRefKey;
  final String pilotID;

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
    @required this.pilotPastTripRefKey,
    @required this.pilotID,
  });

  factory Trip.fromJson(Map<dynamic, dynamic> json) {
    if (json == null || json.isEmpty) return null;
    TripStatus status = getTripStatusFromString(json["trip_status"]);
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
      pilotPastTripRefKey: json["pilot_past_trip_ref_key"],
      pilotID: json["pilot_id"],
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
  final String pilotID;
  final String pilotName;
  final String pilotLastName;
  final int pilotTotalTrips;
  final int pilotMemberSince;
  final String pilotPhoneNumber;
  final String pilotCurrentClientID;
  final double pilotCurrentLatitude;
  final double pilotCurrentLongitude;
  final String pilotCurrentZone;
  final PilotStatus pilotStatus;
  final TripStatus tripStatus;
  final Vehicle pilotVehicle;
  final int pilotIdleSince;
  final double pilotRating;

  ConfirmTripResult({
    @required this.pilotID,
    @required this.pilotName,
    @required this.pilotLastName,
    @required this.pilotTotalTrips,
    @required this.pilotMemberSince,
    @required this.pilotPhoneNumber,
    @required this.pilotCurrentClientID,
    @required this.pilotCurrentLatitude,
    @required this.pilotCurrentLongitude,
    @required this.pilotCurrentZone,
    @required this.pilotStatus,
    @required this.tripStatus,
    @required this.pilotVehicle,
    @required this.pilotIdleSince,
    @required this.pilotRating,
  });

  factory ConfirmTripResult.fromJson(Map<dynamic, dynamic> json) {
    if (json == null || json.isEmpty) return null;
    PilotStatus pilotStatus = getPilotStatusFromString(json["pilot_status"]);
    TripStatus tripStatus = getTripStatusFromString(json["trip_status"]);
    return ConfirmTripResult(
      pilotID: json["pilot_id"],
      pilotName: json["pilot_name"],
      pilotLastName: json["pilot_last_name"],
      pilotTotalTrips: int.parse(json["pilot_total_trips"]),
      pilotMemberSince: int.parse(json["pilot_member_since"]),
      pilotPhoneNumber: json["pilot_phone_number"],
      pilotCurrentClientID: json["current_client_uid"],
      pilotCurrentLatitude: double.parse(json["pilot_current_latitude"]),
      pilotCurrentLongitude: double.parse(json["pilot_current_longitude"]),
      pilotCurrentZone: json["pilot_current_zone"],
      pilotStatus: pilotStatus,
      tripStatus: tripStatus,
      pilotVehicle: Vehicle.fromJson(json["pilot_vehicle"]),
      pilotIdleSince: int.parse(json["pilot_idle_since"]),
      pilotRating:
          double.parse(double.parse(json["pilot_rating"]).toStringAsFixed(2)),
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

enum PilotStatus {
  available,
  unavailable,
  requested,
  busy,
  offline,
}

PilotStatus getPilotStatusFromString(String status) {
  if (status == "available") {
    return PilotStatus.available;
  }
  if (status == "unavailable") {
    return PilotStatus.unavailable;
  }
  if (status == "requested") {
    return PilotStatus.requested;
  }
  if (status == "busy") {
    return PilotStatus.busy;
  }
  if (status == "offline") {
    return PilotStatus.offline;
  }
  return null;
}

enum TripStatus {
  waitingConfirmation,
  waitingPayment,
  waitingPilot,
  lookingForPilot,
  noPilotsAvailable,
  inProgress,
  completed,
  canceledByPilot,
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
  if (status == "waiting-pilot") {
    return TripStatus.waitingPilot;
  }
  if (status == "looking-for-pilot") {
    return TripStatus.lookingForPilot;
  }
  if (status == "no-pilots-available") {
    return TripStatus.noPilotsAvailable;
  }
  if (status == "in-progress") {
    return TripStatus.inProgress;
  }
  if (status == "completed") {
    return TripStatus.completed;
  }
  if (status == "cancelled-by-pilot") {
    return TripStatus.canceledByPilot;
  }
  if (status == "cancelled-by-client") {
    return TripStatus.canceledByClient;
  }
  if (status == "payment-failed") {
    return TripStatus.paymentFailed;
  }
  return null;
}
