// get address from latitude longitude and vice-versa

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/vendors/places.dart';

class Geocoding {
  static Future<GeocodingResponse> _get(String url) async {
    var response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      return GeocodingResponse.fromJson(jsonResponse);
    }
    return null;
  }

  static Future<GeocodingResponse> searchByPosition(Position position) async {
    String url = "https://maps.googleapis.com/maps/api/geocode/json?" +
        "latlng=${position.latitude},${position.longitude}&" +
        "language=pt-BR&" +
        "key=$placesAPIKey";
    return Geocoding._get(url);
  }

  static Future<GeocodingResponse> searchByPlaceID(String placeID) async {
    String url = "https://maps.googleapis.com/maps/api/geocode/json?" +
        "place_id=$placeID" +
        "&key=$placesAPIKey";
    return Geocoding._get(url);
  }
}

class GeocodingResponseStatus {
  static const okay = "OK";
  static const zeroResults = "ZERO_RESULTS";
  static const overDailyLimit = "OVER_DAILY_LIMIT";
  static const overQueryLimit = "OVER_QUERY_LIMIT";
  static const requestDenied = "REQUEST_DENIED";
  static const invalidRequest = "INVALID_REQUEST";
  static const unknownErrorStatus = "UNKNOWN_ERROR";

  final String status;
  final String errorMessage;

  bool get isOkay => status == okay;
  bool get hasNoResults => status == zeroResults;
  bool get isOverQueryLimit => status == overQueryLimit;
  bool get isDenied => status == requestDenied;
  bool get isInvalid => status == invalidRequest;
  bool get unknownError => status == unknownErrorStatus;

  GeocodingResponseStatus({
    @required this.status,
    @required this.errorMessage,
  });
}

class GeocodingResponse extends GeocodingResponseStatus {
  List<GeocodingResult> results;

  GeocodingResponse({
    @required String status,
    @required String errorMessage,
    @required this.results,
  }) : super(
          status: status,
          errorMessage: errorMessage,
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
    // TODO: this is ugly. maybe export the type casting to a function
    List<AddrComponent> acList = (json["address_components"] as List)
        ?.map((ac) => AddrComponent.fromJson(ac))
        ?.toList();
    AddressComponents acs = AddressComponents(acList);
    return json != null
        ? GeocodingResult(
            addressComponents: acs,
            formattedAddress: json["formatted_address"],
            latitude: json["geometry"]["location"]["lat"],
            longitude: json["geometry"]["location"]["lng"],
            placeID: json["place_id"],
          )
        : null;
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

  AddressComponents(this.addressComponents);

  String search(String type) {
    return addressComponents
            .firstWhere(
              (component) => component.types.contains(type),
              orElse: () => null,
            )
            ?.longName ??
        "";
  }

  String buildAddressMainText() {
    return this.search("route") +
        ", " +
        this.search("street_number") +
        (this.search("sublocality_level_1") != ""
            ? " - " + this.search("sublocality_level_1")
            : "");
  }

  String buildAddressSecondaryText() {
    return this.search("administrative_area_level_2") +
        " - " +
        this.search("administrative_area_level_1") +
        ", " +
        this.search("postal_code") +
        ", " +
        this.search("country");
  }
}
