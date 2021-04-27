import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/driver.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/appInputText.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
import 'package:rider_frontend/widgets/circularImage.dart';
import 'package:rider_frontend/widgets/goBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

enum FeedbackComponent {
  cleanliness_went_well,
  safety_went_well,
  waiting_time_went_well,
  another,
}

class RateDriver extends StatefulWidget {
  static String routeName = "RateDriver";

  RateDriverState createState() => RateDriverState();
}

class RateDriverState extends State<RateDriver> {
  String _rateDescription;
  int _rate;
  IconData _cleanlinessIcon;
  IconData _safetyIcon;
  IconData _waitingTimeIcon;
  IconData _anotherIcon;
  FocusNode _textFieldFocusNode;
  TextEditingController _textFieldController;
  Map<FeedbackComponent, bool> feedbackComponents;
  bool _showThankYouMessage;
  bool activateButton;
  bool _lockScreen;

  @override
  void initState() {
    _rateDescription = "nota geral";
    _rate = 0;
    _cleanlinessIcon = Icons.check_box_outline_blank;
    _safetyIcon = Icons.check_box_outline_blank;
    _waitingTimeIcon = Icons.check_box_outline_blank;
    _anotherIcon = Icons.check_box_outline_blank;
    _textFieldFocusNode = FocusNode();
    _textFieldController = TextEditingController();
    feedbackComponents = {};
    _lockScreen = false;
    activateButton = false;
    _showThankYouMessage = false;
    super.initState();
  }

  @override
  void dispose() {
    _textFieldFocusNode.dispose();
    super.dispose();
  }

  void rateDriver(int rate) {
    if (_lockScreen) {
      return;
    }
    switch (rate) {
      case 1:
        _rate = 1;
        _rateDescription = "péssima";
        break;
      case 2:
        _rate = 2;
        _rateDescription = "ruim";
        break;
      case 3:
        _rate = 3;
        _rateDescription = "regular";
        break;
      case 4:
        _rate = 4;
        _rateDescription = "boa";
        break;
      case 5:
        _rate = 5;
        _rateDescription = "excelente";
        break;
      default:
        _rate = 0;
        _rateDescription = "nota geral";
        break;
    }

    // every time the client changes the score, clear out feedback components
    // so they truly reflect the client's intentions
    feedbackComponents.clear();
    _cleanlinessIcon = Icons.check_box_outline_blank;
    _safetyIcon = Icons.check_box_outline_blank;
    _waitingTimeIcon = Icons.check_box_outline_blank;
    _anotherIcon = Icons.check_box_outline_blank;
    _textFieldController.text = "";

    if (_rate > 0) {
      activateButton = true;
    }

    setState(() {});
  }

