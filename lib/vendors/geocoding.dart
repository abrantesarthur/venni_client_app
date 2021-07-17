// get address from latitude longitude and vice-versa

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/vendors/googleService.dart';

class Geocoding extends GoogleWebService {
  Geocoding() : super(baseUrl: AppConfig.env.values.geocodingBaseURL);

  Future<GeocodingResponse> searchByPosition(Position position) async {
    String params = "latlng=${position.latitude},${position.longitude}";
    return _decode(await doGet(params));
  }

  Future<GeocodingResponse> searchByPlaceID(String placeID) async {
    String params = "place_id=$placeID";
    return _decode(await doGet(params));
  }

  GeocodingResponse _decode(http.Response response) {
    if (response != null && response.statusCode == 200) {
      print("response != null && response.statusCode == 200");
      print(response.body);
      return GeocodingResponse.fromJson(jsonDecode(response.body));
    } else {
      print("response failed");
      print(response);
    }

    return null;
  }
}

class GeocodingResponse extends GoogleResponseList<GeocodingResult> {
  GeocodingResponse({
    @required String status,
    @required String errorMessage,
    @required List<GeocodingResult> results,
  }) : super(
          status: status,
          errorMessage: errorMessage,
          results: results,
        );

  factory GeocodingResponse.fromJson(Map json) {
    return json != null
        ? GeocodingResponse(
            status: json["status"],
            errorMessage: json["error_message"],
            results: (json["results"] as List)
                ?.map((r) => GeocodingResult.fromJson(r))
                ?.toList()
                ?.cast<GeocodingResult>())
        : null;
  }
}

class GeocodingResult {
  final AddressComponents addressComponents;
  final String formattedAddress;
  final double latitude;
  final double longitude;
  final String placeID;

  GeocodingResult({
    @required this.addressComponents,
    @required this.formattedAddress,
    @required this.latitude,
    @required this.longitude,
    @required this.placeID,
  });

  factory GeocodingResult.fromJson(Map json) {
    if (json == null) return null;
    double _getLatitude(Map geometry) {
      return geometry != null
          ? (geometry["location"] != null ? geometry["location"]["lat"] : null)
          : null;
    }

    double _getLongitude(Map geometry) {
      return geometry != null
          ? (geometry["location"] != null ? geometry["location"]["lng"] : null)
          : null;
    }

    List<AddrComponent> acList = (json["address_components"] as List)
        ?.map((ac) => AddrComponent.fromJson(ac))
        ?.toList();
    AddressComponents acs = acList != null ? AddressComponents(acList) : null;
    return GeocodingResult(
      addressComponents: acs,
      formattedAddress: json["formatted_address"],
      latitude: _getLatitude(json["geometry"]),
      longitude: _getLongitude(json["geometry"]),
      placeID: json["place_id"],
    );
  }
}

class AddrComponent {
  final List<String> types;
  final String longName;
  final String shortName;

  AddrComponent({
    @required this.types,
    @required this.longName,
    @required this.shortName,
  });

  factory AddrComponent.fromJson(Map json) {
    return json != null
        ? AddrComponent(
            types: (json['types'] as List)?.cast<String>(),
            longName: json['long_name'],
            shortName: json['short_name'])
        : null;
  }
}

class AddressComponents {
  final List<AddrComponent> addressComponents;

  AddressComponents(this.addressComponents) : assert(addressComponents != null);

  String _search(String type, {bool pickShortName = false}) {
    AddrComponent ac = addressComponents.firstWhere(
      (component) => component.types.contains(type),
      orElse: () => null,
    );
    String field;
    if (ac != null) field = pickShortName ? ac.shortName : ac.longName;
    return field ?? "";
  }

// TODO: fix this. it didn;t save my alterations
  String buildAddressMainText() {
    String route = this._search("route");
    String streetNumber = this._search("street_number");
    String sublocality = this._search("sublocality_level_1");
    // contains route, street number and sublocality
    if (route != "" && streetNumber != "" && sublocality != "") {
      return route + ", " + streetNumber + " - " + sublocality;
    }
    // without street number
    if (route != "" && streetNumber == "" && sublocality != "") {
      return route + " - " + sublocality;
    }
    // without sublocality
    if (route != "" && streetNumber != "" && sublocality == "") {
      return route + ", " + streetNumber;
    }
    // contains only street number
    if (route != "" && streetNumber == "" && sublocality == "") {
      return route;
    }
    // doesnt contain route
    return sublocality;
  }

  String buildAddressSecondaryText() {
    String city = this._search("administrative_area_level_2");
    String shortState = this._search(
      "administrative_area_level_1",
      pickShortName: true,
    );
    String longState = this._search("administrative_area_level_1");
    String postalCode = this._search("postal_code");
    String country = this._search("country");
    // contains all fields
    if (city != "" && shortState != "" && postalCode != "" && country != "") {
      return city + " - " + shortState + ". " + postalCode + ", " + country;
    }
    // contains no city
    if (city == "") {
      return (longState != ""
          ? (longState + (country != "" ? ", " + country : "")) // with state
          : country); // without state
    }
    // contains no state
    if (shortState == "") {
      return city + (country != "" ? ", " + country : "");
    }
    // default
    return city + " - " + shortState;
  }
}
