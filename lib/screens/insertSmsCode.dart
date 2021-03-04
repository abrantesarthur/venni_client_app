import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseAuth.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/circularButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';

class InsertSmsCodeArguments {
  final String verificationId;
  final int resendToken;
  final String phoneNumber;

  InsertSmsCodeArguments({
    @required this.verificationId,
    @required this.resendToken,
    @required this.phoneNumber,
  });
}

class InsertSmsCode extends StatefulWidget {
  static const String routeName = "InsertSmsCode";

  final String verificationId;
  final String phoneNumber;
  final int resendToken;

  InsertSmsCode({
    @required this.verificationId,
    @required this.resendToken,
    @required this.phoneNumber,
  });

  @override
  InsertSmsCodeState createState() {
    return InsertSmsCodeState();
  }
}

class InsertSmsCodeState extends State<InsertSmsCode> {
  TextEditingController smsCodeTextEditingController = TextEditingController();
  Color circularButtonColor;
  Function circularButtonCallback;
  String smsCode;
  Widget _circularButtonChild;
  Widget _resendCodeWarning;
  Widget warningMessage;
  Timer timer;
  int remainingSeconds = 15;
  String _verificationId;
  int _resendToken;
  FirebaseAuth _firebaseAuth;
  FirebaseDatabase _firebaseDatabase;

