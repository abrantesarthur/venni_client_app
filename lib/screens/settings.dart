import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/screens/privacy.dart';
import 'package:rider_frontend/screens/profile.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';
import 'package:rider_frontend/vendors/firebaseAnalytics.dart';

class Settings extends StatefulWidget {
  static const String routeName = "Settings";

  @override
  SettingsState createState() => SettingsState();
}

class SettingsState extends State<Settings> {
  bool lockScreen = false;

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final FirebaseModel firebase =
        Provider.of<FirebaseModel>(context, listen: false);
    return GoBackScaffold(
      title: "Configurações",
      onPressed: lockScreen ? () {} : () => Navigator.pop(context),
      children: [
        BorderlessButton(
          onTap: lockScreen
              ? () {}
              : () {
                  Navigator.pushNamed(context, Profile.routeName);
                },
          iconLeft: Icons.account_circle_rounded,
          iconLeftSize: 26,
          primaryText: "Perfil",
          primaryTextSize: 18,
          paddingTop: screenHeight / 80,
          paddingBottom: screenHeight / 80,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        BorderlessButton(
          onTap: lockScreen
              ? () {}
              : () {
                  Navigator.pushNamed(context, Privacy.routeName);
                },
          iconLeft: Icons.lock_rounded,
          iconLeftSize: 26,
          primaryText: "Privacidade",
          primaryTextSize: 18,
          paddingBottom: screenHeight / 80,
          paddingTop: screenHeight / 80,
        ),
        Divider(thickness: 0.1, color: Colors.black),
        Padding(
          padding: EdgeInsets.only(top: screenHeight / 80),
          child: GestureDetector(
            onTap: lockScreen
                ? () {}
                : () {
                    showYesNoDialog(
                      context,
                      title: "Deseja sair?",
                      onPressedYes: () async {
                        setState(() {
                          lockScreen = true;
                        });
                        try {
                          await firebase.analytics.logLogout();
                        } catch (e) {}
                        await firebase.auth.signOut();
                         setState(() {
                          lockScreen = false;
                        });
                      },
                    );
                  },
            child: Text(
              "Sair",
              style: TextStyle(
                fontSize: 18,
                color: AppColor.secondaryRed,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
