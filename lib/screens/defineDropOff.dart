import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/placePicker.dart';
import 'package:rider_frontend/vendors/places.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/padlessDivider.dart';
import 'package:uuid/uuid.dart';

// TODO: focus automatically
// TODO: google maps is enabled if there is initial address

class DefineDropOffArguments {
  final GeocodingResult userGeocoding;
  final Address chosenDropOffAddress;

  DefineDropOffArguments({
    @required this.userGeocoding,
    @required this.chosenDropOffAddress,
  }) : assert(userGeocoding != null);
}

class DefineDropOff extends StatefulWidget {
  static const String routeName = "DefineDropOff";
  final GeocodingResult userGeocoding;
  final Address chosenDropOffAddress;

  DefineDropOff(
      {@required this.userGeocoding, @required this.chosenDropOffAddress})
      : assert(userGeocoding != null);

  @override
  DefineDropOffState createState() => DefineDropOffState();
}

class DefineDropOffState extends State<DefineDropOff> {
  TextEditingController dropOffTextEditingController = TextEditingController();
  List<Address> addressPredictions;
  String sessionToken;
  bool googleMapsEnabled;

  @override
  void initState() {
    super.initState();

    sessionToken = Uuid().v4();

    // if there is an initial address show google maps.
    // it is configured to show that address too
    googleMapsEnabled = widget.chosenDropOffAddress != null;

    // suggest locations as user searches locations
    dropOffTextEditingController.addListener(() async {
      await textFieldListener(true);
    });
  }

  @override
  void dispose() {
    dropOffTextEditingController.dispose();
    super.dispose();
  }

  Future<void> textFieldListener(bool isDropOff) async {
    String location = dropOffTextEditingController.text ?? "";
    if (location.length == 0) {
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
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          OverallPadding(
            bottom: 0,
            child: Column(
              children: [
                Row(
                  children: [
                    ArrowBackButton(
                        onTapCallback: () => Navigator.pop(context)),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 50),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // TODO: render icon with higher definition
                    Image(
                      image: AssetImage("images/dropOff.png"),
                      width: screenWidth / 20,
                    ),
                    AppInputText(
                      onTapCallback: () {
                        // renew session token and hide map
                        setState(() {
                          sessionToken = Uuid().v4();
                          googleMapsEnabled = false;
                        });
                      },
                      fontSize: 16,
                      width: screenWidth / 1.3,
                      hintText: "Para onde?",
                      hintColor: AppColor.disabled,
                      controller: dropOffTextEditingController,
                    ),
                  ],
                ),
                SizedBox(height: screenHeight / 50),
              ],
            ),
          ),
          PadlessDivider(),
          googleMapsEnabled == false
              ? OverallPadding(
                  bottom: 0,
                  top: screenHeight / 100,
                  child: Column(
                    children: [
                      SizedBox(height: screenHeight / 200),
                      BorderlessButton(
                        iconLeft: Icons.add_location,
                        iconRight: Icons.keyboard_arrow_right,
                        primaryText: "Definir destino no mapa",
                        onTapCallback: () async {
                          setState(() {
                            // display map
                            googleMapsEnabled = true;
                            // hide keyboard
                            FocusScope.of(context).unfocus();
                          });
                        },
                      ),
                      Divider(color: Colors.black, thickness: 0.1),
                      _buildAddressPredictionList(context, addressPredictions),
                    ],
                  ),
                )
              : Expanded(
                  child: buildPlacePicker(
                  context: context,
                  userGeocoding: widget.userGeocoding,
                  isDropOff: true,
                  initialAddress: widget.chosenDropOffAddress,
                ))
        ],
      ),
    );
  }
}

// _buildAddressPredictionList returns a ListView of address predictions
Widget _buildAddressPredictionList(
  BuildContext context,
  List<Address> addressPredictions,
) {
  final screenHeight = MediaQuery.of(context).size.height;
  return (addressPredictions != null && addressPredictions.length > 0)
      ? LayoutBuilder(builder: (context, viewportConstraints) {
          return ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight:
                  0.7 * screenHeight - MediaQuery.of(context).viewInsets.bottom,
            ),
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              removeBottom: true,
              child: ListView.separated(
                physics: AlwaysScrollableScrollPhysics(),
                scrollDirection: Axis.vertical,
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  return BorderlessButton(
                    onTapCallback: () {
                      updateDropOffAndPop(context, addressPredictions[index]);
                    },
                    iconLeft: Icons.add_location,
                    primaryText: addressPredictions[index].mainText,
                    secondaryText: addressPredictions[index].secondaryText,
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
      : Container();
}

// updateRoute updates the drop off and pick up locations of the RouteModel
void updateDropOffAndPop(
  BuildContext context,
  Address address,
) {
  RouteModel routeModel = Provider.of<RouteModel>(context, listen: false);
  // set location as drop off point
  routeModel.updateDropOffAddres(address);

  // go back to DefineRoute screen
  Navigator.pop(context);
}
