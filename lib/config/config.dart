import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'dart:io' as dartIo;

import 'package:rider_frontend/app.dart';

enum Flavor { DEV, PROD }

// TODO: add sensitive variables to secure storage package
// TODO: initialize firebase according to environment
// TODO: get android and iOS maps keys from the environment (AppDelegate.swift, main AndroidManifest.xml)
class ConfigValues {
  final String geocodingBaseURL;
  final String autocompleteBaseURL;
  final String googleApiKey;
  final String cloudFunctionsBaseURL;
  final String realtimeDatabaseURL;

  ConfigValues({
    @required this.geocodingBaseURL,
    @required this.autocompleteBaseURL,
    @required this.googleApiKey,
    @required this.cloudFunctionsBaseURL,
    @required this.realtimeDatabaseURL,
  });
}

class AppConfig {
  final Flavor flavor;
  final ConfigValues values;

  static AppConfig _instance;
  static AppConfig get env => _instance;

  AppConfig._internal({
    @required this.flavor,
    @required this.values,
  });

  factory AppConfig({@required Flavor flavor}) {
    ConfigValues values = ConfigValues(
      geocodingBaseURL: DotEnv.env["GEOCODING_BASE_URL"],
      autocompleteBaseURL: DotEnv.env["AUTOCOMPLETE_BASE_URL"],
      googleApiKey: DotEnv.env["GOOGLE_API_KEY"],
      cloudFunctionsBaseURL: AppConfig._buildCloudFunctionsBaseURL(),
      realtimeDatabaseURL: AppConfig._buildRealTimeDatabaseURL(),
    );
    _instance ??= AppConfig._internal(flavor: flavor, values: values);
    return _instance;
  }

  static String _buildCloudFunctionsBaseURL() {
    return DotEnv.env["EMULATE_CLOUD_FUNCTIONS"] == "false"
        ? DotEnv.env["CLOUD_FUNCTIONS_BASE_URL"]
        : 'http://localhost:' + DotEnv.env["CLOUD_FUNCTIONS_PORT"] + "/";
  }

  static String _buildRealTimeDatabaseURL() {
    return DotEnv.env["EMULATE_REALTIME_DATABASE"] == "false"
        ? DotEnv.env["REALTIME_DATABASE_BASE_URL"]
        : (dartIo.Platform.isAndroid
            ? 'http://10.0.2.2:' + DotEnv.env["REALTIME_DATABASE_PORT"] + "/"
            : 'http://localhost:' + DotEnv.env["REALTIME_DATABASE_PORT"] + "/");
  }

  static isProduction() => _instance.flavor == Flavor.PROD;
  static isDevelopment() => _instance.flavor == Flavor.DEV;
}
