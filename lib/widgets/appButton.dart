import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class AppButton extends StatelessWidget {
  final String textData;
  final IconData iconData;
  final VoidCallback onTapCallBack;

  AppButton({
    @required this.textData,
    this.iconData,
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
            Center(
              child: Text(
                textData,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    color: Colors.white),
              ),
            ),
            this.iconData != null
                ? Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                        padding: EdgeInsets.only(right: 30),
                        child: Icon(Icons.arrow_forward, color: Colors.white)))
                : Container()
          ],
        ),
      ),
    );
  }
}
