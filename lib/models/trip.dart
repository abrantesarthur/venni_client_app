import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';

class TripModel extends ChangeNotifier {
  Address _currentPickUpAddress;
  Address _currentDropOffAddress;
  TripStatus _tripStatus;
  double _farePrice;
  int _distanceMeters;
  String _distanceText;
  int _durationSeconds;
  String _durationText;
  String _encodedPoints;
  DateTime _eta;
  String _etaString;
  int _driverArrivalSeconds;
  DateTime _driverArrival;
  String _driverArrivalString;

  TripModel() {
    _tripStatus = TripStatus.off;
  }

  // TODO: try moving driver data to driver model
  Address get pickUpAddress => _currentPickUpAddress;
  Address get dropOffAddress => _currentDropOffAddress;
  TripStatus get tripStatus => _tripStatus;
  double get farePrice => _farePrice;
  int get distanceMeters => _distanceMeters;
  String get distanceText => _distanceText;
  int get durationSeconds => _durationSeconds;
  String get durationText => _durationText;
  String get encodedPoints => _encodedPoints;
  DateTime get eta => _eta;
  String get etaString => _etaString;
  String get driverArrivalString => _driverArrivalString;
  int get driverArrivalSeconds => _driverArrivalSeconds;

  void updatePickUpAddres(Address address) {
    _currentPickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    _currentDropOffAddress = address;
    notifyListeners();
  }

  void updateStatus(TripStatus tripStatus) {
    _tripStatus = tripStatus;
    notifyListeners();
  }

  void updateDriverArrivalSeconds(int s) {
    _driverArrivalSeconds = s;
    _driverArrival = _calculateDriverArrival();
    _driverArrivalString = _calculateDriverArrivalString();
    _eta = _calculateETA();
    _etaString = _calculateETAString();
    notifyListeners();
  }

  void updateDurationSeconds(int s) {
    _durationSeconds = s;
    _eta = _calculateETA();
    _etaString = _calculateETAString();
    notifyListeners();
  }

  void clear({
    TripStatus status = TripStatus.off,
    bool notify = true,
  }) {
    _tripStatus = status;
    _currentPickUpAddress = null;
    _currentDropOffAddress = null;
    _farePrice = null;
    _distanceMeters = null;
    _distanceText = null;
    _durationSeconds = null;
    _durationText = null;
    _encodedPoints = null;
    _eta = null;
    _etaString = null;
    if (notify) {
      notifyListeners();
    }
  }

  DateTime _calculateETA() {
    if (_driverArrivalSeconds == null || _durationSeconds == null) {
      return null;
    }
    return DateTime.now().add(Duration(
      seconds: _durationSeconds + _driverArrivalSeconds,
    ));
  }

  String _calculateETAString() {
    if (_eta == null) {
      return "";
    }
    return (_eta.hour < 10
            ? "0" + _eta.hour.toString()
            : _eta.hour.toString()) +
        ":" +
        (_eta.minute < 10
            ? "0" + _eta.minute.toString()
            : _eta.minute.toString());
  }

  DateTime _calculateDriverArrival() {
    if (_driverArrivalSeconds == null) {
      return null;
    }
    return DateTime.now().add(Duration(
      seconds: _driverArrivalSeconds,
    ));
  }

  String _calculateDriverArrivalString() {
    if (_driverArrival == null) {
      return "";
    }
    return _driverArrival.hour.toString() +
        ":" +
        _driverArrival.minute.toString();
  }

  // TODO: round fare price up if payment is in money
  void fromRequestTripResult(RequestTripResult rrr) {
    if (rrr == null) {
      _tripStatus = TripStatus.off;
      _farePrice = null;
      _distanceMeters = null;
      _distanceText = null;
      _durationSeconds = null;
      _durationText = null;
      _encodedPoints = null;
      _eta = null;
      _etaString = null;
      notifyListeners();
    } else {
      _tripStatus = rrr.tripStatus;
      _farePrice = rrr.farePrice;
      _distanceMeters = rrr.distanceMeters;
      _distanceText = rrr.distanceText;
      _durationSeconds = rrr.durationSeconds;
      _durationText = rrr.durationText;
      _encodedPoints = rrr.encodedPoints;
      _driverArrivalSeconds = 300; // estimate driver will arrive in 5 minutes
      _eta = _calculateETA();
      _etaString = _calculateETAString();
      _driverArrival = _calculateDriverArrival();
      _driverArrivalString = _calculateDriverArrivalString();
      notifyListeners();
    }
  }
}
