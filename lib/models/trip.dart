import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';

class TripModel extends ChangeNotifier {
  Address _currentPickUpAddress;
  Address _currentDropOffAddress;
  TripStatus _tripStatus;
  num _farePrice;
  num _distanceMeters;
  String _distanceText;
  num _durationSeconds;
  String _durationText;
  String _encodedPoints;
  DateTime _eta;
  String _etaString;
  num _pilotArrivalSeconds;
  DateTime _pilotArrival;
  String _pilotArrivalString;

  TripModel() {
    _tripStatus = TripStatus.off;
  }

  // TODO: try moving pilot data to pilot model
  Address get pickUpAddress => _currentPickUpAddress;
  Address get dropOffAddress => _currentDropOffAddress;
  TripStatus get tripStatus => _tripStatus;
  num get farePrice => _farePrice;
  num get distanceMeters => _distanceMeters;
  String get distanceText => _distanceText;
  num get durationSeconds => _durationSeconds;
  String get durationText => _durationText;
  String get encodedPoints => _encodedPoints;
  DateTime get eta => _eta;
  String get etaString => _etaString;
  String get pilotArrivalString => _pilotArrivalString;
  num get pilotArrivalSeconds => _pilotArrivalSeconds;

  void updatePickUpAddres(Address address) {
    _currentPickUpAddress = address;
    notifyListeners();
  }

  void updateDropOffAddres(Address address) {
    _currentDropOffAddress = address;

    notifyListeners();
  }

  void updateStatus(TripStatus tripStatus, {bool notify = true}) {
    _tripStatus = tripStatus;
    if (notify) {
      notifyListeners();
    }
  }

  void updatePilotArrivalSeconds(int s) {
    _pilotArrivalSeconds = s;
    _pilotArrival = _calculatePilotArrival();
    _pilotArrivalString = _calculatePilotArrivalString();
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
    if (_pilotArrivalSeconds == null || _durationSeconds == null) {
      return null;
    }
    return DateTime.now().add(Duration(
      seconds: _durationSeconds + _pilotArrivalSeconds,
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

  DateTime _calculatePilotArrival() {
    if (_pilotArrivalSeconds == null) {
      return null;
    }
    return DateTime.now().add(Duration(
      seconds: _pilotArrivalSeconds,
    ));
  }

  String _calculatePilotArrivalString() {
    if (_pilotArrival == null) {
      return "";
    }
    return _pilotArrival.hour.toString() +
        ":" +
        _pilotArrival.minute.toString();
  }

  // TODO: round fare price up if payment is in money
  void fromRequestTripResult(Trip rrr, {bool notify = true}) {
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
      if (notify) {
        notifyListeners();
      }
    } else {
      _tripStatus = rrr.tripStatus;
      _farePrice = rrr.farePrice;
      _distanceMeters = rrr.distanceMeters;
      _distanceText = rrr.distanceText;
      _durationSeconds = rrr.durationSeconds;
      _durationText = rrr.durationText;
      _encodedPoints = rrr.encodedPoints;
      _pilotArrivalSeconds = 300; // estimate pilot will arrive in 5 minutes
      _eta = _calculateETA();
      _etaString = _calculateETAString();
      _pilotArrival = _calculatePilotArrival();
      _pilotArrivalString = _calculatePilotArrivalString();
      if (notify) {
        notifyListeners();
      }
    }
  }
}
