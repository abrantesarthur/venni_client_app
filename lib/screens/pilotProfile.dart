import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/pilot.dart';
import 'package:rider_frontend/widgets/circularImage.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class PilotProfile extends StatelessWidget {
  static String routeName = "PilotProfile";

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    PilotModel pilot = Provider.of<PilotModel>(context);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              children: [
                GestureDetector(
                  child: Icon(
                    Icons.clear,
                    size: 36,
                  ),
                  onTap: () => Navigator.pop(context),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 15),
            CircularImage(
              size: screenWidth / 3.2,
              imageFile: pilot.profileImage == null
                  ? AssetImage("images/user_icon.png")
                  : pilot.profileImage.file,
            ),
            SizedBox(height: screenHeight / 50),
            Text(
              pilot.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  pilot.rating.toString(),
                  style: TextStyle(fontSize: 18),
                ),
                SizedBox(width: screenWidth / 100),
                Icon(
                  Icons.star_rate,
                  size: 20,
                )
              ],
            ),
            SizedBox(height: screenHeight / 50),
            _buildInfo(context, field: "celular", value: pilot.phoneNumber),
            _buildInfo(context,
                field: "corridas realizadas",
                value: pilot.totalTrips.toString()),
            _buildInfo(context,
                field: "membro desde", value: pilot.memberSince),
            _buildInfo(context,
                field: "moto",
                value: pilot.vehicle.brand + " " + pilot.vehicle.model),
            _buildInfo(context, field: "placa", value: pilot.vehicle.plate)
          ],
        ),
      ),
    );
  }
}

Widget _buildInfo(
  BuildContext context, {
  @required String field,
  @required String value,
}) {
  final double screenHeight = MediaQuery.of(context).size.height;
  return Column(
    children: [
      SizedBox(height: screenHeight / 100),
      Divider(
        thickness: 0.1,
        color: Colors.black,
      ),
      SizedBox(height: screenHeight / 100),
      Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            field,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    ],
  );
}
