import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/creditCard.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';

class Payments extends StatefulWidget {
  static String routeName = "Payments";

  @override
  PaymentsState createState() => PaymentsState();
}

// TODO: use this same screen so user can select payment
class PaymentsState extends State<Payments> {
  @override
  Widget build(BuildContext context) {
    UserModel user = Provider.of<UserModel>(context);
    final screenHeight = MediaQuery.of(context).size.height;

    return GoBackScaffold(
      title: "Formas de Pagamento",
      children: [
        Column(
          children: [
            BorderlessButton(
              iconLeft: Icons.money,
              iconLeftSize: 30,
              iconRight: Icons.keyboard_arrow_right,
              iconRightSize: 15,
              primaryText: "Dinheiro",
              paddingBottom: screenHeight / 200,
              onTap: () {},
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
                                iconRight: Icons.keyboard_arrow_right,
                                primaryText: "•••• " +
                                    user.creditCards[index].lastDigits,
                                paddingTop: screenHeight / 200,
                                paddingBottom: screenHeight / 200,
                                onTap: () {},
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
            user.creditCards != null &&
                    user.creditCards.length < 5 // user can add at most 5 cards
                ? BorderlessButton(
                    iconLeft: Icons.add,
                    iconLeftSize: 24,
                    iconLeftColor: AppColor.primaryPink,
                    primaryText: "Adicionar cartão de crédito",
                    primaryTextColor: AppColor.primaryPink,
                    paddingTop: screenHeight / 200,
                    paddingBottom: screenHeight / 200,
                    onTap: () {
                      Navigator.pushNamed(context, AddCreditCard.routeName);
                    },
                  )
                : Container()
          ],
        )
      ],
    );
  }
}
