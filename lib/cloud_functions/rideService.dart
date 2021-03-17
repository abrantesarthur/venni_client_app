import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/cloud_functions/cloudFunctionsService.dart';

enum RideStatus {
  finished,
  canceledByDriver,
  canceledByClient,
  waitingForConfirmation,
  waitingForRider,
  inProgress,
}

class Ride extends CloudFunctionsWebService {
  Ride({@required String userIdToken}) : super(userIdToken: userIdToken);

  Future<RideRequestResponse> request({
    @required originPlaceID,
    @required destinationPlaceID,
  }) async {
    Map<String, String> data = {
      "origin_place_id": originPlaceID,
      "destination_place_id": destinationPlaceID,
    };

    return _decode(await doPost(
      path: "ride-request",
      body: json.encode(data),
    ));
  }

  Future<RideRequestResponse> edit({
    @required originPlaceID,
    @required destinationPlaceID,
  }) async {
    Map<String, String> data = {
      "origin_place_id": originPlaceID,
      "destination_place_id": destinationPlaceID,
    };

    return _decode(await doPut(
      path: "ride-edit",
      body: json.encode(data),
    ));
  }

  RideRequestResponse _decode(http.Response response) {
    if (response != null && response.statusCode < 300) {
      return RideRequestResponse.fromJson(jsonDecode(response.body));
    } // TODO: log this somewhere
    return null;
  }
}

class RideRequestResponse extends CloudFunctionsResponse<RideRequestResult> {
  RideRequestResponse({
    @required String status,
    @required String errorMessage,
    @required RideRequestResult result,
  }) : super(
          result: result,
          status: status,
          errorMessage: errorMessage,
        );

  factory RideRequestResponse.fromJson(Map<String, dynamic> json) {
    return (json == null)
        ? null
        : RideRequestResponse(
            status: json["status"],
            errorMessage: json["error_message"],
            result: RideRequestResult.fromJson(json["result"]),
          );
  }
}

class RideRequestResult {
  final String uid;
  final RideStatus rideStatus;
  final String originPlaceID;
  final String destinationPlaceID;
  final double farePrice;
  final int distanceMeters;
  final String distanceText;
  final int durationSeconds;
  final String durationText;
  final String encodedPoints;

  RideRequestResult({
    @required this.uid,
    @required this.rideStatus,
    @required this.originPlaceID,
    @required this.destinationPlaceID,
    @required this.farePrice,
    @required this.distanceMeters,
    @required this.distanceText,
    @required this.durationSeconds,
    @required this.durationText,
    @required this.encodedPoints,
  });

  factory RideRequestResult.fromJson(Map<String, dynamic> json) {
    if (json == null) return null;
    RideStatus status = getRideStatusFromString(json["ride_status"]);
    return RideRequestResult(
      uid: json["uid"],
      rideStatus: status,
      originPlaceID: json["origin_place_id"],
      destinationPlaceID: json["destination_place_id"],
      farePrice: double.parse(json["fare_price"]),
      distanceMeters: json["distance_meters"],
      distanceText: json["distance_text"],
      durationSeconds: json["duration_seconds"],
      durationText: json["duration_text"],
      encodedPoints: json["encoded_points"],
    );
  }
}

RideStatus getRideStatusFromString(String status) {
  if (status == "waiting-confirmation") {
    return RideStatus.waitingForConfirmation;
  }
  if (status == "waiting-rider") {
    return RideStatus.waitingForRider;
  }
  if (status == "in-progress") {
    return RideStatus.inProgress;
  }
  if (status == "finished") {
    return RideStatus.finished;
  }
  if (status == "canceled-by-driver") {
    return RideStatus.canceledByDriver;
  }
  if (status == "canceled-by-client") {
    return RideStatus.canceledByClient;
  }
}
