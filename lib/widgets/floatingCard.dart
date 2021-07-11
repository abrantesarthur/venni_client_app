import 'package:flutter/material.dart';

class FloatingCard extends StatelessWidget {
  final Widget child;
  final double width;
  final double leftMargin;
  final double rightMargin;
  final double topMargin;
  final double leftPadding;
  final double rightPadding;
  final double borderRadius;
  final int flex;

  FloatingCard({
    this.width,
    @required this.child,
    this.leftMargin,
    this.rightMargin,
    this.topMargin,
    this.borderRadius,
    this.leftPadding,
    this.rightPadding,
    this.flex,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    Widget buildMaterial() {
      return Material(
        type: MaterialType.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 10),
        ),
        elevation: 10.0,
        child: Padding(
          padding: EdgeInsets.only(
            left: leftPadding ?? screenWidth / 30,
            right: rightPadding ?? screenWidth / 30,
            top: screenHeight / 80,
            bottom: screenHeight / 80,
          ),
          child: child,
        ),
      );
    }

    return this.flex != null
        ? Expanded(
            flex: flex,
            child: buildMaterial(),
          )
        : Container(
            width: width ?? screenWidth,
            padding: EdgeInsets.only(
              left: leftMargin ?? screenWidth / 15,
              right: rightMargin ?? screenWidth / 15,
              top: topMargin ?? 0,
            ),
            child: buildMaterial(),
          );
  }
}
