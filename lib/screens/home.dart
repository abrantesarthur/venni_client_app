import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Home extends StatefulWidget {
  static const routeName = "home";

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  final CameraPosition _kGooglePlex = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 14.4746,
  );

  Completer<GoogleMapController> _googleMapController = Completer();

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
          initialCameraPosition: _kGooglePlex,
          padding: EdgeInsets.only(top: 70.0, bottom: 70.0),
          onMapCreated: (GoogleMapController controller) {
            _googleMapController.complete(controller);
          },
        ),
        OverallPadding(
          child: Container(
            alignment: Alignment.bottomCenter,
            child: AppButton(
              textData: "Para onde vamos?",
              onTapCallBack: () {},
            ),
          ),
        ),
      ],
    ));
  }
}
