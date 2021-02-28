import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class AppButton extends StatelessWidget {
  final String textData;
  final IconData iconRight;
  final IconData iconLeft;
  final VoidCallback onTapCallBack;

  AppButton({
    @required this.textData,
    this.iconRight,
    this.iconLeft,
    @required this.onTapCallBack,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCallBack,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100.0),
          color: AppColor.primaryPink,
        ),
        height: 80,
        child: Stack(
          children: [
            this.iconLeft != null
                ? Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                        padding: EdgeInsets.only(left: 30),
                        child: Icon(iconLeft, color: Colors.white, size: 24)))
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
                        padding: EdgeInsets.only(right: 30),
                        child: Icon(iconRight, color: Colors.white, size: 24)))
                : Container()
          ],
        ),
      ),
    );
  }
}
