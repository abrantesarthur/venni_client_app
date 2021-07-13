import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/menuButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';

class RequestTripWidgets extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  RequestTripWidgets({@required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
      context,
      listen: false,
    );
    return OverallPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MenuButton(
            onPressed: () {
              scaffoldKey.currentState.openDrawer();
              // trigger getUserRating so it is updated in case it's changed
              try {
                firebase.database
                    .getClientData(firebase)
                    .then((value) => user.setRating(value?.rating));
              } catch (e) {}
            },
          ),
          Spacer(),
          Container(
            alignment: Alignment.bottomCenter,
            child: AppButton(
              borderRadius: 10.0,
              iconLeft: Icons.near_me,
              textData: "Para onde vamos?",
              onTapCallBack: () async {
                if (!connectivity.hasConnection) {
                  await connectivity.alertWhenOffline(context);
                  return;
                }
                final success = await Navigator.pushNamed(
                  context,
                  DefineRoute.routeName,
                  arguments: DefineRouteArguments(
                    mode: DefineRouteMode.request,
                    user: user,
                    trip: trip,
                  ),
                ) as bool;
                if (!success) {
                  await showOkDialog(
                    context: context,
                    title: "Algo deu errado",
                    content:
                        "Cheque a sua conexão com a internet e tente novamente",
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
