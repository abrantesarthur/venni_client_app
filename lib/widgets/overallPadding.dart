import 'package:flutter/material.dart';

class OverallPadding extends StatelessWidget {
  final Widget child;
  final double bottom;

  OverallPadding({@required this.child, this.bottom});

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.only(
        left: width / 15,
        right: width / 15,
        top: height / 12,
        bottom: bottom ?? height / 12,
      ),
      child: child,
    );
  }
}
