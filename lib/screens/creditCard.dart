import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';

class AddCreditCard extends StatefulWidget {
  static String routeName = "AddCreditCard";

  @override
  AddCreditCardState createState() => AddCreditCardState();
}

class AddCreditCardState extends State<AddCreditCard> {
  bool lockScreen = false;
  States selectedState;
  String creditCardNumber;
  String expirationDate;
  String cpf;
  String cep;
  Widget buttonChild;

  bool cardNumberIsValid = true;
  bool expirationDateIsValid = true;
  bool cpfIsValid = true;
  bool nameIsValid = true;
  bool cvvIsValid = true;
  bool streetNameIsValid = true;
  bool streetNumberIsValid = true;
  bool cityIsValid = true;
  bool cepIsValid = true;

  TextEditingController creditCardController = TextEditingController();
  TextEditingController expirationDateController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  TextEditingController nameController = TextEditingController();
  TextEditingController cvvController = TextEditingController();
  TextEditingController streetNameController = TextEditingController();
  TextEditingController streetNumberController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController cepController = TextEditingController();

  FocusNode creditCardNumberFocusNode = FocusNode();
  FocusNode nameFocusNode = FocusNode();
  FocusNode expirationDateFocusNode = FocusNode();
  FocusNode cvvFocusNode = FocusNode();
  FocusNode cpfFocusNode = FocusNode();
  FocusNode streetNameFocusNode = FocusNode();
  FocusNode streetNumberFocusNode = FocusNode();
  FocusNode cityFocusNode = FocusNode();
  FocusNode stateFocusNode = FocusNode();
  FocusNode cepFocusNode = FocusNode();

  @override
  void dispose() {
    creditCardController.dispose();
    expirationDateController.dispose();
    cpfController.dispose();
    nameController.dispose();
    cvvController.dispose();
    streetNameController.dispose();
    streetNumberController.dispose();
    cityController.dispose();
    cepController.dispose();
    creditCardNumberFocusNode.dispose();
    nameFocusNode.dispose();
    expirationDateFocusNode.dispose();
    cvvFocusNode.dispose();
    cpfFocusNode.dispose();
    streetNameFocusNode.dispose();
    streetNumberFocusNode.dispose();
    cityFocusNode.dispose();
    stateFocusNode.dispose();
    cepFocusNode.dispose();

    super.dispose();
  }

