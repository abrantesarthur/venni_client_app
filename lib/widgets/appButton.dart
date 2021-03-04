import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class AppButton extends StatelessWidget {
  final String textData;
  final double borderRadius;
  final IconData iconRight;
  final IconData iconLeft;
  final Color buttonColor;
  final VoidCallback onTapCallBack;

  AppButton({
    @required this.textData,
    this.iconRight,
    this.iconLeft,
    this.borderRadius,
    this.buttonColor,
    @required this.onTapCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCallBack,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius ?? 100.0),
          color: buttonColor ?? AppColor.primaryPink,
        ),
        height: 80,
        child: Stack(
          children: [
            this.iconLeft != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 20),
                      child: Icon(iconLeft, color: Colors.white, size: 24),
                    ))
                : Container(),
            Center(
              child: Text(
                textData,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white),
              ),
            ),
            this.iconRight != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: EdgeInsets.only(right: 20),
                        child: Icon(iconRight, color: Colors.white, size: 24)))
                : Container()
          ],
        ),
      ),
    );
  }
}
