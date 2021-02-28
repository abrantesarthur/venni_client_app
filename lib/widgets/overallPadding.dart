import 'package:flutter/material.dart';

class OverallPadding extends StatelessWidget {
  final Widget child;

  OverallPadding({@required this.child});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Padding(
      padding:
          EdgeInsets.only(left: screenHeight/33, right: screenHeight/33, top: screenHeight/12, bottom: screenHeight/12,),
      child: child,
    );
  }
}
