import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/widgets/circularImage.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class PartnerProfile extends StatelessWidget {
  static String routeName = "PartnerProfile";

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    PartnerModel partner = Provider.of<PartnerModel>(context);

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
              imageFile: partner.profileImage == null
                  ? AssetImage("images/user_icon.png")
                  : partner.profileImage.file,
            ),
            SizedBox(height: screenHeight / 50),
            Text(
              partner.name,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  partner.rating.toString(),
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
            _buildInfo(context,
                field: "celular", value: partner.phoneNumber ?? ""),
            _buildInfo(context,
                field: "corridas realizadas",
                value: partner.totalTrips?.toString() ?? ""),
            _buildInfo(context,
                field: "membro desde", value: partner.memberSince ?? ""),
            _buildInfo(context,
                field: "moto",
                value: (partner.vehicle?.brand ?? "") +
                    " - " +
                    (partner.vehicle?.model ?? "")),
            _buildInfo(context,
                field: "placa", value: partner.vehicle?.plate ?? "")
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
