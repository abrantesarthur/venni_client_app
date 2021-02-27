import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

class FirebaseModel extends ChangeNotifier {
  FirebaseAuth _firebaseAuth;
  FirebaseDatabase _firebaseDatabase;
  bool _isRegistered = false;

  FirebaseAuth get auth => _firebaseAuth;
  FirebaseDatabase get database => _firebaseDatabase;
  bool get isRegistered => _isRegistered;

  FirebaseModel({
    @required FirebaseAuth firebaseAuth,
    @required FirebaseDatabase firebaseDatabase,
  })  : assert(firebaseAuth != null),
        assert(firebaseDatabase != null) {
    // set firebase instances
    _firebaseAuth = firebaseAuth;
    _firebaseDatabase = firebaseDatabase;

    // check whether a user is logged in
    _isRegistered = false;
    if (this._userIsRegistered(firebaseAuth.currentUser)) {
      // if so, add listener to track changes in user status
      listenForStatusChanges();
      _isRegistered = true;
    }
    notifyListeners();
  }

  // listenForStatusChanges responds to changes in user login status
  // by modifying the isRegistered flag and notifying listeners.
  void listenForStatusChanges() {
    _firebaseAuth.authStateChanges().listen((User user) {
      if (this._userIsRegistered(user)) {
        _isRegistered = true;
      } else {
        _isRegistered = false;
      }
      notifyListeners();
    });
  }

  // returns true if user is logged in and has a displayName
  // i.e., went through the registration process.
  bool _userIsRegistered(User user) {
    return user != null && user.displayName != null;
  }
}
