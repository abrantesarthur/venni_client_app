import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';

class RouteModel extends ChangeNotifier {
  Address pickUpAddress;
  Address dropOffAddress;

  void updatePickUpAddres(Address address) {
    print("pick up address updated");
    print(address.mainText);
    pickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    print("drop off address updated");
    print(address.mainText);
    dropOffAddress = address;
    notifyListeners();
  }
}
