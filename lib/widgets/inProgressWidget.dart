import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class InProgressWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    TripModel trip = Provider.of<TripModel>(context);
    UserModel user = Provider.of<UserModel>(context);

    return Column(
      children: [
        Spacer(),
        _buildETAFloatingCard(
          context,
          trip: trip,
          user: user,
        ),
      ],
    );
  }

  Widget _buildETAFloatingCard(
    BuildContext context, {
    @required TripModel trip,
    @required UserModel user,
  }) {
    final screenHeight = MediaQuery.of(context).size.height;
    // Listen is false, so we must call setState manually if we change the model

    return OverallPadding(
      bottom: screenHeight / 20,
      left: 0,
      right: 0,
      child: FloatingCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Previsão de chegada",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              (trip.eta.hour < 10
                      ? "0" + trip.eta.hour.toString()
                      : trip.eta.hour.toString()) +
                  ":" +
                  (trip.eta.minute < 10
                      ? "0" + trip.eta.minute.toString()
                      : trip.eta.minute.toString()),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 60,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
