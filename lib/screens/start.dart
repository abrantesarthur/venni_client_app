import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/insertPhone.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Start extends StatelessWidget {
  static const String routeName = "login";

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;
    return Scaffold(
      body: Center(
        child: OverallPadding(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 3),
              Image(
                image: AssetImage("images/horizontal-pink-logo.png"),
                width: width * 0.8,
              ),
              Spacer(flex: 3),
              Text(
                "Chame uma corrida",
                style: TextStyle(
                  fontFamily: "OpenSans",
                  fontWeight: FontWeight.bold,
                  fontSize: 30,
                ),
              ),
              Spacer(flex: 5),
              AppButton(
                textData: "Começar",
                iconRight: Icons.arrow_forward,
                onTapCallBack: () {
                  Navigator.pushNamed(context, InsertPhone.routeName);
                },
              ),
              Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
