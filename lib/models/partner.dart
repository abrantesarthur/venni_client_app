import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/models/user.dart';

class PartnerModel extends ChangeNotifier {
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

  PartnerModel();

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

  void updateProfileImage(ProfileImage img, {bool notify = true}) {
    _profileImage = img;
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> downloadData({
    @required FirebaseModel firebase,
    @required String id,
    bool notify = true,
  }) async {
    Partner p = await firebase.functions.getPartner(id);
    await fromPartnerInterface(partner: p, notify: false);

    // download partner profile picture
    if (_id != null) {
      ProfileImage img = await firebase.storage.getPartnerProfilePicture(_id);
      updateProfileImage(img, notify: false);
    }
    if (notify) {
      notifyListeners();
    }
  }

  Future<void> fromPartnerInterface({
    Partner partner,
    bool notify = true,
  }) async {
    if (partner == null) {
      return Future.value();
    }
    _id = partner.id;
    _name = partner.name;
    _lastName = partner.lastName;
    _phoneNumber = partner.phoneNumber;
    _vehicle = partner.vehicle;
    _rating = partner.rating;
    _currentLatitude = partner.currentLatitude;
    _currentLongitude = partner.currentLongitude;
    _totalTrips = partner.totalTrips;
    _memberSinceDate = partner.memberSince == null
        ? null
        : (DateTime.fromMillisecondsSinceEpoch(partner.memberSince));
    _memberSince = partner.memberSince == null
        ? null
        : partner.memberSince.getFormatedDate();

    if (notify) {
      notifyListeners();
    }
  }

  Future<void> fromConfirmTripResult(
    BuildContext context,
    ConfirmTripResult result,
  ) async {
    if (result == null) {
      return Future.value();
    }
    _id = result.partnerID;
    _name = result.partnerName;
    _lastName = result.partnerLastName;
    _phoneNumber = result.partnerPhoneNumber;
    _vehicle = result.partnerVehicle;
    _rating = result.partnerRating;
    _currentLatitude = result.partnerCurrentLatitude;
    _currentLongitude = result.partnerCurrentLongitude;
    _totalTrips = result.partnerTotalTrips;
    _memberSinceDate = result.partnerMemberSince == null
        ? null
        : (DateTime.fromMillisecondsSinceEpoch(result.partnerMemberSince));
    _memberSince = result.partnerMemberSince == null
        ? null
        : result.partnerMemberSince.getFormatedDate();
  }
}
