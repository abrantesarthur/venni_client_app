import 'package:flutter/material.dart';
import 'package:rider_frontend/screens/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: Login.routeName,
      routes: {Login.routeName: (context) => Login()},
    );
  }
}
