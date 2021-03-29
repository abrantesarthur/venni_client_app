import 'package:flutter/material.dart';

class GoBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  GoBackButton({@required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      child: Icon(
        Icons.arrow_back,
        size: 36,
      ),
      onTap: onPressed,
    );
  }
}
