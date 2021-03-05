import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';

class DefineRouteArguments {
  final RouteModel routeModel;
  final GeocodingResult userGeocoding;

  DefineRouteArguments({
    @required this.routeModel,
    @required this.userGeocoding,
  }) : assert(routeModel != null);
}

class DefineRoute extends StatefulWidget {
  static const String routeName = "DefineRoute";
  final RouteModel routeModel;
  final GeocodingResult userGeocoding;

  DefineRoute({
    @required this.routeModel,
    @required this.userGeocoding,
  }) : assert(routeModel != null);

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

  @override
  void initState() {
    // TODO: review this after I finish calling a ride

    // text field initial values
    dropOffController.text = widget.routeModel.dropOffAddress != null
        ? widget.routeModel.dropOffAddress.mainText
        : "";
    pickUpController.text = "";
    final pickUpAddress = widget.routeModel.pickUpAddress;
    final userLatitude = widget.userGeocoding.latitude;
    final userLongitude = widget.userGeocoding.longitude;
    if (userLatitude != pickUpAddress.latitude ||
        userLongitude != pickUpAddress.longitude) {
      pickUpController.text = pickUpAddress.mainText;
    }

    // set button state
    setButtonState(
      pickUp: widget.routeModel.pickUpAddress,
      dropOff: widget.routeModel.dropOffAddress,
    );

    widget.routeModel.addListener(() {
      setButtonState(
        pickUp: widget.routeModel.pickUpAddress,
        dropOff: widget.routeModel.dropOffAddress,
      );
    });

    super.initState();
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
    UserPositionModel userPositionModel = Provider.of<UserPositionModel>(
      context,
      listen: false,
    );
    RouteModel routeModel = Provider.of<RouteModel>(
      context,
      listen: false,
    );

    // define variables based on whether we're choosing dropOff or not
    FocusNode focusNode = isDropOff ? dropOffFocusNode : pickUpFocusNode;
    TextEditingController controller =
        isDropOff ? dropOffController : pickUpController;
    dynamic args = isDropOff
        ? DefineDropOffArguments(
            userGeocoding: userPositionModel.geocoding,
            chosenDropOffAddress: routeModel.dropOffAddress,
          )
        : DefinePickUpArguments(
            userGeocoding: userPositionModel.geocoding,
            chosenPickUpAddress: routeModel.pickUpAddress,
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
    if (isDropOff) {
      controller.text = routeModel.dropOffAddress.mainText;
    } else {
      if (widget.routeModel.pickUpAddress.placeID !=
          widget.userGeocoding.placeID) {
        // update pick up only if it's different from current location
        controller.text = routeModel.pickUpAddress.mainText;
      } else {
        controller.text = "";
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final RouteModel routeModel = Provider.of<RouteModel>(context);
    final UserPositionModel userPos = Provider.of<UserPositionModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () {
                  Navigator.pop(context, false);
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
                Image(image: AssetImage("images/pickroute.png")),
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
              buttonColor: buttonColor,
              textData: "Pronto",
              onTapCallBack: () {
                if (activateCallback != null) {
                  Navigator.pop(context, true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