  @override
  void initState() {
    creditCardController.addListener(() {
      creditCardNumber = creditCardController.text.getCleanedCardNumber();
      cardNumberIsValid = creditCardNumber.isValidCardNumber();
      setState(() {});
    });

    expirationDateController.addListener(() {
      setState(() {
        expirationDate =
            expirationDateController.text.getCleanedExpirationDate();
        expirationDateIsValid = expirationDate.isValidExpirationDate();
      });
    });

    cpfController.addListener(() {
      setState(() {
        cpf = cpfController.text.getCleanedCPF();
        cpfIsValid = cpf.isValidCPF();
      });
    });

    nameController.addListener(() {
      setState(() {
        nameIsValid = nameController.text.length > 4;
      });
    });

    cvvController.addListener(() {
      setState(() {
        cvvIsValid = cvvController.text.length >= 3;
      });
    });

    streetNameController.addListener(() {
      setState(() {
        streetNameIsValid = streetNameController.text.length > 0;
      });
    });

    streetNumberController.addListener(() {
      setState(() {
        streetNumberIsValid = streetNumberController.text.length > 0;
      });
    });

    cityController.addListener(() {
      setState(() {
        cityIsValid = cityController.text.length > 2;
      });
    });

    cepController.addListener(() {
      setState(() {
        cepIsValid = cepController.text.length == 9;
        cep = cepIsValid
            ? cepController.text.substring(0, 5) +
                cepController.text.substring(6)
            : "";
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.white,
      body: OverallPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ArrowBackButton(
                  onTapCallback:
                      lockScreen ? () {} : () => Navigator.pop(context),
                ),
                Spacer(),
              ],
            ),
            SizedBox(height: screenHeight / 30),
            Text(
              "Adicionar cartão",
              style: TextStyle(
                color: Colors.black,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: screenHeight / 30),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              width: screenWidth / 1.4,
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 14.0,
                                    color: Colors.black,
                                  ),
                                  children: [
                                    TextSpan(
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                      text: "Não se preocupe ",
                                    ),
                                    TextSpan(
                                      text:
                                          " - guardamos seus dados com 100% de segurança!",
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Icon(
                              Icons.lock,
                              color: AppColor.primaryPink,
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight / 50),
                        buildInputText(
                          context: context,
                          title: "Número do cartão",
                          hintText: "0000 0000 0000 0000",
                          iconData: Icons.credit_card,
                          controller: creditCardController,
                          enabled: !lockScreen,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(19),
                            FilteringTextInputFormatter.digitsOnly,
                            MaskedInputFormatter(mask: "xxxx-xxxx-xxxx-"),
                          ],
                          thisFocusNode: creditCardNumberFocusNode,
                        ),
                        buildWarning(
                          fieldIsValid: cardNumberIsValid,
                          focusNode: creditCardNumberFocusNode,
                          controller: creditCardController,
                          whenEmpty: "insira um número de cartão de crédito",
                          whenFail: "número de cartão de crédito inválido",
                        ),
                        SizedBox(height: screenHeight / 50),
                        buildInputText(
                          context: context,
                          title: "Nome (como está no cartão)",
                          hintText: "Fulano de Tal",
                          keyboardType: TextInputType.text,
                          controller: nameController,
                          enabled: !lockScreen,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                            FilteringTextInputFormatter.allow(
                                RegExp('[a-zA-Z ]')),
                          ],
                          thisFocusNode: nameFocusNode,
                        ),
                        buildWarning(
                          fieldIsValid: nameIsValid,
                          focusNode: nameFocusNode,
                          controller: nameController,
                          whenEmpty: "insira o nome do titular",
                          whenFail: "insira um nome válido",
                        ),
                        SizedBox(height: screenHeight / 50),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputText(
                                  context: context,
                                  title: "Data de expiração",
                                  hintText: "MM/AA",
                                  width: screenWidth / 2.8,
                                  controller: expirationDateController,
                                  enabled: !lockScreen,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(5),
                                    FilteringTextInputFormatter.digitsOnly,
                                    MaskedInputFormatter(mask: "xx/xx"),
                                  ],
                                  thisFocusNode: expirationDateFocusNode,
                                ),
                                buildWarning(
                                  fieldIsValid: expirationDateIsValid,
                                  focusNode: expirationDateFocusNode,
                                  controller: expirationDateController,
                                  whenEmpty: "insira uma data",
                                  whenFail: "data inválida",
                                ),
                              ],
                            ),
                            Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputText(
                                  context: context,
                                  title: "Código de segurança",
                                  hintText: "000",
                                  width: screenWidth / 2.8,
                                  controller: cvvController,
                                  enabled: !lockScreen,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(4),
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  thisFocusNode: cvvFocusNode,
                                ),
                                buildWarning(
                                  fieldIsValid: cvvIsValid,
                                  focusNode: cvvFocusNode,
                                  controller: cvvController,
                                  whenEmpty: "insira um cvv",
                                  whenFail: "cvv inválido",
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight / 50),
                        buildInputText(
                          context: context,
                          title: "CPF do titular",
                          hintText: "000.000.000-00",
                          controller: cpfController,
                          enabled: !lockScreen,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(14),
                            FilteringTextInputFormatter.digitsOnly,
                            MaskedInputFormatter(mask: "xxx.xxx.xxx-xx")
                          ],
                          thisFocusNode: cpfFocusNode,
                        ),
                        buildWarning(
                          fieldIsValid: cpfIsValid,
                          focusNode: cpfFocusNode,
                          controller: cpfController,
                          whenEmpty: "insira um número de CPF",
                          whenFail: "CPF inválido",
                        ),
                        SizedBox(height: screenHeight / 30),
                        Text(
                          "Endereço de cobrança",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColor.disabled,
                          ),
                        ),
                        SizedBox(height: screenHeight / 50),
                        buildInputText(
                          context: context,
                          title: "Rua",
                          hintText: "Rua Ciclano de Tal",
                          keyboardType: TextInputType.name,
                          controller: streetNameController,
                          enabled: !lockScreen,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50)
                          ],
                          thisFocusNode: streetNameFocusNode,
                        ),
                        buildWarning(
                          fieldIsValid: streetNameIsValid,
                          focusNode: streetNameFocusNode,
                          controller: streetNameController,
                          whenEmpty: "insira o nome da rua",
                          whenFail: "rua inválida",
                        ),
                        SizedBox(height: screenHeight / 50),
                        buildInputText(
                          context: context,
                          title: "Número",
                          hintText: "000",
                          controller: streetNumberController,
                          enabled: !lockScreen,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(6),
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          thisFocusNode: streetNumberFocusNode,
                        ),
                        buildWarning(
                          fieldIsValid: streetNumberIsValid,
                          focusNode: streetNumberFocusNode,
                          controller: streetNumberController,
                          whenEmpty: "insira um número",
                          whenFail: "número inválido",
                        ),
                        SizedBox(height: screenHeight / 50),
                        buildInputText(
                          context: context,
                          title: "Cidade",
                          hintText: "Tangamandápio",
                          keyboardType: TextInputType.name,
                          controller: cityController,
                          enabled: !lockScreen,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(40)
                          ],
                          thisFocusNode: cityFocusNode,
                        ),
                        buildWarning(
                          fieldIsValid: cityIsValid,
                          focusNode: cityFocusNode,
                          controller: cityController,
                          whenEmpty: "insira uma cidade",
                          whenFail: "cidade inválida",
                        ),
                        SizedBox(height: screenHeight / 50),
                        Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Estado",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColor.disabled,
                                  ),
                                ),
                                Container(
                                  width: screenWidth / 3,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: Colors.black.withOpacity(0.04),
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: ButtonTheme(
                                      alignedDropdown: true,
                                      child: DropdownButton(
                                          focusNode: stateFocusNode,
                                          value: selectedState,
                                          hint: Text(
                                            "XX",
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: AppColor.disabled,
                                            ),
                                          ),
                                          onChanged: (value) {
                                            stateFocusNode.unfocus();
                                            FocusScope.of(context)
                                                .requestFocus(cepFocusNode);
                                            setState(() {
                                              selectedState = value;
                                            });
                                          },
                                          items: States.values
                                              .map((state) => DropdownMenuItem(
                                                    child: Text(state
                                                        .toString()
                                                        .substring(7)),
                                                    value: state,
                                                  ))
                                              .toList()),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Spacer(),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                buildInputText(
                                  context: context,
                                  title: "CEP",
                                  hintText: "00000-000",
                                  width: screenWidth / 2.5,
                                  controller: cepController,
                                  enabled: !lockScreen,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(9),
                                    FilteringTextInputFormatter.digitsOnly,
                                    MaskedInputFormatter(mask: "xxxxx-xxx")
                                  ],
                                  thisFocusNode: cepFocusNode,
                                ),
                                buildWarning(
                                  fieldIsValid: cepIsValid,
                                  focusNode: cepFocusNode,
                                  controller: cepController,
                                  whenEmpty: "insira um cep",
                                  whenFail: "cep inválido",
                                ),
                              ],
                            ),
                          ],
                        ),
                        SizedBox(height: screenHeight / 50),
                        Text(
                          "Para sua segurança, faremos uma pré-autorização de " +
                              "até R\$2,00 em seu cartão. Não se preocupe, essa " +
                              "é apenas uma validação e o valor não será cobrado " +
                              "em sua fatura.",
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColor.disabled,
                          ),
                        ),
                        SizedBox(height: screenHeight / 5),
                      ],
                    ),
                  ),
                  // only show button when keyboard is hidden
                  MediaQuery.of(context).viewInsets.bottom == 0
                      ? Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: AppButton(
                            child: buttonChild ??
                                Text(
                                  "Adicionar",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                    color: Colors.white,
                                  ),
                                ),
                            textData: "Adicionar",
                            buttonColor: allFieldsAreValid()
                                ? AppColor.primaryPink
                                : AppColor.disabled,
                            onTapCallBack: !lockScreen && allFieldsAreValid()
                                ? () => buttonCallback(context)
                                : () {},
                          ),
                        )
                      : Container()
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  bool allFieldsAreValid() {
    return cardNumberIsValid &&
        nameIsValid &&
        expirationDateIsValid &&
        cvvIsValid &&
        cpfIsValid &&
        streetNameIsValid &&
        streetNumberIsValid &&
        cityIsValid &&
        cepIsValid &&
        selectedState != null;
  }

  Future<void> buttonCallback(BuildContext context) async {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);

    // lock screen and show circular button
    setState(() {
      lockScreen = true;
      buttonChild = CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
      );
    });

    CreditCard card;

    try {
      card = await firebase.functions.createCard(
        CreateCardArguments(
          cardNumber: creditCardNumber,
          cardExpirationDate: expirationDate,
          cardHolderName: nameController.text.trim(),
          cpfNumber: cpf,
          phoneNumber: firebase.auth.currentUser.phoneNumber,
          email: firebase.auth.currentUser.email,
          cardCvv: cvvController.text,
          billingAddress: BillingAddress(
            country: "br",
            state: selectedState.toString().substring(7),
            city: cityController.text.trim(),
            street: streetNameController.text.trim(),
            streetNumber: streetNumberController.text,
            zipcode: cep,
          ),
        ),
      );
    } on FirebaseFunctionsException catch (e) {
      print(e);

      // unlock screen and hide circular progress indicator
      setState(() {
        lockScreen = false;
        buttonChild = null;
      });

      String warningMessage = e.code == "invalid-argument"
          ? "Dados inválidos."
          : "Algo deu errado.";

      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(warningMessage),
            content: Text(
              "Verifique os dados inseridos e tente novamente.",
              style: TextStyle(color: AppColor.disabled),
            ),
            actions: [
              TextButton(
                child: Text(
                  "ok",
                  style: TextStyle(fontSize: 18),
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        },
      );
      return;
    }

    // add created card to user's list of cards
    user.addCreditCard(card);

    setState(() {
      lockScreen = false;
      buttonChild = null;
    });
    // pop back if no error happened
    Navigator.pop(context);
  }
}

