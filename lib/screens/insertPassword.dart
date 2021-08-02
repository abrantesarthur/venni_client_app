import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseAuth/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseAuth/methods.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appInputPassword.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/passwordWarning.dart';
import 'package:rider_frontend/widgets/warning.dart';
import 'package:url_launcher/url_launcher.dart';

class InsertPasswordArguments {
  final UserCredential userCredential;
  final String name;
  final String surname;
  final String userEmail;
  InsertPasswordArguments({
    @required this.userCredential,
    this.name,
    this.surname,
    this.userEmail,
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
    this.userEmail,
    this.name,
    this.surname,
  });

  @override
  InsertPasswordState createState() => InsertPasswordState();
}

class InsertPasswordState extends State<InsertPassword> {
  Future<bool> successfullyRegisteredUser;
  double screenHeight;
  Color circularButtonColor;
  Function circularButtonCallback;
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

  Future<void> handleRegistrationFailure(
    FirebaseModel firebase,
    FirebaseAuthException e,
  ) async {
    // disactivate CircularButton callback
    setState(() {
      circularButtonCallback = null;
      circularButtonColor = AppColor.disabled;
    });

    if (e.code == "weak-password") {
      // this should never happen
      setState(() {
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
      });
    } else {
      // delete client entry in database
      await firebase.database.deleteClient(widget.userCredential.user.uid);

      // if user did not already have a partner account
      if (!firebase.isRegistered) {
        // rollback and delete user from authentication
        await widget.userCredential.user.delete();
      }

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
              onTapCallback: (BuildContext context) {
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

  Future<bool> registerUser(
    FirebaseModel firebase,
    UserModel user,
  ) async {
    // if user already has a partner account
    if (firebase.isRegistered) {
      // make sure they've entered a correct password
      CheckPasswordResponse cpr = await firebase.auth.checkPassword(
        passwordTextEditingController.text,
      );
      if (cpr != null && !cpr.successful) {
        // if not, display appropriate warning
        setState(() {
          registrationErrorWarnings = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: screenHeight / 40),
              Warning(
                message: cpr.message,
              ),
              SizedBox(height: screenHeight / 80),
            ],
          );
        });
        return false;
      }

      // if user entered correct password, create them a client account
      try {
        await firebase.auth.createClient(
          firebase: firebase,
          credential: widget.userCredential,
        );
        // we enforce a variant that, by the time Home is pushed, user model
        // must be already populated
        await user.downloadData(firebase);

        // log event
        try {
          await firebase.analytics.logSignUp(signUpMethod: "phoneNubmer");
        } catch (e) {}
        return true;
      } catch (e) {
        await handleRegistrationFailure(firebase, e);
        return false;
      }
    }

    // if user doensn't already have a partner account, we simply create one
    try {
      await firebase.auth.createClient(
        firebase: firebase,
        credential: widget.userCredential,
        email: widget.userEmail,
        password: passwordTextEditingController.text,
        displayName: widget.name + " " + widget.surname,
      );
      // we enforce a variant that, by the time Home is pushed, user model
      // must be already populated
      await user.downloadData(firebase);

      // log event
      try {
        await firebase.analytics.logSignUp(signUpMethod: "phoneNubmer");
      } catch (e) {}
      return true;
    } on FirebaseAuthException catch (e) {
      await handleRegistrationFailure(firebase, e);
      return false;
    }
  }

  // buttonCallback tries signing user up by adding remainig data to its credential
  void buttonCallback(BuildContext context) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);
    // dismiss keyboard
    FocusScope.of(context).requestFocus(FocusNode());

    // ask user to abide by privacy terms
    await showYesNoDialog(
      context,
      title: "Termos de Uso",
      child: RichText(
        text: TextSpan(
          text: "Você precisa aceitar os nossos ",
          style: TextStyle(
            color: Colors.black,
            fontSize: 14,
          ),
          children: [
            TextSpan(
                text: "termos de uso",
                style: TextStyle(color: Colors.blue),
                recognizer: TapGestureRecognizer()
                  ..onTap = () async {
                    String _url = "https://venni.app/termos/clientes";
                    if (await canLaunch(_url)) {
                      try {
                        await launch(_url);
                      } catch (_) {}
                    }
                  }),
            TextSpan(
              text: " para criar a sua conta. Deseja aceitar os termos?",
            ),
          ],
        ),
      ),
      onPressedYes: () {
        // dismiss dialog
        Navigator.pop(context);
        setState(() {
          successfullyRegisteredUser = registerUser(
            firebase,
            user,
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);
    GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(
      context,
      listen: false,
    );
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );

    return FutureBuilder(
      future: successfullyRegisteredUser,
      builder: (
        BuildContext context,
        AsyncSnapshot<bool> snapshot,
      ) {
        // user has tapped to register, and registration has finished succesfully
        if (snapshot.hasData && snapshot.data == true) {
          // future builder must return Widget, but we want to push a route.
          // thus, schedule pushing for right afer returning a Container.
          SchedulerBinding.instance.addPostFrameCallback((_) {
            Navigator.pushNamedAndRemoveUntil(
              context,
              Home.routeName,
              (_) => false,
              arguments: HomeArguments(
                firebase: firebase,
                trip: trip,
                user: user,
                googleMaps: googleMaps,
                connectivity: connectivity,
              ),
            );
          });
          return Container();
        }

        // user has tapped to register, and we are waiting for registration to finish
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show loading screen
          return Splash(
              text: "Criando conta",
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ));
        }

        // error cases and default: show password screen
        return Scaffold(
          body: LayoutBuilder(
            builder: (
              BuildContext context,
              BoxConstraints viewportConstraints,
            ) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: viewportConstraints.maxHeight,
                  ),
                  child: OverallPadding(
                    child: IntrinsicHeight(
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
                            firebase.isRegistered
                                ? "Insira sua senha"
                                : "Insira uma senha",
                            style: TextStyle(color: Colors.black, fontSize: 18),
                          ),
                          SizedBox(height: screenHeight / 40),
                          AppInputPassword(
                            controller: passwordTextEditingController,
                            autoFocus: true,
                          ),
                          firebase.isRegistered
                              ? Column(
                                  children: [
                                    SizedBox(height: screenHeight / 40),
                                    Warning(
                                      message:
                                          "Já existe uma conta de parceiro com o telefone selecionado. Insira sua senha para prosseguir.",
                                    )
                                  ],
                                )
                              : displayPasswordWarnings
                                  ? Column(
                                      children: [
                                        SizedBox(height: screenHeight / 40),
                                        PasswordWarning(
                                          isValid: passwordChecks[0],
                                          message:
                                              "Precisa ter no mínimo 8 caracteres",
                                        ),
                                        SizedBox(height: screenHeight / 80),
                                        PasswordWarning(
                                          isValid: passwordChecks[1],
                                          message:
                                              "Precisa ter pelo menos uma letra",
                                        ),
                                        SizedBox(height: screenHeight / 80),
                                        PasswordWarning(
                                          isValid: passwordChecks[2],
                                          message:
                                              "Precisa ter pelo menos um dígito",
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
                                onPressedCallback:
                                    circularButtonCallback == null
                                        ? () {}
                                        : () => circularButtonCallback(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
