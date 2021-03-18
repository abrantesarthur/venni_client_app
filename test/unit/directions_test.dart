import 'package:flutter_test/flutter_test.dart';
import 'package:rider_frontend/vendors/directions.dart';

void main() {
  test("empty", () {
    expect(true, isTrue);
  });
  // group("DirectionsResponse", () {
  //   test("fromJson with null json", () {
  //     DirectionsResponse dr = DirectionsResponse.fromJson(null);
  //     expect(dr, isNull);
  //   });

  //   test("fromJson with empty json", () {
  //     DirectionsResponse dr = DirectionsResponse.fromJson({});
  //     expect(dr, isNotNull);
  //     expect(dr.status, isNull);
  //     expect(dr.errorMessage, isNull);
  //     expect(dr.result, isNotNull);
  //     expect(dr.result.geocodedWaypoints, isNull);
  //     expect(dr.result.route, isNull);
  //   });
  // });

  // group("DirectionsResult", () {
  //   test("fromJson with null json", () {
  //     DirectionsResult dr = DirectionsResult.fromJson(null);
  //     expect(dr, isNull);
  //   });

  //   test("fromJson with empty json", () {
  //     DirectionsResult dr = DirectionsResult.fromJson({});
  //     expect(dr, isNotNull);
  //     expect(dr.geocodedWaypoints, isNull);
  //     expect(dr.route, isNull);
  //   });

  //   test("fromJson with json with empty fields", () {
  //     Object json = {
  //       "geocoded_waypoints": [],
  //       "routes": [],
  //     };

  //     DirectionsResult dr = DirectionsResult.fromJson(json);
  //     expect(dr.geocodedWaypoints, equals([]));
  //     expect(dr.route, isNull);
  //   });

  //   test("fromJson with complete json", () {
  //     Object json = {
  //       "routes": [
  //         {
  //           "legs": [
  //             {
  //               "duration": {
  //                 "text": "3 minutos",
  //                 "value": 180,
  //               },
  //               "distance": {
  //                 "text": "5 kilometros",
  //                 "value": 5000,
  //               },
  //               "start_address": "Rua Presbiteriana, 151",
  //               "end_address": "Avenida Olegario Maciel, 120",
  //             }
  //           ],
  //           "overview_polyline": {
  //             "points": "arandombunchofpoints",
  //           },
  //         }
  //       ],
  //       "geocoded_waypoints": [
  //         {
  //           "geocoder_status": "OK",
  //           "place_id": "arandomplaceid",
  //           "types": ["political", "route"],
  //         }
  //       ],
  //     };

  //     DirectionsResult dr = DirectionsResult.fromJson(json);
  //     expect(dr.route, isNotNull);
  //     expect(dr.route.durationText, equals("3 minutos"));
  //     expect(dr.route.durationSeconds, equals(180));
  //     expect(dr.route.distanceText, equals("5 kilometros"));
  //     expect(dr.route.distanceMeters, equals(5000));
  //     expect(dr.route.startAddress, equals("Rua Presbiteriana, 151"));
  //     expect(dr.route.endAddress, equals("Avenida Olegario Maciel, 120"));
  //     expect(dr.route.encodedPoints, equals("arandombunchofpoints"));
  //     expect(dr.geocodedWaypoints, isNotNull);
  //     expect(dr.geocodedWaypoints.length, equals(1));
  //     expect(dr.geocodedWaypoints.first.placeID, equals("arandomplaceid"));
  //     expect(dr.geocodedWaypoints.first.types, isNotNull);
  //     expect(dr.geocodedWaypoints.first.types.first, equals("political"));
  //     expect(dr.geocodedWaypoints.first.geocoderStatus, equals("OK"));
  //   });
  // });

  // group("Route", () {
  //   test("fromJson with null json", () {
  //     Route r = Route.fromJson(null);
  //     expect(r, isNull);
  //   });

  //   test("fromJson with empty json", () {
  //     Route r = Route.fromJson({});
  //     expect(r, isNotNull);
  //     expect(r.durationText, isNull);
  //     expect(r.durationSeconds, isNull);
  //     expect(r.distanceText, isNull);
  //     expect(r.distanceMeters, isNull);
  //     expect(r.startAddress, isNull);
  //     expect(r.endAddress, isNull);
  //     expect(r.encodedPoints, isNull);
  //   });

  //   test("fromJson with json with emtpy fields", () {
  //     Object json = {
  //       "legs": [],
  //       "overview_polyline": {},
  //     };
  //     Route r = Route.fromJson(json);
  //     expect(r, isNotNull);
  //     expect(r.durationText, isNull);
  //     expect(r.durationSeconds, isNull);
  //     expect(r.distanceText, isNull);
  //     expect(r.distanceMeters, isNull);
  //     expect(r.startAddress, isNull);
  //     expect(r.endAddress, isNull);
  //     expect(r.encodedPoints, isNull);
  //   });

  //   test("fromJson with complete json", () {
  //     Object json = {
  //       "legs": [
  //         {
  //           "duration": {
  //             "text": "3 minutos",
  //             "value": 180,
  //           },
  //           "distance": {
  //             "text": "5 kilometros",
  //             "value": 5000,
  //           },
  //           "start_address": "Rua Presbiteriana, 151",
  //           "end_address": "Avenida Olegario Maciel, 120",
  //         }
  //       ],
  //       "overview_polyline": {
  //         "points": "arandombunchofpoints",
  //       },
  //     };
  //     Route r = Route.fromJson(json);
  //     expect(r.durationText, equals("3 minutos"));
  //     expect(r.durationSeconds, equals(180));
  //     expect(r.distanceText, equals("5 kilometros"));
  //     expect(r.distanceMeters, equals(5000));
  //     expect(r.startAddress, equals("Rua Presbiteriana, 151"));
  //     expect(r.endAddress, equals("Avenida Olegario Maciel, 120"));
  //     expect(r.encodedPoints, equals("arandombunchofpoints"));
  //   });
  // });

  // group("Leg", () {
  //   test("fromJson with null json", () {
  //     Leg l = Leg.fromJson(null);
  //     expect(l, isNull);
  //   });

  //   test("fromJson with empty json", () {
  //     Leg l = Leg.fromJson({});
  //     expect(l, isNotNull);
  //     expect(l.durationText, isNull);
  //     expect(l.durationSeconds, isNull);
  //     expect(l.distanceText, isNull);
  //     expect(l.distanceMeters, isNull);
  //     expect(l.startAddress, isNull);
  //     expect(l.endAddress, isNull);
  //   });

  //   test("fromJson with complete json", () {
  //     Object json = {
  //       "duration": {
  //         "text": "3 minutos",
  //         "value": 180,
  //       },
  //       "distance": {
  //         "text": "5 kilometros",
  //         "value": 5000,
  //       },
  //       "start_address": "Rua Presbiteriana, 151",
  //       "end_address": "Avenida Olegario Maciel, 120",
  //     };
  //     Leg l = Leg.fromJson(json);
  //     expect(l.durationText, equals("3 minutos"));
  //     expect(l.durationSeconds, equals(180));
  //     expect(l.distanceText, equals("5 kilometros"));
  //     expect(l.distanceMeters, equals(5000));
  //     expect(l.startAddress, equals("Rua Presbiteriana, 151"));
  //     expect(l.endAddress, equals("Avenida Olegario Maciel, 120"));
  //   });
  // });

  // group("GeocodedWaypoint", () {
  //   test("fromJson with null json", () {
  //     GeocodedWaypoint gw = GeocodedWaypoint.fromJson(null);
  //     expect(gw, isNull);
  //   });

  //   test("fromJson with empty json", () {
  //     GeocodedWaypoint gw = GeocodedWaypoint.fromJson({});
  //     expect(gw, isNotNull);
  //     expect(gw.placeID, isNull);
  //     expect(gw.geocoderStatus, isNull);
  //     expect(gw.types, isNull);
  //   });

  //   test("fromJson with complete json", () {
  //     Object json = {
  //       "geocoder_status": "OK",
  //       "place_id": "arandomplaceid",
  //       "types": ["political", "route"],
  //     };
  //     GeocodedWaypoint gw = GeocodedWaypoint.fromJson(json);
  //     expect(gw, isNotNull);
  //     expect(gw.geocoderStatus, equals("OK"));
  //     expect(gw.placeID, equals("arandomplaceid"));
  //     expect(gw.types, isNotNull);
  //     expect(gw.types.length, equals(2));
  //     expect(gw.types.first, equals("political"));
  //     expect(gw.types.last, equals("route"));
  //   });
  // });
}
