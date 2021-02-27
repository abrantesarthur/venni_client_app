import 'package:flutter/material.dart';

class OverallPadding extends StatelessWidget {
  final Widget child;

  OverallPadding({@required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(left: 25.0, right: 25.0, top: 70.0, bottom: 70.0),
      child: child,
    );
  }
}
