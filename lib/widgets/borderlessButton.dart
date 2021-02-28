import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class BorderlessButton extends StatelessWidget {
  final VoidCallback onTapCallback;
  final String primaryText;
  final String secondaryText;
  final IconData iconLeft;
  final IconData iconRight;

  BorderlessButton({
    this.primaryText,
    this.onTapCallback,
    this.secondaryText,
    this.iconLeft,
    this.iconRight,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: onTapCallback,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconLeft),
          SizedBox(width: screenWidth / 30),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                primaryText,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                ),
              ),
              secondaryText != null
                  ? Text(
                      secondaryText,
                      style: TextStyle(
                        color: AppColor.disabled,
                        fontSize: 16,
                      ),
                    )
                  : Container()
            ],
          ),
          Spacer(),
          Icon(
            iconRight,
            color: Colors.black,
            size: 16,
          )
        ],
      ),
    );
  }
}
