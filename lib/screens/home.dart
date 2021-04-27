import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/driver.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/confirmTrip.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/menu.dart';
import 'package:rider_frontend/screens/pilotProfile.dart';
import 'package:rider_frontend/screens/rateDriver.dart';
import 'package:rider_frontend/screens/shareLocation.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/cancelButton.dart';
import 'package:rider_frontend/widgets/circularImage.dart';
import 'package:rider_frontend/widgets/floatingCard.dart';
import 'package:rider_frontend/widgets/menuButton.dart';
import 'package:rider_frontend/widgets/overallPadding.dart';
import 'package:rider_frontend/widgets/yesNoDialog.dart';

class HomeArguments {
  final FirebaseModel firebase;
  final TripModel trip;
  final UserModel user;
  final GoogleMapsModel googleMaps;

  HomeArguments({
    @required this.firebase,
    @required this.trip,
    @required this.user,
    @required this.googleMaps,
  });
}

class Home extends StatefulWidget {
  static const routeName = "home";
  final FirebaseModel firebase;
  final TripModel trip;
  final UserModel user;
  final GoogleMapsModel googleMaps;

  Home({
    @required this.firebase,
    @required this.trip,
    @required this.user,
    @required this.googleMaps,
  });

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> {
  Future<bool> finishedDownloadingUserData;
  GlobalKey<ScaffoldState> _scaffoldKey;
  StreamSubscription driverSubscription;
  StreamSubscription tripSubscription;
  StreamSubscription userPositionSubscription;
  var _firebaseListener;
  var _tripListener;

  @override
  void initState() {
    super.initState();

    _scaffoldKey = GlobalKey<ScaffoldState>();

    // trigger download user data
    finishedDownloadingUserData = _downloadUserData();

    // after finishing download, user retrieved lat and lng to set maps camera view
    finishedDownloadingUserData.then(
      (_) => {
        if (widget.user.geocoding != null)
          {
            widget.googleMaps.initialCameraLatLng = LatLng(
                widget.user.geocoding?.latitude,
                widget.user.geocoding?.longitude),
          }
      },
    );

    // add listeners after tree is built and we have context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // add listener to FirebaseModel so user is redirected to Start when logs out
      _firebaseListener = () {
        _signOut(context);
      };
      widget.firebase.addListener(_firebaseListener);

      // add listener to TripModel so UI is redrawn whenever trip changes status
      _tripListener = () async {
        await _redrawUIOnTripUpdate(context);
      };
      widget.trip.addListener(_tripListener);
    });
  }

  @override
  void dispose() {
    widget.firebase.removeListener(_firebaseListener);
    widget.trip.removeListener(_tripListener);
    if (userPositionSubscription != null) {
      userPositionSubscription.cancel();
    }
    if (driverSubscription != null) {
      driverSubscription.cancel();
    }
    if (tripSubscription != null) {
      tripSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // get user position
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    TripModel trip = Provider.of<TripModel>(context);
    GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(context);
    UserModel user = Provider.of<UserModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context);

    // provide GoogleMapsModel
    return FutureBuilder(
        initialData: false,
        future: finishedDownloadingUserData,
        builder: (
          BuildContext context,
          AsyncSnapshot<bool> snapshot,
        ) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            // show loading screen while waiting for download to succeed
            return Splash(
                text: "Muito bom ter você de volta, " +
                    firebase.auth.currentUser.displayName.split(" ").first +
                    "!");
          }

          // make sure we successfully got user position
          if (snapshot.data == false) {
            return ShareLocation(push: Home.routeName);
          }

          // user data download finished: show home screen
          return Scaffold(
            key: _scaffoldKey,
            drawer: Menu(),
            body: Stack(
              children: [
                GoogleMap(
                  myLocationButtonEnabled: googleMaps.myLocationButtonEnabled,
                  myLocationEnabled: googleMaps.myLocationEnabled,
                  trafficEnabled: false,
                  zoomControlsEnabled: false,
                  mapType: MapType.normal,
                  initialCameraPosition: CameraPosition(
                    target: googleMaps.initialCameraLatLng,
                    zoom: googleMaps.initialZoom,
                  ),
                  padding: EdgeInsets.only(
                    top: googleMaps.googleMapsTopPadding ?? screenHeight / 12,
                    bottom: googleMaps.googleMapsBottomPadding ??
                        screenHeight / 8.5,
                    left: screenWidth / 20,
                    right: screenWidth / 20,
                  ),
                  onMapCreated: googleMaps.onMapCreatedCallback,
                  polylines: Set<Polyline>.of(googleMaps.polylines.values),
                  markers: googleMaps.markers,
                ),
                for (var child in _buildRemainingStackChildren(
                  context: context,
                  scaffoldKey: _scaffoldKey,
                  trip: trip,
                  user: user,
                ))
                  child,
              ],
            ),
          );
        });
  }

  Future<bool> _downloadUserData() async {
    // get user address
    await widget.user.getGeocoding();
    if (widget.user.geocoding == null) {
      return false;
    }
    await widget.user.downloadData(widget.firebase);
    try {
      // update position whenever it changes 100 meters or every 10 seconds
      Stream<Position> userPositionStream = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.best,
        distanceFilter: 100,
        intervalDuration: Duration(seconds: 10),
      );
      userPositionSubscription = userPositionStream.listen((position) {
        widget.user.getGeocoding(pos: position);
      });
    } catch (_) {}
    return true;
  }

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    if (!widget.firebase.isRegistered) {
      Navigator.pushNamedAndRemoveUntil(context, Start.routeName, (_) => false);
    }
  }

  void _cancelDriverSubscription() {
    if (driverSubscription != null) {
      driverSubscription.cancel();
    }
    driverSubscription = null;
  }

  void _cancelTripSubscription() {
    if (tripSubscription != null) {
      tripSubscription.cancel();
    }
    tripSubscription = null;
  }

  void _cancelSubscriptions() {
    _cancelDriverSubscription();
    _cancelTripSubscription();
  }

  // _redrawUIOnTripUpdate is triggered whenever we update the tripModel.
  // it looks at the trip status and updates the UI accordingly
  Future<void> _redrawUIOnTripUpdate(BuildContext context) async {
    TripModel trip = widget.trip;
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    DriverModel driver = Provider.of<DriverModel>(context, listen: false);
    GoogleMapsModel googleMaps =
        Provider.of<GoogleMapsModel>(context, listen: false);

    if (trip.tripStatus == null ||
        trip.tripStatus == TripStatus.off ||
        trip.tripStatus == TripStatus.canceledByClient ||
        trip.tripStatus == TripStatus.canceledByDriver) {
      // wait before undrawing polyline to help prevent concurrency issues
      await Future.delayed(Duration(milliseconds: 500));
      await googleMaps.undrawPolyline(context);
      return;
    }

    if (trip.tripStatus == TripStatus.waitingConfirmation) {
      await widget.googleMaps.drawPolyline(
        context: context,
        encodedPoints: trip.encodedPoints,
        topPadding: MediaQuery.of(context).size.height / 40,
        bottomPadding: MediaQuery.of(context).size.height / 3,
      );
      return;
    }

    void handleDriverUpdates(TripStatus expectedStatus) {
      // only reset subscription if it's null (i.e., it has been cancelled or this
      // is the first time it's being used). We enforce a business rule that
      // when we cancel subscriptions we set them to null. This allows us to
      // update the TripModel and, as a consequence, notify listeners without
      // redefining subscriptions when _redrawUIOnTripUpdate is called again.
      if (driverSubscription == null) {
        driverSubscription = firebase.database.onDriverUpdate(driver.id, (e) {
          // if pilot was set free, stop listening for his updates, as he is
          // no longer handling our trip.
          DriverStatus driverStatus =
              getDriverStatusFromString(e.snapshot.value["status"]);
          if (driverStatus != DriverStatus.busy) {
            _cancelDriverSubscription();
            return;
          }
          // only redraw polyline if trip status is as expected and driver
          // position has changed. The first check is necessary because it is
          // possible that local status may be updated before backend learns
          // about the update thus triggering the cancelling of this listener.
          // If we don't perform this check, we will continue redrawing the
          // polyline even though local trip state has already changed. The
          // second check is necessary as to avoid unecessary redrawing.
          double newLat = double.parse(e.snapshot.value["current_latitude"]);
          double newLng = double.parse(e.snapshot.value["current_longitude"]);
          if (trip.tripStatus == expectedStatus &&
              (newLat != driver.currentLatitude ||
                  newLng != driver.currentLongitude)) {
            // update driver coordinates
            driver.updateCurrentLatitude(newLat);
            driver.updateCurrentLongitude(newLng);
            // draw polyline from driver to origin or from driver to destination
            if (expectedStatus == TripStatus.waitingDriver) {
              googleMaps.drawPolylineFromDriverToOrigin(context);
            } else if (expectedStatus == TripStatus.inProgress) {
              googleMaps.drawPolylineFromDriverToDestination(context);
            }
          }
        });
      }
    }

    void handleTripUpdates(TripStatus expectedStatus) {
      if (tripSubscription == null) {
        String uid = firebase.auth.currentUser.uid;
        tripSubscription = firebase.database.onTripStatusUpdate(uid, (e) {
          TripStatus newTripStatus = getTripStatusFromString(e.snapshot.value);
          if (newTripStatus != expectedStatus) {
            // stop subscriptions when new trip status is not what we expected
            _cancelSubscriptions();
            if (newTripStatus == TripStatus.inProgress) {
              // if new trip status is inProgress redrawy polyline, but this time
              // from driver to destination
              trip.updateStatus(newTripStatus);
              googleMaps.drawPolylineFromDriverToDestination(context);
            } else if (trip.tripStatus != newTripStatus) {
              // otherwise, do something only if local trip status has not
              // been already updated to newTripStatus by some other code path
              // (i.e., user canceled the trip request, which immediately updates
              // local status, but also sends a request to cancel in firebase),
              googleMaps.undrawPolyline(context);
              trip.updateStatus(newTripStatus);
            }
          }
        });
      }
    }

    if (trip.tripStatus == TripStatus.waitingDriver) {
      handleDriverUpdates(TripStatus.waitingDriver);
      handleTripUpdates(TripStatus.waitingDriver);
      return;
    }

    if (trip.tripStatus == TripStatus.inProgress) {
      handleDriverUpdates(TripStatus.inProgress);
      handleTripUpdates(TripStatus.inProgress);
      return;
    }

    if (trip.tripStatus == TripStatus.completed) {
      await googleMaps.undrawPolyline(context);
      await Navigator.pushNamed(context, RateDriver.routeName);
      // important: don't notify listeneres when clearing models. This may cause
      // null exceptions because there may still be widgets from RateDriver
      //  that use the values from the models.
      driver.clear(notify: false);
      trip.clear(notify: false);
      return;
    }

    if (trip.tripStatus == TripStatus.noDriversAvailable ||
        trip.tripStatus == TripStatus.lookingForDriver) {
      // alert user to wait
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Nenhum motorista disponível"),
              content: Text(
                "Aguarde um minutinho e tente novamente.",
                style: TextStyle(color: AppColor.disabled),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "ok",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      });
      return;
    }

    if (trip.tripStatus == TripStatus.paymentFailed) {
      // give user the option of picking another payment method
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("O pagamento falhou :("),
              content: Text(
                "Escolha outra forma de pagamento",
                style: TextStyle(color: AppColor.disabled),
              ),
              actions: [
                TextButton(
                  child: Text(
                    "cancelar",
                    style: TextStyle(color: Colors.red, fontSize: 18),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                TextButton(
                  child: Text(
                    "escolher",
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),
                  // TODO: substitute for pushing the payment screen and then updating
                  // user's payment method which will reflect on floating card selection
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            );
          },
        );
      });
      return;
    }
    return;
  }
}

