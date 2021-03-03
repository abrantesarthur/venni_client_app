import 'package:flutter/material.dart';

class RouteModel extends ChangeNotifier {
  String pickUpPlaceID;
  String dropOffPlaceID;

  void updatePickUpLocation(String placeID) {
    pickUpPlaceID = placeID;
    notifyListeners();
  }

  void updateDropOffLocation(String placeID) {
    dropOffPlaceID = placeID;
    notifyListeners();
  }
}
