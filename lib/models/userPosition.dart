import 'package:flutter/material.dart';
import 'package:rider_frontend/vendors/geocoding.dart';

class UserPositionModel extends ChangeNotifier {
  GeocodingResult geocoding; // maybe change name to initial

  UserPositionModel({@required this.geocoding});
}
