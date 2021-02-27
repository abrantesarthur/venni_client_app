import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';

class InsertNameArguments {
  final UserCredential userCredential;
  final String userEmail;
  InsertNameArguments({
    @required this.userCredential,
    @required this.userEmail,
  });
}

class InsertName extends StatefulWidget {
  static const routeName = "InsertName";

  final UserCredential userCredential;
  final String userEmail;
  InsertName({
    @required this.userCredential,
    @required this.userEmail,
  });

  @override
  InsertNameState createState() => InsertNameState();
}

class InsertNameState extends State<InsertName> {
  Color circularButtonColor;
  Function circularButtonCallback;
  TextEditingController nameTextEditingController = TextEditingController();
  TextEditingController surnameTextEditingController = TextEditingController();
  FocusNode nameFocusNode = FocusNode();
  FocusNode surnameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    circularButtonColor = AppColor.disabled;
    nameTextEditingController.addListener(() {
      controllerListener(
        nameTextEditingController.text ?? "",
        surnameTextEditingController.text ?? "",
      );
    });
    surnameTextEditingController.addListener(() {
      controllerListener(
        nameTextEditingController.text ?? "",
        surnameTextEditingController.text ?? "",
      );
    });
  }

  @override
  void dispose() {
    nameTextEditingController.dispose();
    surnameTextEditingController.dispose();
    nameFocusNode.dispose();
    surnameFocusNode.dispose();
    super.dispose();
  }

  void controllerListener(String name, String surname) {
    if (name.length > 1 && surname.length > 1) {
      setState(() {
        circularButtonCallback = buttonCallback;
        circularButtonColor = AppColor.primaryPink;
      });
    } else {
      setState(() {
        circularButtonCallback = null;
        circularButtonColor = AppColor.disabled;
      });
    }
  }

  // buttonCallback checks whether email is valid and not already used.
  // it displays warning in case the email is invalid and redirects user
  // to next registration screen in case the email is valid.
  void buttonCallback(BuildContext context) async {
    Navigator.pushNamed(
      context,
      InsertPassword.routeName,
      arguments: InsertPasswordArguments(
          userCredential: widget.userCredential,
          name: nameTextEditingController.text,
          surname: surnameTextEditingController.text,
          userEmail: widget.userEmail),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(onTapCallback: () => Navigator.pop(context)),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 25),
            Text(
              "Insira o seu nome e sobrenome",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            SizedBox(height: screenHeight / 40),
            Warning(
              color: AppColor.disabled,
              message:
                  "Usaremos seu nome para conseguir te identificar durante corridas e comunicações.",
            ),
            SizedBox(height: screenHeight / 40),
            AppInputText(
              autoFocus: true,
              focusNode: nameFocusNode,
              onSubmittedCallback: (String name) {
                nameFocusNode.unfocus();
                FocusScope.of(context).requestFocus(surnameFocusNode);
              },
              hintText: "nome",
              controller: nameTextEditingController,
              inputFormatters: [LengthLimitingTextInputFormatter(32)],
            ),
            SizedBox(height: screenHeight / 40),
            AppInputText(
              focusNode: surnameFocusNode,
              hintText: "sobrenome",
              controller: surnameTextEditingController,
              inputFormatters: [LengthLimitingTextInputFormatter(32)],
            ),
            Spacer(),
            Row(
              children: [
                Spacer(),
                CircularButton(
                  buttonColor: circularButtonColor,
                  child: Icon(
                    Icons.arrow_forward,
                    color: Colors.white,
                    size: 36,
                  ),
                  onPressedCallback: circularButtonCallback == null
                      ? () {}
                      : () => buttonCallback(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
