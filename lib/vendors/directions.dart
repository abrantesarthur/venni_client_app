// get address from latitude longitude and vice-versa

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/vendors/googleService.dart';

// TODO: test the shit out of this

class Directions extends GoogleWebService {
  Directions()
      : super(baseUrl: "https://maps.googleapis.com/maps/api/directions");

  Future<DirectionsResponse> searchByPlaceIDs({
    @required String originPlaceID,
    @required String destinationPlaceID,
  }) async {
    String params = "origin=place_id:$originPlaceID&" +
        "destination=place_id:$destinationPlaceID";
    return _decode(await doGet(params));
  }

  DirectionsResponse _decode(http.Response response) {
    if (response != null && response.statusCode == 200) {
      return DirectionsResponse.fromJson(jsonDecode(response.body));
    }
    return null;
  }
}

class DirectionsResponse extends GoogleResponse<DirectionsResult> {
  DirectionsResponse({
    @required String status,
    @required String errorMessage,
    @required DirectionsResult result,
  }) : super(
          status: status,
          errorMessage: errorMessage,
          result: result,
        );

  factory DirectionsResponse.fromJson(Map json) {
    return json != null
        ? DirectionsResponse(
            status: json["status"],
            errorMessage: json["error_message"],
            result: DirectionsResult.fromJson(json),
          )
        : null;
  }
}

class DirectionsResult {
  final List<GeocodedWaypoint> geocodedWaypoints;
  final Route route;

  DirectionsResult({
    @required this.geocodedWaypoints,
    @required this.route,
  });

  factory DirectionsResult.fromJson(Map json) {
    List<GeocodedWaypoint> gWps = (json["geocoded_waypoints"] as List)
        ?.map((gwp) => GeocodedWaypoint.fromJson(gwp))
        ?.toList();
    return json != null
        ? DirectionsResult(
            geocodedWaypoints: gWps,
            route: Route.fromJson((json["routes"] as List)?.first),
          )
        : null;
  }
}

class Route {
  final String durationText;
  final double durationSeconds;
  final String distanceText;
  final double distanceMeters;
  final String startAddress;
  final String endAddress;
  final String overviewPolyline;

  Route({
    @required this.durationText,
    @required this.durationSeconds,
    @required this.overviewPolyline,
    @required this.distanceText,
    @required this.distanceMeters,
    @required this.startAddress,
    @required this.endAddress,
  });

  factory Route.fromJson(Map<String, dynamic> json) {
    Leg leg = Leg.fromJson((json["legs"] as List)?.first);
    return json != null
        ? Route(
            durationText: leg.durationText,
            durationSeconds: leg.durationValue,
            distanceText: leg.distanceText,
            distanceMeters: leg.distanceValue,
            startAddress: leg.startAddress,
            endAddress: leg.endAddress,
            overviewPolyline: json["overview_polyline"]["points"],
          )
        : null;
  }
}

class Leg {
  final String durationText;
  final double durationValue;
  final String distanceText;
  final double distanceValue;
  final String startAddress;
  final String endAddress;

  Leg({
    @required this.durationText,
    @required this.durationValue,
    @required this.distanceText,
    @required this.distanceValue,
    @required this.startAddress,
    @required this.endAddress,
  });

  factory Leg.fromJson(Map<String, dynamic> json) => json != null
      ? Leg(
          durationText: json["duration"]["text"],
          durationValue: json["duration"]["value"],
          distanceText: json["distance"]["text"],
          distanceValue: json["distance"]["value"],
          startAddress: json["start_address"],
          endAddress: json["end_address"],
        )
      : null;
}

class GeocodedWaypoint extends GeocoderStatus {
  final String placeID;
  final List<String> types;

  GeocodedWaypoint({
    @required String geocoderStatus,
    @required this.placeID,
    @required this.types,
  }) : super(geocoderStatus: geocoderStatus);

  factory GeocodedWaypoint.fromJson(Map<String, dynamic> json) {
    return json != null
        ? GeocodedWaypoint(
            geocoderStatus: json["geocoder_status"],
            placeID: json["place_id"],
            types: (json["types"] as List)?.cast<String>(),
          )
        : null;
  }
}

class GeocoderStatus {
  static const String ok = "OK";
  static const String zeroResults = "ZERO_RESULTS";

  bool get isOk => geocoderStatus == ok;
  bool get hasNoResults => geocoderStatus == zeroResults;

  final String geocoderStatus;

  GeocoderStatus({@required this.geocoderStatus});
}
