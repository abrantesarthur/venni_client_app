import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';

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
  num _partnerArrivalSeconds;
  DateTime _partnerArrival;
  String _partnerArrivalString;

  TripModel() {
    _tripStatus = TripStatus.off;
  }

  // TODO: try moving partner data to partner model
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
  String get partnerArrivalString => _partnerArrivalString;
  num get partnerArrivalSeconds => _partnerArrivalSeconds;

  void updatePickUpAddres(Address address, {bool notify = true}) {
    print("updatePickUpAdress with address that is null?");
    print(address == null);
    _currentPickUpAddress = address;
    if (notify) {
      print("notifyListeners");
      notifyListeners();
    }
  }

  void updateDropOffAddres(Address address, {bool notify = true}) {
    _currentDropOffAddress = address;
    if (notify) {
      notifyListeners();
    }
  }

  void updateStatus(TripStatus tripStatus, {bool notify = true}) {
    _tripStatus = tripStatus;
    if (notify) {
      notifyListeners();
    }
  }

  void updatePartnerArrivalSeconds(int s, {bool notify = true}) {
    _partnerArrivalSeconds = s;
    _partnerArrival = _calculatePartnerArrival();
    _partnerArrivalString = _calculatePartnerArrivalString();
    _eta = _calculateETA();
    _etaString = _calculateETAString();
    if (notify) {
      notifyListeners();
    }
  }

  void updateDurationSeconds(int s, {bool notify = true}) {
    _durationSeconds = s;
    _eta = _calculateETA();
    _etaString = _calculateETAString();
    if (notify) {
      notifyListeners();
    }
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
    if (_partnerArrivalSeconds == null || _durationSeconds == null) {
      return null;
    }
    return DateTime.now().add(Duration(
      seconds: _durationSeconds + _partnerArrivalSeconds,
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

  DateTime _calculatePartnerArrival() {
    if (_partnerArrivalSeconds == null) {
      return null;
    }
    return DateTime.now().add(Duration(
      seconds: _partnerArrivalSeconds,
    ));
  }

  String _calculatePartnerArrivalString() {
    if (_partnerArrival == null) {
      return "";
    }
    return _partnerArrival.hour.toString() +
        ":" +
        _partnerArrival.minute.toString();
  }

  // downloadData sends requests to download data about current trips and partner
  Future<void> downloadData({
    FirebaseModel firebase,
    PartnerModel partner,
    bool notify = true,
  }) async {
    Trip trip;
    try {
      trip = await firebase.functions.getCurrentTrip();
      fromTripInterface(trip, notify: notify);
    } on FirebaseException catch (e) {
      // an error was thrown becasue there is no active trip, clear model
      if (e.code == "not-found") {
        clear(notify: notify);
      }
      return;
    }

    // if trip has already been completed, clear the model
    if (trip.tripStatus == TripStatus.completed ||
        trip.tripStatus == TripStatus.cancelledByClient) {
      clear(notify: notify);
      partner.clear(notify: notify);
    }

    //if trip exists and has waiting-partner or in-progress status
    if (trip.tripStatus == TripStatus.inProgress ||
        trip.tripStatus == TripStatus.waitingPartner) {
      //  download partner data. This may throw an error.
      await partner.downloadData(
        firebase: firebase,
        id: trip.partnerID,
        notify: notify,
      );
    } else {
      partner.clear(notify: notify);
    }
  }

  // TODO: round fare price up if payment is in money
  void fromTripInterface(Trip trip, {bool notify = true}) {
    if (trip == null) {
      _tripStatus = TripStatus.off;
      _farePrice = null;
      _distanceMeters = null;
      _distanceText = null;
      _durationSeconds = null;
      _durationText = null;
      _encodedPoints = null;
      _eta = null;
      _etaString = null;
    } else {
      _tripStatus = trip.tripStatus;
      _farePrice = trip.farePrice;
      _distanceMeters = trip.distanceMeters;
      _distanceText = trip.distanceText;
      _durationSeconds = trip.durationSeconds;
      _durationText = trip.durationText;
      _encodedPoints = trip.encodedPoints;
      _partnerArrivalSeconds = 300; // estimate partner will arrive in 5 minutes
      _eta = _calculateETA();
      _etaString = _calculateETAString();
      _partnerArrival = _calculatePartnerArrival();
      _partnerArrivalString = _calculatePartnerArrivalString();
      // enrich adddress with coordinates
      Address enrichedPickUpAddress = Address(
        isDropOff: false,
        mainText: _currentPickUpAddress?.mainText ?? trip.originAddress,
        secondaryText:
            _currentPickUpAddress?.secondaryText ?? trip.originAddress,
        placeID: _currentPickUpAddress?.placeID ?? trip.originPlaceID,
        latitude: trip.originLat,
        longitude: trip.originLng,
      );

      _currentPickUpAddress = enrichedPickUpAddress;
      Address enrichedDropOffAddress = Address(
        isDropOff: true,
        mainText: _currentDropOffAddress?.mainText ?? trip.destinationAddress,
        secondaryText:
            _currentDropOffAddress?.secondaryText ?? trip.destinationAddress,
        placeID: _currentDropOffAddress?.placeID ?? trip.destinationPlaceID,
        latitude: trip.destinationLat,
        longitude: trip.destinationLng,
      );

      _currentDropOffAddress = enrichedDropOffAddress;
    }
    if (notify) {
      notifyListeners();
    }
  }
}
