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
      behavior: HitTestBehavior.translucent,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(iconLeft),
          SizedBox(width: screenWidth / 30),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  primaryText,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                  ),
                ),
                secondaryText != null
                    ? Text(
                        secondaryText,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColor.disabled,
                          fontSize: 13,
                        ),
                      )
                    : Container()
              ],
            ),
          ),
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
