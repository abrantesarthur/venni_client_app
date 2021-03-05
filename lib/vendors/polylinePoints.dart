import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_frontend/styles.dart';

class AppPolylinePoints {
  static Polyline getPolylineFromEncodedPoints({
    @required PolylineId id,
    @required String encodedPoints,
  }) {
    // decode polyline points
    List<PointLatLng> points = PolylinePoints().decodePolyline(encodedPoints);

    // build coordinates
    List<LatLng> coordinates = [];
    points.forEach((PointLatLng p) {
      coordinates.add(LatLng(p.latitude, p.longitude));
    });

    // build polyline
    return Polyline(
      polylineId: id,
      color: AppColor.primaryPink,
      points: coordinates,
    );
  }
}
