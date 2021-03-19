import 'package:flutter/material.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Menu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;

    return Drawer(
      child: ListView(
        children: [
          Container(
            height: screenHeight / 3.5,
            child: DrawerHeader(
              decoration: BoxDecoration(color: Colors.white),
              child: Column(
                children: [
                  Spacer(flex: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.asset(
                      "images/user_icon.png", // TODO: download from backend
                      height: 100.0,
                      width: 100.0,
                    ),
                  ),
                  Spacer(),
                  Text(
                    "Ana da Silva",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "4.96", // TODO: make dynamic
                        style: TextStyle(fontSize: 15.0),
                      ),
                      SizedBox(width: screenWidth / 80),
                      Icon(Icons.star_rate, size: 18, color: Colors.black87),
                    ],
                  ),
                  Spacer(flex: 2),
                ],
              ),
            ),
          ),
          SizedBox(height: screenHeight / 50),
          OverallPadding(
            top: 0,
            child: Column(
              children: [
                BorderlessButton(
                  iconLeft: Icons.featured_play_list_rounded,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Minhas Viagens",
                  primaryTextSize: 18,
                ),
                _buildDivider(screenHeight, screenWidth),
                BorderlessButton(
                  iconLeft: Icons.payment_rounded,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Pagamento",
                  primaryTextSize: 18,
                ),
                _buildDivider(screenHeight, screenWidth),
                BorderlessButton(
                  iconLeft: Icons.settings,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Configurações",
                  primaryTextSize: 18,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

Widget _buildDivider(double screenHeight, double screenWidth) {
  return Column(children: [
    SizedBox(height: screenHeight / 50),
    Divider(
      height: 0,
      color: Colors.black,
      thickness: 0.1,
    ),
    SizedBox(height: screenHeight / 50),
  ]);
}
