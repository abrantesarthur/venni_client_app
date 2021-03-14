import 'package:flutter/material.dart';
import 'package:rider_frontend/app.dart';

enum Flavor { DEV, PROD }

// TODO: add sensitive variables to secure storage package
// TODO: initialize firebase according to environment
class ConfigValues {
  final String directionsBaseURL;
  final String geocodingBaseURL;
  final String autocompleteBaseURL;
  final String cloudFunctionsBaseURL;
  final String googleApiKey;

  ConfigValues({
    @required this.directionsBaseURL,
    @required this.geocodingBaseURL,
    @required this.autocompleteBaseURL,
    @required this.cloudFunctionsBaseURL,
    @required this.googleApiKey,
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

  factory AppConfig({
    @required Flavor flavor,
    @required ConfigValues values,
  }) {
    _instance ??= AppConfig._internal(flavor: flavor, values: values);
    return _instance;
  }

  static isProduction() => _instance.flavor == Flavor.PROD;
  static isDevelopment() => _instance.flavor == Flavor.DEV;
}
