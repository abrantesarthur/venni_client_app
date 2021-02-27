import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/screens/insertName.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';

class InsertEmailArguments {
  final UserCredential userCredential;
  InsertEmailArguments({@required this.userCredential});
}

class InsertEmail extends StatefulWidget {
  static const routeName = "InsertEmail";
  final UserCredential userCredential;

  InsertEmail({@required this.userCredential});

  @override
  InsertEmailState createState() => InsertEmailState();
}

class InsertEmailState extends State<InsertEmail> {
  Warning warningMessage;
  Color circularButtonColor;
  Function circularButtonCallback;
  Widget _circularButtonChild;
  TextEditingController emailTextEditingController = TextEditingController();
  FirebaseAuth _firebaseAuth;

  @override
  void initState() {
    super.initState();
    circularButtonColor = AppColor.disabled;
    _circularButtonChild = Icon(
      Icons.arrow_forward,
      color: Colors.white,
      size: 36,
    );
    emailTextEditingController.addListener(() {
      String email = emailTextEditingController.text ?? "";
      if (email != null && email.isValidEmail()) {
        setState(() {
          warningMessage = null;
          circularButtonCallback = buttonCallback;
          circularButtonColor = AppColor.primaryPink;
        });
      } else {
        setState(() {
          circularButtonCallback = null;
          circularButtonColor = AppColor.disabled;
        });
      }
    });
  }

  @override
  void dispose() {
    emailTextEditingController.dispose();
    super.dispose();
  }

  // buttonCallback checks whether email is valid and not already used.
  // it displays warning in case the email is invalid and redirects user
  // to next registration screen in case the email is valid.
  void buttonCallback(BuildContext context) async {
    // display progress while verification happens
    setState(() {
      _circularButtonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    bool validEmail;
    String warning;
    try {
      // try to sign in with provided email
      await _firebaseAuth.signInWithEmailAndPassword(
        email: emailTextEditingController.text,
        password: "WronggndoisngPassword!135",
      );
      // in the unlikely case sign in succeeds, sign back out
      _firebaseAuth.signOut();
      // return false because there is already an account with the email;
      warning = "O email já está sendo usado. Tente outro.";
      validEmail = false;
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        // user not found means there is no account with the email
        validEmail = true;
      } else if (e.code == "wrong-password") {
        // wrong password means the email is already registered
        warning = "O email já está sendo usado. Tente outro.";
        validEmail = false;
      } else if (e.code == "invalid-email") {
        // display appropriate message
        warning = "Email inválido. Tente outro.";
        validEmail = false;
      } else {
        warning = "O email não pode ser usado. Tente outro.";
        validEmail = false;
      }
    }

    // stop progress
    setState(() {
      _circularButtonChild = Icon(
        Icons.arrow_forward,
        color: Colors.white,
        size: 36,
      );
    });

    if (warning != null) {
      setState(() {
        warningMessage = Warning(message: warning);
        circularButtonCallback = null;
        circularButtonColor = AppColor.disabled;
      });
    }
    if (validEmail) {
      Navigator.pushNamed(
        context,
        InsertName.routeName,
        arguments: InsertNameArguments(
            userCredential: widget.userCredential,
            userEmail: emailTextEditingController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    _firebaseAuth = Provider.of<FirebaseModel>(context, listen: false).auth;

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
              "Insira o seu endereço de email",
              style: TextStyle(color: Colors.black, fontSize: 18),
            ),
            SizedBox(height: screenHeight / 40),
            Warning(
              color: AppColor.disabled,
              message:
                  "Usaremos o email para enviar os recibos das suas corridas",
            ),
            SizedBox(height: screenHeight / 40),
            AppInputText(
              autoFocus: true,
              hintText: "exemplo@dominio.com",
              controller: emailTextEditingController,
              inputFormatters: [LengthLimitingTextInputFormatter(60)],
            ),
            SizedBox(height: screenHeight / 40),
            warningMessage != null ? warningMessage : Container(),
            Spacer(),
            Row(
              children: [
                Spacer(),
                CircularButton(
                  buttonColor: circularButtonColor,
                  child: _circularButtonChild,
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

extension on String {
  bool isValidEmail() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}
