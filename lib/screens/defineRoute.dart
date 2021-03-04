import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class DefineRoute extends StatefulWidget {
  static const String routeName = "DefineRoute";

  @override
  DefineRouteState createState() => DefineRouteState();
}

class DefineRouteState extends State<DefineRoute> {
  List<Address> addressPredictions;
  FocusNode dropOffFocusNode = FocusNode();
  FocusNode pickUpFocusNode = FocusNode();
  TextEditingController dropOffController = TextEditingController();
  TextEditingController pickUpController = TextEditingController();

  @override
  void initState() {
    dropOffController.text = "";
    pickUpController.text = "";
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
    final address = await Navigator.pushNamed(
      context,
      routeName,
      arguments: args,
    ) as Address;

    // add selected address to text field
    controller.text = address.mainText;
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final RouteModel routeModel = Provider.of<RouteModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () {
                  // TODO: might need to issue a cancel request
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
            Spacer(),
            AppButton(
              buttonColor: routeModel.dropOffAddress != null &&
                      routeModel.pickUpAddress != null
                  ? AppColor.primaryPink
                  : AppColor.disabled,
              textData: "Pronto",
              onTapCallBack: routeModel.dropOffAddress != null &&
                      routeModel.pickUpAddress != null
                  ? () => Navigator.pop(context)
                  : () {},
            ),
          ],
        ),
      ),
    );
  }
}
