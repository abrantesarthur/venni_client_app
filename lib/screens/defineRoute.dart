import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/cloud_functions/rideService.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';

enum DefineRouteMode {
  request,
  edit,
}

class DefineRouteArguments {
  final DefineRouteMode mode;

  DefineRouteArguments({
    @required this.mode,
  });
}

class DefineRoute extends StatefulWidget {
  static const String routeName = "DefineRoute";
  final DefineRouteMode mode;

  DefineRoute({
    @required this.mode,
  });

  @override
  DefineRouteState createState() => DefineRouteState();
}

class DefineRouteState extends State<DefineRoute> {
  List<Address> addressPredictions;
  FocusNode dropOffFocusNode = FocusNode();
  FocusNode pickUpFocusNode = FocusNode();
  TextEditingController dropOffController = TextEditingController();
  TextEditingController pickUpController = TextEditingController();
  String warning;
  Color buttonColor;
  bool activateCallback;
  Widget buttonChild;

// TODO: get models using postFrameCallback method
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // get relevant models
      RouteModel route = Provider.of<RouteModel>(context, listen: false);
      UserPositionModel userPos =
          Provider.of<UserPositionModel>(context, listen: false);

      // pickUp location defaults to user's current address
      if (route.pickUpAddress == null) {
        route.updatePickUpAddres(Address.fromGeocodingResult(
          geocodingResult: userPos.geocoding,
          dropOff: false,
        ));
      }

      // text field initial values
      dropOffController.text =
          route.dropOffAddress != null ? route.dropOffAddress.mainText : "";
      pickUpController.text = "";
      final pickUpAddress = route.pickUpAddress;
      final userLatitude = userPos.geocoding.latitude;
      final userLongitude = userPos.geocoding.longitude;
      // change pick up text field only if it's different from user location
      if (userLatitude != pickUpAddress.latitude ||
          userLongitude != pickUpAddress.longitude) {
        pickUpController.text = pickUpAddress.mainText;
      }

      // set button state
      setButtonState(
        pickUp: route.pickUpAddress,
        dropOff: route.dropOffAddress,
      );

      route.addListener(() {
        setButtonState(
          pickUp: route.pickUpAddress,
          dropOff: route.dropOffAddress,
        );
      });
    });
  }

  @override
  void setState(fn) {
    if (mounted) {
      super.setState(fn);
    }
  }

  @override
  void dispose() {
    dropOffController.dispose();
    pickUpController.dispose();
    dropOffFocusNode.dispose();
    pickUpFocusNode.dispose();
    super.dispose();
  }

  void setButtonState({@required Address pickUp, @required Address dropOff}) {
    // not allow user to pick route if they haven't pick both addresses
    if (pickUp == null || dropOff == null) {
      setState(() {
        warning = null;
        buttonColor = AppColor.disabled;
        activateCallback = false;
      });
    } else {
      // display warning if both addresses are equal
      if (pickUp.placeID == dropOff.placeID) {
        setState(() {
          warning =
              "O endereço de partida e o destino são iguais. Tente novamente.";
          buttonColor = AppColor.disabled;
          activateCallback = false;
        });
      } else {
        // otherwise, allow user to pick route
        setState(() {
          warning = null;
          buttonColor = AppColor.primaryPink;
          activateCallback = true;
        });
      }
    }
  }

  // onTapCallback pushes new screen where user can pick an address
  Future<void> textFieldCallback({
    @required BuildContext context,
    @required bool isDropOff,
  }) async {
    UserPositionModel userPos = Provider.of<UserPositionModel>(
      context,
      listen: false,
    );
    RouteModel route = Provider.of<RouteModel>(context, listen: false);

    // define variables based on whether we're choosing dropOff or not
    FocusNode focusNode = isDropOff ? dropOffFocusNode : pickUpFocusNode;
    TextEditingController controller =
        isDropOff ? dropOffController : pickUpController;
    // TODO: probably don't have to pass userGeocoding or dropOffAddres
    dynamic args = isDropOff
        ? DefineDropOffArguments(
            userGeocoding: userPos.geocoding,
            chosenDropOffAddress: route.dropOffAddress,
            mode: widget.mode,
          )
        : DefinePickUpArguments(
            userGeocoding: userPos.geocoding,
            chosenPickUpAddress: route.pickUpAddress,
            mode: widget.mode,
          );
    String routeName =
        isDropOff ? DefineDropOff.routeName : DefinePickUp.routeName;

    // unfocus text fields to make it behave like a button
    focusNode.unfocus();

    // push screen to allow user to select an address
    await Navigator.pushNamed(
      context,
      routeName,
      arguments: args,
    ) as Address;

    // add selected address to text field
    if (isDropOff && route.dropOffAddress != null) {
      controller.text = route.dropOffAddress.mainText;
    } else {
      if (route.pickUpAddress.placeID != userPos.geocoding.placeID) {
        // update pick up only if it's different from current location
        controller.text = route.pickUpAddress.mainText;
      } else {
        controller.text = "";
      }
    }
  }

  // buttonCallback enriches pickUp and dropOff addresses with coordinates before
  // returning to previous screen
  void buttonCallback(BuildContext context) async {
    // show loading icon
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    RouteModel route = Provider.of<RouteModel>(context, listen: false);

    // get user ID token from firebase
    String userIdToken = await firebase.auth.currentUser.getIdToken();

    // send ride request to retrieve fare price, ride distance, polyline, etc.
    Ride ride = Ride(userIdToken: userIdToken);
    RideRequestResponse response = await ride.request(
      originPlaceID: route.pickUpAddress.placeID,
      destinationPlaceID: route.dropOffAddress.placeID,
    );

    if (response.isOkay) {
      // update route model
      route.fromRideRequest(response.result);
    } else {
      // TODO: handle errors or at least not return true
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () {
                  Navigator.pop(context);
                }),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Escolha o ponto de partida e o destino.",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            SizedBox(height: screenHeight / 40),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // TODO: render icon with higher definition
                SvgPicture.asset(
                  "images/dropOffToPickUpIcon.svg",
                  width: screenWidth / 36,
                ),
                Column(
                  children: [
                    AppInputText(
                        fontSize: 16,
                        width: screenWidth / 1.3,
                        hintText: "Localização atual",
                        focusNode: pickUpFocusNode,
                        controller: pickUpController,
                        maxLines: null,
                        onTapCallback: () async {
                          await textFieldCallback(
                            context: context,
                            isDropOff: false,
                          );
                        }),
                    SizedBox(height: screenHeight / 100),
                    // output to a builder function
                    AppInputText(
                      fontSize: 16,
                      width: screenWidth / 1.3,
                      hintText: "Para onde?",
                      focusNode: dropOffFocusNode,
                      controller: dropOffController,
                      maxLines: null,
                      onTapCallback: () async {
                        await textFieldCallback(
                          context: context,
                          isDropOff: true,
                        );
                      },
                      hintColor: AppColor.disabled,
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: screenWidth / 20),
            warning != null ? Warning(message: warning) : Container(),
            Spacer(),
            AppButton(
              child: buttonChild,
              buttonColor: buttonColor,
              textData: "Pronto",
              onTapCallBack: () async {
                if (activateCallback == true) {
                  buttonCallback(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
