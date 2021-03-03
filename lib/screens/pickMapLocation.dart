import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_place_picker/google_maps_place_picker.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/places.dart';

class PickMapLocationArguments {
  final LatLng initialPosition;
  final bool isDropOff;

  PickMapLocationArguments({this.initialPosition, this.isDropOff});
}

class PickMapLocation extends StatefulWidget {
  static const String routeName = "PickMapLocation";
  final LatLng initialPosition;
  final bool isDropOff;

  PickMapLocation({
    @required this.initialPosition,
    @required this.isDropOff,
  });

  PickMapLocationState createState() => PickMapLocationState();
}

class PickMapLocationState extends State<PickMapLocation> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PlacePicker(
            apiKey: placesAPIKey,
            initialPosition: widget.initialPosition,
            useCurrentLocation: false,
            enableMyLocationButton: false,
            enableMapTypeButton: false,
            automaticallyImplyAppBarLeading: true,
            strictbounds: false, // a bug that prevents autocomplete
            selectedPlaceWidgetBuilder: selectedPlaceWidgetBuilderCallback,
          )
        ],
      ),
    );
  }

  Widget selectedPlaceWidgetBuilderCallback(
    BuildContext context,
    PickResult data,
    SearchingState state,
    bool isSearchBarFocused,
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
          : _buildSelectionDetails(context, data),
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

  Widget _buildSelectionDetails(BuildContext context, PickResult result) {
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
              "Selecionar",
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
              Address place = Address.fromPickResult(result, widget.isDropOff);
              print("here");
              Navigator.pop(context, place);
            },
          ),
        ],
      ),
    );
  }
}
