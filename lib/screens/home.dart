import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/pilot.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/confirmTrip.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/menu.dart';
import 'package:rider_frontend/screens/pastTrips.dart';
import 'package:rider_frontend/screens/payTrip.dart';
import 'package:rider_frontend/screens/payments.dart';
import 'package:rider_frontend/screens/pilotProfile.dart';
import 'package:rider_frontend/screens/ratePilot.dart';
import 'package:rider_frontend/screens/shareLocation.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/widgets/appButton.dart';
import 'package:rider_frontend/widgets/borderlessButton.dart';
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
  final ConnectivityModel connectivity;

  HomeArguments({
    @required this.firebase,
    @required this.trip,
    @required this.user,
    @required this.googleMaps,
    @required this.connectivity,
  });
}

class Home extends StatefulWidget {
  static const routeName = "home";
  final FirebaseModel firebase;
  final TripModel trip;
  final UserModel user;
  final GoogleMapsModel googleMaps;
  final ConnectivityModel connectivity;

  Home({
    @required this.firebase,
    @required this.trip,
    @required this.user,
    @required this.googleMaps,
    @required this.connectivity,
  });

  @override
  HomeState createState() => HomeState();
}

class HomeState extends State<Home> with WidgetsBindingObserver {
  Future<Position> userPositionFuture;
  GlobalKey<ScaffoldState> _scaffoldKey;
  StreamSubscription pilotSubscription;
  StreamSubscription tripSubscription;
  bool _hasConnection;
  var _firebaseListener;
  var _tripListener;

