import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart' as DotEnv;
import 'package:rider_frontend/app.dart';
import 'package:rider_frontend/config/config.dart';

void main() async {
  await DotEnv.load(fileName: ".env");
  AppConfig(flavor: Flavor.STAG);

  runApp(App());
}
