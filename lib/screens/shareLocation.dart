import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/appButton.dart';

class ShareLocationArguments {
  String push;
  ShareLocationArguments({@required this.push});
}

class ShareLocation extends StatefulWidget {
  static String routeName = "ShareLocation";
  final String push;

  ShareLocation({@required this.push});

  @override
  ShareLocationState createState() => ShareLocationState();
}

class ShareLocationState extends State<ShareLocation> {
  bool reload;

  @override
  void initState() {
    super.initState();
    reload = false;
  }

  @override
  Widget build(BuildContext context) {
    UserModel user = Provider.of<UserModel>(context, listen: false);
    return Splash(
      text: "Compartilhe sua localização",
      button: reload
          ? AppButton(
              buttonColor: Colors.white,
              textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColor.primaryPink),
              borderRadius: 10.0,
              textData: "Recarregar Aplicatiavo",
              onTapCallBack: () async {
                Navigator.pushReplacementNamed(context, widget.push);
              },
            )
          : AppButton(
              buttonColor: Colors.white,
              textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                  color: AppColor.primaryPink),
              borderRadius: 10.0,
              textData: "Abrir Configurações",
              onTapCallBack: () async {
                await user.getGeocoding();
                setState(() {
                  reload = true;
                });
              },
            ),
    );
  }
}
