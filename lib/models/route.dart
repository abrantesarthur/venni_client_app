import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/cloud_functions/rideService.dart';

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
  DateTime _eta;
  String _etaString;

  Address get pickUpAddress => _currentPickUpAddress;
  Address get dropOffAddress => _currentDropOffAddress;
  RideStatus get rideStatus => _rideStatus;
  double get farePrice => _farePrice;
  int get distanceMeters => _distanceMeters;
  String get distanceText => _distanceText;
  int get durationSeconds => _durationSeconds;
  String get durationText => _durationText;
  String get encodedPoints => _encodedPoints;
  DateTime get eta => _eta;
  String get etaString => _etaString;

  void updatePickUpAddres(Address address) {
    _currentPickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    _currentDropOffAddress = address;
    notifyListeners();
  }

  void updateRideStatus(RideStatus rideStatus) {
    _rideStatus = rideStatus;
    notifyListeners();
  }

  // TODO: round fare price up if payment is in money
  void fromRideRequest(RideRequestResult rrr) {
    // TODO: improve estimates of driver arrival time
    // estimate that pilot arrives in 5 seconds
    int secondsForDriverArrival = 300;
    DateTime eta = DateTime.now().add(Duration(
      seconds: rrr.durationSeconds + secondsForDriverArrival,
    ));
    String etaString = eta.hour.toString() + ":" + eta.minute.toString();

    _rideStatus = rrr.rideStatus;
    _farePrice = rrr.farePrice;
    _distanceMeters = rrr.distanceMeters;
    _distanceText = rrr.distanceText;
    _durationSeconds = rrr.durationSeconds;
    _durationText = rrr.durationText;
    _encodedPoints = rrr.encodedPoints;
    _eta = eta;
    _etaString = etaString;
    notifyListeners();
  }
}
