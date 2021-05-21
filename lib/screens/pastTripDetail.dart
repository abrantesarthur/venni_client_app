import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/pastTrips.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/widgets/circularImage.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/goBackButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';

class PastTripDetailArguments {
  final Trip pastTrip;
  final FirebaseModel firebase;

  PastTripDetailArguments({
    @required this.pastTrip,
    @required this.firebase,
  });
}

class PastTripDetail extends StatefulWidget {
  static String routeName = "PastTripDetail";
  final Trip pastTrip;
  final FirebaseModel firebase;

  PastTripDetail({
    @required this.pastTrip,
    @required this.firebase,
  });

  @override
  PastTripDetailState createState() => PastTripDetailState();
}

class PastTripDetailState extends State<PastTripDetail> {
  Future<bool> doneGettingPilotInfo;
  int pilotRating;
  ProfileImage pilotImage;
  GoogleMapsModel googleMaps;

  @override
  void initState() {
    super.initState();

    googleMaps = GoogleMapsModel();

    doneGettingPilotInfo = getPilotInfo();
  }

  Future<bool> getPilotInfo() async {
    // get pilot rating
    int rating = await widget.firebase.functions
        .pilotGetTripRating(PilotGetTripRatingArguments(
      pilotID: widget.pastTrip.pilotID,
      pastTripRefKey: widget.pastTrip.pilotPastTripRefKey,
    ));

    // get pilot profile image
    ProfileImage img = await widget.firebase.storage
        .getPilotProfilePicture(widget.pastTrip.pilotID);

    setState(() {
      pilotRating = rating;
      pilotImage = img;
    });

    return true;
  }

  @override
  void dispose() {
    googleMaps.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    UserModel user = Provider.of<UserModel>(context, listen: false);

    return FutureBuilder(
        future: doneGettingPilotInfo,
        builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
          return Scaffold(
            body: Stack(
              children: [
                GoogleMap(
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                  trafficEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      user.position?.latitude,
                      user.position?.longitude,
                    ),
                    zoom: googleMaps.initialZoom,
                  ),
                  padding: EdgeInsets.only(
                    top: screenHeight / 12,
                    bottom: screenHeight / 3.6,
                    left: screenWidth / 20,
                    right: screenWidth / 20,
                  ),
                  onMapCreated: (GoogleMapController c) {
                    googleMaps.onMapCreatedCallback(c);
                    googleMaps.drawPolyline(
                      context: context,
                      encodedPoints: widget.pastTrip.encodedPoints,
                    );
                  },
                  polylines: Set<Polyline>.of(googleMaps.polylines.values),
                  markers: googleMaps.markers,
                ),
                OverallPadding(
                  child: Column(
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
                    ],
                  ),
                ),
                _buildPilotRatingDetail(
                  context: context,
                  pastTrip: widget.pastTrip,
                  pilotRating: pilotRating,
                  pilotImage: pilotImage,
                  snapshot: snapshot,
                ),
              ],
            ),
          );
        });
  }
}

Widget _buildPilotRatingDetail({
  @required BuildContext context,
  @required Trip pastTrip,
  @required int pilotRating,
  @required ProfileImage pilotImage,
  @required AsyncSnapshot<bool> snapshot,
}) {
  final screenWidth = MediaQuery.of(context).size.width;
  final screenHeight = MediaQuery.of(context).size.height;
  return Column(
    children: [
      Spacer(),
      FloatingCard(
        leftMargin: screenWidth / 50,
        rightMargin: screenWidth / 50,
        child: Column(
          children: [
            SizedBox(height: screenHeight / 200),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularImage(
                  size: screenHeight / 12,
                  imageFile: pilotImage == null
                      ? AssetImage("images/user_icon.png")
                      : pilotImage.file,
                ),
                SizedBox(width: screenWidth / 30),
                snapshot.connectionState == ConnectionState.waiting
                    ? Container(
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                              AppColor.primaryPink),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getRateDescription(pilotRating),
                            style: TextStyle(
                                fontSize: 14, fontWeight: FontWeight.w700),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Padding(
                                padding:
                                    EdgeInsets.only(right: screenWidth / 200),
                                child: Icon(
                                  pilotRating != null && pilotRating >= 1
                                      ? Icons.star_sharp
                                      : Icons.star_border_sharp,
                                  size: 25,
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(right: screenWidth / 200),
                                child: Icon(
                                  pilotRating != null && pilotRating >= 2
                                      ? Icons.star_sharp
                                      : Icons.star_border_sharp,
                                  size: 25,
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(right: screenWidth / 200),
                                child: Icon(
                                  pilotRating != null && pilotRating >= 3
                                      ? Icons.star_sharp
                                      : Icons.star_border_sharp,
                                  size: 25,
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(right: screenWidth / 200),
                                child: Icon(
                                  pilotRating != null && pilotRating >= 4
                                      ? Icons.star_sharp
                                      : Icons.star_border_sharp,
                                  size: 25,
                                ),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.only(right: screenWidth / 200),
                                child: Icon(
                                  pilotRating != null && pilotRating >= 5
                                      ? Icons.star_sharp
                                      : Icons.star_border_sharp,
                                  size: 25,
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
              ],
            ),
            SizedBox(height: screenHeight / 200),
            Divider(thickness: 0.1, color: Colors.black),
            SizedBox(height: screenHeight / 200),
            Column(
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
                      formatDatetime(pastTrip.requestTime),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Spacer(),
                    Text(
                      "R\$ " + (pastTrip.farePrice / 100).toString(),
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
                        pastTrip.originAddress,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                    Spacer(flex: 1),
                    Text(
                      pastTrip.paymentMethod == PaymentMethodType.cash
                          ? "Dinheiro"
                          : "Cartão •••• " + pastTrip.creditCard.lastDigits,
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
                        pastTrip.destinationAddress,
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
            SizedBox(height: screenHeight / 75),
          ],
        ),
      ),
      SizedBox(height: screenHeight / 20),
    ],
  );
}

String getRateDescription(int rate) {
  if (rate == null) {
    return "sem avaliação";
  }
  switch (rate) {
    case 1:
      return "péssima";
    case 2:
      return "ruim";
    case 3:
      return "regular";
    case 4:
      return "boa";
    case 5:
      return "excelente";
    default:
      return "";
  }
}
