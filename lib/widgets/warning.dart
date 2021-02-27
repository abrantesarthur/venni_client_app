import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class Warning extends StatelessWidget {
  final String message;
  final Function onTapCallback;
  final Color color;

  Warning({@required this.message, this.onTapCallback, this.color});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTapCallback,
      child: Text(
        message,
        style: TextStyle(
          color: color ??
              (onTapCallback != null
                  ? AppColor.secondaryPurple
                  : AppColor.secondaryYellow),
          fontSize: 14,
        ),
      ),
    );
  }
}
