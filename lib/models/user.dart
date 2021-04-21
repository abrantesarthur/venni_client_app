import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/geolocator.dart';

class ProfileImage {
  final ImageProvider<Object> file;
  final String name;

  ProfileImage({@required this.file, @required this.name});
}

class UserModel extends ChangeNotifier {
  GeocodingResult _geocoding;
  ProfileImage _profileImage;
  double _rating;

  GeocodingResult get geocoding => _geocoding;
  ProfileImage get profileImage => _profileImage;
  double get rating => _rating;

  UserModel();

  void setProfileImage(ProfileImage img) {
    _profileImage = img;
    notifyListeners();
  }

  void setRating(double r) {
    _rating = r;
    notifyListeners();
  }

  void setGeocoding(GeocodingResult g) {
    _geocoding = g;
    notifyListeners();
  }

  // TODO: use cache
  Future<void> downloadData(FirebaseModel firebase) async {
    // download user image file
    // TODO: there is aproblem with getProfileImage. it's not returning. fix it
    firebase.storage
        .getUserProfileImage(uid: firebase.auth.currentUser.uid)
        .then((value) => this.setProfileImage(value));

    // get user rating
    double rating =
        await firebase.database.getUserRating(firebase.auth.currentUser.uid);
    this.setRating(rating);
  }

  Future<Position> getPosition() async {
    Position userPos;
    try {
      userPos = await determineUserPosition();
    } catch (_) {
      return null;
    }
    return userPos;
  }

  Future<void> getGeocoding({Position pos}) async {
    Position userPos = pos;
    if (userPos == null) {
      // get user position
      userPos = await getPosition();
      if (userPos == null) {
        // don't update geocoding if fail to get position.
        return;
      }
    }

    // get user geocoding
    GeocodingResponse geocoding = await Geocoding().searchByPosition(userPos);
    GeocodingResult geocodingResult;
    if (geocoding != null &&
        geocoding.results != null &&
        geocoding.results.length > 0) {
      geocodingResult = geocoding.results[0];
    }
    // set user position
    setGeocoding(geocodingResult);
  }
}