  // didChangeAppLifecycleState is notified whenever the system puts the app in
  // the background or returns the app to the foreground
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) async {
    super.didChangeAppLifecycleState(state);
    // if user stopped sharing location, _getUserPosition asks them to reshare
    await _getUserPosition();
  }

  @override
  void initState() {
    super.initState();

    // HomeState uses WidgetsBindingObserver as a mixin. Thus, we can pass it as
    // argument to WidgetsBinding.addObserver. The didChangeAppLifecycleState that
    // we override, is notified whenever an application even occurs (e.g., system
    // puts app in background).
    WidgetsBinding.instance.addObserver(this);

    _scaffoldKey = GlobalKey<ScaffoldState>();

    // trigger _getUserPosition
    userPositionFuture = _getUserPosition();

    _hasConnection = widget.connectivity.hasConnection;

    // add listeners after tree is built and we have context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // after finishing _getUserPosition,
      userPositionFuture.then((position) async {
        if (position != null) {
          // user retrieved lat and lng to set maps camera view
          widget.googleMaps.initialCameraLatLng = LatLng(
            widget.user.position?.latitude,
            widget.user.position?.longitude,
          );
        }
      });

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
    WidgetsBinding.instance.removeObserver(this);
    widget.firebase.removeListener(_firebaseListener);
    widget.trip.removeListener(_tripListener);
    widget.user.cancelPositionChangeSubscription();
    if (pilotSubscription != null) {
      pilotSubscription.cancel();
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
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    // if connectivity has changed
    if (_hasConnection != connectivity.hasConnection) {
      // update _hasConnectivity
      _hasConnection = connectivity.hasConnection;
      // if connectivity changed from offline to online
      if (connectivity.hasConnection) {
        // download user data
        user.downloadData(firebase);
      }
    }

    // provide GoogleMapsModel
    return FutureBuilder(
      initialData: null,
      future: userPositionFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<Position> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show loading screen while waiting for download to succeed
          return Splash(
              text: "Muito bom ter você de volta, " +
                  firebase.auth.currentUser.displayName.split(" ").first +
                  "!");
        }

        // make sure we successfully got user position
        if (snapshot.data == null) {
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
                  target: googleMaps.initialCameraLatLng ??
                      LatLng(-17.217600, -46.874621), // defaults to paracatu
                  zoom: googleMaps.initialZoom ?? 16.5,
                ),
                padding: EdgeInsets.only(
                  top: googleMaps.googleMapsTopPadding ?? screenHeight / 12,
                  bottom:
                      googleMaps.googleMapsBottomPadding ?? screenHeight / 8.5,
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
                child
            ],
          ),
        );
      },
    );
  }

  Future<Position> _getUserPosition() async {
    // Try getting user position. If it returns null, it's because user stopped
    // sharing location. getPosition() will automatically handle that case, asking
    // the user to share again and preventing them from using the app if they
    // don't.
    Position pos = await widget.user.getPosition(notify: false);
    if (pos == null) {
      return null;
    }
    // if we could get position, make sure to resubscribe to position changes
    // again, as the subscription may have been cancelled if user stopped
    // sharing location.
    widget.user.updateGeocodingOnPositionChange();
    return pos;
  }

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    if (!widget.firebase.isRegistered) {
      Navigator.pushNamedAndRemoveUntil(context, Start.routeName, (_) => false);
    }
  }

  void _cancelPilotSubscription() {
    if (pilotSubscription != null) {
      pilotSubscription.cancel();
    }
    pilotSubscription = null;
  }

  void _cancelTripSubscription() {
    if (tripSubscription != null) {
      tripSubscription.cancel();
    }
    tripSubscription = null;
  }

  void _cancelSubscriptions() {
    _cancelPilotSubscription();
    _cancelTripSubscription();
  }

  // _redrawUIOnTripUpdate is triggered whenever we update the tripModel.
  // it looks at the trip status and updates the UI accordingly
  Future<void> _redrawUIOnTripUpdate(BuildContext context) async {
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PilotModel pilot = Provider.of<PilotModel>(context, listen: false);
    GoogleMapsModel googleMaps =
        Provider.of<GoogleMapsModel>(context, listen: false);

    if (trip.tripStatus == null || trip.tripStatus == TripStatus.off) {
      // wait before undrawing polyline to help prevent concurrency issues
      await Future.delayed(Duration(milliseconds: 500));
      await googleMaps.undrawPolyline(context);
      return;
    }

    if (trip.tripStatus == TripStatus.canceledByClient ||
        trip.tripStatus == TripStatus.canceledByPilot) {
      await googleMaps.undrawPolyline(context);
      return;
    }

    if (trip.tripStatus == TripStatus.waitingConfirmation) {
      await widget.googleMaps.drawPolyline(
        context: context,
        encodedPoints: trip.encodedPoints,
        topPadding: MediaQuery.of(context).size.height / 9.5,
        bottomPadding: MediaQuery.of(context).size.height / 4.8,
      );
      return;
    }

    void handlePilotUpdates(TripStatus expectedStatus) {
      // only reset subscription if it's null (i.e., it has been cancelled or this
      // is the first time it's being used). We enforce a business rule that
      // when we cancel subscriptions we set them to null. This allows us to
      // update the TripModel and, as a consequence, notify listeners without
      // redefining subscriptions when _redrawUIOnTripUpdate is called again.
      if (pilotSubscription == null) {
        pilotSubscription = firebase.database.onPilotUpdate(pilot.id, (e) {
          // if pilot was set free, stop listening for his updates, as he is
          // no longer handling our trip.
          PilotStatus pilotStatus =
              getPilotStatusFromString(e.snapshot.value["status"]);
          if (pilotStatus != PilotStatus.busy) {
            _cancelPilotSubscription();
            return;
          }
          // only redraw polyline if trip status is as expected and pilot
          // position has changed. The first check is necessary because it is
          // possible that local status may be updated before backend learns
          // about the update thus triggering the cancelling of this listener.
          // If we don't perform this check, we will continue redrawing the
          // polyline even though local trip state has already changed. The
          // second check is necessary as to avoid unecessary redrawing.
          double newLat = double.parse(e.snapshot.value["current_latitude"]);
          double newLng = double.parse(e.snapshot.value["current_longitude"]);
          if (trip.tripStatus == expectedStatus &&
              (newLat != pilot.currentLatitude ||
                  newLng != pilot.currentLongitude)) {
            // update pilot coordinates
            pilot.updateCurrentLatitude(newLat);
            pilot.updateCurrentLongitude(newLng);
            // draw polyline from pilot to origin or from pilot to destination
            if (expectedStatus == TripStatus.waitingPilot) {
              googleMaps.drawPolylineFromPilotToOrigin(context);
            } else if (expectedStatus == TripStatus.inProgress) {
              googleMaps.drawPolylineFromPilotToDestination(context);
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
              // from pilot to destination
              trip.updateStatus(newTripStatus);
              googleMaps.drawPolylineFromPilotToDestination(context);
            } else if (newTripStatus != trip.tripStatus) {
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

    if (trip.tripStatus == TripStatus.waitingPilot) {
      handlePilotUpdates(TripStatus.waitingPilot);
      handleTripUpdates(TripStatus.waitingPilot);
      return;
    }

    if (trip.tripStatus == TripStatus.inProgress) {
      handlePilotUpdates(TripStatus.inProgress);
      handleTripUpdates(TripStatus.inProgress);
      return;
    }

    if (trip.tripStatus == TripStatus.completed) {
      await googleMaps.undrawPolyline(context);
      await Navigator.pushNamed(context, RatePilot.routeName);
      // important: don't notify listeneres when clearing models. This may cause
      // null exceptions because there may still be widgets from the previous
      // screen RatePilot that use the values from the models.
      pilot.clear(notify: false);
      trip.clear(notify: false);
      return;
    }

    if (trip.tripStatus == TripStatus.noPilotsAvailable ||
        trip.tripStatus == TripStatus.lookingForPilot) {
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
      // change trip status locally so AlertDialog is not shown twice. This could
      // happen, for example, if UI is rebuilt againt because TripModel notified
      // listeners after user updated route.
      trip.updateStatus(TripStatus.waitingConfirmation);
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
                "Escolha outra forma de pagamento e tente novamente.",
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
                  onPressed: () async {
                    await Navigator.pushNamed(
                      context,
                      Payments.routeName,
                      arguments: PaymentsArguments(mode: PaymentsMode.pick),
                    );
                    Navigator.pop(context);
                  },
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

List<Widget> _buildRemainingStackChildren({
  @required BuildContext context,
  @required GlobalKey<ScaffoldState> scaffoldKey,
  @required TripModel trip,
  @required UserModel user,
}) {
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
  ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
    context,
    listen: false,
  );

  // lock trip request if user has pending payments
  if (user.unpaidTrip != null) {
    return [
      Positioned(
        child: OverallPadding(
          child: MenuButton(onPressed: () {
            scaffoldKey.currentState.openDrawer();
            // trigger getUserRating so it is updated in case it's changed
            firebase.database
                .getClientData(firebase)
                .then((value) => user.setRating(value.rating));
          }),
        ),
      ),
      Column(
        children: [
          Spacer(),
          _buildPendingPaymentFloatingCard(context, user.unpaidTrip, user),
        ],
      ),
    ];
  }

  if (trip.tripStatus == null ||
      trip.tripStatus == TripStatus.off ||
      trip.tripStatus == TripStatus.canceledByClient ||
      trip.tripStatus == TripStatus.canceledByPilot ||
      trip.tripStatus == TripStatus.completed) {
    return [
      OverallPadding(
        child: Container(
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
              Navigator.pushNamed(
                context,
                DefineRoute.routeName,
                arguments: DefineRouteArguments(
                  mode: DefineRouteMode.request,
                ),
              );
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
                .getClientData(firebase)
                .then((value) => user.setRating(value.rating));
          }),
        ),
      )
    ];
  }

  if (trip.tripStatus == TripStatus.waitingConfirmation ||
      trip.tripStatus == TripStatus.paymentFailed ||
      trip.tripStatus == TripStatus.noPilotsAvailable ||
      trip.tripStatus == TripStatus.lookingForPilot) {
    // if user is about to confirm trip for the first time (waitingConfirmation)
    // has already confirmed but received a paymentFailed, give them the
    // option of trying again.
    return [
      _buildCancelTripButton(context, trip),
      _buildEditRouteButton(context, trip),
      Column(
        children: [
          Spacer(),
          _buildTripSummaryFloatingCard(context, trip, user),
        ],
      ),
    ];
  }

  if (trip.tripStatus == TripStatus.waitingPilot) {
    return [
      _buildCancelTripButton(context, trip,
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
          _buildETAFloatingCard(
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

Widget _buildPilotSummaryFloatingCard(
  BuildContext context, {
  @required TripModel trip,
  @required UserModel user,
}) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  // Listen is false, so we must call setState manually if we change the model
  PilotModel pilot = Provider.of<PilotModel>(context, listen: false);

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
                    // TODO: notify client when pilot is near
                    trip.pilotArrivalSeconds > 90
                        ? "Motorista a caminho"
                        : (trip.pilotArrivalSeconds > 5
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
                (trip.pilotArrivalSeconds / 60).round().toString() + " min",
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
                  imageFile: pilot.profileImage == null
                      ? AssetImage("images/user_icon.png")
                      : pilot.profileImage.file,
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
                            pilot.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth / 50),
                        Text(
                          pilot.rating.toString(),
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
                      pilot.vehicle.brand.toUpperCase() +
                          " " +
                          pilot.vehicle.model.toUpperCase(),
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColor.disabled,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      pilot.phoneNumber,
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
                  pilot.vehicle.plate.toUpperCase(),
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

Widget _buildCancelTripButton(
  BuildContext context,
  TripModel trip, {
  String title,
  String content,
}) {
  final screenWidth = MediaQuery.of(context).size.width;

  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
  PilotModel pilot = Provider.of<PilotModel>(context, listen: false);
  return Positioned(
    left: 0,
    child: OverallPadding(
      left: screenWidth / 30,
      child: CancelButton(
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
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return YesNoDialog(
                title: title ?? "Cancelar Pedido?",
                content: content,
                onPressedYes: () async {
                  if (!connectivity.hasConnection) {
                    await connectivity.alertWhenOffline(
                      context,
                      message: "Conecte-se à internet para cancelar o pedido,",
                    );
                    return;
                  }
                  // TODO: charge fee if necessary
                  // cancel trip and update trip and pilot models once it succeeds
                  try {
                    firebase.functions.cancelTrip();
                  } catch (_) {}
                  // update models
                  trip.clear(status: TripStatus.canceledByClient);
                  pilot.clear();
                  Navigator.pop(context);
                },
              );
            },
          );
        },
      ),
    ),
  );
}

Widget _buildEditRouteButton(
  BuildContext context,
  TripModel trip,
) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  TripModel trip = Provider.of<TripModel>(context, listen: false);

  return Positioned(
    right: 0,
    child: FloatingCard(
      leftMargin: screenWidth / 4.5,
      rightMargin: screenWidth / 30,
      leftPadding: screenWidth / 20,
      topMargin: screenHeight / 15,
      borderRadius: 25,
      child: InkWell(
        onTap: () async {
          Navigator.pushNamed(
            context,
            DefineRoute.routeName,
            arguments: DefineRouteArguments(
              mode: DefineRouteMode.edit,
            ),
          );
        },
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: screenWidth / 2,
                  child: BorderlessButton(
                    svgLeftPath: "images/pickUpIcon.svg",
                    svgLeftWidth: 10,
                    primaryText: trip.pickUpAddress.mainText,
                    primaryTextWeight: FontWeight.bold,
                    primaryTextSize: 13,
                    primaryTextColor: AppColor.disabled,
                  ),
                ),
                SizedBox(height: screenHeight / 150),
                Container(
                  width: screenWidth / 2,
                  child: BorderlessButton(
                    svgLeftPath: "images/dropOffIcon.svg",
                    svgLeftWidth: 10,
                    primaryText: trip.dropOffAddress.mainText,
                    primaryTextWeight: FontWeight.bold,
                    primaryTextSize: 13,
                    primaryTextColor: AppColor.disabled,
                  ),
                ),
              ],
            ),
            Expanded(
              flex: 1,
              child: Text(
                "Alterar",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColor.disabled,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildTripSummaryFloatingCard(
  BuildContext context,
  TripModel trip,
  UserModel user,
) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

  return FloatingCard(
    leftMargin: 0,
    rightMargin: 0,
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
        SizedBox(height: screenHeight / 100),
        Row(
          children: [
            Text(
              "Preço",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Spacer(),
            Text(
              // TODO: make sure this workd
              "R\$ " + (trip.farePrice / 100).toString(),
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        SizedBox(height: screenHeight / 200),
        Divider(thickness: 0.1, color: Colors.black),
        SizedBox(height: screenHeight / 200),
        Padding(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 5,
            right: 5,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: BorderlessButton(
                  svgLeftPath: user.getPaymentMethodSvgPath(context),
                  svgLeftWidth: 28,
                  primaryText: user.getPaymentMethodDescription(context),
                  primaryTextWeight: FontWeight.bold,
                  iconRight: Icons.keyboard_arrow_right,
                  iconRightColor: Colors.black,
                  paddingTop: screenHeight / 200,
                  paddingBottom: screenHeight / 200,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      Payments.routeName,
                      arguments: PaymentsArguments(mode: PaymentsMode.pick),
                    );
                  },
                ),
              ),
              Spacer(flex: 1),
              AppButton(
                textData: "Confirmar",
                borderRadius: 30.0,
                height: screenHeight / 15,
                width: screenWidth / 2.5,
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                onTapCallBack: () =>
                    confirmTripCallback(context, trip, firebase, user),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> confirmTripCallback(
  BuildContext context,
  TripModel trip,
  FirebaseModel firebase,
  UserModel user,
) async {
  // make sure user is connected to the internet
  ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
    context,
    listen: false,
  );
  if (!connectivity.hasConnection) {
    await connectivity.alertWhenOffline(context);
    return;
  }
  // alert user in case they're paying with cash
  if (user.defaultPaymentMethod.type == PaymentMethodType.cash) {
    final useCard = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirmar pagamento em dinheiro?"),
          content: Text(
            "Considere pagar com cartão de crédito. É prático e seguro.",
            style: TextStyle(color: AppColor.disabled),
          ),
          actions: [
            TextButton(
              child: Text(
                "usar cartão",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
            TextButton(
              child: Text(
                "confirmar",
                style: TextStyle(
                  color: AppColor.primaryPink,
                  fontSize: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    ) as bool;
    // push payments screen if user decides to pick a card
    if (useCard) {
      await Navigator.pushNamed(
        context,
        Payments.routeName,
        arguments: PaymentsArguments(mode: PaymentsMode.pick),
      );
      return;
    }
  }

  // push confirmation screen if user picks a card or decides to continue cash payment
  await Navigator.pushNamed(
    context,
    ConfirmTrip.routeName,
    arguments: ConfirmTripArguments(
      firebase: firebase,
      trip: trip,
      user: user,
    ),
  );
}

// TODO: update map paddings
Widget _buildPendingPaymentFloatingCard(
  BuildContext context,
  Trip trip,
  UserModel user,
) {
  final screenHeight = MediaQuery.of(context).size.height;
  final screenWidth = MediaQuery.of(context).size.width;
  return FloatingCard(
    leftMargin: 0,
    rightMargin: 0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(height: screenHeight / 200),
        Text(
          "Pagamento pendente",
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColor.primaryPink,
          ),
        ),
        SizedBox(height: screenHeight / 200),
        Divider(thickness: 0.1, color: Colors.black),
        SizedBox(height: screenHeight / 200),
        buildPastTrip(context, trip),
        SizedBox(height: screenHeight / 200),
        Divider(thickness: 0.1, color: Colors.black),
        SizedBox(height: screenHeight / 200),
        Padding(
          padding: const EdgeInsets.only(
            bottom: 40,
            left: 5,
            right: 5,
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: BorderlessButton(
                  svgLeftPath: user.getPaymentMethodSvgPath(context),
                  svgLeftWidth: 28,
                  primaryText: user.getPaymentMethodDescription(context),
                  primaryTextWeight: FontWeight.bold,
                  iconRight: Icons.keyboard_arrow_right,
                  iconRightColor: Colors.black,
                  paddingTop: screenHeight / 200,
                  paddingBottom: screenHeight / 200,
                  onTap: () async {
                    await Navigator.pushNamed(
                      context,
                      Payments.routeName,
                      arguments: PaymentsArguments(mode: PaymentsMode.pick),
                    );
                  },
                ),
              ),
              Spacer(flex: 1),
              AppButton(
                  textData: "Pagar",
                  borderRadius: 30.0,
                  height: screenHeight / 15,
                  width: screenWidth / 2.5,
                  textStyle: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                  onTapCallBack: () => payTripCallback(context, trip, user)),
            ],
          ),
        ),
      ],
    ),
  );
}

Future<void> payTripCallback(
  BuildContext context,
  Trip trip,
  UserModel user,
) async {
  // make sure user is connected to the internet
  ConnectivityModel connectivity = Provider.of<ConnectivityModel>(
    context,
    listen: false,
  );
  if (!connectivity.hasConnection) {
    await connectivity.alertWhenOffline(context);
    return;
  }
  FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);

  // alert user in case they're paying with cash
  if (user.defaultPaymentMethod.type == PaymentMethodType.cash) {
    final chooseCard = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Pagamento em dinheiro não permitido."),
          actions: [
            TextButton(
              child: Text(
                "cancelar",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
            TextButton(
              child: Text(
                "escolher cartão",
                style: TextStyle(
                  color: AppColor.primaryPink,
                  fontSize: 18,
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
            ),
          ],
        );
      },
    ) as bool;
    // push payments screen if user decides to choose a card
    if (chooseCard) {
      await Navigator.pushNamed(
        context,
        Payments.routeName,
        arguments: PaymentsArguments(mode: PaymentsMode.pick),
      );
    }
    // return, so PayTrip is only pushed if payment method is credit card
    return;
  }

  // push PayTrip screen after user picks a card
  final paid = await Navigator.pushNamed(
    context,
    PayTrip.routeName,
    arguments: PayTripArguments(
      firebase: firebase,
      cardID: user.defaultPaymentMethod.creditCardID,
    ),
  ) as bool;

  // show warnings about payment status
  if (paid) {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "Pagamento concluido!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: Text(
              "Muito obrigado! Agora você pode continuar pedindo corridas."),
          actions: [
            TextButton(
              child: Text(
                "ok",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    );
  } else {
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            "O pagamento falhou!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
              "Tente novamente. Utilizar outro cartão pode resolver o problema."),
          actions: [
            TextButton(
              child: Text(
                "ok",
                style: TextStyle(fontSize: 18),
              ),
              onPressed: () => Navigator.pop(context, false),
            ),
          ],
        );
      },
    );
  }
}
