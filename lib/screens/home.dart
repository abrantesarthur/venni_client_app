import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/vendors/directions.dart';
import 'package:rider_frontend/vendors/polylinePoints.dart';
import 'package:rider_frontend/vendors/svg.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:flutter/services.dart' show rootBundle;

class Home extends StatefulWidget {
  static const routeName = "home";

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  GoogleMapController _googleMapController;
  String _mapStyle;
  Map<PolylineId, Polyline> polylines = {};
  Set<Marker> markers = {};
  bool myLocationEnabled;
  bool myLocationButtonEnabled;
  var rideStatus;

  @override
  void initState() {
    super.initState();
    myLocationEnabled = true;
    myLocationButtonEnabled = true;
    rideStatus = RideStatus.off;

    // load map style
    rootBundle
        .loadString("assets/map_style.txt")
        .then((value) => {_mapStyle = value});
  }

  @override
  void dispose() {
    if (_googleMapController != null) {
      _googleMapController.dispose();
    }
    super.dispose();
  }

  void onMapCreatedCallback(BuildContext context, GoogleMapController c) async {
    // set map style
    await c.setMapStyle(_mapStyle);

    setState(() {
      _googleMapController = c;
    });
  }

  Future<void> drawMarkers(
    BuildContext context,
    Polyline polyline,
  ) async {
    BitmapDescriptor pickUpMarkerIcon = await Svg.bitmapDescriptorFromSvg(
      context,
      "images/pickUpIcon.svg",
    );
    BitmapDescriptor dropOffMarkerIcon = await Svg.bitmapDescriptorFromSvg(
      context,
      "images/dropOffIcon.svg",
    );
    Marker pickUpMarker = Marker(
      markerId: MarkerId("pickUpMarker"),
      position: LatLng(
        polyline.points.first.latitude,
        polyline.points.first.longitude,
      ),
      icon: pickUpMarkerIcon,
    );
    Marker dropOffMarker = Marker(
      markerId: MarkerId("dropOffMakrer"),
      position: LatLng(
        polyline.points.last.latitude,
        polyline.points.last.longitude,
      ),
      icon: dropOffMarkerIcon,
    );
    markers.add(pickUpMarker);
    markers.add(dropOffMarker);
  }

  Future<void> drawPolyline(
    BuildContext context,
    RouteModel routeModel,
  ) async {
    print("drawPolyline called");
    // get directions
    DirectionsResponse dr = await Directions().searchByPlaceIDs(
        originPlaceID: routeModel.pickUpAddress.placeID,
        destinationPlaceID: routeModel.dropOffAddress.placeID);
    if (dr.isOkay) {
      // set polylines
      PolylineId polylineId = PolylineId("poly");
      Polyline polyline = AppPolylinePoints.getPolylineFromEncodedPoints(
        id: polylineId,
        encodedPoints: dr.result.route.encodedPoints,
      );
      polylines[polylineId] = polyline;

      // add bounds to map view
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        AppPolylinePoints.calculateBounds(polyline),
        30,
      ));

      // draw  markers
      await drawMarkers(context, polyline);
      setState(() {});
    } else {
      // TODO: display warning
    }
  }

  void defineRoute(BuildContext context) async {
    RouteModel routeModel = Provider.of<RouteModel>(context, listen: false);
    UserPositionModel userPos =
        Provider.of<UserPositionModel>(context, listen: false);

    // pickUp location defaults to user's current address
    if (routeModel.pickUpAddress == null) {
      routeModel.updatePickUpAddres(Address.fromGeocodingResult(
        geocodingResult: userPos.geocoding,
        dropOff: false,
      ));
    }

    final _requestRide = await Navigator.pushNamed(
      context,
      DefineRoute.routeName,
      arguments: DefineRouteArguments(
        routeModel: routeModel,
        userGeocoding: userPos.geocoding,
      ),
    );

    // if user tapped to request ride
    if (_requestRide) {
      // TODO: reactivate whenever user cancels ride
      // hide user's location details
      myLocationEnabled = false;
      myLocationButtonEnabled = false;

      // change ride status to hide "Para onde vamos" and show "Confirmar" button
      rideStatus = RideStatus.waitingForConfirmation;

      // draw directions on map
      await drawPolyline(context, routeModel);

      // hide "Para onde Vamos" button
      // show "Confirmar" button
    }
  }

  @override
  Widget build(BuildContext context) {
    // get user position
    // TODO: should this be listen: false?
    UserPositionModel userPos =
        Provider.of<UserPositionModel>(context, listen: false);
    final firebaseModel = Provider.of<FirebaseModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    if (!firebaseModel.isRegistered) {
      //  if user logs out, send user back to start screen
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.pushNamedAndRemoveUntil(
            context, Start.routeName, (_) => false);
      });
      return Container();
    }

    return Scaffold(
        body: Stack(
      children: [
        GoogleMap(
          myLocationButtonEnabled: myLocationButtonEnabled,
          myLocationEnabled: myLocationEnabled,
          trafficEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(
              userPos.geocoding.latitude,
              userPos.geocoding.longitude,
            ),
            zoom: 16.5,
          ),
          padding: EdgeInsets.only(
            top: screenHeight / 6,
            bottom: screenHeight / 6,
            left: screenWidth / 20,
            right: screenWidth / 20,
          ),
          onMapCreated: (GoogleMapController c) {
            onMapCreatedCallback(context, c);
          },
          polylines: Set<Polyline>.of(polylines.values),
          markers: markers,
        ),
        OverallPadding(
          child: rideStatus == RideStatus.off
              ? Container(
                  alignment: Alignment.bottomCenter,
                  child: AppButton(
                    borderRadius: 10.0,
                    iconLeft: Icons.near_me,
                    textData: "Para onde vamos?",
                    onTapCallBack: () {
                      defineRoute(context);
                    },
                  ),
                )
              : (rideStatus == RideStatus.waitingForConfirmation)
                  ? Container(
                      alignment: Alignment.bottomCenter,
                      child: AppButton(
                        borderRadius: 10.0,
                        iconLeft: Icons.near_me,
                        textData: "Esperando por motorista",
                        onTapCallBack: () {
                          defineRoute(context);
                        },
                      ),
                    )
                  : Container(),
        ),
      ],
    ));
  }
}

Widget _buildRideCard({
  @required BuildContext context,
  @required HomeState homeState,
  @required var rideStatus,
}) {
  switch (rideStatus) {
    case RideStatus.off:
      return Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          iconLeft: Icons.near_me,
          textData: "Para onde vamos?",
          onTapCallBack: () {
            homeState.defineRoute(context);
          },
        ),
      );
    case RideStatus.waitingForConfirmation:
      return Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          iconLeft: Icons.near_me,
          textData: "Waiting for confirmation.",
          onTapCallBack: () {
            homeState.defineRoute(context);
          },
        ),
      );
    case RideStatus.waitingForRider:
      return Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          iconLeft: Icons.near_me,
          textData: "Waiting for rider.",
          onTapCallBack: () {
            homeState.defineRoute(context);
          },
        ),
      );
    case RideStatus.riding:
      return Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          iconLeft: Icons.near_me,
          textData: "riding.",
          onTapCallBack: () {
            homeState.defineRoute(context);
          },
        ),
      );
    default:
      return Container();
  }
}

enum RideStatus {
  off,
  waitingForConfirmation,
  waitingForRider,
  riding,
}
