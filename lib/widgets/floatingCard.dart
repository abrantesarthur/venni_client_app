import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class FloatingCard extends StatelessWidget {
  final double top;
  final double bottom;
  final Widget child;

  FloatingCard({
    this.bottom,
    this.top,
    @required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return Positioned(
      top: top,
      bottom: bottom,
      child: Container(
        width: width,
        padding: EdgeInsets.only(
          left: width / 15,
          right: width / 15,
        ),
        child: Material(
          type: MaterialType.card,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 8.0,
          child: Padding(
            padding: EdgeInsets.all(width / 40),
            child: child,
          ),
        ),
      ),
    );
  }
}
