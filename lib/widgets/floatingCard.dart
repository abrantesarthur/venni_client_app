import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class FloatingCard extends StatelessWidget {
  final double top;
  final double bottom;
  final Widget child;
  final double width;

  FloatingCard({
    this.width,
    this.bottom,
    this.top,
    @required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: width,
      padding: EdgeInsets.only(
        left: screenWidth / 15,
        right: screenWidth / 15,
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
