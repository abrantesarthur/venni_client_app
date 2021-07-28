import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:system_settings/system_settings.dart';

class FirebaseModel extends ChangeNotifier {
  FirebaseAuth _firebaseAuth;
  FirebaseDatabase _firebaseDatabase;
  FirebaseStorage _firebaseStorage;
  FirebaseFunctions _firebaseFunctions;
  FirebaseMessaging _firebaseMessaging;
  bool _isRegistered = false;
  bool _notificationDialogOn = false;

  FirebaseAuth get auth => _firebaseAuth;
  FirebaseDatabase get database => _firebaseDatabase;
  FirebaseStorage get storage => _firebaseStorage;
  FirebaseFunctions get functions => _firebaseFunctions;
  FirebaseMessaging get messaging => _firebaseMessaging;
  bool get isRegistered => _isRegistered;

  FirebaseModel({
    @required FirebaseAuth firebaseAuth,
    @required FirebaseDatabase firebaseDatabase,
    @required FirebaseStorage firebaseStorage,
    @required FirebaseFunctions firebaseFunctions,
    @required FirebaseMessaging firebaseMessaging,
  }) {
    // set firebase instances
    _firebaseAuth = firebaseAuth;
    _firebaseDatabase = firebaseDatabase;
    _firebaseStorage = firebaseStorage;
    _firebaseFunctions = firebaseFunctions;
    _firebaseMessaging = firebaseMessaging;
    if (_userIsRegistered(firebaseAuth.currentUser)) {
      _isRegistered = true;
    } else {
      _isRegistered = false;
    }

    // add listener to track changes in user status
    listenForStatusChanges();

    notifyListeners();
  }

  // listenForStatusChanges responds to changes in user login status
  // by modifying the isRegistered flag and notifying listeners.
  void listenForStatusChanges() {
    _firebaseAuth.authStateChanges().listen((User user) {
      if (this._userIsRegistered(user)) {
        _updateIsRegistered(true);
      } else {
        _updateIsRegistered(false);
      }
    });
  }

  void _updateIsRegistered(bool isRegistered) {
    _isRegistered = isRegistered;
    notifyListeners();
  }

  // returns true if user is logged in and has a displayName
  // i.e., went through the registration process.
  bool _userIsRegistered(User user) {
    return user != null && user.displayName != null;
  }

  // checks whether notifications are turned on.
  Future<bool> _areNotificationsOn() async {
    NotificationSettings settings =
        await _firebaseMessaging.requestPermission();
    return settings.authorizationStatus == AuthorizationStatus.authorized;
  }

  // request permission to send notifications. If denied, shows dialog prompting
  // user to open settings and set notifications
  Future<bool> requestNotifications(BuildContext context) async {
    if (await _areNotificationsOn()) {
      return true;
    }

    // ask user to activate notifications. We check notificationDialogOn so we
    // don't display stacks of Dialogs in case this function is called multiple
    // successive times
    if (!_notificationDialogOn) {
      _notificationDialogOn = true;
      await showYesNoDialog(
        context,
        title: "Notificações desativadas",
        content:
            "Ative as notificações para ter uma melhor experiência. Abrir configurações?",
        onPressedYes: () async {
          Navigator.pop(context);
          await SystemSettings.appNotifications();
        },
      );
      _notificationDialogOn = false;
    }

    return await _areNotificationsOn();
  }
}
