import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/driver.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/vendors/directions.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/vendors/polylinePoints.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;

// TODO: write tests
class GoogleMapsModel extends ChangeNotifier {
  Map<PolylineId, Polyline> _polylines;
  Set<Marker> _markers;
  GoogleMapController _googleMapController;
  bool _myLocationEnabled;
  bool _myLocationButtonEnabled;
  double _googleMapsBottomPadding;
  double _googleMapsTopPadding;
  LatLng _initialCameraLatLng;
  double _initialZoom;
  String _mapStyle;

  GoogleMapsModel() {
    _polylines = {};
    _markers = {};
    _myLocationEnabled = true;
    _myLocationButtonEnabled = true;
    _initialZoom = 16.5;
    rootBundle
        .loadString("assets/map_style.txt")
        .then((value) => {_mapStyle = value});
  }

  set initialCameraLatLng(LatLng latlng) {
    _initialCameraLatLng = latlng;
    notifyListeners();
  }

  // getters
  Map<PolylineId, Polyline> get polylines => _polylines;
  Set<Marker> get markers => _markers;
  GoogleMapController get googleMapController => _googleMapController;
  bool get myLocationEnabled => _myLocationEnabled;
  bool get myLocationButtonEnabled => _myLocationButtonEnabled;
  double get googleMapsBottomPadding => _googleMapsBottomPadding;
  double get googleMapsTopPadding => _googleMapsTopPadding;
  LatLng get initialCameraLatLng => _initialCameraLatLng;
  double get initialZoom => _initialZoom;
  String get mapStyle => _mapStyle;

  @override
  void dispose() {
    if (_googleMapController != null) {
      _googleMapController.dispose();
    }
    super.dispose();
  }

  void onMapCreatedCallback(GoogleMapController c) async {
    await c.setMapStyle(_mapStyle);
    _googleMapController = c;
  }

  Future<void> undrawPolyline(
    BuildContext context,
  ) async {
    // remove polylines
    _polylines.clear();
    // remove markers
    _undrawMarkers();

    await _googleMapController.animateCamera(CameraUpdate.newLatLngZoom(
      _initialCameraLatLng,
      _initialZoom,
    ));

    // reset maps camera view by showing location button and removing padding
    setGoogleMapsCameraView();
  }

  Future<void> drawPolylineFromDriverToDestination(BuildContext context) async {
    // only draw polyline between the driver and origin if inProgress
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    if (trip.tripStatus != TripStatus.inProgress) {
      return;
    }

    // remove old polyline
    _polylines.clear();
    _undrawMarkers();

    // get driver position
    DriverModel driver = Provider.of<DriverModel>(context, listen: false);
    LatLng driverCoordinates = LatLng(
      driver.currentLatitude,
      driver.currentLongitude,
    );

    // get trip destination position
    LatLng destinationCoordinates = LatLng(
      trip.dropOffAddress.latitude,
      trip.dropOffAddress.longitude,
    );

    // request google directions API for encoded points between driver and destination
    // TODO: move directions api requests to server. Request it when driver reports
    // their position and, besides their coordinates, set the encoded points too.
    // Also, user placeIDs instead of coordinates whenever possible. This makes
    // markers more precise
    DirectionsResponse response = await Directions().searchByCoordinates(
      originCoordinates: driverCoordinates,
      destinationCoordinates: destinationCoordinates,
    );

    if (response != null && response.status == "OK") {
      // get encodedPoints
      String encodedPoints = response.result.route.encodedPoints;

      // set driver coordinates locally to what directions returns
      driver.updateCurrentLatitude(response.result.route.originLatitude);
      driver.updateCurrentLongitude(response.result.route.originLongitude);

      // draw the polyline
      final screenHeight = MediaQuery.of(context).size.height;
      drawPolyline(
        context: context,
        encodedPoints: encodedPoints,
        topPadding: screenHeight / 40,
        bottomPadding: screenHeight / 5,
      );

      // set trip remaining duration
      trip.updateDurationSeconds(response.result.route.durationSeconds);
    }
  }

