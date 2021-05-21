import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_svg/svg.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/screens/pastTripDetail.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/widgets/goBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class PastTripsArguments {
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;

  PastTripsArguments(this.firebase, this.connectivity);
}

class PastTrips extends StatefulWidget {
  static String routeName = "PastTrips";
  final FirebaseModel firebase;
  final ConnectivityModel connectivity;

  PastTrips({@required this.firebase, @required this.connectivity});

  @override
  PastTripsState createState() => PastTripsState();
}

class PastTripsState extends State<PastTrips> {
  List<Trip> pastTrips;
  Future<Trips> getPastTripsResult;
  bool isLoading;
  ScrollController scrollController;
  bool _hasConnection;

  @override
  void initState() {
    super.initState();
    pastTrips = [];
    isLoading = false;
    _hasConnection = widget.connectivity.hasConnection;

    // create scroll controller that triggers getMorePastTrips once user
    // scrolls all the way down to the bottom of the past trips list
    scrollController = ScrollController();
    scrollController.addListener(() {
      if (!isLoading &&
          scrollController.position.userScrollDirection ==
              ScrollDirection.reverse &&
          scrollController.position.pixels ==
              scrollController.position.maxScrollExtent) {
        setState(() {
          isLoading = true;
        });
        getMorePastTrips();
      }
    });

    GetPastTripsArguments args = GetPastTripsArguments(pageSize: 10);
    getPastTripsResult = widget.firebase.functions.getPastTrips(args: args);
  }

  @override
  void dispose() {
    scrollController.dispose();
    super.dispose();
  }

  Future<void> getMorePastTrips() async {
    //  least recent trip is the last in chronologically sorted pastTrips
    Trip leastRecentTrip;
    if (pastTrips.isNotEmpty) {
      leastRecentTrip = pastTrips[pastTrips.length - 1];
    }

    // get 10 trips that happened before least recent trip
    int maxRequestTime;
    if (leastRecentTrip != null) {
      maxRequestTime = leastRecentTrip.requestTime - 1;
    }
    GetPastTripsArguments args = GetPastTripsArguments(
      pageSize: 10,
      maxRequestTime: maxRequestTime,
    );
    Trips result;
    try {
      result = await widget.firebase.functions.getPastTrips(args: args);
    } catch (_) {}
    setState(() {
      if (result != null) {
        pastTrips.addAll(result.items);
      }
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    // get more past trips whenever connection changes from offline to online
    if (_hasConnection != connectivity.hasConnection) {
      _hasConnection = connectivity.hasConnection;
      if (connectivity.hasConnection) {
        getMorePastTrips();
      }
    }

    return FutureBuilder(
      future: getPastTripsResult,
      builder: (BuildContext context, AsyncSnapshot<Trips> snapshot) {
        // populate pastTrips as soon as future returns. Do this once. Otherwise
        // we may override trips that were added later to pastTrips.
        if (snapshot.hasData && pastTrips.length == 0) {
          pastTrips = snapshot.data.items;
        }

        return Scaffold(
          resizeToAvoidBottomInset: false,
          body: OverallPadding(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    GoBackButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Spacer(),
                  ],
                ),
                SizedBox(height: screenHeight / 15),
                Text(
                  "Minhas viagens",
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.black),
                ),
                SizedBox(height: screenHeight / 30),
                Expanded(
                  child: snapshot.connectionState == ConnectionState.waiting
                      ? Container(
                          alignment: Alignment.center,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                AppColor.primaryPink),
                          ),
                        )
                      : MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: pastTrips.length == 0
                              ? !connectivity.hasConnection
                                  ? Text(
                                      "Você está offline.",
                                      style:
                                          TextStyle(color: AppColor.disabled),
                                    )
                                  : Text(
                                      "Você ainda não fez nenhuma corrida.",
                                      style:
                                          TextStyle(color: AppColor.disabled),
                                    )
                              : ListView.separated(
                                  controller: scrollController,
                                  physics: AlwaysScrollableScrollPhysics(),
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemBuilder: (context, index) {
                                    return buildPastTrip(
                                      context,
                                      pastTrips[index],
                                    );
                                  },
                                  separatorBuilder: (context, index) {
                                    return Divider(
                                        thickness: 0.1, color: Colors.black);
                                  },
                                  itemCount: pastTrips.length,
                                ),
                        ),
                ),
                Container(
                  height: isLoading ? 50.0 : 0,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppColor.primaryPink),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

Widget buildPastTrip(
  BuildContext context,
  Trip trip,
) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
  return InkWell(
    onTap: () {
      Navigator.pushNamed(
        context,
        PastTripDetail.routeName,
        arguments: PastTripDetailArguments(
          pastTrip: trip,
          firebase: firebase,
        ),
      );
    },
    child: Column(
      children: [
        SizedBox(height: screenHeight / 100),
        Row(
          children: [
            Icon(
              Icons.access_time,
              size: 10,
            ),
            SizedBox(width: screenWidth / 50),
            Text(
              formatDatetime(trip.requestTime),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            Spacer(),
            Text(
              "R\$ " + (trip.farePrice / 100).toString(),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight / 100),
        Row(
          children: [
            SvgPicture.asset(
              "images/pickUpIcon.svg",
              width: 8,
            ),
            SizedBox(width: screenWidth / 50),
            Flexible(
              flex: 3,
              child: Text(
                trip.originAddress,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ),
            Spacer(flex: 1),
            Text(
              trip.paymentMethod == PaymentMethodType.cash
                  ? "Dinheiro"
                  : "Cartão •••• " + trip.creditCard.lastDigits,
              style: TextStyle(
                fontSize: 14,
                color: AppColor.disabled,
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight / 100),
        Row(
          children: [
            SvgPicture.asset(
              "images/dropOffIcon.svg",
              width: 8,
            ),
            SizedBox(width: screenWidth / 50),
            Flexible(
              child: Text(
                trip.destinationAddress,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 14),
              ),
            ),
            Spacer(),
          ],
        ),
        SizedBox(height: screenHeight / 100),
      ],
    ),
  );
}

String formatDatetime(int ms) {
  String appendZero(int val) {
    return val < 10 ? "0" + val.toString() : val.toString();
  }

  DateTime dt = DateTime.fromMillisecondsSinceEpoch(ms);
  return appendZero(dt.day) +
      "/" +
      appendZero(dt.month) +
      "/" +
      dt.year.toString() +
      " às " +
      appendZero(dt.hour) +
      ":" +
      appendZero(dt.minute);
}
