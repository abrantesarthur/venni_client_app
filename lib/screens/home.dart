import 'dart:async';
import 'dart:convert';

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

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    // get user position
    UserPositionModel userPos =
        Provider.of<UserPositionModel>(context, listen: false);
    final firebaseModel = Provider.of<FirebaseModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    RouteModel routeModel = Provider.of<RouteModel>(context, listen: false);

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
          myLocationButtonEnabled: true,
          myLocationEnabled: true,
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
        ),
        OverallPadding(
          child: Container(
            alignment: Alignment.bottomCenter,
            child: AppButton(
              borderRadius: 10.0,
              iconLeft: Icons.near_me,
              textData: "Para onde vamos?",
              onTapCallBack: () async {
                // pickUp location defaults to user's current address
                if (routeModel.pickUpAddress == null) {
                  routeModel.updatePickUpAddres(Address.fromGeocodingResult(
                    geocodingResult: userPos.geocoding,
                    dropOff: false,
                  ));
                }

                final requestRide =
                    await Navigator.pushNamed(context, DefineRoute.routeName,
                        arguments: DefineRouteArguments(
                          routeModel: routeModel,
                          userGeocoding: userPos.geocoding,
                        ));

                if (routeModel.pickUpAddress != null &&
                    routeModel.dropOffAddress != null) {
                  DirectionsResponse dr = await Directions().searchByPlaceIDs(
                      originPlaceID: routeModel.pickUpAddress.placeID,
                      destinationPlaceID: routeModel.dropOffAddress.placeID);
                }
              },
            ),
          ),
        ),
      ],
    ));
  }
}
