import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/vendors/googleService.dart';
import 'package:uuid/uuid.dart';

// create autocomplete class similar to Geocoding

class Places extends GoogleWebService {
  Places() : super(serviceName: "place/autocomplete");

  Future<List<Address>> findAddressPredictions({
    @required String placeName,
    @required double latitude,
    @required double longitude,
    @required bool isDropOff,
    String sessionToken,
  }) async {
    sessionToken ??= Uuid().v4();

    List<Address> predictionList = [];
    if (placeName.length > 1) {
      String params = "input=$placeName&" +
          "sessiontoken=$sessionToken&" +
          "location=$latitude,$longitude&" +
          "radius=${30000}&" +
          "strictbounds";

      predictionList = _decode(await doGet(params), isDropOff);
    }
    return predictionList;
  }

  List<Address> _decode(http.Response response, bool isDropOff) {
    List<Address> predictionList = [];
    if (response != null && response.statusCode < 300) {
      var jsonResponse = jsonDecode(response.body);
      if (jsonResponse["status"] == "OK") {
        var predictions = jsonResponse["predictions"];
        predictionList = (predictions as List).map((p) {
          return Address.fromAutocompleteResponse(p, isDropOff);
        }).toList();
      }
    }
    return predictionList;
    ;
  }
}
