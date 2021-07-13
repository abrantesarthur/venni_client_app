import 'dart:async';
import 'dart:io';

import 'package:connectivity/connectivity.dart';
import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/utils/utils.dart';

class ConnectivityModel extends ChangeNotifier {
  bool _hasConnection;
  Connectivity _connectivity;
  StreamSubscription _connectivitySubscription;

  bool get hasConnection => _hasConnection;

  ConnectivityModel() {
    // start listening for connectivity changes
    _connectivity = Connectivity();
    _connectivitySubscription = _connectivity.onConnectivityChanged
        .listen((e) async => await _checkConnection());
    _checkConnection();
  }

  @override
  void dispose() {
    if (_connectivitySubscription != null) {
      _connectivitySubscription.cancel();
    }
    super.dispose();
  }

  // checkConnection tests whether there is a connection
  Future<void> _checkConnection() async {
    bool previousHasConnection = _hasConnection;

    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        _hasConnection = true;
      } else {
        _hasConnection = false;
      }
    } on SocketException catch (_) {
      _hasConnection = false;
    }

    // notify listeners if connection status has changed
    if (previousHasConnection != _hasConnection) {
      notifyListeners();
    }
  }

  Future<void> alertWhenOffline(BuildContext context, {String message}) async {
    await showOkDialog(
      context: context,
      title: "Você está offline.",
      content: message ?? "Conecte-se à internet para continuar.",
    );
  }
}