  @override
  void initState() {
    super.initState();
    // _verificationId and _resendToken start with values pushed to widget
    _verificationId = widget.verificationId;
    _resendToken = widget.resendToken;
    timer = kickOffTimer();
    // button starts off disabled
    circularButtonColor = AppColor.disabled;
    _circularButtonChild = Icon(
      Icons.autorenew_sharp,
      color: Colors.white,
      size: 36,
    );
    // decide to activate button based on entered smsCode
    smsCodeTextEditingController.addListener(() {
      if (smsCodeTextEditingController.text.length == 6) {
        activateButton();
      } else {
        disactivateButton();
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    smsCodeTextEditingController.dispose();
    super.dispose();
  }

  // activateButton adds a callback and primary color to the button
  void activateButton() {
    setState(() {
      circularButtonCallback = verifySmsCode;
      circularButtonColor = AppColor.primaryPink;
      smsCode = smsCodeTextEditingController.text;
    });
  }

  // disactivateButton removes callback and primary color from the button
  void disactivateButton() {
    setState(() {
      circularButtonCallback = null;
      circularButtonColor = AppColor.disabled;
      smsCode = null;
    });
  }

  // kickOffTimer decrements remainingSeconds once per second until 0
  Timer kickOffTimer() {
    return Timer.periodic(
      const Duration(seconds: 1),
      (Timer t) {
        if (remainingSeconds == 0) {
          t.cancel();
        } else {
          setState(() {
            remainingSeconds--;
          });
        }
      },
    );
  }

  // codeSentCallback is called when sms code is successfully resent.
  // it resets the state to value similar to initState.
  void codeSentCallback(String verificationId, int resendToken) {
    setState(() {
      _verificationId = verificationId;
      _resendToken = resendToken;
      warningMessage = null;
      remainingSeconds = 15;
      timer = kickOffTimer();
    });
  }

  void resendCodeVerificationFailedCallback(FirebaseAuthException e) {
    String errorMsg = verificationFailedCallback(e);
    setState(() {
      // reset timer and resendCodeWarning
      remainingSeconds = 15;
      timer = kickOffTimer();
      warningMessage = Warning(message: errorMsg);
    });
  }

  // resendCode tries to resend the sms code to the same phoneNumber
  Future<void> resendCode(BuildContext context) async {
    // remove warning message
    setState(() {
      timer.cancel();
      warningMessage = null;
    });

    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: widget.phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {
        verificationCompletedCallback(
          context: context,
          credential: credential,
          firebaseDatabase: _firebaseDatabase,
          firebaseAuth: _firebaseAuth,
          onExceptionCallback: (FirebaseAuthException e) {
            setState(() {
              // reset timer and resendCodeWarning
              remainingSeconds = 15;
              timer = kickOffTimer();
              warningMessage =
                  Warning(message: "Algo deu errado. Tente novamente");
            });
          },
        );
      },
      verificationFailed: resendCodeVerificationFailedCallback,
      codeSent: codeSentCallback,
      codeAutoRetrievalTimeout: (String verificationId) {},
      forceResendingToken: _resendToken,
    );
  }

  // displayErrorMessage displays warning message depending on received exception
  void displayErrorMessage(BuildContext context, FirebaseAuthException e) {
    if (e.code == "invalid-verification-code") {
      setState(() {
        warningMessage = Warning(message: "Código inválido. Tente outro.");
        circularButtonCallback = verifySmsCode;
        _circularButtonChild = Icon(
          Icons.autorenew_sharp,
          color: Colors.white,
          size: 36,
        );
      });
    } else {
      setState(() {
        warningMessage = Warning(message: "Algo deu errado. Tente mais tarde.");
        circularButtonCallback = verifySmsCode;
        _circularButtonChild = Icon(
          Icons.autorenew_sharp,
          color: Colors.white,
          size: 36,
        );
      });
    }
  }

  // verifySmsCode is called when user taps circular button.
  // it checks if the code entered by the user is valid.
  // During verification, a CircularProgressIndicator widget
  // is displayed. Upon success, user is redirected to another screen.
  Future<void> verifySmsCode(BuildContext context) async {
    setState(() {
      warningMessage = null;
      circularButtonCallback = null;
      _circularButtonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    // Create a PhoneAuthCredential with the entered verification code
    PhoneAuthCredential phoneCredential = PhoneAuthProvider.credential(
        verificationId: _verificationId, smsCode: smsCode);

    await verificationCompletedCallback(
      context: context,
      credential: phoneCredential,
      firebaseDatabase: _firebaseDatabase,
      firebaseAuth: _firebaseAuth,
      onExceptionCallback: (FirebaseAuthException e) =>
          displayErrorMessage(context, e),
    );

    setState(() {
      // stop circular Progress indicator
      _circularButtonChild = Icon(
        Icons.autorenew_sharp,
        color: Colors.white,
        size: 36,
      );
    });
  }

  Widget displayWarnings(BuildContext context, double padding) {
    Warning editPhoneWarning = Warning(
      message: "Editar o número do meu celular",
      onTapCallback: Navigator.pop,
    );
    if (warningMessage != null && _resendCodeWarning != null) {
      return Expanded(
          flex: 18,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              warningMessage,
              SizedBox(height: padding),
              _resendCodeWarning,
              SizedBox(height: padding),
              editPhoneWarning,
            ],
          ));
    }
    if (warningMessage == null && _resendCodeWarning == null) {
      return Expanded(
        flex: 18,
        child: editPhoneWarning,
      );
    }
    if (warningMessage != null) {
      return Expanded(
        flex: 18,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            warningMessage,
            SizedBox(height: padding),
            editPhoneWarning,
          ],
        ),
      );
    }
    return Expanded(
      flex: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _resendCodeWarning,
          SizedBox(height: padding),
          editPhoneWarning,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    _firebaseAuth = Provider.of<FirebaseModel>(context).auth;
    _firebaseDatabase = Provider.of<FirebaseModel>(context).database;

    if (remainingSeconds <= 0) {
      // if remainingSeconds reaches 0, allow user to resend sms code.
      _resendCodeWarning = Warning(
        onTapCallback: resendCode,
        message: "Reenviar o código para meu celular",
      );
    } else {
      // otherwise, display countdown message
      _resendCodeWarning = Warning(
          color: AppColor.disabled,
          message: "Reenviar o código em " + remainingSeconds.toString());
    }

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
                              onTapCallback: () => Navigator.pop(context)),
                          Spacer(),
                        ],
                      ),
                      SizedBox(height: screenHeight / 25),
                      RichText(
                        text: TextSpan(
                          text: 'Insira o código de 6 digitos enviado para ',
                          style: TextStyle(fontSize: 18, color: Colors.black),
                          children: <TextSpan>[
                            TextSpan(
                                text: widget.phoneNumber,
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight / 40),
                      AppInputText(
                        autoFocus: true,
                        iconData: Icons.lock,
                        controller: smsCodeTextEditingController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          LengthLimitingTextInputFormatter(6),
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      SizedBox(height: screenHeight / 40),
                      displayWarnings(context, screenHeight / 40),
                      Row(
                        children: [
                          Spacer(),
                          CircularButton(
                            buttonColor: circularButtonColor,
                            child: _circularButtonChild,
                            onPressedCallback: circularButtonCallback == null
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
  }
}
