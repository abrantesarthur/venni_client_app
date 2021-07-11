import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/screens/splash.dart';

class PayTripArguments {
  final FirebaseModel firebase;
  final String cardID;

  PayTripArguments({
    @required this.firebase,
    @required this.cardID,
  });
}

class PayTrip extends StatefulWidget {
  static String routeName = "PayTrip";
  final FirebaseModel firebase;
  final String cardID;

  PayTrip({
    @required this.firebase,
    @required this.cardID,
  });

  @override
  PayTripState createState() => PayTripState();
}

class PayTripState extends State<PayTrip> {
  Future<bool> paymentResult;

  @override
  void initState() {
    paymentResult = widget.firebase.functions.captureUnpaidTrip(widget.cardID);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
        future: paymentResult,
        builder: (
          BuildContext context,
          AsyncSnapshot<bool> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // show Splash screen while waiting for confirmPayment to finish
            return Splash(
                text: "confirmando pagamento...",
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ));
          }

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            bool paid;
            if (snapshot.hasError) {
              print("some error happened");
              print(snapshot.error);
              paid = false;
            } else {
              paid = snapshot.data;
            }

            if (paid) {
              // remove unpaid trip from UserModel so user can request new trips
              UserModel user = Provider.of<UserModel>(context, listen: false);
              user.setUnpaidTrip(null);
            }

            // navigate back
            Navigator.pop(context, paid);
          });

          // this is irrelevant
          return Splash(text: "confirmando...");
        });
  }
}
