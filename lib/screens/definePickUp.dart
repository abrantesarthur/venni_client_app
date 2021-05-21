import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/placePicker.dart';
import 'package:rider_frontend/vendors/places.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/padlessDivider.dart';
import 'package:uuid/uuid.dart';

class DefinePickUp extends StatefulWidget {
  static const String routeName = "DefinePickUp";
  final Places places;

  DefinePickUp({@required this.places}) : assert(places != null);

  @override
  DefinePickUpState createState() => DefinePickUpState();
}

class DefinePickUpState extends State<DefinePickUp> {
  TextEditingController pickUpTextEditingController = TextEditingController();
  List<Address> addressPredictions;
  String sessionToken;
  bool googleMapsEnabled;
  Address initialAddress;

  @override
  void initState() {
    super.initState();

    sessionToken = Uuid().v4();

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // get relevant models
      TripModel trip = Provider.of<TripModel>(context, listen: false);
      UserModel user = Provider.of<UserModel>(context, listen: false);

// google maps is enabled if a pickUpAddress is already chosen
      googleMapsEnabled = trip.pickUpAddress != null;

      // suggest locations as user searches locations
      pickUpTextEditingController.addListener(() async {
        await textFieldListener(false, user.position);
      });
    });
  }

  @override
  void dispose() {
    pickUpTextEditingController.dispose();
    super.dispose();
  }

  Future<void> textFieldListener(bool isDropOff, Position userPosition) async {
    String location = pickUpTextEditingController.text ?? "";
    if (location.length == 0) {
      if (this.mounted) {
        setState(() {
          addressPredictions = null;
        });
      }
    } else {
      // get drop off address predictions
      List<Address> predictions = await widget.places.findAddressPredictions(
        placeName: location,
        latitude: userPosition.latitude,
        longitude: userPosition.longitude,
        sessionToken: sessionToken,
        isDropOff: isDropOff,
      );
      if (this.mounted) {
        setState(() {
          addressPredictions = predictions;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);

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
                    SvgPicture.asset(
                      "images/pickUpIcon.svg",
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
                      hintText: "Insira endereço de partida.",
                      hintColor: AppColor.disabled,
                      controller: pickUpTextEditingController,
                      autoFocus: trip.pickUpAddress == null,
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
                        primaryText: "Definir origem no mapa",
                        onTap: () async {
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
                  userPosition: user.position,
                  isDropOff: false,
                  initialAddress: trip.pickUpAddress,
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
                    onTap: () {
                      updatePickUpAndPop(context, addressPredictions[index]);
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

// updateRoute updates the drop off and pick up locations of the TripModel
void updatePickUpAndPop(
  BuildContext context,
  Address address,
) {
  TripModel tripModel = Provider.of<TripModel>(context, listen: false);

  // set location as pick up point
  tripModel.updatePickUpAddres(address);

  // go back to DefineRoute screen
  Navigator.pop(context);
}
