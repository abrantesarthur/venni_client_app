import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/insertPhone.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Start extends StatelessWidget {
  static const String routeName = "login";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: OverallPadding(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Spacer(flex: 2),
              Image(image: AssetImage("images/logo.png")),
              Spacer(),
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
