import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputPassword.dart';
import 'package:rider_frontend/widgets/arrowBackButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/warning.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';
import 'package:rider_frontend/vendors/firebaseAuth.dart';

import '../models/firebase.dart';

class DeleteAccount extends StatefulWidget {
  static const String routeName = "DeleteAccount";

  DeleteAccountState createState() => DeleteAccountState();
}

class DeleteAccountState extends State<DeleteAccount> {
  TextEditingController passwordTextEditingController;
  FocusNode passwordFocusNode;
  Widget warningMessage;
  Color buttonColor;
  Widget buttonChild;
  Function buttonCallback;
  IconData badTripExperienceIcon;
  IconData badAppExperienceIcon;
  IconData hasAnotherAccountIcon;
  IconData doesntUseServiceIcon;
  IconData anotherIcon;
  Map<DeleteReason, bool> deleteReasons;

  @override
  void initState() {
    passwordTextEditingController = TextEditingController();
    passwordFocusNode = FocusNode();
    buttonCallback = null;
    buttonColor = AppColor.disabled;
    badTripExperienceIcon = Icons.check_box_outline_blank;
    badAppExperienceIcon = Icons.check_box_outline_blank;
    hasAnotherAccountIcon = Icons.check_box_outline_blank;
    doesntUseServiceIcon = Icons.check_box_outline_blank;
    anotherIcon = Icons.check_box_outline_blank;
    deleteReasons = {
      DeleteReason.badAppExperience: false,
      DeleteReason.badTripExperience: false,
      DeleteReason.hasAnotherAccount: false,
      DeleteReason.doesntUseService: false,
      DeleteReason.another: false,
    };

    passwordTextEditingController.addListener(() {
      String password = passwordTextEditingController.text;
      if (password.length < 8) {
        setState(() {
          buttonCallback = null;
          buttonColor = AppColor.disabled;
        });
      } else {
        setState(() {
          buttonCallback = _buttonCallback;
          buttonColor = AppColor.primaryPink;
        });
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    passwordTextEditingController.dispose();
    super.dispose();
  }

  void _buttonCallback(BuildContext context) {
    final FirebaseModel firebase =
        Provider.of<FirebaseModel>(context, listen: false);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return YesNoDialog(
          title: "Tem certeza?",
          content:
              "Atenção: esta operação não pode ser desfeita e você perderá todos os dados da sua conta.",
          onPressedYes: () async {
            // show loading icon
            setState(() {
              buttonChild = CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              );
            });

            // pop off dialog
            Navigator.pop(context);

            // remove focus from text field
            passwordFocusNode.unfocus();

            // clear password field
            String password = passwordTextEditingController.text;
            passwordTextEditingController.text = "";

            // submit delete reasons
            await firebase.database.submitDeleteReasons(
              reasons: deleteReasons,
              uid: firebase.auth.currentUser.uid,
            );

            // request to delete
            final response = await firebase.auth.deleteAccount(
              firebase: firebase,
              password: password,
              reasons: deleteReasons,
            );

            // show warnings if unsuccesfull
            if (response != null && !response.successful) {
              setState(() {
                warningMessage = Warning(message: response.message);
              });
            }

            // remove loading icon
            setState(() {
              buttonChild = null;
            });
          },
          onPressedNo: () {
            // pop off dialog
            Navigator.pop(context);

            // remove focus from text field
            passwordFocusNode.unfocus();
          },
        );
      },
    );
  }

