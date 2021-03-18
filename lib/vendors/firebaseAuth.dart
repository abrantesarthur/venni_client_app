import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertEmail.dart';

// TODO: put this in the model
Future<void> verificationCompletedCallback({
  @required BuildContext context,
  @required PhoneAuthCredential credential,
  @required FirebaseDatabase firebaseDatabase,
  @required FirebaseAuth firebaseAuth,
  @required Function onExceptionCallback,
}) async {
  try {
    // important: if the user doesn't have an account, one will be created
    UserCredential userCredential =
        await firebaseAuth.signInWithCredential(credential);

    // however, we only consider the user to be registered, if they have a displayName,
    // meaning, they went through the whole registration process
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    if (firebase.isRegistered) {
      // redirect to Home screen
      Navigator.pushNamed(context, Home.routeName);
    } else {
      Navigator.pushNamed(
        context,
        InsertEmail.routeName,
        arguments: InsertEmailArguments(userCredential: userCredential),
      );
    }
  } catch (e) {
    onExceptionCallback(e);
  }
}

String verificationFailedCallback(FirebaseAuthException e) {
  String warningMessage;
  if (e.code == "invalid-phone-number") {
    warningMessage = "Número de telefone inválido. Por favor, tente outro.";
  } else if (e.code == "too-many-requests") {
    warningMessage =
        "Ops, número de tentativas excedidas. Tente novamente em alguns minutos.";
  } else {
    warningMessage = "Ops, algo deu errado. Tente novamente mais tarde.";
  }
  return warningMessage;
}
