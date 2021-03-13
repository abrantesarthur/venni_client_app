// get address from latitude longitude and vice-versa

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:rider_frontend/vendors/googleService.dart';

class Geocoding extends GoogleWebService {
  Geocoding() : super(baseUrl: "https://maps.googleapis.com/maps/api/geocode");

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
      return GeocodingResponse.fromJson(jsonDecode(response.body));
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

// TODO: fix this. it didn;t save my alterations
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
