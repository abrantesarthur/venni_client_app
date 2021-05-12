import 'package:flutter/material.dart';
import 'package:rider_frontend/widgets/goBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class GoBackScaffold extends StatelessWidget {
  static const String routeName = "GoBackScaffold";

  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final bool resizeToAvoidBottomInset;
  final String title;
  final bool lockScreen;
  final IconData goBackIcon;
  final TextStyle titleStyle;
  final double paddingLeft;
  final double paddingRight;

  GoBackScaffold({
    @required this.children,
    this.crossAxisAlignment,
    this.resizeToAvoidBottomInset,
    this.title,
    this.lockScreen,
    this.goBackIcon,
    this.titleStyle,
    this.paddingLeft,
    this.paddingRight,
  });

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset ?? false,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GoBackButton(
                  icon: goBackIcon,
                  onPressed: lockScreen != null && lockScreen
                      ? () {}
                      : () {
                          Navigator.pop(context);
                        },
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 15),
            title != null
                ? Column(children: [
                    Text(
                      title,
                      style: titleStyle ??
                          TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                              color: Colors.black),
                    ),
                    SizedBox(height: screenHeight / 30),
                  ])
                : Container(),
            for (var w in children) w,
          ],
        ),
      ),
    );
  }
}