Future<void> _pushDefineRoute(
    BuildContext context, DefineRouteMode mode) async {
  Navigator.pushNamed(
    context,
    DefineRoute.routeName,
    arguments: DefineRouteArguments(
      mode: mode,
    ),
  );
}

List<Widget> _buildRemainingStackChildren({
  @required BuildContext context,
  @required GlobalKey<ScaffoldState> scaffoldKey,
  @required TripModel trip,
  @required UserModel user,
}) {
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
  if (trip.tripStatus == null ||
      trip.tripStatus == TripStatus.off ||
      trip.tripStatus == TripStatus.canceledByClient ||
      trip.tripStatus == TripStatus.canceledByDriver ||
      trip.tripStatus == TripStatus.completed) {
    return [
      OverallPadding(
        child: Container(
          alignment: Alignment.bottomCenter,
          child: AppButton(
            borderRadius: 10.0,
            iconLeft: Icons.near_me,
            textData: "Para onde vamos?",
            onTapCallBack: () {
              _pushDefineRoute(context, DefineRouteMode.request);
            },
          ),
        ),
      ),
      Positioned(
        child: OverallPadding(
          child: MenuButton(onPressed: () {
            scaffoldKey.currentState.openDrawer();
            // trigger getUserRating so it is updated in case it's changed
            firebase.database
                .getUserRating(firebase.auth.currentUser.uid)
                .then((value) => user.setRating(value));
          }),
        ),
      )
    ];
  }

  if (trip.tripStatus == TripStatus.waitingConfirmation ||
      trip.tripStatus == TripStatus.paymentFailed ||
      trip.tripStatus == TripStatus.noDriversAvailable ||
      trip.tripStatus == TripStatus.lookingForDriver) {
    // if user is about to confirm trip for the first time (waitingConfirmation)
    // has already confirmed but received a paymentFailed, give them the
    // option of trying again.
    return [
      _buildCancelRideButton(context, trip),
      Column(
        children: [
          Spacer(),
          _buildRideSummaryFloatingCard(context, trip),
          _buildEditAndConfirmButtons(context, trip),
        ],
      ),
    ];
  }

  if (trip.tripStatus == TripStatus.waitingDriver) {
    return [
      _buildCancelRideButton(context, trip,
          // TODO: decide on final fee
          content:
              "Atenção: como alguém já está a caminho, será cobrada uma taxa de R\$2,00,"),
      Column(
        children: [
          Spacer(),
          _buildPilotSummaryFloatingCard(
            context,
            trip: trip,
            user: user,
          ),
        ],
      ),
    ];
  }

  if (trip.tripStatus == TripStatus.inProgress) {
    return [
      Column(
        children: [
          Spacer(),
          _buildTripSummaryFloatingCard(
            context,
            trip: trip,
            user: user,
          ),
        ],
      ),
    ];
  }
  return [];
}

