import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Splash extends StatelessWidget {
  final String text;
  final Widget button;
  final VoidCallback onTap;

  Splash({this.text, this.button, this.onTap});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            final width = MediaQuery.of(context).size.width;
            final height = MediaQuery.of(context).size.height;
            return Container(
              color: AppColor.primaryPink,
              alignment: Alignment.center,
              child: OverallPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image(
                      image: AssetImage("images/icon-white.png"),
                      width: 0.25 * width,
                    ),
                    text != null
                        ? Column(
                            children: [
                              SizedBox(height: height / 40),
                              Text(text,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontFamily: "OpenSans",
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ))
                            ],
                          )
                        : Container(),
                    SizedBox(height: height / 20),
                    button != null ? button : Container(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
