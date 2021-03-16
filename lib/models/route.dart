import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/vendors/rideService.dart';

class RouteModel extends ChangeNotifier {
  Address _currentPickUpAddress;
  Address _currentDropOffAddress;
  RideStatus _rideStatus;
  double _farePrice;
  int _distanceMeters;
  String _distanceText;
  int _durationSeconds;
  String _durationText;
  String _encodedPoints;

  Address get pickUpAddress => _currentPickUpAddress;
  Address get dropOffAddress => _currentDropOffAddress;
  RideStatus get rideStatus => _rideStatus;
  double get farePrice => _farePrice;
  int get distanceMeters => _distanceMeters;
  String get distanceText => _distanceText;
  int get durationSeconds => _durationSeconds;
  String get durationText => _durationText;
  String get encodedPoints => _encodedPoints;

  void updatePickUpAddres(Address address) {
    _currentPickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    _currentDropOffAddress = address;
    notifyListeners();
  }

  void fromRideRequest(RideRequestResult rrr) {
    _rideStatus = rrr.rideStatus;
    _farePrice = rrr.farePrice;
    _distanceMeters = rrr.distanceMeters;
    _distanceText = rrr.distanceText;
    _durationSeconds = rrr.durationSeconds;
    _durationText = rrr.durationText;
    _encodedPoints = rrr.encodedPoints;
    print(_rideStatus.toString());
    notifyListeners();
  }
}
