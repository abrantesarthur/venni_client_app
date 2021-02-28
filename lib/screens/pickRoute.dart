import 'package:flutter/material.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class PickRoute extends StatefulWidget {
  static const String routeName = "PickRoute";

  @override
  PickRouteState createState() => PickRouteState();
}

class PickRouteState extends State<PickRoute> {
  TextEditingController dropOffTextEditingController = TextEditingController();

  @override
  void initState() {
    super.initState();

    // suggest drop off locations as user types text
    dropOffTextEditingController.addListener(() {
      String dropOff = dropOffTextEditingController.text ?? "";
    });
  }

  @override
  void dispose() {
    dropOffTextEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      // TODO: decide between single child scroll view and fixed
      body: OverallPadding(
        child: Column(
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () => Navigator.pop(context)),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image(image: AssetImage("images/pickroute.png")),
                Column(
                  children: [
                    // TODO: open map when tapping "localização atual"
                    AppInputText(
                      width: screenWidth / 1.3,
                      hintText: "Localização atual",
                      onTapCallback: () {
                        Navigator.pop(context);
                      },
                    ),
                    SizedBox(height: screenHeight / 50),
                    AppInputText(
                      width: screenWidth / 1.3,
                      hintText: "Para onde?",
                    ),
                  ],
                )
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Divider(thickness: 0.3, color: Colors.black),
            SizedBox(height: screenHeight / 100),
            BorderlessButton(
              // TODO: define this
              onTapCallback: () {},
              iconLeft: Icons.add_location,
              iconRight: Icons.keyboard_arrow_right,
              primaryText: "Definir local no mapa",
            ),
            SizedBox(height: screenHeight / 100),
            Divider(thickness: 0.1, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