  Future<void> drawPolylineFromDriverToOrigin(BuildContext context) async {
    // only draw polyline between the use and the driver if waitingDriver
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    if (trip.tripStatus != TripStatus.waitingDriver) {
      return;
    }

    // remove old polyline
    _polylines.clear();
    _undrawMarkers();

    // get driver position
    DriverModel driver = Provider.of<DriverModel>(context, listen: false);
    LatLng driverCoordinates = LatLng(
      driver.currentLatitude,
      driver.currentLongitude,
    );

    // get trip origin position
    LatLng originCoordinates = LatLng(
      trip.pickUpAddress.latitude,
      trip.pickUpAddress.longitude,
    );

    // request google directions API for encoded points between user and driver
    // TODO: move directions api requests to server. Request it when driver reports
    // their position and, besides their coordinates, set the encoded points too.
    DirectionsResponse response = await Directions().searchByCoordinates(
      originCoordinates: originCoordinates,
      destinationCoordinates: driverCoordinates,
    );

    if (response != null && response.status == "OK") {
      // get encodedPoints
      String encodedPoints = response.result.route.encodedPoints;

      // set driver coordinates locally to what directions returns
      driver.updateCurrentLatitude(response.result.route.destinationLatitude);
      driver.updateCurrentLongitude(response.result.route.destinationLongitude);

      // draw the polyline
      final screenHeight = MediaQuery.of(context).size.height;
      drawPolyline(
        context: context,
        encodedPoints: encodedPoints,
        topPadding: screenHeight / 40,
        bottomPadding: screenHeight / 4,
      );

      // set driver arrival time
      trip.updateDriverArrivalSeconds(response.result.route.durationSeconds);
    }
  }

  Future<void> drawPolyline({
    @required BuildContext context,
    @required String encodedPoints,
    double topPadding,
    double bottomPadding,
  }) async {
    // drive polyline between user's pick up and drop off points
    // set polylines
    PolylineId polylineId = PolylineId("poly");
    Polyline polyline = AppPolylinePoints.getPolylineFromEncodedPoints(
      id: polylineId,
      encodedPoints: encodedPoints,
    );
    if (polyline.points.first.latitude == polyline.points.last.latitude &&
        polyline.points.first.longitude == polyline.points.last.longitude) {
      // clear polyline if end and start points are the same
      _polylines.clear();
    } else {
      _polylines[polylineId] = polyline;
    }

    // add bounds to map view
    // for some reason we have to delay computation so animateCamera works
    Future.delayed(Duration(milliseconds: 50), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        AppPolylinePoints.calculateBounds(polyline),
        50,
      ));
    });

    // draw  markers
    await _drawMarkers(context, polyline: polyline);

    // hide user's location details and set maps padding
    setGoogleMapsCameraView(
      locationButtonEnabled: false,
      topPadding: topPadding,
      bottomPadding: bottomPadding,
    );
  }

  void setGoogleMapsCameraView({
    bool locationEnabled = true,
    bool locationButtonEnabled = true,
    double topPadding,
    double bottomPadding,
  }) {
    // hide user's location details (true by default)
    _myLocationEnabled = locationEnabled;
    _myLocationButtonEnabled = locationButtonEnabled;

    // set paddings (null by default)
    _googleMapsBottomPadding = bottomPadding;
    _googleMapsTopPadding = topPadding;

    notifyListeners();
  }

  void _undrawMarkers() {
    _markers.clear();
  }

  Future<void> _drawMarkers(
    BuildContext context, {
    Polyline polyline,
  }) async {
    _markers.clear();
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // first marker icon depends on whether trip is in progress
    BitmapDescriptor firstMarkerIcon;
    if (trip.tripStatus == TripStatus.inProgress) {
      // pilot's helmet
      firstMarkerIcon =
          await AppBitmapDescriptor.fromIconData(Icons.sports_motorsports);
    } else {
      // pink square
      firstMarkerIcon = await AppBitmapDescriptor.fromSvg(
        context,
        "images/pickUpIcon.svg",
      );
    }

    LatLng firstMarkerPosition = LatLng(
      polyline.points.first.latitude,
      polyline.points.first.longitude,
    );
    Marker firstMarker = Marker(
      markerId: MarkerId("firstMarker"),
      position: firstMarkerPosition,
      icon: firstMarkerIcon,
    );

    // second marker icon depends on whether user is waiting driver or in progress
    BitmapDescriptor secondMarkerIcon;
    if (trip.tripStatus == TripStatus.waitingDriver) {
      // draw pilot helmet if waiting driver
      secondMarkerIcon =
          await AppBitmapDescriptor.fromIconData(Icons.sports_motorsports);
    } else {
      // draw round circle if in progres or in another state
      secondMarkerIcon = await AppBitmapDescriptor.fromSvg(
        context,
        "images/dropOffIcon.svg",
      );
    }

    LatLng secondMarkerPosition = LatLng(
      polyline.points.last.latitude,
      polyline.points.last.longitude,
    );
    Marker secondMarker = Marker(
      markerId: MarkerId("dropOffMakrer"),
      position: secondMarkerPosition,
      icon: secondMarkerIcon,
    );

    // add markers
    _markers.add(firstMarker);
    _markers.add(secondMarker);
  }
}
