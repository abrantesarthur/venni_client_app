import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';

class CancelButton extends StatelessWidget {
  final VoidCallback onPressed;

  CancelButton({@required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.cancel_rounded,
        color: AppColor.primaryPink,
        size: 48,
      ),
      onPressed: onPressed,
    );
  }
}
