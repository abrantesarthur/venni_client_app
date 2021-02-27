import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/passwordWarning.dart';
import 'package:rider_frontend/widgets/warning.dart';

class InsertPasswordArguments {
  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  InsertPasswordArguments({
    @required this.userCredential,
    @required this.name,
    @required this.surname,
    @required this.userEmail,
  });
}

class InsertPassword extends StatefulWidget {
  static const String routeName = "insertPassword";

  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  InsertPassword({
    @required this.userCredential,
    @required this.userEmail,
    @required this.name,
    @required this.surname,
  });

  @override
  InsertPasswordState createState() => InsertPasswordState();
}

class InsertPasswordState extends State<InsertPassword> {
  Future<bool> successfullyRegisteredUser;
  double screenHeight;
  Color circularButtonColor;
  Function circularButtonCallback;
  IconData _endIconData;
  bool obscurePassword;
  TextEditingController passwordTextEditingController = TextEditingController();
  List<bool> passwordChecks = [false, false, false];
  bool displayPasswordWarnings;
  Widget registrationErrorWarnings;
  bool passwordTextFieldEnabled;
  bool preventNavigateBack;

  @override
  void initState() {
    super.initState();
    circularButtonColor = AppColor.disabled;
    _endIconData = Icons.remove_red_eye_outlined;
    passwordTextFieldEnabled = true;
    preventNavigateBack = false;
    obscurePassword = true;
    displayPasswordWarnings = true;
    passwordTextEditingController.addListener(() {
      // check password requirements as user types
      String password = passwordTextEditingController.text ?? "";

      if (password.length > 0) {
        // show password warnings and hide registration error warnigns
        displayPasswordWarnings = true;
        registrationErrorWarnings = null;
      }
      if (password.length >= 8) {
        setState(() {
          passwordChecks[0] = true;
        });
      } else {
        setState(() {
          passwordChecks[0] = false;
        });
      }
      if (password.containsLetter()) {
        setState(() {
          passwordChecks[1] = true;
        });
      } else {
        setState(() {
          passwordChecks[1] = false;
        });
      }
      if (password.containsDigit()) {
        setState(() {
          passwordChecks[2] = true;
        });
      } else {
        setState(() {
          passwordChecks[2] = false;
        });
      }
      if (passwordChecks[0] && passwordChecks[1] && passwordChecks[2]) {
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
    });
  }

  @override
  void dispose() {
    passwordTextEditingController.dispose();
    super.dispose();
  }

  void toggleObscurePassword() {
    setState(() {
      if (obscurePassword) {
        _endIconData = Icons.remove_red_eye;
        obscurePassword = false;
      } else {
        _endIconData = Icons.remove_red_eye_outlined;
        obscurePassword = true;
      }
    });
  }

  Future<void> handleRegistrationFailure(
    BuildContext context,
    FirebaseAuthException e,
  ) async {
    // disactivate CircularButton callback
    setState(() {
      circularButtonCallback = null;
      circularButtonColor = AppColor.disabled;
    });

    if (e.code == "weak-password") {
      // this should never happen
      // remove password warning messages
      displayPasswordWarnings = false;

      // display warning for user to try again
      registrationErrorWarnings = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: screenHeight / 40),
          Warning(
            message: "Senha muito fraca. Tente outra.",
          ),
          SizedBox(height: screenHeight / 80),
        ],
      );
    } else {
      // rollback and delete user
      await widget.userCredential.user.delete();

      String firstWarningMessage;
      if (e.code == "requires-recent-login") {
        firstWarningMessage =
            "Infelizmente a sua sessão expirou devido à demora.";
      } else {
        firstWarningMessage = "Algo deu errado.";
      }

      setState(() {
        // remove password warnings
        displayPasswordWarnings = false;

        // remove typed password from text field
        passwordTextEditingController.text = "";

        // prevent users from typing a new password
        passwordTextFieldEnabled = false;

        // prevent users from navigating back
        preventNavigateBack = true;

        // display warnings for user to login again
        registrationErrorWarnings = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: screenHeight / 40),
            Warning(
              color: Colors.black,
              message: firstWarningMessage,
            ),
            SizedBox(height: screenHeight / 80),
            Warning(
              onTapCallback: () {
                Navigator.pushNamedAndRemoveUntil(
                    context, Start.routeName, (_) => false);
              },
              message: "Clique aqui para recomeçar o cadastro.",
            ),
            SizedBox(height: screenHeight / 80),
          ],
        );
      });
    }
  }

  Future<bool> registerUser(BuildContext context) async {
    try {
      // update other userCredential information
      await widget.userCredential.user.updateEmail(widget.userEmail);
      await widget.userCredential.user
          .updatePassword(passwordTextEditingController.text);
      await widget.userCredential.user
          .updateProfile(displayName: widget.name + " " + widget.surname);
      return true;
    } on FirebaseAuthException catch (e) {
      await handleRegistrationFailure(context, e);
      return false;
    }
  }

  // buttonCallback tries signing user up by adding remainig data to its credential
  void buttonCallback(BuildContext context) async {
    setState(() {
      successfullyRegisteredUser = registerUser(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    final firebaseModel = Provider.of<FirebaseModel>(context, listen: false);

    return FutureBuilder(
      future: successfullyRegisteredUser,
      builder: (
        BuildContext context,
        AsyncSnapshot<bool> snapshot,
      ) {
        // user has tapped to register, and registration has finished succesfully
        if (snapshot.hasData && snapshot.data == true) {
          //  add listener to track user changes and send to Home screen
          firebaseModel.listenForStatusChanges();
          // future builder must return Widget, but we want to push a route.
          // thus, schedule pushing for right afer returning a Container.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamed(context, Home.routeName);
          });
          return Container();
        }

        // user has tapped to register, and we are waiting for registration to finish
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show loading screen
          return _RegistrationLoading();
        }

        // error cases and default: show password screen
        return Scaffold(
          body: OverallPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ArrowBackButton(
                        onTapCallback: preventNavigateBack
                            ? () {}
                            : () => Navigator.pop(context)),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 25),
                Text(
                  "Insira uma senha",
                  style: TextStyle(color: Colors.black, fontSize: 18),
                ),
                SizedBox(height: screenHeight / 40),
                AppInputText(
                  enabled: passwordTextFieldEnabled,
                  iconData: Icons.lock,
                  endIcon: _endIconData,
                  endIconOnTapCallback: toggleObscurePassword,
                  hintText: "senha",
                  controller: passwordTextEditingController,
                  obscureText: obscurePassword,
                  inputFormatters: [LengthLimitingTextInputFormatter(32)],
                ),
                displayPasswordWarnings
                    ? Column(
                        children: [
                          SizedBox(height: screenHeight / 40),
                          PasswordWarning(
                            isValid: passwordChecks[0],
                            message: "Precisa ter no mínimo 8 caracteres",
                          ),
                          SizedBox(height: screenHeight / 80),
                          PasswordWarning(
                            isValid: passwordChecks[1],
                            message: "Precisa ter pelo menos uma letra",
                          ),
                          SizedBox(height: screenHeight / 80),
                          PasswordWarning(
                            isValid: passwordChecks[2],
                            message: "Precisa ter pelo menos um dígito",
                          ),
                          SizedBox(height: screenHeight / 80),
                        ],
                      )
                    : Container(),
                registrationErrorWarnings != null
                    ? registrationErrorWarnings
                    : Container(),
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
      },
    );
  }
}

class _RegistrationLoading extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColor.primaryPink,
        child: Center(
          child: Column(
            children: [
              Spacer(),
              SizedBox(
                height: 50,
                width: 50,
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 30),
                child: Text(
                  "Criando sua conta...",
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ),
              Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

extension on String {
  bool containsLetter() {
    return RegExp(r'[a-zA-Z]+').hasMatch(this);
  }

  bool containsDigit() {
    return RegExp(r'\d+').hasMatch(this);
  }
}
