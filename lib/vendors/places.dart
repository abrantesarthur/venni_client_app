import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/models/address.dart';
import 'package:uuid/uuid.dart';

// TODO: hide from codebase
const String placesAPIKey = "AIzaSyDHUnoB6uGH-8OoW4SIBnJRVpzRVD8fNVw";

// create autocomplete class similar to Geocoding

class Places {
  Places();

  // TODO: test this
  Future<List<Address>> findAddressPredictions({
    @required String placeName,
    @required double latitude,
    @required double longitude,
    @required bool isDropOff,
    @required String sessionToken,
  }) async {
    sessionToken ??= Uuid().v4();

    List<Address> predictionList = [];
    if (placeName.length > 1) {
      String autoCompleteUrl =
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?" +
              "input=$placeName&" +
              "key=$placesAPIKey&" +
              "sessiontoken=$sessionToken&" +
              "location=$latitude,$longitude&" +
              "radius=${30000}&" +
              "strictbounds&" +
              "language=pt-BR";

      var autocompleteResponse = await http.get(autoCompleteUrl);
      if (autocompleteResponse.statusCode < 300) {
        var autocompleteJson = jsonDecode(autocompleteResponse.body);
        if (autocompleteJson["status"] == "OK") {
          var predictions = autocompleteJson["predictions"];
          predictionList = (predictions as List).map((p) {
            return Address.fromAutocompleteResponse(p, isDropOff);
          }).toList();
        }
      }
    }
    return predictionList;
  }
}
