import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/vendors/directions.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/polylinePoints.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:flutter/services.dart' show rootBundle;

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

  void setInitialCameraLatLng(LatLng latlng, {bool notify = true}) {
    _initialCameraLatLng = latlng;
    if (notify) {
      notifyListeners();
    }
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

  Future<void> onMapCreatedCallback(
    GoogleMapController c, {
    bool notify = true,
  }) async {
    await c.setMapStyle(_mapStyle);
    _googleMapController = c;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> undrawPolyline(
    BuildContext context, {
    bool animateCamera = true,
  }) async {
    // remove polylines
    _polylines.clear();
    // remove markers
    _undrawMarkers();

    if (animateCamera) {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngZoom(
        _initialCameraLatLng,
        _initialZoom,
      ));
    }

    // reset maps camera view by showing location button and removing padding
    setGoogleMapsCameraView(notify: false);
    notifyListeners();
  }

  Future<void> drawPolylineFromPartnerToDestination(
      BuildContext context) async {
    // only draw polyline between the partner and origin if inProgress
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    if (trip.tripStatus != TripStatus.inProgress) {
      return;
    }

    // remove old polyline
    _polylines.clear();
    _undrawMarkers();

    // get partner position
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    LatLng partnerCoordinates = LatLng(
      partner.currentLatitude,
      partner.currentLongitude,
    );

    // get trip destination position
    LatLng destinationCoordinates = LatLng(
      trip.dropOffAddress.latitude,
      trip.dropOffAddress.longitude,
    );

    // request google directions API for encoded points between partner and destination
    DirectionsResponse response = await Directions().searchByCoordinates(
      originCoordinates: partnerCoordinates,
      destinationCoordinates: destinationCoordinates,
    );

    if (response != null && response.status == "OK") {
      // get encodedPoints
      String encodedPoints = response.result.route.encodedPoints;

      // set partner coordinates locally to what directions returns
      partner.updateCurrentLatitude(response.result.route.originLatitude);
      partner.updateCurrentLongitude(response.result.route.originLongitude);

      // set trip remaining duration. Don't notify. Drawing polyline already
      // triggers a Home rebuild
      trip.updateDurationSeconds(
        response.result.route.durationSeconds,
        notify: false,
      );

      // draw the polyline
      final screenHeight = MediaQuery.of(context).size.height;
      await drawPolyline(
        context: context,
        encodedPoints: encodedPoints,
        topPadding: screenHeight / 40,
        bottomPadding: screenHeight / 5,
      );
    }
  }

  Future<void> drawPolylineFromPartnerToOrigin(BuildContext context) async {
    // only draw polyline between the use and the partner if waitingPartner
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    if (trip.tripStatus != TripStatus.waitingPartner) {
      return;
    }

    // remove old polyline
    _polylines.clear();
    _undrawMarkers();

    // get partner position
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    LatLng partnerCoordinates = LatLng(
      partner.currentLatitude,
      partner.currentLongitude,
    );

    // get trip origin position
    LatLng originCoordinates = LatLng(
      trip.pickUpAddress.latitude,
      trip.pickUpAddress.longitude,
    );

    // request google directions API for encoded points between user and partner
    DirectionsResponse response = await Directions().searchByCoordinates(
      originCoordinates: originCoordinates,
      destinationCoordinates: partnerCoordinates,
    );

    if (response != null && response.status == "OK") {
      // get encodedPoints
      String encodedPoints = response.result.route.encodedPoints;

      // set partner coordinates locally to what directions returns
      partner.updateCurrentLatitude(response.result.route.destinationLatitude);
      partner
          .updateCurrentLongitude(response.result.route.destinationLongitude);

      // set partner arrival time. Don't notify. Drawing the polyline already
      // triggers a tree rebuild
      trip.updatePartnerArrivalSeconds(
        response.result.route.durationSeconds,
        notify: false,
      );

      // draw the polyline
      final screenHeight = MediaQuery.of(context).size.height;
      await drawPolyline(
        context: context,
        encodedPoints: encodedPoints,
        topPadding: screenHeight / 40,
        bottomPadding: screenHeight / 4,
      );
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

    // hide user's location details and set maps padding. Don't notify, since
    // we already do this at the end of this method.
    setGoogleMapsCameraView(
      topPadding: topPadding,
      bottomPadding: bottomPadding,
      notify: false,
    );

    // add bounds to map view
    // for some reason we have to delay computation so animateCamera works
    Future.delayed(Duration(milliseconds: 100), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        AppPolylinePoints.calculateBounds(polyline),
        50,
      ));
    });

    // draw  markers
    await _drawMarkers(context, polyline: polyline);
    notifyListeners();
  }

  void setGoogleMapsCameraView({
    bool locationEnabled = true,
    bool locationButtonEnabled = true,
    double topPadding,
    double bottomPadding,
    bool notify = true,
  }) {
    // hide user's location details (true by default)
    _myLocationEnabled = locationEnabled;
    _myLocationButtonEnabled = locationButtonEnabled;

    // set paddings (null by default)
    _googleMapsBottomPadding = bottomPadding;
    _googleMapsTopPadding = topPadding;
    if (notify) {
      notifyListeners();
    }
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
      // partner's helmet
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

    // second marker icon depends on whether user is waiting partner or in progress
    BitmapDescriptor secondMarkerIcon;
    if (trip.tripStatus == TripStatus.waitingPartner) {
      // draw partner helmet if waiting partner
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

  // rebuild triggers a map rebuild by notifying listeners. This is used as a
  // workaround on an android issue that hides the map from view if the app
  // stays on background for a long time
  void rebuild() {
    if (_googleMapController != null) {
      _googleMapController.setMapStyle('[]');
      notifyListeners();
      _googleMapController.setMapStyle(_mapStyle);
      notifyListeners();
    }
  }
}
