// // get address from latitude longitude and vice-versa

// import 'dart:convert';

// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:rider_frontend/config/config.dart';
// import 'package:rider_frontend/vendors/googleService.dart';

// class Directions extends GoogleWebService {
//   Directions() : super(baseUrl: AppConfig.env.values.directionsBaseURL);

//   Future<DirectionsResponse> searchByPlaceIDs({
//     @required String originPlaceID,
//     @required String destinationPlaceID,
//   }) async {
//     String params = "origin=place_id:$originPlaceID&" +
//         "destination=place_id:$destinationPlaceID";
//     return _decode(await doGet(params));
//   }

//   DirectionsResponse _decode(http.Response response) {
//     if (response != null && response.statusCode < 300) {
//       return DirectionsResponse.fromJson(jsonDecode(response.body));
//     }
//     return null;
//   }
// }

// class DirectionsResponse extends GoogleResponse<DirectionsResult> {
//   DirectionsResponse({
//     @required String status,
//     @required String errorMessage,
//     @required DirectionsResult result,
//   }) : super(
//           status: status,
//           errorMessage: errorMessage,
//           result: result,
//         );

//   factory DirectionsResponse.fromJson(Map json) {
//     return json != null
//         ? DirectionsResponse(
//             status: json["status"],
//             errorMessage: json["error_message"],
//             result: DirectionsResult.fromJson(json),
//           )
//         : null;
//   }
// }

// class DirectionsResult {
//   final List<GeocodedWaypoint> geocodedWaypoints;
//   final Route route;

//   DirectionsResult({
//     @required this.geocodedWaypoints,
//     @required this.route,
//   });

//   factory DirectionsResult.fromJson(Map json) {
//     if (json == null) return null;
//     List<GeocodedWaypoint> gWps = (json["geocoded_waypoints"] as List)
//         ?.map((gwp) => GeocodedWaypoint.fromJson(gwp))
//         ?.toList();
//     List routes = (json["routes"] as List);
//     Route route = routes != null
//         ? (routes.isNotEmpty ? Route.fromJson(routes.first) : null)
//         : null;
//     return DirectionsResult(
//       geocodedWaypoints: gWps,
//       route: route,
//     );
//   }
// }

// class Route {
//   final String durationText;
//   final int durationSeconds;
//   final String distanceText;
//   final int distanceMeters;
//   final String startAddress;
//   final String endAddress;
//   final String encodedPoints;

//   Route({
//     @required this.durationText,
//     @required this.durationSeconds,
//     @required this.encodedPoints,
//     @required this.distanceText,
//     @required this.distanceMeters,
//     @required this.startAddress,
//     @required this.endAddress,
//   });

//   factory Route.fromJson(Map<String, dynamic> json) {
//     if (json == null) return null;
//     List legs = json["legs"] as List;
//     Leg leg = legs != null
//         ? (legs.isNotEmpty ? Leg.fromJson(legs.first) : null)
//         : null;
//     return Route(
//       durationText: leg != null ? leg.durationText : null,
//       durationSeconds: leg != null ? leg.durationSeconds : null,
//       distanceText: leg != null ? leg.distanceText : null,
//       distanceMeters: leg != null ? leg.distanceMeters : null,
//       startAddress: leg != null ? leg.startAddress : null,
//       endAddress: leg != null ? leg.endAddress : null,
//       encodedPoints: json["overview_polyline"] != null
//           ? json["overview_polyline"]["points"]
//           : null,
//     );
//   }
// }

// class Leg {
//   final String durationText;
//   final int durationSeconds;
//   final String distanceText;
//   final int distanceMeters;
//   final String startAddress;
//   final String endAddress;

//   Leg({
//     @required this.durationText,
//     @required this.durationSeconds,
//     @required this.distanceText,
//     @required this.distanceMeters,
//     @required this.startAddress,
//     @required this.endAddress,
//   });

//   factory Leg.fromJson(Map<String, dynamic> json) {
//     return json != null
//         ? Leg(
//             durationText:
//                 json["duration"] != null ? json["duration"]["text"] : null,
//             durationSeconds:
//                 json["duration"] != null ? json["duration"]["value"] : null,
//             distanceText:
//                 json["distance"] != null ? json["distance"]["text"] : null,
//             distanceMeters:
//                 json["distance"] != null ? json["distance"]["value"] : null,
//             startAddress: json["start_address"],
//             endAddress: json["end_address"],
//           )
//         : null;
//   }
// }

// class GeocodedWaypoint extends GeocoderStatus {
//   final String placeID;
//   final List<String> types;

//   GeocodedWaypoint({
//     @required String geocoderStatus,
//     @required this.placeID,
//     @required this.types,
//   }) : super(geocoderStatus: geocoderStatus);

//   factory GeocodedWaypoint.fromJson(Map<String, dynamic> json) {
//     return json != null
//         ? GeocodedWaypoint(
//             geocoderStatus: json["geocoder_status"],
//             placeID: json["place_id"],
//             types: (json["types"] as List)?.cast<String>(),
//           )
//         : null;
//   }
// }

// class GeocoderStatus {
//   static const String ok = "OK";
//   static const String zeroResults = "ZERO_RESULTS";

//   bool get isOk => geocoderStatus == ok;
//   bool get hasNoResults => geocoderStatus == zeroResults;

//   final String geocoderStatus;

//   GeocoderStatus({@required this.geocoderStatus});
// }
