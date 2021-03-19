import 'package:flutter/material.dart';

class MenuButton extends StatelessWidget {
  final VoidCallback onPressed;

  MenuButton({@required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            offset: Offset(3, 3),
            spreadRadius: 1,
            blurRadius: 8,
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(
          Icons.menu_rounded,
        ),
        onPressed: onPressed,
      ),
    );
  }
}
