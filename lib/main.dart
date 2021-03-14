import 'package:flutter/material.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/app.dart';

void main() {
  AppConfig(
    flavor: Flavor.DEV,
    values: ConfigValues(
        cloudFunctionsBaseURL:
            "https://us-central1-venni-rider-staging.cloudfunctions.net/",
        googleApiKey: "AIzaSyDHUnoB6uGH-8OoW4SIBnJRVpzRVD8fNVw"),
  );

  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 * https://iiro.dev/2018/03/02/separating-build-environments/
 *  how to set up the environment (read it when deploying the app)
 */
