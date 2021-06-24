import 'package:cloud_functions/cloud_functions.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';
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
  FocusNode dropOffFocusNode = FocusNode();
  FocusNode pickUpFocusNode = FocusNode();
  TextEditingController dropOffController = TextEditingController();
  TextEditingController pickUpController = TextEditingController();
  String warning;
  Color buttonColor;
  bool activateCallback;
  Widget buttonChild;
  UserModel _user;
  TripModel _trip;
  bool lockScreen;
  var _tripListener;

  @override
  void initState() {
    super.initState();

    lockScreen = false;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // get relevant models
      _trip = Provider.of<TripModel>(context, listen: false);
      _user = Provider.of<UserModel>(context, listen: false);

      // pickUp location defaults to user's current address
      if (_trip.pickUpAddress == null) {
        _trip.updatePickUpAddres(Address.fromGeocodingResult(
          geocodingResult: _user.geocoding,
          dropOff: false,
        ));
      }

      // text field initial values
      dropOffController.text =
          _trip.dropOffAddress != null ? _trip.dropOffAddress.mainText : "";
      pickUpController.text = "";
      final pickUpAddress = _trip.pickUpAddress;
      final userLatitude = _user.geocoding?.latitude;
      final userLongitude = _user.geocoding?.longitude;
      // change pick up text field only if it's different from user location
      if (userLatitude != pickUpAddress?.latitude ||
          userLongitude != pickUpAddress?.longitude) {
        pickUpController.text = pickUpAddress?.mainText;
      }

      // set button state
      setButtonState(
        pickUp: _trip.pickUpAddress,
        dropOff: _trip.dropOffAddress,
      );

      _tripListener = () {
        setButtonState(
          pickUp: _trip.pickUpAddress,
          dropOff: _trip.dropOffAddress,
        );
      };

      _trip.addListener(_tripListener);
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
    _trip.removeListener(_tripListener);
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
    UserModel userPos = Provider.of<UserModel>(
      context,
      listen: false,
    );
    TripModel route = Provider.of<TripModel>(context, listen: false);
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );

    // define variables based on whether we're choosing dropOff or not
    FocusNode focusNode = isDropOff ? dropOffFocusNode : pickUpFocusNode;
    TextEditingController controller =
        isDropOff ? dropOffController : pickUpController;
    String routeName =
        isDropOff ? DefineDropOff.routeName : DefinePickUp.routeName;

    // unfocus text fields to make it behave like a button
    focusNode.unfocus();

    // make sure user is connected to the internet
    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(context);
      return;
    }

    // push screen to allow user to select an address
    await Navigator.pushNamed(context, routeName);

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
    // make sure user is connected to the internet
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(context);
      return;
    }

    // show loading icon and lock screen
    setState(() {
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
      lockScreen = true;
    });

    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);

    // RideRequestResult result;
    Trip result;
    if (widget.mode == DefineRouteMode.request) {
      try {
        result = await firebase.functions.requestTrip(RequestTripArguments(
          originPlaceID: trip.pickUpAddress.placeID,
          destinationPlaceID: trip.dropOffAddress.placeID,
        ));
      } on FirebaseFunctionsException catch (e) {
        // TODO: handle by updating the UI;
        lockScreen = false;
      }
    } else if (widget.mode == DefineRouteMode.edit) {
      try {
        // send ride request to retrieve fare price, ride distance, polyline, etc.
        result = await firebase.functions.editTrip(EditTripArguments(
          originPlaceID: trip.pickUpAddress.placeID,
          destinationPlaceID: trip.dropOffAddress.placeID,
        ));
      } on FirebaseFunctionsException catch (e) {
        // TODO: handle by updating the UI;
        lockScreen = false;
      }
    }

    // update trip with response
    trip.fromRequestTripResult(result);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return GoBackScaffold(
      resizeToAvoidBottomInset: false,
      lockScreen: lockScreen,
      children: [
        Text(
          "Escolha o ponto de partida e o destino.",
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
        SizedBox(height: screenHeight / 40),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            SvgPicture.asset(
              "images/dropOffToPickUpIcon.svg",
              width: screenWidth / 36,
            ),
            Column(
              children: [
                AppInputText(
                    fontSize: 16,
                    width: screenWidth / 1.3,
                    hintText: "Localização atual selecionada",
                    focusNode: pickUpFocusNode,
                    controller: pickUpController,
                    maxLines: null,
                    onTapCallback: () async {
                      if (!lockScreen) {
                        await textFieldCallback(
                          context: context,
                          isDropOff: false,
                        );
                      }
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
                    if (!lockScreen) {
                      await textFieldCallback(
                        context: context,
                        isDropOff: true,
                      );
                    }
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
            if (activateCallback == true && !lockScreen) {
              buttonCallback(context);
            }
          },
        ),
      ],
    );
  }
}
