import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/models/user.dart';

class DriverModel extends ChangeNotifier {
  ProfileImage _profileImage;
  String _id;
  String _name;
  String _lastName;
  String _phoneNumber;
  Vehicle _vehicle;
  double _rating;
  double _currentLatitude;
  double _currentLongitude;
  int _totalTrips;
  DateTime _memberSinceDate;
  String _memberSince;

  // getters
  ProfileImage get profileImage => _profileImage;
  String get id => _id;
  String get name => _name;
  String get lastName => _lastName;
  String get phoneNumber => _phoneNumber;
  Vehicle get vehicle => _vehicle;
  double get rating => _rating;
  double get currentLatitude => _currentLatitude;
  double get currentLongitude => _currentLongitude;
  int get totalTrips => _totalTrips;
  String get memberSince => _memberSince;

  DriverModel();

  void clear({
    TripStatus status = TripStatus.off,
    bool notify = true,
  }) {
    _profileImage = null;
    _id = null;
    _name = null;
    _lastName = null;
    _phoneNumber = null;
    _vehicle = null;
    _rating = null;
    _currentLatitude = null;
    _currentLongitude = null;
    _totalTrips = null;
    _memberSinceDate = null;
    _memberSince = null;
    if (notify) {
      notifyListeners();
    }
  }

  // don't notify listeners, since we will update UI when redrawing polyline
  void updateCurrentLatitude(double lat) {
    _currentLatitude = lat;
  }

  // don't notify listeners, since we will update UI when redrawing polyline
  void updateCurrentLongitude(double lng) {
    _currentLongitude = lng;
  }

  void updateProfileImage(ProfileImage img) {}

  Future<void> fromConfirmTripResult(
    BuildContext context,
    ConfirmTripResult result,
  ) async {
    if (result == null) {
      return Future.value();
    }
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    _id = result.uid;
    _name = result.name;
    _lastName = result.lastName;
    _phoneNumber = result.phoneNumber;
    _vehicle = result.vehicle;
    _rating = result.rating;
    _currentLatitude = result.currentLatitude;
    _currentLongitude = result.currentLongitude;
    _totalTrips = result.totalTrips;
    _memberSinceDate = result.memberSince == null
        ? null
        : (DateTime.fromMillisecondsSinceEpoch(result.memberSince));
    _memberSince = _memberSinceDate == null
        ? null
        : (_memberSinceDate.day < 10
                ? "0" + _memberSinceDate.day.toString()
                : _memberSinceDate.day.toString()) +
            "/" +
            (_memberSinceDate.month < 10
                ? "0" + _memberSinceDate.month.toString()
                : _memberSinceDate.month.toString()) +
            "/" +
            _memberSinceDate.year.toString();

    // download driver profile picture
    ProfileImage img =
        await firebase.storage.getDriverProfilePicture(result.uid);
    this._profileImage = img;
  }
}
