import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertEmail.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
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

      // try download client data
      await user.downloadData(firebase);

      // if user already has a client account
      if (user.id != null && firebase.isRegistered) {
        print("user.id != null && firebase.isRegistered");
        // redirect to Home screen
        Navigator.pushReplacementNamed(
          context,
          Home.routeName,
          arguments: HomeArguments(
            firebase: firebase,
            trip: trip,
            user: user,
            googleMaps: googleMaps,
            connectivity: connectivity,
          ),
        );
      } else if (firebase.isRegistered) {
        print("firebase.isRegistered");

        // otherwise, if user already has a partner account, skip email and name
        // screens and jump straigth to password. In that case, we want to confirm
        // the password, not insert a new one.
        Navigator.pushNamed(
          context,
          InsertPassword.routeName,
          arguments: InsertPasswordArguments(userCredential: userCredential),
        );
      } else {
        print("else");
        // if user has no account whatsoever, push email screen to create a new
        // account
        Navigator.pushNamed(
          context,
          InsertEmail.routeName,
          arguments: InsertEmailArguments(userCredential: userCredential),
        );
      }
    } catch (e) {
      print(e);
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
        message: "O email já está sendo usado. Tente outro.",
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
          message: "O email já está sendo usado. Tente outro.",
        );
      }
      if (e.code == "invalid-email") {
        // display appropriate message
        return CreateEmailResponse(
          successful: false,
          message: "Email inválido. Tente outro.",
        );
      }
      return CreateEmailResponse(
        successful: false,
        message: "O email não pode ser usado. Tente outro.",
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
          message: "O email já está sendo usado. Tente outro.",
        );
      }
      if (e.code == "invalid-email") {
        // display appropriate message
        return UpdateEmailResponse(
          successful: false,
          code: e.code,
          message: "Email inválido. Tente outro.",
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

class CreateEmailResponse {
  final bool successful;
  final String message;
  final String code;

  CreateEmailResponse({
    @required this.successful,
    this.code,
    this.message,
  });
}

class UpdateEmailResponse extends CreateEmailResponse {
  UpdateEmailResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class UpdatePasswordResponse extends CreateEmailResponse {
  UpdatePasswordResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class DeleteAccountResponse extends CreateEmailResponse {
  DeleteAccountResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}

class CheckPasswordResponse extends CreateEmailResponse {
  CheckPasswordResponse({
    @required bool successful,
    String code,
    String message,
  }) : super(
          successful: successful,
          message: message,
          code: code,
        );
}