Widget _buildTripSummaryFloatingCard(
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

Widget _buildPilotSummaryFloatingCard(
  BuildContext context, {
  @required TripModel trip,
  @required UserModel user,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  // Listen is false, so we must call setState manually if we change the model
  DriverModel driver = Provider.of<DriverModel>(context, listen: false);

  return OverallPadding(
    bottom: screenHeight / 20,
    left: 0,
    right: 0,
    child: FloatingCard(
      child: Column(
        children: [
          SizedBox(height: screenHeight / 100),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    // TODO: notify client when driver is near
                    trip.driverArrivalSeconds > 90
                        ? "Motorista a caminho"
                        : (trip.driverArrivalSeconds > 5
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
                (trip.driverArrivalSeconds / 60).round().toString() + " min",
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
                  imageFile: driver.profileImage == null
                      ? AssetImage("images/user_icon.png")
                      : driver.profileImage.file,
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
                            driver.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth / 50),
                        Text(
                          driver.rating.toString(),
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
                      driver.vehicle.brand.toUpperCase() +
                          " " +
                          driver.vehicle.model.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.disabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      driver.phoneNumber,
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
                  driver.vehicle.plate.toUpperCase(),
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            onTap: () => Navigator.pushNamed(context, PilotProfile.routeName),
          ),
          SizedBox(height: screenHeight / 100),
        ],
      ),
    ),
  );
}

Widget _buildCancelRideButton(
  BuildContext context,
  TripModel trip, {
  String title,
  String content,
}) {
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
  DriverModel driver = Provider.of<DriverModel>(context, listen: false);
  return Positioned(
    right: 0,
    child: OverallPadding(
      child: CancelButton(onPressed: () {
        showDialog(
            context: context,
            builder: (BuildContext context) {
              return YesNoDialog(
                title: title ?? "Cancelar Pedido?",
                content: content,
                onPressedYes: () {
                  // TODO: charge fee if necessary
                  // cancel trip and update trip and driver models once it succeeds
                  firebase.functions.cancelTrip();
                  // update models
                  trip.clear(status: TripStatus.canceledByClient);
                  driver.clear();

                  Navigator.pop(context);
                },
              );
            });
      }),
    ),
  );
}

Widget _buildRideSummaryFloatingCard(BuildContext context, TripModel trip) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;

  return FloatingCard(
    child: Column(
      children: [
        SizedBox(height: screenHeight / 200),
        Row(
          children: [
            Text(
              "Chegada ao destino",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              trip.etaString,
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        SizedBox(height: screenHeight / 200),
        Row(
          children: [
            Text(
              "Preço",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              "R\$ " + trip.farePrice.toString(),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        SizedBox(height: screenHeight / 200),
        Divider(thickness: 0.1, color: Colors.black),
        SizedBox(height: screenHeight / 200),
        Text(
          "Escolha a forma de pagamento",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        SizedBox(height: screenHeight / 75),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            GestureDetector(
              child: Material(
                type: MaterialType.card,
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                    side: BorderSide(
                        color: AppColor.secondaryGreen) // TODO: make dynamic
                    ),
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.money,
                        size: 40,
                        color: AppColor.secondaryGreen, // TODO: make dynamic
                      ),
                      SizedBox(width: screenWidth / 50),
                      Text(
                        "Dinheiro",
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColor.secondaryGreen, // TODO: make dynamic
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            GestureDetector(
              child: Material(
                type: MaterialType.card,
                elevation: 4.0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Padding(
                  padding: EdgeInsets.all(5),
                  child: Row(
                    children: [
                      Icon(
                        Icons.credit_card,
                        size: 40,
                        color: Colors.black, // TODO: make dynamic
                      ),
                      SizedBox(width: screenWidth / 50),
                      Text(
                        "Cartão",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black, // TODO: make dynamic
                        ),
                      ),
                      Icon(Icons.arrow_right),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: screenHeight / 200),
      ],
    ),
  );
}

Widget _buildEditAndConfirmButtons(BuildContext context, TripModel trip) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

  return OverallPadding(
    bottom: screenHeight / 20,
    top: screenHeight / 40,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppButton(
          textData: "Editar Rota",
          borderRadius: 10.0,
          height: screenHeight / 15,
          width: screenWidth / 2.5,
          buttonColor: Colors.grey[900],
          textStyle: TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
          onTapCallBack: () async {
            await _pushDefineRoute(context, DefineRouteMode.edit);
          },
        ),
        AppButton(
            textData: "Confirmar",
            borderRadius: 10.0,
            height: screenHeight / 15,
            width: screenWidth / 2.5,
            textStyle: TextStyle(
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
            onTapCallBack: () async {
              await Navigator.pushNamed(context, ConfirmTrip.routeName,
                  arguments: ConfirmTripArguments(
                    firebase: firebase,
                    trip: trip,
                  ));
            }),
      ],
    ),
  );
}
