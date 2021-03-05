import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';

class RouteModel extends ChangeNotifier {
  Address pickUpAddress;
  Address dropOffAddress;

  void updatePickUpAddres(Address address) {
    pickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    dropOffAddress = address;
    notifyListeners();
  }
}
