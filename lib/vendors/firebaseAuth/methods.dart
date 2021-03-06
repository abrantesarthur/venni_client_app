import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertEmail.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/vendors/firebaseAuth/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';
import 'package:uuid/uuid.dart';

extension AppFirebaseAuth on FirebaseAuth {
  Future<void> verificationCompletedCallback({
    @required BuildContext context,
    @required PhoneAuthCredential credential,
    @required FirebaseDatabase firebaseDatabase,
    @required FirebaseAuth firebaseAuth,
    @required Function onExceptionCallback,
  }) async {
    try {
      // important: if the user doesn't have an account, one will be created
      UserCredential userCredential = await firebaseAuth.signInWithCredential(
        credential,
      );

      // however, we only consider the user to be registered, if they have a displayName,
      // meaning, they went through the whole registration process
      FirebaseModel firebase = Provider.of<FirebaseModel>(
        context,
        listen: false,
      );
      GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(
        context,
        listen: false,
      );
      UserModel user = Provider.of<UserModel>(context, listen: false);
      TripModel trip = Provider.of<TripModel>(context, listen: false);
      ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
        context,
        listen: false,
      );
      PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);

      // try download client data
      await user.downloadData(firebase, notify: false);

      // if user already has a client account
      if (user.id != null && firebase.isRegistered) {
        // log event
        try {
          await firebase.analytics.logLogin();
        } catch (_) {}

        // try downloading any possible current trips
        try {
          await trip.downloadData(firebase, partner, notify: false);
        } catch (e) {}

        // redirect to Home screen
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
      } else if (firebase.isRegistered) {
        // otherwise, if user already has a partner account, skip email and name
        // screens and jump straigth to password. In that case, we want to confirm
        // the password, not insert a new one.
        Navigator.pushNamed(
          context,
          InsertPassword.routeName,
          arguments: InsertPasswordArguments(userCredential: userCredential),
        );
      } else {
        // if user has no account whatsoever, push email screen to create a new
        // account
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
      warningMessage = "N??mero de telefone inv??lido. Por favor, tente outro.";
    } else if (e.code == "too-many-requests") {
      warningMessage =
          "Ops, n??mero de tentativas excedidas. Tente novamente em alguns minutos.";
    } else if (e.code == "network-request-failed") {
      warningMessage =
          "Voc?? est?? offline. Conecte-se ?? internet e tente novamente.";
    } else {
      warningMessage = "Ops, algo deu errado. Tente novamente mais tarde.";
    }
    return warningMessage;
  }

  Future<CreateEmailResponse> createEmail(String email) async {
    try {
      // try to sign in with provided email
      await this.signInWithEmailAndPassword(
        email: email,
        password: Uuid().v4(),
      );
      // in the unlikely case sign in succeeds, sign back out
      this.signOut();
      // return false because there is already an account with the email;
      return CreateEmailResponse(
        successful: false,
        message: "O email j?? est?? sendo usado. Tente outro.",
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == "user-not-found") {
        // user not found means there is no account with the email
        return CreateEmailResponse(successful: true);
      }
      if (e.code == "wrong-password") {
        // wrong password means the email is already registered
        return CreateEmailResponse(
          successful: false,
          message: "O email j?? est?? sendo usado. Tente outro.",
        );
      }
      if (e.code == "invalid-email") {
        // display appropriate message
        return CreateEmailResponse(
          successful: false,
          message: "Email inv??lido. Tente outro.",
        );
      }
      return CreateEmailResponse(
        successful: false,
        message: "O email n??o pode ser usado. Tente outro.",
      );
    }
  }

  Future<void> createClient({
    @required FirebaseModel firebase,
    @required UserCredential credential,
    String email,
    String password,
    String displayName,
  }) async {
    //  update other userCredential information. This may throw
    // 'requires-recent-login or other errors
    if (email != null) {
      await credential.user.updateEmail(email);
    }
    if (password != null) {
      await credential.user.updatePassword(password);
    }
    if (displayName != null) {
      await credential.user.updateProfile(displayName: displayName);
    }

    // create client entry in database with some of the fields set
    try {
      await firebase.database.createClient(this.currentUser);
    } catch (e) {
      throw FirebaseAuthException(
        code: "database-failure",
        message: "Failed to add client entry to database.",
      );
    }

    // send email verification if necessary
    if (!firebase.auth.currentUser.emailVerified) {
      await credential.user.sendEmailVerification();
    }
  }

  Future<UserCredential> _reauthenticateWithEmailAndPassword(String password) {
    EmailAuthCredential credential = EmailAuthProvider.credential(
      email: this.currentUser.email,
      password: password,
    );
    return this.currentUser.reauthenticateWithCredential(credential);
  }

  Future<CheckPasswordResponse> checkPassword(String password) async {
    try {
      // check if user entered correct old password and avoid 'requires-recent-login' error
      await _reauthenticateWithEmailAndPassword(password);
      return CheckPasswordResponse(successful: true);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "wrong-password":
          return CheckPasswordResponse(
            successful: false,
            code: e.code,
            message: "Senha incorreta. Tente novamente.",
          );
        case "too-many-requests":
          return CheckPasswordResponse(
            successful: false,
            code: e.code,
            message:
                "Muitas tentativas sucessivas. Tente novamente mais tarde.",
          );
        default:
          // user-mismatch, user-not-found, invalid-credential, invalid-email
          // should never happen
          return CheckPasswordResponse(
            successful: false,
            code: e.code,
            message: "Algo deu errado. Tente novamente mais tarde.",
          );
      }
    }
  }

  Future<UpdatePasswordResponse> reauthenticateAndUpdatePassword({
    @required String oldPassword,
    @required String newPassword,
  }) async {
    // check if user entered correct old password and avoid 'requires-recent-login' error
    CheckPasswordResponse cpr = await checkPassword(oldPassword);
    if (cpr != null && !cpr.successful) {
      return UpdatePasswordResponse(
        successful: cpr.successful,
        code: cpr.code,
        message: cpr.message,
      );
    }

    try {
      // update password
      await this.currentUser.updatePassword(newPassword);
      return UpdatePasswordResponse(successful: true);
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case "weak-password": // should never happen
          return UpdatePasswordResponse(
            successful: false,
            code: e.code,
            message: "Nova senha muito fraca. Tente novamente.",
          );
        default: // should never happen
          // requires-recent-login
          return UpdatePasswordResponse(
            successful: false,
            code: e.code,
            message:
                "Falha ao atualizar senha. Saia da conta, entre novamente e tente outra vez.",
          );
      }
    }
  }

  Future<UpdateEmailResponse> reauthenticateAndUpdateEmail({
    @required String email,
    @required String password,
  }) async {
    try {
      // reauthenticate user to avoid 'requires-recent-login' error
      await _reauthenticateWithEmailAndPassword(password);
    } on FirebaseAuthException catch (e) {
      if (e.code == "wrong-password") {
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Senha incorreta. Tente novamente.",
        );
      } else {
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Algo deu errado. Tente novamente mais tarde.",
        );
      }
    }

    try {
      // try to update email
      await this.currentUser.updateEmail(email);
      return UpdateEmailResponse(successful: true);
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "O email j?? est?? sendo usado. Tente outro.",
        );
      }
      if (e.code == "invalid-email") {
        // display appropriate message
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Email inv??lido. Tente outro.",
        );
      }
      // e.code == "requires-recent-login" should never happen
      return UpdateEmailResponse(
        successful: false,
        code: e.code,
        message:
            "Falha ao alterar email. Saia e entre novamente na sua conta e tente novamente.",
      );
    }
  }
}
