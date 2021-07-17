import 'package:flutter/material.dart';
import 'package:flutter_credit_card/credit_card_widget.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/goBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

class CreditCardDetailArguments {
  final CreditCard creditCard;

  CreditCardDetailArguments({@required this.creditCard});
}

class CreditCardDetail extends StatefulWidget {
  static String routeName = "CreditCardDetail";
  final CreditCard creditCard;

  CreditCardDetail({@required this.creditCard});

  CreditCardDetailState createState() => CreditCardDetailState();
}

class CreditCardDetailState extends State<CreditCardDetail> {
  Widget buttonChild;

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OverallPadding(
            bottom: screenHeight / 15,
            child: Row(
              children: [
                GoBackButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                Spacer(),
              ],
            ),
          ),
          OverallPadding(
            top: 0,
            bottom: screenHeight / 30,
            child: Column(children: [
              Text(
                "Cartão de crédito",
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black),
              ),
            ]),
          ),
          CreditCardWidget(
            cardNumber: formatCreditCardNumber(
                widget.creditCard.firstDigits, widget.creditCard.lastDigits),
            expiryDate: formatExpirationDate(widget.creditCard.expirationDate),
            cardHolderName: widget.creditCard.holderName,
            cvvCode: "",
            showBackView: false,
          ),
          Spacer(),
          OverallPadding(
            child: AppButton(
                textData: "Deletar",
                child: buttonChild,
                onTapCallBack: () async {
                  await buttonCallback(context);
                }),
          ),
        ],
      ),
    );
  }

  Future<void> buttonCallback(BuildContext context) async {
    // ensure user is connected to the internet
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    if (!connectivity.hasConnection) {
      await connectivity.alertWhenOffline(
        context,
        message: "Conecte-se à internet para deletar o cartão.",
      );
      return;
    }

    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

    UserModel user = Provider.of<UserModel>(context, listen: false);
    final deleteConfirmed = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return YesNoDialog(
          title: "Tem certeza?",
          content: "Você pode adicioná-lo novamente depois.",
          onPressedYes: () {
            Navigator.pop(context, true);
          },
          onPressedNo: () {
            Navigator.pop(context, false);
          },
        );
      },
    ) as bool;

    if (deleteConfirmed) {
      setState(() {
        buttonChild = CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        );
      });

      try {
        // remove credit card in backend and locally then pop back
        await firebase.functions.deleteCard(widget.creditCard.id);
        user.removeCreditCardByID(widget.creditCard.id);
        Navigator.pop(context);
      } catch (e) {
        // alert user on failure
        setState(() {
          buttonChild = null;
        });
        await showOkDialog(
          context: context,
          title: "Falha ao deletar cartão.",
          content: "Verifique a sua conexão com a internet e tente novamente.",
        );
        return;
      }
    }
  }
}

String formatExpirationDate(String date) {
  return date.substring(0, 2) + "/" + date.substring(2);
}

String formatCreditCardNumber(String firstDigits, String lastDigits) {
  return firstDigits.substring(0, 4) +
      "  " +
      firstDigits.substring(4) +
      "00  " +
      "0000  " +
      lastDigits;
}

BoxDecoration getDecoration() {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(5),
    border: Border.all(color: Colors.black, width: 0.5),
  );
}
