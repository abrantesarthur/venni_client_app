import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class BorderlessButton extends StatelessWidget {
  final VoidCallback onTap;
  final String primaryText;
  final String secondaryText;
  final IconData iconLeft;
  final double iconLeftSize;
  final IconData iconRight;
  final double iconRightSize;
  final Color iconRightColor;

  final double primaryTextSize;
  final double secondaryTextSize;
  final Color primaryTextColor;
  final double paddingTop;
  final double paddingBottom;
  final String label;
  final Color labelColor;

  BorderlessButton({
    this.primaryTextColor,
    this.iconLeftSize,
    this.iconRightSize,
    this.iconRightColor,
    this.primaryTextSize,
    this.secondaryTextSize,
    this.primaryText,
    this.onTap,
    this.secondaryText,
    this.iconLeft,
    this.iconRight,
    this.paddingBottom,
    this.paddingTop,
    this.label,
    this.labelColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
          top: paddingTop ?? 0,
          bottom: paddingBottom ?? 0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            iconLeft != null
                ? Row(children: [
                    Icon(
                      iconLeft,
                      size: iconLeftSize ?? 18,
                    ),
                    SizedBox(width: screenWidth / 30),
                  ])
                : Container(),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    primaryText,
                    style: TextStyle(
                      color: primaryTextColor ?? Colors.black,
                      fontSize: primaryTextSize ?? 16,
                    ),
                  ),
                  secondaryText != null
                      ? Container(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            secondaryText,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColor.disabled,
                              fontSize: secondaryTextSize ?? 13,
                            ),
                          ),
                        )
                      : Container()
                ],
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                label != null
                    ? Padding(
                        padding: EdgeInsets.only(
                          right: screenWidth / 100,
                          left: screenWidth / 100,
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 13,
                            color: labelColor ?? Colors.green,
                          ),
                        ),
                      )
                    : Container(),
                Icon(
                  iconRight,
                  color: iconRightColor ?? AppColor.disabled,
                  size: iconRightSize ?? 18,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
