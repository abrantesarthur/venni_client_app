import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:rider_frontend/app.dart';
import 'package:rider_frontend/config/config.dart';

// TODO: store sensitive data safely https://medium.com/flutterdevs/secure-storage-in-flutter-660d7cb81bc
void main() {
  DotEnv.load(fileName: "dev.env").then(
    (_) => AppConfig(flavor: Flavor.DEV),
  );

  runApp(App());
}

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 * https://iiro.dev/2018/03/02/separating-build-environments/
 *  how to set up the environment (read it when deploying the app)
 */
