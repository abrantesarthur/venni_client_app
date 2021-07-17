import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:rider_frontend/app.dart';
import 'package:rider_frontend/config/config.dart';

void main() async {
  await DotEnv.load(fileName: ".env");
  AppConfig(flavor: Flavor.PROD);

  // disable landscape mode
  SystemChrome.setPreferredOrientations(
    [DeviceOrientation.portraitUp],
  );

  runApp(App());
}
