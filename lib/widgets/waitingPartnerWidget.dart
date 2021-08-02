import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/partnerProfile.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/widgets/cancelButton.dart';
import 'package:rider_frontend/widgets/circularImage.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';

class WaitingPartnerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TripModel trip = Provider.of<TripModel>(context);
    UserModel user = Provider.of<UserModel>(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OverallPadding(child: _buildCancelTripButton(context, trip)),
        Spacer(),
        _buildPartnerSummaryFloatingCard(
          context,
          trip: trip,
          user: user,
        ),
      ],
    );
  }

  Widget _buildCancelTripButton(
    BuildContext context,
    TripModel trip, {
    String title,
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
              firebase.functions.cancelTrip(context);
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

  Widget _buildPartnerSummaryFloatingCard(
    BuildContext context, {
    @required TripModel trip,
    @required UserModel user,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    // Listen is false, so we must call setState manually if we change the model
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);

    return FloatingCard(
      leftMargin: 0,
      rightMargin: 0,
      child: Column(
        children: [
          SizedBox(height: screenHeight / 100),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    trip.partnerArrivalSeconds > 90
                        ? "Motorista a caminho"
                        : (trip.partnerArrivalSeconds > 5
                            ? "Motorista próximo"
                            : "Motorista no local"),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    "Vá ao local de encontro",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColor.disabled,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(width: screenWidth / 20),
              Spacer(),
              Text(
                (trip.partnerArrivalSeconds / 60).round().toString() + " min",
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
          SizedBox(height: screenHeight / 100),
          Divider(thickness: 0.1, color: Colors.black),
          SizedBox(height: screenHeight / 100),
          InkWell(
            child: Row(
              children: [
                CircularImage(
                  size: screenHeight / 13,
                  imageFile: partner.profileImage == null
                      ? AssetImage("images/user_icon.png")
                      : partner.profileImage.file,
                ),
                SizedBox(width: screenWidth / 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: screenWidth / 4.2, // avoid overflowsr
                          ),
                          child: Text(
                            partner.name ?? "",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth / 50),
                        Text(
                          partner.rating?.toString() ?? "",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Icon(
                          Icons.star_rate,
                          size: 17,
                          color: Colors.black87,
                        )
                      ],
                    ),
                    Text(
                      (partner.vehicle?.brand?.toUpperCase() ?? "") +
                          " " +
                          (partner.vehicle?.model?.toUpperCase() ?? ""),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.disabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      partner.phoneNumber,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.disabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                Spacer(),
                Text(
                  partner.vehicle?.plate?.toUpperCase() ?? "",
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            onTap: () => Navigator.pushNamed(context, PartnerProfile.routeName),
          ),
          SizedBox(height: screenHeight / 30),
        ],
      ),
    );
  }
}
