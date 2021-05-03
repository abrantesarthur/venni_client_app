import 'package:flutter/material.dart';

class FloatingCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double leftPadding;
  final double rightPadding;

  FloatingCard({
    this.width,
    @required this.child,
    this.leftPadding,
    this.rightPadding,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: width ?? screenWidth,
      padding: EdgeInsets.only(
        left: leftPadding ?? screenWidth / 15,
        right: rightPadding ?? screenWidth / 15,
      ),
      child: Material(
        type: MaterialType.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        elevation: 10.0,
        child: Padding(
          padding: EdgeInsets.all(screenWidth / 40),
          child: child,
        ),
      ),
    );
  }
}