  // toogleReason adds reason to map of reasons why user has chosen to delete app.
  void toggleReason(DeleteReason reason) {
    switch (reason) {
      case DeleteReason.badAppExperience:
        if (badAppExperienceIcon == Icons.check_box_outline_blank) {
          // user toogled on: switch icon and add reason to map
          badAppExperienceIcon = Icons.check_box_rounded;
          deleteReasons[DeleteReason.badAppExperience] = true;
        } else {
          // user toogled off: switch icon and remove reason from map
          badAppExperienceIcon = Icons.check_box_outline_blank;
          deleteReasons[DeleteReason.badAppExperience] = false;
        }
        break;
      case DeleteReason.badTripExperience:
        if (badTripExperienceIcon == Icons.check_box_outline_blank) {
          badTripExperienceIcon = Icons.check_box_rounded;
          deleteReasons[DeleteReason.badTripExperience] = true;
        } else {
          badTripExperienceIcon = Icons.check_box_outline_blank;
          deleteReasons[DeleteReason.badTripExperience] = false;
        }
        break;
      case DeleteReason.hasAnotherAccount:
        if (hasAnotherAccountIcon == Icons.check_box_outline_blank) {
          hasAnotherAccountIcon = Icons.check_box_rounded;
          deleteReasons[DeleteReason.hasAnotherAccount] = true;
        } else {
          hasAnotherAccountIcon = Icons.check_box_outline_blank;
          deleteReasons[DeleteReason.hasAnotherAccount] = false;
        }
        break;
      case DeleteReason.doesntUseService:
        if (doesntUseServiceIcon == Icons.check_box_outline_blank) {
          doesntUseServiceIcon = Icons.check_box_rounded;
          deleteReasons[DeleteReason.doesntUseService] = true;
        } else {
          doesntUseServiceIcon = Icons.check_box_outline_blank;
          deleteReasons[DeleteReason.doesntUseService] = false;
        }
        break;
      case DeleteReason.another:
        if (anotherIcon == Icons.check_box_outline_blank) {
          anotherIcon = Icons.check_box_rounded;
          deleteReasons[DeleteReason.another] = true;
        } else {
          anotherIcon = Icons.check_box_outline_blank;
          deleteReasons[DeleteReason.another] = false;
        }
        break;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: LayoutBuilder(builder: (
        BuildContext context,
        BoxConstraints viewportConstraints,
      ) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: OverallPadding(
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ArrowBackButton(
                            onTapCallback: () => Navigator.pop(context)),
                        Spacer(),
                      ],
                    ),
                    SizedBox(height: screenHeight / 30),
                    Text(
                      "Conte-nos o motivo para que possamos melhorar.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: screenHeight / 40),
                    BorderlessButton(
                      onTap: () => toggleReason(DeleteReason.badTripExperience),
                      primaryText: "Experiência ruim durante corrida.",
                      iconRight: badTripExperienceIcon,
                      iconRightColor: AppColor.primaryPink,
                      primaryTextSize: 16,
                    ),
                    SizedBox(height: screenHeight / 40),
                    BorderlessButton(
                      onTap: () => toggleReason(DeleteReason.hasAnotherAccount),
                      primaryText: "Tenho outra conta.",
                      iconRight: hasAnotherAccountIcon,
                      iconRightColor: AppColor.primaryPink,
                      primaryTextSize: 16,
                    ),
                    SizedBox(height: screenHeight / 40),
                    BorderlessButton(
                      onTap: () => toggleReason(DeleteReason.doesntUseService),
                      primaryText: "Não utilizo muito o serviço.",
                      iconRight: doesntUseServiceIcon,
                      iconRightColor: AppColor.primaryPink,
                      primaryTextSize: 16,
                    ),
                    SizedBox(height: screenHeight / 40),
                    BorderlessButton(
                      onTap: () => toggleReason(DeleteReason.badAppExperience),
                      primaryText: "Experiência ruim com a conta.",
                      iconRight: badAppExperienceIcon,
                      iconRightColor: AppColor.primaryPink,
                      primaryTextSize: 16,
                    ),
                    SizedBox(height: screenHeight / 40),
                    BorderlessButton(
                      onTap: () => toggleReason(DeleteReason.another),
                      primaryText: "Outro.",
                      iconRight: anotherIcon,
                      iconRightColor: AppColor.primaryPink,
                      primaryTextSize: 16,
                    ),
                    SizedBox(height: screenHeight / 40),
                    AppInputPassword(
                      controller: passwordTextEditingController,
                      focusNode: passwordFocusNode,
                      hintText: "insira sua senha",
                    ),
                    SizedBox(height: screenHeight / 40),
                    warningMessage == null
                        ? Spacer()
                        : Expanded(child: warningMessage),
                    AppButton(
                      textData: "Excluir Conta",
                      child: buttonChild,
                      buttonColor: buttonColor,
                      onTapCallBack: buttonCallback == null
                          ? () {}
                          : () => buttonCallback(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
