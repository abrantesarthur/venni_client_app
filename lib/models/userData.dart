import 'package:flutter/material.dart';
import 'package:rider_frontend/vendors/geocoding.dart';

class ProfileImage {
  final ImageProvider<Object> file;
  final String name;

  ProfileImage({@required this.file, @required this.name});
}

class UserDataModel extends ChangeNotifier {
  GeocodingResult geocoding; // maybe change name to initial
  ProfileImage profileImage;
  double rating;

  UserDataModel({@required this.geocoding});

  void setProfileImage({
    @required ImageProvider<Object> file,
    @required String name,
  }) {
    profileImage = ProfileImage(
      file: file,
      name: name,
    );
    notifyListeners();
  }

  void setUserRating(double r) {
    rating = r;
    notifyListeners();
  }
}
