import 'package:flutter/material.dart';

class AppConfig extends InheritedWidget {
  final String cloudFunctionsBaseURL;
  final String googleApiKey;

  AppConfig({
    @required this.cloudFunctionsBaseURL,
    @required this.googleApiKey,
    @required Widget child,
  }) : super(child: child);

  static AppConfig of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppConfig>();
  }

  @override
  bool updateShouldNotify(InheritedWidget oldWidget) => false;
}
