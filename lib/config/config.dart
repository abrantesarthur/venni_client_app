import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;

enum Flavor { DEV, PROD }

class ConfigValues {
  final String urlsApiKey;
  final String googleMapsApiKey;
  final bool emulateCloudFunctions;
  final String cloudFunctionsBaseURL;
  final String realtimeDatabaseURL;

  ConfigValues({
    @required this.urlsApiKey,
    @required this.googleMapsApiKey,
    @required this.emulateCloudFunctions,
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
      urlsApiKey: AppConfig._buildUrlsApiKey(flavor),
      googleMapsApiKey: AppConfig._buildGoogleMapsApiKey(flavor),
      emulateCloudFunctions: DotEnv.env["EMULATE_CLOUD_FUNCTIONS"] == "true",
      cloudFunctionsBaseURL: AppConfig._buildCloudFunctionsBaseURL(),
      realtimeDatabaseURL: _buildRealtimeDatabaseURL(flavor),
    );
    _instance ??= AppConfig._internal(flavor: flavor, values: values);
    return _instance;
  }

  static String _buildUrlsApiKey(Flavor flavor) {
    if (flavor == Flavor.DEV) {
      return DotEnv.env["DEV_URLS_API_KEY"];
    }
    if (flavor == Flavor.PROD) {
      return DotEnv.env["URLS_API_KEY"];
    }
    return "";
  }

  static String _buildRealtimeDatabaseURL(Flavor flavor) {
    if (flavor == Flavor.DEV) {
      return DotEnv.env["DEV_REALTIME_DATABASE_BASE_URL"];
    }
    if (flavor == Flavor.PROD) {
      return DotEnv.env["REALTIME_DATABASE_BASE_URL"];
    }
    return "";
  }

  static String _buildGoogleMapsApiKey(Flavor flavor) {
    if (flavor == Flavor.DEV) {
      if (Platform.isAndroid) {
        return DotEnv.env["DEV_ANDROID_GOOGLE_MAPS_API_KEY"];
      } else if (Platform.isIOS) {
        return DotEnv.env["DEV_IOS_GOOGLE_MAPS_API_KEY"];
      }
    }
    if (flavor == Flavor.PROD) {
      if (Platform.isAndroid) {
        return DotEnv.env["ANDROID_GOOGLE_MAPS_API_KEY"];
      } else if (Platform.isIOS) {
        return DotEnv.env["IOS_GOOGLE_MAPS_API_KEY"];
      }
    }
    return "";
  }

  static String _buildCloudFunctionsBaseURL() {
    return "http://" +
        DotEnv.env["HOST_IP_ADDRESS"] +
        ":" +
        DotEnv.env["CLOUD_FUNCTIONS_PORT"];
  }

  static isProduction() => _instance.flavor == Flavor.PROD;
  static isDevelopment() => _instance.flavor == Flavor.DEV;
}