AppInputText buildInputText({
  @required BuildContext context,
  @required String title,
  @required FocusNode thisFocusNode,
  String hintText,
  IconData iconData,
  List<TextInputFormatter> inputFormatters,
  double width,
  TextInputType keyboardType,
  TextEditingController controller,
  Function onSubmittedCallback,
  bool enabled,
}) {
  return AppInputText(
    title: title,
    titleStyle: thisFocusNode.hasFocus
        ? TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColor.primaryPink,
          )
        : null,
    hintText: hintText,
    width: width,
    iconData: iconData,
    iconDataColor: AppColor.disabled,
    backgroundColor: Colors.black.withOpacity(0.03),
    hasBorders: false,
    maxLines: 1,
    inputFormatters: inputFormatters,
    keyboardType: keyboardType ?? TextInputType.numberWithOptions(signed: true),
    controller: controller,
    focusNode: thisFocusNode,
    enabled: enabled,
    onSubmittedCallback: onSubmittedCallback,
  );
}

Widget buildWarning({
  @required bool fieldIsValid,
  @required FocusNode focusNode,
  @required TextEditingController controller,
  @required String whenEmpty,
  @required String whenFail,
}) {
  return (!fieldIsValid && !focusNode.hasFocus)
      ? controller.text.length == 0
          ? Warning(
              message: whenEmpty,
              color: AppColor.secondaryYellow,
            )
          : Warning(
              message: whenFail,
              color: AppColor.secondaryYellow,
            )
      : Container();
}
