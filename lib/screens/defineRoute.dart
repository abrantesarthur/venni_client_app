import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/places.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/screens/pickMapLocation.dart';
import 'package:uuid/uuid.dart';

class DefineRouteArguments {
  final GeocodingResult userGeocoding;

  DefineRouteArguments({@required this.userGeocoding});
}

class DefineRoute extends StatefulWidget {
  static const String routeName = "DefineRoute";
  final GeocodingResult userGeocoding;

  DefineRoute({this.userGeocoding});

  @override
  DefineRouteState createState() => DefineRouteState();
}

/**
 * TODO: it's probably best to split pickUp and DropOff into two screens
 * TODO: review everything in this file and in pickMapLocation
 * TODO: write tests here and vendors that I just added
 * TODO: 
 * TODO: review focus nodes when
 *  choosing location from suggestions
 *  returning from PickMapLocation (probably unfocus both)
 */

class DefineRouteState extends State<DefineRoute> {
  TextEditingController dropOffTextEditingController = TextEditingController();
  TextEditingController pickUpTextEditingController = TextEditingController();

  FocusNode dropOffFocusNode = FocusNode();
  FocusNode pickUpFocusNode = FocusNode();

  List<Address> addressPredictions;

  String sessionToken;

  @override
  void initState() {
    super.initState();

    sessionToken = Uuid().v4();

    // suggest locations as user searches pick up and drop off locations
    dropOffTextEditingController.addListener(() async {
      await textFieldListener(true);
    });
    pickUpTextEditingController.addListener(() async {
      await textFieldListener(false);
    });
  }

  Future<void> textFieldListener(bool isDropOff) async {
    String location;
    if (isDropOff) {
      location = dropOffTextEditingController.text ?? "";
    } else {
      location = pickUpTextEditingController.text ?? "";
    }
    if (location.length == 0) {
      // TODO: fix for  case when pick up is not null
      setState(() {
        addressPredictions = null;
      });
    } else {
      // get drop off address predictions
      List<Address> predictions = await Places.findAddressPredictions(
        placeName: location,
        latitude: widget.userGeocoding.latitude,
        longitude: widget.userGeocoding.longitude,
        sessionToken: sessionToken,
        isDropOff: isDropOff,
      );
      setState(() {
        addressPredictions = predictions;
      });
    }
  }

  @override
  void dispose() {
    dropOffTextEditingController.dispose();
    super.dispose();
  }

  // updateRoute updates the drop off and pick up locations of the RouteModel
  void updateRoute(Address addr, RouteModel rm) {
    // TODO: go back to home screen if both pick up and drop off are selected

    if (addr.isDropOff) {
      // set location as drop off point
      rm.updateDropOffLocation(addr.placeID);

      // add drop off description to text box
      String newText = addr.mainText;
      int newSelection = newText.length;
      dropOffTextEditingController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newSelection),
        ),
      );
    } else {
      // set location as pick up point
      rm.updatePickUpLocation(addr.placeID);

      // add drop off description to text box
      String newText = addr.mainText;
      int newSelection = newText.length;
      pickUpTextEditingController.value = TextEditingValue(
        text: newText,
        selection: TextSelection.fromPosition(
          TextPosition(offset: newSelection),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    RouteModel routeModel = Provider.of<RouteModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () => Navigator.pop(context)),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 50),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TODO: render icon with higher definition
                Image(image: AssetImage("images/pickroute.png")),
                Column(
                  children: [
                    AppInputText(
                      fontSize: 16,
                      width: screenWidth / 1.3,
                      hintText: "Localização atual",
                      focusNode: pickUpFocusNode,
                      controller: pickUpTextEditingController,
                      // TODO: export all callbacks to functions
                      onTapCallback: () async {
                        // renew session token
                        setState(() {
                          sessionToken = Uuid().v4();
                        });

                        // update pick up text field to show current location
                        Address userAddress = Address.fromGeocodingResult(
                          geocodingResult: widget.userGeocoding,
                          dropOff: false,
                        );
                        pickUpTextEditingController.text = userAddress.mainText;
                        pickUpTextEditingController.selection =
                            TextSelection.fromPosition(TextPosition(
                          offset: userAddress.mainText.length,
                        ));
                      },
                    ),
                    SizedBox(height: screenHeight / 100),
                    AppInputText(
                      onTapCallback: () {
                        // renew session token
                        setState(() {
                          sessionToken = Uuid().v4();
                        });
                      },
                      fontSize: 16,
                      width: screenWidth / 1.3,
                      hintText: "Para onde?",
                      hintColor: AppColor.disabled,
                      controller: dropOffTextEditingController,
                      focusNode: dropOffFocusNode,
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: screenHeight / 50),
            Divider(thickness: 0.3, color: Colors.black),
            BorderlessButton(
              iconLeft: Icons.add_location,
              iconRight: Icons.keyboard_arrow_right,
              // TODO: change according to whether we're choosing drop off or pick up
              primaryText: "Definir local no mapa",
              onTapCallback: () async {
                // define whether picked location is drop off or pick up. default to dropoff
                bool isDropOff =
                    dropOffFocusNode.hasFocus || !pickUpFocusNode.hasFocus;

                // push a PickMapLocation that allows user to pick a place
                final pickedPlace = await Navigator.pushNamed(
                  context,
                  PickMapLocation.routeName,
                  arguments: PickMapLocationArguments(
                    initialPosition: LatLng(
                      widget.userGeocoding.latitude,
                      widget.userGeocoding.longitude,
                    ),
                    isDropOff: isDropOff,
                  ),
                ) as Address;

                // update route if user ended up picking a place
                if (pickedPlace != null) {
                  updateRoute(pickedPlace, routeModel);
                }
              },
            ),
            SizedBox(height: screenHeight / 100),
            Divider(thickness: 0.1, color: Colors.black),
            (addressPredictions != null && addressPredictions.length > 0)
                ? LayoutBuilder(builder: (context, viewportConstraints) {
                    return ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: 0.6 * screenHeight -
                            MediaQuery.of(context).viewInsets.bottom,
                      ),
                      child: MediaQuery.removePadding(
                        removeTop: true,
                        removeBottom: true,
                        context: context,
                        child: ListView.separated(
                          physics: AlwaysScrollableScrollPhysics(),
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemBuilder: (context, index) {
                            return BorderlessButton(
                              onTapCallback: () => updateRoute(
                                addressPredictions[index],
                                routeModel,
                              ),
                              iconLeft: Icons.add_location,
                              primaryText: addressPredictions[index].mainText,
                              secondaryText:
                                  addressPredictions[index].secondaryText,
                            );
                          },
                          separatorBuilder: (context, index) {
                            return Divider(thickness: 0.1, color: Colors.black);
                          },
                          itemCount: addressPredictions.length,
                        ),
                      ),
                    );
                  })
                : Container(),
            SizedBox(height: screenHeight / 100),
          ],
        ),
      ),
    );
  }
}
