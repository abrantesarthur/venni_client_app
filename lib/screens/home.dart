import 'dart:async';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/polylinePoints.dart';
import 'package:rider_frontend/cloud_functions/rideService.dart';
import 'package:rider_frontend/vendors/svg.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
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
  double googleMapsTopPadding;
  double googleMapsBottomPadding;

  @override
  void initState() {
    super.initState();
    myLocationEnabled = true;
    myLocationButtonEnabled = true;

    // load map style
    rootBundle
        .loadString("assets/map_style.txt")
        .then((value) => {_mapStyle = value});

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // get relevant models
      RouteModel route = Provider.of<RouteModel>(context, listen: false);
      FirebaseModel firebase =
          Provider.of<FirebaseModel>(context, listen: false);

      // add listener to RouteModel so polyline is redrawn automatically
      route.addListener(() async {
        await _rideStatusListener(context, route.rideStatus);
      });

      // add listener to FirebaseModel so user logs out
      firebase.addListener(() {
        if (!firebase.isRegistered) {
          Navigator.pushNamedAndRemoveUntil(
              context, Start.routeName, (_) => false);
        }
      });
    });
  }

  Future<void> _rideStatusListener(
    BuildContext context,
    RideStatus rideStatus,
  ) async {
    if (rideStatus == null) return;

    final screenHeight = MediaQuery.of(context).size.height;
    if (rideStatus == RideStatus.waitingForConfirmation) {
      // draw directions on map
      await drawPolyline(context);

      setState(() {
        // hide user's location details
        myLocationEnabled = false;
        myLocationButtonEnabled = false;

        // reset paddings
        googleMapsBottomPadding = screenHeight * 0.4;
        googleMapsTopPadding = screenHeight * 0.06;
      });
    }
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
    LatLng pickUpMarkerPosition = LatLng(
      polyline.points.first.latitude,
      polyline.points.first.longitude,
    );
    Marker pickUpMarker = Marker(
      markerId: MarkerId("pickUpMarker"),
      position: pickUpMarkerPosition,
      icon: pickUpMarkerIcon,
    );
    LatLng dropOffMarkerPosition = LatLng(
      polyline.points.last.latitude,
      polyline.points.last.longitude,
    );
    Marker dropOffMarker = Marker(
      markerId: MarkerId("dropOffMakrer"),
      position: dropOffMarkerPosition,
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
    Future.delayed(Duration(milliseconds: 50), () async {
      await _googleMapController.animateCamera(CameraUpdate.newLatLngBounds(
        AppPolylinePoints.calculateBounds(polyline),
        30,
      ));
    });

    // draw  markers
    await drawMarkers(context, polyline);
  }

  void defineRoute(BuildContext context) async {
    Navigator.pushNamed(
      context,
      DefineRoute.routeName,
      arguments: DefineRouteArguments(
        mode: DefineRouteMode.request,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // get user position
    // TODO: should this be listen: false?
    UserPositionModel userPos =
        Provider.of<UserPositionModel>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

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
          for (var widget in _buildRemainingStackChildren(
            context: context,
            homeState: this,
          ))
            widget,
        ],
      ),
    );
  }
}

List<Widget> _buildRemainingStackChildren({
  @required BuildContext context,
  @required HomeState homeState,
}) {
  RouteModel route = Provider.of<RouteModel>(context, listen: false);

  if (route.rideStatus == null) {
    return [
      OverallPadding(
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
      )
    ];
  }
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  switch (route.rideStatus) {
    case RideStatus.waitingForConfirmation:
      return [
        Column(
          children: [
            Spacer(),
            _buildRideSummaryFloatingCard(context),
            OverallPadding(
              bottom: screenHeight / 20,
              top: screenHeight / 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppButton(
                    textData: "Editar Rota",
                    borderRadius: 10.0,
                    height: screenHeight / 15,
                    width: screenWidth / 2.5,
                    buttonColor: Colors.grey[900],
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onTapCallBack: () async {
                      await Navigator.pushNamed(
                        context,
                        DefineRoute.routeName,
                        arguments: DefineRouteArguments(
                          mode: DefineRouteMode.edit,
                        ),
                      );
                    },
                  ),
                  AppButton(
                    textData: "Confirmar",
                    borderRadius: 10.0,
                    height: screenHeight / 15,
                    width: screenWidth / 2.5,
                    textStyle: TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    onTapCallBack: () {
                      homeState.setState(() {});
                    },
                  ),
                ],
              ),
            )
          ],
        ),
      ];
    case RideStatus.waitingForRider:
      return [
        Container(
          alignment: Alignment.bottomCenter,
          child: AppButton(
            borderRadius: 10.0,
            textData: "Waiting for rider.",
            onTapCallBack: () {
              homeState.setState(() {});
            },
          ),
        )
      ];
    case RideStatus.inProgress:
      return [
        Container(
          alignment: Alignment.bottomCenter,
          child: AppButton(
            borderRadius: 10.0,
            textData: "in Progress",
            onTapCallBack: () {
              homeState.setState(() {});
            },
          ),
        )
      ];
    default:
      return [Container()];
  }
}

Widget _buildRideSummaryFloatingCard(BuildContext context) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  RouteModel route = Provider.of<RouteModel>(context, listen: false);

  return FloatingCard(
    bottom: 0,
    child: Column(
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
              route.etaString,
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
              "R\$ " + route.farePrice.toString(),
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
    ),
  );
}
