import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/pastTrips.dart';
import 'package:rider_frontend/screens/payTrip.dart';
import 'package:rider_frontend/screens/payments.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/menuButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';

class UnpaidTripWidget extends StatelessWidget {
  GlobalKey<ScaffoldState> scaffoldKey;
  UnpaidTripWidget({@required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverallPadding(
          child: MenuButton(onPressed: () {
            scaffoldKey.currentState.openDrawer();
            // trigger getUserRating so it is updated in case it's changed
            try {
              firebase.database.getClientData(firebase).then(
                    (value) => user.setRating(value.rating),
                  );
            } catch (e) {}
          }),
        ),
        Spacer(),
        _buildPendingPaymentFloatingCard(context, user.unpaidTrip, user),
      ],
    );
  }

  // TODO: update map paddings
  Widget _buildPendingPaymentFloatingCard(
    BuildContext context,
    Trip trip,
    UserModel user,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    return FloatingCard(
      leftMargin: 0,
      rightMargin: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: screenHeight / 200),
          Text(
            "Pagamento pendente",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColor.primaryPink,
            ),
          ),
          SizedBox(height: screenHeight / 200),
          Divider(thickness: 0.1, color: Colors.black),
          SizedBox(height: screenHeight / 200),
          buildPastTrip(context, trip),
          SizedBox(height: screenHeight / 200),
          Divider(thickness: 0.1, color: Colors.black),
          SizedBox(height: screenHeight / 200),
          Padding(
            padding: const EdgeInsets.only(
              bottom: 40,
              left: 5,
              right: 5,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: BorderlessButton(
                    svgLeftPath: user.getPaymentMethodSvgPath(context),
                    svgLeftWidth: 28,
                    primaryText: user.getPaymentMethodDescription(context),
                    primaryTextWeight: FontWeight.bold,
                    iconRight: Icons.keyboard_arrow_right,
                    iconRightColor: Colors.black,
                    paddingTop: screenHeight / 200,
                    paddingBottom: screenHeight / 200,
                    onTap: () async {
                      await Navigator.pushNamed(
                        context,
                        Payments.routeName,
                        arguments: PaymentsArguments(mode: PaymentsMode.pick),
                      );
                    },
                  ),
                ),
                Spacer(flex: 1),
                AppButton(
                  textData: "Pagar",
                  borderRadius: 30.0,
                  height: screenHeight / 15,
                  width: screenWidth / 2.5,
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onTapCallBack: () => payTripCallback(context, trip, user),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> payTripCallback(
  BuildContext context,
  Trip trip,
  UserModel user,
) async {
  // make sure user is connected to the internet
  ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
    context,
    listen: false,
  );
  if (!connectivity.hasConnection) {
    await connectivity.alertWhenOffline(context);
    return;
  }
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

  // alert user in case they're paying with cash
  if (user.defaultPaymentMethod.type == PaymentMethodType.cash) {
    final chooseCard = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pagamento em dinheiro não permitido."),
          actions: [
            TextButton(
              child: Text(
                "cancelar",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text(
                "escolher cartão",
                style: TextStyle(
                  color: AppColor.primaryPink,
                  fontSize: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    ) as bool;
    // push payments screen if user decides to choose a card
    if (chooseCard) {
      await Navigator.pushNamed(
        context,
        Payments.routeName,
        arguments: PaymentsArguments(mode: PaymentsMode.pick),
      );
    }
    // return, so PayTrip is only pushed if payment method is credit card
    return;
  }

  // push PayTrip screen after user picks a card
  final paid = await Navigator.pushNamed(
    context,
    PayTrip.routeName,
    arguments: PayTripArguments(
      firebase: firebase,
      cardID: user.defaultPaymentMethod.creditCardID,
    ),
  ) as bool;

  // show warnings about payment status
  if (paid) {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Pagamento concluido!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: Text(
              "Muito obrigado! Agora você pode continuar pedindo corridas."),
          actions: [
            TextButton(
              child: Text(
                "ok",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    );
  } else {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "O pagamento falhou!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
              "Tente novamente. Utilizar outro cartão pode resolver o problema."),
          actions: [
            TextButton(
              child: Text(
                "ok",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    );
  }
}
