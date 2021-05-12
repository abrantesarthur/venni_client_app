import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/screens/insertNewPhone.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';

import '../models/firebase.dart';
import '../models/firebase.dart';

class EditPhone extends StatefulWidget {
  static const String routeName = "EditPhone";

  @override
  EditPhoneState createState() => EditPhoneState();
}

class EditPhoneState extends State<EditPhone> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;
    final FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    return GoBackScaffold(
      title: "Atualizar número de telefone",
      children: [
        Text(
          firebase.auth.currentUser.phoneNumber.withoutCountryCode(),
          style: TextStyle(
            fontSize: 16,
            color: Colors.black,
          ),
        ),
        SizedBox(height: screenHeight / 30),
        Text(
          "Mudar seu número de telefone não afetará outras informações da sua conta.",
          style: TextStyle(
            fontSize: 16,
            color: AppColor.disabled,
          ),
        ),
        Spacer(),
        AppButton(
          textData: "Atualizar Telefone",
          onTapCallBack: () async {
            final _ = await Navigator.pushNamed(
              context,
              InsertNewPhone.routeName,
            );
          },
        )
      ],
    );
  }
}
