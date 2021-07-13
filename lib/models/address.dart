import 'package:flutter/material.dart';
import 'package:flutter_maps_place_picker/flutter_maps_place_picker.dart';
import 'package:rider_frontend/vendors/geocoding.dart';

class Address {
  bool isDropOff;
  String mainText;
  String secondaryText;
  String placeID;
  double latitude;
  double longitude;

  Address({
    @required this.isDropOff,
    @required this.mainText,
    this.secondaryText,
    @required this.placeID,
    this.latitude,
    this.longitude,
  });

  factory Address.fromGeocodingResult({
    @required GeocodingResult geocodingResult,
    @required bool dropOff,
  }) {
    if (geocodingResult == null) {
      return null;
    }

    AddressComponents addressComponents = geocodingResult.addressComponents;

    return Address(
      isDropOff: dropOff,
      mainText: addressComponents.buildAddressMainText(),
      secondaryText: addressComponents.buildAddressSecondaryText(),
      placeID: geocodingResult.placeID,
      latitude: geocodingResult.latitude,
      longitude: geocodingResult.longitude,
    );
  }

  Address.fromPickResult(PickResult pickResult, bool dropOff) {
    final acList =
        pickResult.addressComponents.fold<List<AddrComponent>>([], (acc, elt) {
      AddrComponent newElt = AddrComponent(
          types: elt.types, longName: elt.longName, shortName: elt.shortName);
      acc.add(newElt);
      return acc;
    });
    final acs = AddressComponents(acList);
    isDropOff = dropOff;
    mainText = acs.buildAddressMainText();
    secondaryText = acs.buildAddressSecondaryText();
    placeID = pickResult.placeId;
  }

  // TODO: format just like GeocodingResult
  Address.fromAutocompleteResponse(Map<String, dynamic> json, bool dropOff) {
    isDropOff = dropOff;
    mainText = json["structured_formatting"]["main_text"];
    secondaryText = json["structured_formatting"]["secondary_text"];
    placeID = json["place_id"];
  }
}
