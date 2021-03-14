import 'package:flutter/material.dart';
import 'package:rider_frontend/config.dart';
import 'package:rider_frontend/main.dart';

void main() {
  final AppConfig configuredApp = AppConfig(
      cloudFunctionsBaseURL:
          "https://us-central1-venni-rider-staging.cloudfunctions.net/",
      googleApiKey: "AIzaSyDHUnoB6uGH-8OoW4SIBnJRVpzRVD8fNVw",
      child: App());

  WidgetsFlutterBinding.ensureInitialized();
  runApp(configuredApp);
}


/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 * https://iiro.dev/2018/03/02/separating-build-environments/
 *  how to set up the environment (read it when deploying the app)
 */
