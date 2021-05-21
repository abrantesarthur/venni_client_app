import 'package:flutter/material.dart';
import 'package:flutter_maps_place_picker/flutter_maps_place_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/geocoding.dart';

Widget buildPlacePicker({
  @required BuildContext context,
  @required Position userPosition,
  Address initialAddress,
  @required bool isDropOff,
}) {
  return PlacePicker(
    onMapCreated: (GoogleMapController c) async {
      await _moveCameraToAddress(c, initialAddress);
    },
    apiKey: AppConfig.env.values.googleMapsApiKey,
    initialPosition: LatLng(userPosition.latitude, userPosition.longitude),
    useCurrentLocation: false,
    enableMyLocationButton: false,
    enableMapTypeButton: false,
    automaticallyImplyAppBarLeading: true,
    selectedPlaceWidgetBuilder: (context, data, state, isSearchBarFocused) {
      return _selectedPlaceWidgetBuilderCallback(
        context,
        data,
        state,
        isSearchBarFocused,
        isDropOff,
      );
    },
  );
}

Future<void> _moveCameraToAddress(
    GoogleMapController c, Address address) async {
  // move camera if address is not null
  if (address != null && address.placeID != null) {
    // calculate latitude and longitude if necessary
    if (address.latitude == null || address.longitude == null) {
      GeocodingResponse geocodingResponse =
          await Geocoding().searchByPlaceID(address.placeID);
      GeocodingResult geocodingResult = geocodingResponse.results[0];
      address.latitude = geocodingResult.latitude;
      address.longitude = geocodingResult.longitude;
    }

    // move camera to address position
    await c.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(address.latitude, address.longitude),
      16.5,
    ));
  }
}

Widget _selectedPlaceWidgetBuilderCallback(
  BuildContext context,
  PickResult data,
  SearchingState state,
  bool isSearchBarFocused,
  bool isDropOff,
) {
  final height = MediaQuery.of(context).size.height;
  final width = MediaQuery.of(context).size.width;
  return FloatingCard(
    bottomPosition: height / 12,
    leftPosition: width / 12,
    rightPosition: width / 15,
    width: width,
    borderRadius: BorderRadius.circular(10.0),
    elevation: 4.0,
    color: Colors.white,
    child: state == SearchingState.Searching
        ? _buildLoadingIndicator()
        : _buildSelectionDetails(
            context,
            data,
            isDropOff,
          ),
  );
}

Widget _buildLoadingIndicator() {
  return Container(
    height: 70,
    child: const Center(
      child: SizedBox(
        width: 40,
        height: 40,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation(AppColor.primaryPink),
        ),
      ),
    ),
  );
}

Widget _buildSelectionDetails(
  BuildContext context,
  PickResult result,
  bool isDropOff,
) {
  return Container(
    margin: EdgeInsets.all(10),
    child: Column(
      children: <Widget>[
        Text(
          result.formattedAddress,
          style: TextStyle(fontSize: 18),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 10),
        RaisedButton(
          color: AppColor.primaryPink,
          padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
          child: Text(
            "Pronto",
            style: TextStyle(
              fontSize: 18,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4.0),
          ),
          onPressed: () {
            // build place response
            Address address = Address.fromPickResult(result, isDropOff);

            if (isDropOff) {
              updateDropOffAndPop(context, address);
            } else {
              updatePickUpAndPop(context, address);
            }
          },
        ),
      ],
    ),
  );
}
