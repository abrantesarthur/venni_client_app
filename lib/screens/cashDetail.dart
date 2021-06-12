import 'package:flutter/material.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/goBackScaffold.dart';

class CashDetail extends StatelessWidget {
  static String routeName = "CashDetail";

  @override
  Widget build(BuildContext context) {
    return GoBackScaffold(
      title: "Pagamentos em dinheiro",
      children: [
        Text(
          "Para maior praticidade, adicione um cartão de crédito à sua conta. " +
              "Assim, o pagamento é feito automaticamente e com segurança. " +
              "Caso opte por pagamentos em dinheiro, o " +
              "valor a ser pago será mostrado ao final da corrida para você " +
              "e para o partner. Garanta que você tenha troco!",
          style: TextStyle(color: AppColor.disabled),
        ),
      ],
    );
  }
}
