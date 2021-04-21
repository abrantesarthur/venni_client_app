import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/screens/privacy.dart';
import 'package:rider_frontend/screens/profile.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

class Settings extends StatelessWidget {
  static const String routeName = "Settings";

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final FirebaseModel firebase =
        Provider.of<FirebaseModel>(context, listen: false);
    return GoBackScaffold(
      title: "Configurações",
      children: [
        BorderlessButton(
          onTap: () {
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
          onTap: () {
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
            onTap: () {
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return YesNoDialog(
                      title: "Deseja sair?",
                      onPressedYes: () {
                        firebase.auth.signOut();
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
