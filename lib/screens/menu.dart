import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/userData.dart';
import 'package:rider_frontend/screens/settings.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class Menu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final double screenWidth = MediaQuery.of(context).size.width;
    final UserDataModel userData = Provider.of<UserDataModel>(context);
    final FirebaseModel firebase = Provider.of<FirebaseModel>(context);

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
                  Container(
                    width: screenHeight / 7,
                    height: screenHeight / 7,
                    decoration: new BoxDecoration(
                      shape: BoxShape.circle,
                      image: new DecorationImage(
                        fit: BoxFit.cover,
                        image: userData.profileImage == null
                            ? AssetImage("images/user_icon.png")
                            : userData.profileImage.file,
                      ),
                    ),
                  ),
                  Spacer(),
                  Text(
                    firebase.auth.currentUser != null
                        ? firebase.auth.currentUser.displayName
                        : "",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  userData.rating != null
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              userData.rating.toString(),
                              style: TextStyle(fontSize: 15.0),
                            ),
                            SizedBox(width: screenWidth / 80),
                            Icon(Icons.star_rate,
                                size: 18, color: Colors.black87),
                          ],
                        )
                      : Container(),
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
                  paddingBottom: screenHeight / 80,
                ),
                Divider(thickness: 0.1, color: Colors.black),
                BorderlessButton(
                  iconLeft: Icons.payment_rounded,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Pagamento",
                  primaryTextSize: 18,
                  paddingTop: screenHeight / 80,
                  paddingBottom: screenHeight / 80,
                ),
                Divider(thickness: 0.1, color: Colors.black),
                BorderlessButton(
                  onTap: () {
                    Navigator.pushNamed(context, Settings.routeName);
                  },
                  iconLeft: Icons.settings,
                  iconRight: Icons.keyboard_arrow_right,
                  primaryText: "Configurações",
                  primaryTextSize: 18,
                  paddingTop: screenHeight / 80,
                  paddingBottom: screenHeight / 80,
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
