import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_frontend/models/address.dart';

class RouteModel extends ChangeNotifier {
  Address _currentPickUpAddress;
  Address _currentDropOffAddress;

  Address get pickUpAddress => _currentPickUpAddress;
  Address get dropOffAddress => _currentDropOffAddress;

  void updatePickUpAddres(Address address) {
    _currentPickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    _currentDropOffAddress = address;
    notifyListeners();
  }

  LatLngBounds calculateBounds() {
    double pickUpLat = pickUpAddress.latitude;
    double pickUpLng = pickUpAddress.longitude;
    double dropOffLat = dropOffAddress.latitude;
    double dropOffLng = dropOffAddress.longitude;

    LatLngBounds bounds;

    if (pickUpLat > dropOffLat && pickUpLng > dropOffLng) {
      bounds = LatLngBounds(
        southwest: LatLng(dropOffLat, dropOffLng),
        northeast: LatLng(pickUpLat, pickUpLng),
      );
    } else if (pickUpLat < dropOffLat && pickUpLng < dropOffLng) {
      bounds = LatLngBounds(
        southwest: LatLng(pickUpLat, pickUpLng),
        northeast: LatLng(dropOffLat, dropOffLng),
      );
    } else if (pickUpLat > dropOffLat && pickUpLng < dropOffLng) {
      bounds = LatLngBounds(
        southwest: LatLng(dropOffLat, pickUpLng),
        northeast: LatLng(pickUpLat, dropOffLng),
      );
    } else {
      bounds = LatLngBounds(
        southwest: LatLng(pickUpLat, dropOffLng),
        northeast: LatLng(dropOffLat, pickUpLng),
      );
    }

    return bounds;
  }
}
