import 'package:flutter/material.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
      color: Colors.black,
      points: coordinates,
      width: 5,
      geodesic: true,
    );
  }

  static LatLngBounds calculateBounds(Polyline polyline) {
    double highestLat = -90;
    double highestLng = -180;
    double lowestLat = 90;
    double lowestLng = 180;

    polyline.points.forEach((point) {
      if (point.latitude > highestLat) highestLat = point.latitude;
      if (point.longitude > highestLng) highestLng = point.longitude;
      if (point.latitude < lowestLat) lowestLat = point.latitude;
      if (point.longitude < lowestLng) lowestLng = point.longitude;
    });

    return LatLngBounds(
      southwest: LatLng(lowestLat, lowestLng),
      northeast: LatLng(highestLat, highestLng),
    );
  }
}
