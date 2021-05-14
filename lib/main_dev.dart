import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:rider_frontend/app.dart';
import 'package:rider_frontend/config/config.dart';

// TODO: store sensitive data safely https://medium.com/flutterdevs/secure-storage-in-flutter-660d7cb81bc
void main() async {
  await DotEnv.load(fileName: ".env");
  AppConfig(flavor: Flavor.DEV);

  runApp(App());
}

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 */