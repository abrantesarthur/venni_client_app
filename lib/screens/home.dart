import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/vendors/geolocator.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Home extends StatefulWidget {
  static const routeName = "home";

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  GoogleMapController _googleMapController;

  void onMapCreatedCallback(BuildContext context, GoogleMapController c) async {
    // get user coordinates
    Position userPos = await determineUserPosition(context);

    // move camera to user position
    await c.animateCamera(CameraUpdate.newLatLngZoom(
        LatLng(userPos.latitude, userPos.longitude), 18));

    _googleMapController = c;
  }

  @override
  void dispose() {
    _googleMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseModel = Provider.of<FirebaseModel>(context);

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
          rotateGesturesEnabled: false,
          zoomControlsEnabled: false,
          mapType: MapType.normal,
          initialCameraPosition: CameraPosition(
            target: LatLng(-17.22, -46.87),
            zoom: 14.4746,
          ),
          padding: EdgeInsets.only(top: 70.0, bottom: 70.0),
          onMapCreated: (GoogleMapController c) {
            onMapCreatedCallback(context, c);
          },
        ),
        OverallPadding(
          child: Container(
            alignment: Alignment.bottomCenter,
            child: AppButton(
              iconLeft: Icons.near_me,
              textData: "Para onde vamos?",
              onTapCallBack: () {
                firebaseModel.auth.signOut();
              },
            ),
          ),
        ),
      ],
    ));
  }
}
