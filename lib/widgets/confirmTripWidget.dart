import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/timer.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/confirmTrip.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/payments.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/cancelButton.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

class ConfirmTripWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    TripModel trip = Provider.of<TripModel>(context);
    UserModel user = Provider.of<UserModel>(context);
    return Column(
      children: [
        OverallPadding(
          left: screenWidth / 30,
          right: screenWidth / 30,
          child: Row(
            children: [
              _buildCancelTripButton(context, trip),
              SizedBox(width: screenWidth / 30),
              _buildEditRouteButton(context, trip),
            ],
          ),
        ),
        Spacer(),
        _buildTripSummaryFloatingCard(context, trip, user),
      ],
    );
  }

  Widget _buildCancelTripButton(
    BuildContext context,
    TripModel trip, {
    String title,
    String content,
  }) {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    return CancelButton(
      onPressed: () async {
        // make sure user is connected to the internet
        ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
          context,
          listen: false,
        );
        if (!connectivity.hasConnection) {
          await connectivity.alertWhenOffline(
            context,
            message: "Conecte-se à internet para cancelar o pedido,",
          );
          return;
        }
        showYesNoDialog(
          context,
          title: title ?? "Cancelar Pedido?",
          content: content,
          onPressedYes: () async {
            if (!connectivity.hasConnection) {
              await connectivity.alertWhenOffline(
                context,
                message: "Conecte-se à internet para cancelar o pedido,",
              );
              return;
            }
            // cancel trip and update trip and partner models once it succeeds
            try {
              firebase.functions.cancelTrip();
            } catch (_) {}
            // update models
            trip.clear(status: TripStatus.cancelledByClient);
            partner.clear();
            Navigator.pop(context);
          },
        );
      },
    );
  }

  Widget _buildEditRouteButton(
    BuildContext context,
    TripModel trip,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    UserModel user = Provider.of<UserModel>(context, listen: false);

    return FloatingCard(
      flex: 3,
      child: InkWell(
        onTap: () async {
          Navigator.pushNamed(
            context,
            DefineRoute.routeName,
            arguments: DefineRouteArguments(
              mode: DefineRouteMode.edit,
              trip: trip,
              user: user,
            ),
          );
        },
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BorderlessButton(
                    svgLeftPath: "images/pickUpIcon.svg",
                    svgLeftWidth: 10,
                    primaryText: trip.pickUpAddress.mainText,
                    primaryTextWeight: FontWeight.bold,
                    primaryTextSize: 13,
                    primaryTextColor: AppColor.disabled,
                  ),
                  SizedBox(height: screenHeight / 150),
                  BorderlessButton(
                    svgLeftPath: "images/dropOffIcon.svg",
                    svgLeftWidth: 10,
                    primaryText: trip.dropOffAddress.mainText,
                    primaryTextWeight: FontWeight.bold,
                    primaryTextSize: 13,
                    primaryTextColor: AppColor.disabled,
                  ),
                ],
              ),
            ),
            Text(
              "Alterar",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColor.disabled,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSummaryFloatingCard(
    BuildContext context,
    TripModel trip,
    UserModel user,
  ) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

    return FloatingCard(
      leftMargin: 0,
      rightMargin: 0,
      child: Column(
        children: [
          SizedBox(height: screenHeight / 200),
          Row(
            children: [
              Text(
                "Chegada ao destino",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                trip.etaString,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: screenHeight / 100),
          Row(
            children: [
              Text(
                "Preço",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Spacer(),
              Text(
                "R\$ " + (trip.farePrice / 100).toStringAsFixed(2),
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
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
                  textData: "Confirmar",
                  borderRadius: 30.0,
                  height: screenHeight / 15,
                  width: screenWidth / 2.5,
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onTapCallBack: () => confirmTripCallback(
                    context,
                    trip,
                    firebase,
                    user,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> confirmTripCallback(
  BuildContext context,
  TripModel trip,
  FirebaseModel firebase,
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
  // alert user in case they're paying with cash
  if (user.defaultPaymentMethod.type == PaymentMethodType.cash) {
    final useCard = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar pagamento em dinheiro?"),
          content: Text(
            "Considere pagar com cartão de crédito. É prático e seguro.",
            style: TextStyle(color: AppColor.disabled),
          ),
          actions: [
            TextButton(
              child: Text(
                "usar cartão",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              child: Text(
                "confirmar",
                style: TextStyle(
                  color: AppColor.primaryPink,
                  fontSize: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    ) as bool;
    // push payments screen if user decides to pick a card
    if (useCard) {
      await Navigator.pushNamed(
        context,
        Payments.routeName,
        arguments: PaymentsArguments(mode: PaymentsMode.pick),
      );
      return;
    }
  }

  TimerModel timer = Provider.of<TimerModel>(context, listen: false);
  // push confirmation screen if user picks a card or decides to continue cash payment
  await Navigator.pushNamed(
    context,
    ConfirmTrip.routeName,
    arguments: ConfirmTripArguments(
      firebase: firebase,
      trip: trip,
      user: user,
      timer: timer,
    ),
  );
}
