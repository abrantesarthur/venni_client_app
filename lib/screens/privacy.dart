import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/screens/deleteAccount.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

import '../models/models.dart';

class Privacy extends StatefulWidget {
  static const String routeName = "Privacy";

  PrivacyState createState() => PrivacyState();
}

class PrivacyState extends State<Privacy> {
  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final FirebaseModel firebase = Provider.of<FirebaseModel>(context);

    return GoBackScaffold(
      resizeToAvoidBottomInset: false,
      title: "Privacidade",
      children: [
        BorderlessButton(
          onTap: () {
            Navigator.pushNamed(context, DeleteAccount.routeName);
          },
          primaryText: "Excluir minha conta",
          iconRight: Icons.keyboard_arrow_right,
          iconRightSize: 20,
          primaryTextColor: AppColor.secondaryRed,
          primaryTextSize: 18,
        ),
      ],
    );
  }
}
