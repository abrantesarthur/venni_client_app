import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/addCreditCard.dart';
import 'package:rider_frontend/screens/cashDetail.dart';
import 'package:rider_frontend/screens/creditCardDetail.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';

enum PaymentsMode { display, pick }

class PaymentsArguments {
  final PaymentsMode mode;

  PaymentsArguments({@required this.mode});
}

class Payments extends StatefulWidget {
  static String routeName = "Payments";
  final PaymentsMode mode;

  Payments({@required this.mode});

  @override
  PaymentsState createState() => PaymentsState();
}

class PaymentsState extends State<Payments> {
  @override
  Widget build(BuildContext context) {
    UserModel user = Provider.of<UserModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    final screenHeight = MediaQuery.of(context).size.height;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    return GoBackScaffold(
      title: widget.mode == PaymentsMode.display
          ? "Formas de Pagamento"
          : "Escolha a forma de pagamento",
      children: [
        Column(
          children: [
            BorderlessButton(
              svgLeftPath: "images/money.svg",
              svgLeftWidth: 28,
              iconRight: widget.mode == PaymentsMode.display
                  ? Icons.keyboard_arrow_right
                  : null,
              iconRightSize: 15,
              primaryText: "Dinheiro",
              paddingBottom: screenHeight / 200,
              // TODO: extract to function
              onTap: () {
                if (widget.mode == PaymentsMode.pick) {
                  // set 'cash' as default payment method locally and remotely
                  user.setDefaultPaymentMethod(
                    ClientPaymentMethod(type: PaymentMethodType.cash),
                  );
                  firebase.functions.setDefaultPaymentMethod();
                  // go back to previous screen
                  Navigator.pop(context);
                } else {
                  Navigator.pushNamed(context, CashDetail.routeName);
                }
              },
            ),
            Divider(thickness: 0.1, color: Colors.black),
            user.creditCards != null && user.creditCards.length > 0
                ? Column(
                    children: [
                      MediaQuery.removePadding(
                        context: context,
                        removeTop: true,
                        removeBottom: true,
                        child: ListView.separated(
                            shrinkWrap: true,
                            itemBuilder: (context, index) {
                              String brand =
                                  user.creditCards[index].brand.getString();
                              return BorderlessButton(
                                iconLeft: brand.isEmpty || brand == "aura"
                                    ? Icons.credit_card
                                    : null,
                                svgLeftPath: "images/" + brand + ".svg",
                                svgLeftWidth: 30,
                                iconRight: widget.mode == PaymentsMode.display
                                    ? Icons.keyboard_arrow_right
                                    : null,
                                primaryText: "•••• " +
                                    user.creditCards[index].lastDigits,
                                paddingTop: screenHeight / 200,
                                paddingBottom: screenHeight / 200,
                                onTap: () {
                                  // if mode is pick payment method
                                  if (widget.mode == PaymentsMode.pick) {
                                    // set 'credit_card' as default payment method locally and remotely
                                    user.setDefaultPaymentMethod(
                                      ClientPaymentMethod(
                                        type: PaymentMethodType.credit_card,
                                        creditCardID:
                                            user.creditCards[index].id,
                                      ),
                                    );
                                    firebase.functions.setDefaultPaymentMethod(
                                      cardID: user.creditCards[index].id,
                                    );
                                    // go back to previous screen
                                    Navigator.pop(context);
                                  } else {
                                    // if mode is display payment method, show credit card detailadicionar
                                    Navigator.pushNamed(
                                      context,
                                      CreditCardDetail.routeName,
                                      arguments: CreditCardDetailArguments(
                                        creditCard: user.creditCards[index],
                                      ),
                                    );
                                  }
                                },
                              );
                            },
                            separatorBuilder: (context, index) {
                              return Divider(
                                  thickness: 0.1, color: Colors.black);
                            },
                            itemCount: user.creditCards.length),
                      ),
                      Divider(thickness: 0.1, color: Colors.black),
                    ],
                  )
                : Container(),
            user.creditCards == null ||
                    user.creditCards.length < 5 // user can add at most 5 cards
                ? BorderlessButton(
                    iconLeft: Icons.add,
                    iconLeftSize: 24,
                    iconLeftColor: AppColor.primaryPink,
                    primaryText: "Adicionar cartão de crédito",
                    primaryTextColor: AppColor.primaryPink,
                    paddingTop: screenHeight / 200,
                    paddingBottom: screenHeight / 200,
                    onTap: () async {
                      if (!connectivity.hasConnection) {
                        await connectivity.alertWhenOffline(
                          context,
                          message:
                              "Conecte-se à internet para adicionar um cartão.",
                        );
                        return;
                      }
                      final addedCard = await Navigator.pushNamed(
                        context,
                        AddCreditCard.routeName,
                      ) as CreditCard;

                      // if we are in pick mode
                      if (widget.mode == PaymentsMode.pick) {
                        //set added card as default locally and remotely
                        user.setDefaultPaymentMethod(
                          ClientPaymentMethod(
                            type: PaymentMethodType.credit_card,
                            creditCardID: addedCard.id,
                          ),
                        );
                        firebase.functions.setDefaultPaymentMethod(
                          cardID: addedCard.id,
                        );
                        // pop back
                        Navigator.pop(context);
                      }
                    },
                  )
                : Container()
          ],
        )
      ],
    );
  }
}

// TODO: tapping payment method in pick mode sets it as default locally and remotely and pops back
// TODO: adding card in pick mode also sets it as default
