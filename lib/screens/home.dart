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
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/directions.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/polylinePoints.dart';
import 'package:rider_frontend/vendors/rideService.dart';
import 'package:rider_frontend/vendors/svg.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:rider_frontend/widgets/padlessDivider.dart';

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
  double googleMapsTopPadding;
  double googleMapsBottomPadding;

  RideStatus rideStatus;

  @override
  void initState() {
    super.initState();
    myLocationEnabled = true;
    myLocationButtonEnabled = true;

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
  ) async {
    // get route model
    RouteModel route = Provider.of<RouteModel>(context, listen: false);

    // set polylines
    PolylineId polylineId = PolylineId("poly");
    Polyline polyline = AppPolylinePoints.getPolylineFromEncodedPoints(
      id: polylineId,
      encodedPoints: route.encodedPoints,
    );
    polylines[polylineId] = polyline;

    // add bounds to map view
    // for some reason we have to delay computation so animateCamera works
    Future.delayed(Duration(milliseconds: 10), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        AppPolylinePoints.calculateBounds(polyline),
        30,
      ));
    });

    // draw  markers
    await drawMarkers(context, polyline);
  }

  void defineRoute(BuildContext context) async {
    RouteModel routeModel = Provider.of<RouteModel>(context, listen: false);
    UserPositionModel userPos =
        Provider.of<UserPositionModel>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;

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
      setState(() {
        // hide user's location details
        myLocationEnabled = false;
        myLocationButtonEnabled = false;

        // reset paddings
        googleMapsBottomPadding = screenHeight * 0.4;
        googleMapsTopPadding = screenHeight * 0.06;

        // change ride status to hide "Para onde vamos" and show "Confirmar" button
        rideStatus = RideStatus.waitingForConfirmation;
      });

      // draw directions on map
      await drawPolyline(context);
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
              top: googleMapsTopPadding ?? screenHeight / 12,
              bottom: googleMapsBottomPadding ?? screenHeight / 7,
              left: screenWidth / 20,
              right: screenWidth / 20,
            ),
            onMapCreated: (GoogleMapController c) {
              onMapCreatedCallback(context, c);
            },
            polylines: Set<Polyline>.of(polylines.values),
            markers: markers,
          ),
          _buildRideCard(
            context: context,
            homeState: this,
            rideStatus: rideStatus,
          ),
        ],
      ),
    );
  }
}

Widget _buildRideCard({
  @required BuildContext context,
  @required HomeState homeState,
  @required var rideStatus,
}) {
  if (rideStatus == null) {
    return OverallPadding(
      child: Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          iconLeft: Icons.near_me,
          textData: "Para onde vamos?",
          onTapCallBack: () {
            homeState.defineRoute(context);
          },
        ),
      ),
    );
  }
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  switch (rideStatus) {
    case RideStatus.waitingForConfirmation:
      return Column(
        children: [
          Spacer(),
          FloatingCard(
            bottom: 0,
            child: _buildWaitingForConfirmationWidget(context),
          ),
          OverallPadding(
            bottom: screenHeight / 20,
            top: screenHeight / 40,
            child: AppButton(
              textData: "Confirmar Trajeto",
              onTapCallBack: () {
                homeState.setState(() {});
              },
            ),
          )
        ],
      );
    case RideStatus.waitingForRider:
      return Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          textData: "Waiting for rider.",
          onTapCallBack: () {
            homeState.setState(() {});
          },
        ),
      );
    case RideStatus.inProgress:
      return Container(
        alignment: Alignment.bottomCenter,
        child: AppButton(
          borderRadius: 10.0,
          textData: "in Progress",
          onTapCallBack: () {
            homeState.setState(() {});
          },
        ),
      );
    default:
      return Container();
  }
}

Widget _buildWaitingForConfirmationWidget(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  return Column(
    children: [
      SizedBox(height: screenHeight / 200),
      Row(
        children: [
          Text(
            "Chegada ao destino",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            "14:27", // TODO: make dynamic
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      SizedBox(height: screenHeight / 200),
      Row(
        children: [
          Text(
            "Preço",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Spacer(),
          Text(
            "R\$ 5,60", // TODO: make dynamic
            style: TextStyle(fontSize: 18),
          ),
        ],
      ),
      SizedBox(height: screenHeight / 200),
      Divider(thickness: 0.1, color: Colors.black),
      SizedBox(height: screenHeight / 200),
      Text(
        "Escolha a forma de pagamento",
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
      SizedBox(height: screenHeight / 75),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GestureDetector(
            child: Material(
              type: MaterialType.card,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                  side: BorderSide(
                      color: AppColor.secondaryGreen) // TODO: make dynamic
                  ),
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    Icon(
                      Icons.money,
                      size: 40,
                      color: AppColor.secondaryGreen, // TODO: make dynamic
                    ),
                    SizedBox(width: screenWidth / 50),
                    Text(
                      "Dinheiro",
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColor.secondaryGreen, // TODO: make dynamic
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            child: Material(
              type: MaterialType.card,
              elevation: 4.0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(5),
              ),
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Row(
                  children: [
                    Icon(
                      Icons.credit_card,
                      size: 40,
                      color: Colors.black, // TODO: make dynamic
                    ),
                    SizedBox(width: screenWidth / 50),
                    Text(
                      "Cartão",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black, // TODO: make dynamic
                      ),
                    ),
                    Icon(Icons.arrow_right),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      SizedBox(height: screenHeight / 200),
    ],
  );
}
