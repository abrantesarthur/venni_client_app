import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/models/address.dart';
import 'package:uuid/uuid.dart';

// TODO: hide from codebase
const String placesAPIKey = "AIzaSyDHUnoB6uGH-8OoW4SIBnJRVpzRVD8fNVw";

// create autocomplete class similar to Geocoding

class Places {
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

  // static void getPlaceDetails(String placeID, BuildContext context) async {
  //   showDialog(
  //       context: context,
  //       builder: (BuildContext context) => SimpleDialog(
  //             children: [Text("setting drop off..")],
  //           ));

  //   String placeDetailsURL =
  //       "https://maps.googleapis.com/maps/api/place/details/" +
  //           "json?" +
  //           "key=$androidMapsKey&" +
  //           "place_id=$placeID&" +
  //           "sessionToken=123456765431";

  //   var res = await http.get(placeDetailsURL);

  //   Navigator.pop(context);

  //   if (res.statusCode < 300) {
  //     var jsonResponse = jsonDecode(res.body);
  //     if (jsonResponse["status"] == "OK") {
  //       Address address = Address();
  //       address.placeName = jsonResponse["result"]["name"];
  //       address.placeID = placeID;
  //       address.latitude =
  //           jsonResponse["result"]["geometry"]["location"]["lat"];
  //       address.latitude =
  //           jsonResponse["result"]["geometry"]["location"]["lng"];

  //       Provider.of<AppData>(context, listen: false)
  //           .updateDropOffAddress(address);

  //       Navigator.pop(context, "obtainDirection");
  //     }
  //   }
  // }
}
