import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class Splash extends StatelessWidget {
  final String text;

  Splash({this.text});

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image(
                    image: AssetImage("images/vertical-white-logo.png"),
                    width: 0.8 * width,
                  ),
                  text != null
                      ? Column(
                          children: [
                            SizedBox(height: height / 40),
                            Text(text,
                                style: TextStyle(
                                  fontSize: 26,
                                  fontFamily: "OpenSans",
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ))
                          ],
                        )
                      : Container()
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
