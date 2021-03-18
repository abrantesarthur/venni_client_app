import 'package:flutter/material.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/app.dart';

// TODO: store sensitive data safely https://medium.com/flutterdevs/secure-storage-in-flutter-660d7cb81bc
void main() {
  AppConfig(
    flavor: Flavor.DEV,
    values: ConfigValues(
      directionsBaseURL: "https://maps.googleapis.com/maps/api/directions",
      geocodingBaseURL: "https://maps.googleapis.com/maps/api/geocode",
      autocompleteBaseURL:
          "https://maps.googleapis.com/maps/api/place/autocomplete/json?",
      cloudFunctionsBaseURL:
          "https://us-central1-venni-rider-staging.cloudfunctions.net/",
      googleApiKey: "AIzaSyDHUnoB6uGH-8OoW4SIBnJRVpzRVD8fNVw",
    ),
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