  void selectFeedback(FeedbackComponent feedback) {
    if (_lockScreen) {
      return;
    }
    bool value = _rate == 5;
    switch (feedback) {
      case FeedbackComponent.cleanliness_went_well:
        if (_cleanlinessIcon == Icons.check_box_outline_blank) {
          // toggle icon
          _cleanlinessIcon = Icons.check_box_rounded;
          // set feedback
          feedbackComponents[FeedbackComponent.cleanliness_went_well] = value;
        } else {
          // toggle icon
          _cleanlinessIcon = Icons.check_box_outline_blank;
          // remove feedback
          feedbackComponents.remove(FeedbackComponent.cleanliness_went_well);
        }
        break;
      case FeedbackComponent.safety_went_well:
        if (_safetyIcon == Icons.check_box_outline_blank) {
          _safetyIcon = Icons.check_box_rounded;
          feedbackComponents[FeedbackComponent.safety_went_well] = value;
        } else {
          _safetyIcon = Icons.check_box_outline_blank;
          feedbackComponents.remove(FeedbackComponent.safety_went_well);
        }
        break;
      case FeedbackComponent.waiting_time_went_well:
        if (_waitingTimeIcon == Icons.check_box_outline_blank) {
          _waitingTimeIcon = Icons.check_box_rounded;
          feedbackComponents[FeedbackComponent.waiting_time_went_well] = value;
        } else {
          _waitingTimeIcon = Icons.check_box_outline_blank;
          feedbackComponents.remove(FeedbackComponent.waiting_time_went_well);
        }
        break;
      case FeedbackComponent.another:
        if (_anotherIcon == Icons.check_box_outline_blank) {
          _anotherIcon = Icons.check_box_rounded;
        } else {
          _anotherIcon = Icons.check_box_outline_blank;
        }
        break;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    DriverModel driver = Provider.of<DriverModel>(context);
    TripModel trip = Provider.of<TripModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: OverallPadding(
        child: _showThankYouMessage
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Obrigado pela avaliação!",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: AppColor.primaryPink,
                    ),
                  ),
                  SizedBox(height: screenHeight / 50),
                  Text(
                    "Até a próxima.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: AppColor.disabled,
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      GoBackButton(
                        icon: Icons.close,
                        onPressed: _lockScreen
                            ? () {}
                            : () {
                                Navigator.pop(context);
                              },
                      ),
                      Spacer(),
                    ],
                  ),
                  SizedBox(height: screenHeight / 100),
                  Text(
                    "R\$ " + trip.farePrice.toString(),
                    style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w700,
                        color: Colors.black),
                  ),
                  SizedBox(height: screenHeight / 200),
                  Text(
                    "Pago com cartão •••• 8709", // TODO: make dynamic
                    style: TextStyle(fontSize: 15, color: Colors.green),
                  ),
                  SizedBox(height: screenHeight / (_rate > 0 ? 100 : 50)),
                  Divider(thickness: 0.1, color: Colors.black),
                  SizedBox(height: screenHeight / (_rate > 0 ? 100 : 50)),
                  Text(
                    "Como foi a sua corrida com " + driver.name + "?",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: screenHeight / 50),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularImage(
                        size: screenHeight / 9,
                        imageFile: driver.profileImage == null
                            ? AssetImage("images/user_icon.png")
                            : driver.profileImage.file,
                      ),
                      Spacer(),
                      Column(
                        children: [
                          Text(
                            _rateDescription,
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              GestureDetector(
                                onTap: () => rateDriver(1),
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: screenWidth / 100),
                                  child: Icon(
                                    _rate >= 1
                                        ? Icons.star_sharp
                                        : Icons.star_border_sharp,
                                    size: 35,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => rateDriver(2),
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: screenWidth / 100),
                                  child: Icon(
                                    _rate >= 2
                                        ? Icons.star_sharp
                                        : Icons.star_border_sharp,
                                    size: 35,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => rateDriver(3),
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: screenWidth / 100),
                                  child: Icon(
                                    _rate >= 3
                                        ? Icons.star_sharp
                                        : Icons.star_border_sharp,
                                    size: 35,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => rateDriver(4),
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: screenWidth / 100),
                                  child: Icon(
                                    _rate >= 4
                                        ? Icons.star_sharp
                                        : Icons.star_border_sharp,
                                    size: 35,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () => rateDriver(5),
                                child: Padding(
                                  padding:
                                      EdgeInsets.only(right: screenWidth / 100),
                                  child: Icon(
                                    _rate >= 5
                                        ? Icons.star_sharp
                                        : Icons.star_border_sharp,
                                    size: 35,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    ],
                  ),
                  SizedBox(height: screenHeight / (_rate > 0 ? 100 : 50)),
                  Divider(thickness: 0.1, color: Colors.black),
                  SizedBox(height: screenHeight / (_rate > 0 ? 100 : 50)),
                  _rate ==
                          0 // hide feedback components if user hasn't tapped stars
                      ? Container()
                      : Column(
                          children: [
                            // hide feedback compoennts if text field is focused
                            !_textFieldFocusNode.hasFocus
                                ? Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            _rate > 4
                                                ? "O que foi excelente?"
                                                : "Como podemos melhorar?",
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          Spacer(),
                                        ],
                                      ),
                                      SizedBox(height: screenHeight / 100),
                                      BorderlessButton(
                                        onTap: () => selectFeedback(
                                            FeedbackComponent
                                                .cleanliness_went_well),
                                        primaryText:
                                            "Limpeza da moto ou capacete.",
                                        iconRight: _cleanlinessIcon,
                                        iconRightColor: AppColor.primaryPink,
                                        primaryTextSize: 15,
                                        paddingTop: screenHeight / 100,
                                        paddingBottom: screenHeight / 100,
                                      ),
                                      BorderlessButton(
                                        onTap: () => selectFeedback(
                                            FeedbackComponent.safety_went_well),
                                        primaryText: "Segurança ao pilotar.",
                                        iconRight: _safetyIcon,
                                        iconRightColor: AppColor.primaryPink,
                                        primaryTextSize: 15,
                                        paddingTop: screenHeight / 100,
                                        paddingBottom: screenHeight / 100,
                                      ),
                                      BorderlessButton(
                                        onTap: () => selectFeedback(
                                            FeedbackComponent
                                                .waiting_time_went_well),
                                        primaryText: "Tempo de espera.",
                                        iconRight: _waitingTimeIcon,
                                        iconRightColor: AppColor.primaryPink,
                                        primaryTextSize: 15,
                                        paddingTop: screenHeight / 100,
                                        paddingBottom: screenHeight / 100,
                                      ),
                                      BorderlessButton(
                                        onTap: () => selectFeedback(
                                            FeedbackComponent.another),
                                        primaryText: "Outro",
                                        iconRight: _anotherIcon,
                                        iconRightColor: AppColor.primaryPink,
                                        primaryTextSize: 15,
                                        paddingTop: screenHeight / 100,
                                        paddingBottom: screenHeight / 100,
                                      ),
                                      SizedBox(height: screenHeight / 100),
                                    ],
                                  )
                                : Container(),
                            Column(
                              children: [
                                // show text field if user has tapped "another"
                                _anotherIcon == Icons.check_box_rounded
                                    ? AppInputText(
                                        hintText: "descreva",
                                        hintColor: AppColor.disabled,
                                        maxLines: 1,
                                        inputFormatters: [
                                          LengthLimitingTextInputFormatter(150),
                                        ],
                                        fontSize: 15,
                                        focusNode: _textFieldFocusNode,
                                        controller: _textFieldController,
                                        enabled: !_lockScreen,
                                        onSubmittedCallback: (String v) {
                                          _textFieldFocusNode.unfocus();
                                        },
                                      )
                                    : Container(),
                              ],
                            )
                          ],
                        ),
                  Spacer(),
                  AppButton(
                    textData: "Avaliar",
                    buttonColor: activateButton
                        ? AppColor.primaryPink
                        : AppColor.disabled,
                    onTapCallBack: (!activateButton || _lockScreen)
                        ? () {}
                        : () async {
                            // lock screen and show message
                            setState(() {
                              _lockScreen = true;
                              _showThankYouMessage = true;
                            });

                            // call rate Driver
                            firebase.functions.rateDriver(
                              driverID: driver.id,
                              score: _rate,
                              feedbackComponents: feedbackComponents,
                              feedbackMessage: _textFieldController.text,
                            );
                            // wait 3 seconds then pop back
                            await Future.delayed(Duration(seconds: 3));
                            Navigator.pop(context);
                          },
                  ),
                ],
              ),
      ),
    );
  }
}
