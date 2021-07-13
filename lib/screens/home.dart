import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/menu.dart';
import 'package:rider_frontend/screens/payments.dart';
import 'package:rider_frontend/screens/ratePartner.dart';
import 'package:rider_frontend/screens/shareLocation.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/styles.dart';
import 'package:rider_frontend/utils/utils.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';
import 'package:rider_frontend/widgets/confirmTripWidget.dart';
import 'package:rider_frontend/widgets/inProgressWidget.dart';
import 'package:rider_frontend/widgets/requestTripWidgets.dart';
import 'package:rider_frontend/widgets/unpaidTripWidget.dart';
import 'package:rider_frontend/widgets/waitingPartnerWidget.dart';

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
  GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  StreamSubscription partnerSubscription;
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
    _getUserPosition(notify: false);
  }

  @override
  void initState() {
    super.initState();

    // HomeState uses WidgetsBindingObserver as a mixin. Thus, we can pass it as
    // argument to WidgetsBinding.addObserver. The didChangeAppLifecycleState that
    // we override, is notified whenever an application even occurs (e.g., system
    // puts app in background).
    WidgetsBinding.instance.addObserver(this);

    // trigger _getUserPosition
    userPositionFuture = _getUserPosition();

    _hasConnection = widget.connectivity.hasConnection;

    // add listeners after tree is built and we have context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // after finishing _getUserPosition,
      userPositionFuture.then((position) async {
        if (position != null) {
          // user retrieved lat and lng to set maps camera view. notifying is
          // not necessary
          widget.googleMaps.setInitialCameraLatLng(
            LatLng(
              widget.user.position?.latitude,
              widget.user.position?.longitude,
            ),
            notify: false,
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
    if (partnerSubscription != null) {
      partnerSubscription.cancel();
    }
    if (tripSubscription != null) {
      tripSubscription.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    UserModel user = Provider.of<UserModel>(context, listen: false);
    GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(context);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context);
    ConnectivityModel connectivity = Provider.of<ConnectivityModel>(context);

    // if connectivity has changed
    if (_hasConnection != connectivity.hasConnection) {
      // update _hasConnectivity
      _hasConnection = connectivity.hasConnection;
      // if connectivity changed from offline to online
      if (connectivity.hasConnection) {
        // download user data
        try {
          user.downloadData(firebase);
          trip.downloadData();
        } catch (e) {}
      }
    }

    return FutureBuilder(
      initialData: null,
      future: userPositionFuture,
      builder: (
        BuildContext context,
        AsyncSnapshot<Position> snapshot,
      ) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // show loading screen while waiting to get user position
          return Splash(
              text: "Muito bom ter você de volta, " +
                  firebase.auth.currentUser.displayName.split(" ").first +
                  "!");
        }

        // make sure we successfully got user position
        if (snapshot.data == null) {
          return ShareLocation(
            push: Home.routeName,
            routeArguments: HomeArguments(
              firebase: firebase,
              googleMaps: widget.googleMaps,
              trip: widget.trip,
              user: widget.user,
              connectivity: connectivity,
            ),
          );
        }

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
                onMapCreated: (c) async {
                  await googleMaps.onMapCreatedCallback(c, notify: false);
                  // call _redrawUIOnTripUpdate so UI is updated once when maps is ready
                  await _redrawUIOnTripUpdate(context);
                },
                polylines: Set<Polyline>.of(googleMaps.polylines.values),
                markers: googleMaps.markers,
              ),
              Consumer<UserModel>(builder: (context, u, _) {
                return Stack(
                  children: [
                    // lock trip request if user has pending payments
                    (u.unpaidTrip != null)
                        ? UnpaidTripWidget(scaffoldKey: _scaffoldKey)
                        // otherwise, build UI depending on TripModel's state
                        : Consumer<TripModel>(
                            builder: (context, t, _) {
                              return Stack(
                                children: [
                                  (t.tripStatus == null ||
                                          t.tripStatus == TripStatus.off ||
                                          t.tripStatus ==
                                              TripStatus.cancelledByClient ||
                                          t.tripStatus == TripStatus.completed)
                                      ? RequestTripWidgets(
                                          scaffoldKey: _scaffoldKey,
                                        )
                                      : Container(),
                                  (t.tripStatus ==
                                              TripStatus.waitingConfirmation ||
                                          t.tripStatus ==
                                              TripStatus.paymentFailed ||
                                          t.tripStatus ==
                                              TripStatus.noPartnersAvailable ||
                                          t.tripStatus ==
                                              TripStatus.lookingForPartner ||
                                          t.tripStatus ==
                                              TripStatus.cancelledByPartner)
                                      ?
                                      // if user is about to confirm trip for the first time (waitingConfirmation)
                                      // has already confirmed but received a paymentFailed, or the partner canceleld,
                                      // give them the option of trying again.
                                      ConfirmTripWidget()
                                      : Container(),
                                  (t.tripStatus == TripStatus.waitingPartner)
                                      ? WaitingPartnerWidget()
                                      : Container(),
                                  (t.tripStatus == TripStatus.inProgress)
                                      ? InProgressWidget()
                                      : Container(),
                                ],
                              );
                            },
                          ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<Position> _getUserPosition({bool notify = true}) async {
    // Try getting user position. If it returns null, it's because user stopped
    // sharing location. getPosition() will automatically handle that case, asking
    // the user to share again and preventing them from using the app if they
    // don't.
    Position pos = await widget.user.getPosition(notify: false);
    if (pos == null) {
      return null;
    }

    // if we could get position, get user's geocoding.
    try {
      await widget.user.getGeocoding(pos, notify: notify);
    } catch (_) {}

    // if we could get position, make sure to resubscribe to position changes
    // again, as the subscription may have been cancelled if user stopped
    // sharing location.
    widget.user.updateGeocodingOnPositionChange();
    return pos;
  }

  // push start screen when user logs out
  void _signOut(BuildContext context) {
    UserModel user = Provider.of<UserModel>(context, listen: false);
    if (!widget.firebase.isRegistered) {
      user.clear();
      Navigator.pushNamedAndRemoveUntil(context, Start.routeName, (_) => false);
    }
  }

  void _cancelPartnerSubscription() {
    if (partnerSubscription != null) {
      partnerSubscription.cancel();
    }
    partnerSubscription = null;
  }

  void _cancelTripSubscription() {
    if (tripSubscription != null) {
      tripSubscription.cancel();
    }
    tripSubscription = null;
  }

  void _cancelSubscriptions() {
    _cancelPartnerSubscription();
    _cancelTripSubscription();
  }

  // _redrawUIOnTripUpdate is triggered whenever we update the tripModel.
  // it looks at the trip status and updates the UI accordingly
  Future<void> _redrawUIOnTripUpdate(BuildContext context) async {
    TripModel trip = Provider.of<TripModel>(context, listen: false);
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    PartnerModel partner = Provider.of<PartnerModel>(context, listen: false);
    GoogleMapsModel googleMaps = Provider.of<GoogleMapsModel>(
      context,
      listen: false,
    );

    if (trip.tripStatus == null || trip.tripStatus == TripStatus.off) {
      // wait before undrawing polyline to help prevent concurrency issues
      await Future.delayed(Duration(milliseconds: 500));
      await googleMaps.undrawPolyline(context);
      return;
    }

    if (trip.tripStatus == TripStatus.completed) {
      await googleMaps.undrawPolyline(context);
      await Navigator.pushNamed(context, RatePartner.routeName);
      // important: don't notify listeneres when clearing models. This may cause
      // null exceptions because there may still be widgets from the previous
      // screen RatePartner that use the values from the models.
      partner.clear(notify: false);
      trip.clear(notify: false);

      // download user data to make sure he has no unpaid trips
      try {
        await widget.user.downloadData(firebase);
      } catch (_) {}
      return;
    }

    if (trip.tripStatus == TripStatus.cancelledByClient) {
      await googleMaps.undrawPolyline(context);
      return;
    }

    if (trip.tripStatus == TripStatus.cancelledByPartner) {
      await widget.googleMaps.drawPolyline(
        context: context,
        encodedPoints: trip.encodedPoints,
        topPadding: MediaQuery.of(context).size.height / 9.5,
        bottomPadding: MediaQuery.of(context).size.height / 4.8,
      );
      await showOkDialog(
        context: context,
        title: "Nosso(a) parceiro(a) cancelou a corrida",
        content: "faça o pedido novamente",
      );
      // change trip status locally so AlertDialog is not shown twice. This could
      // happen, for example, if route is modified in TripModel, thus rebuilding
      // the UI
      trip.updateStatus(TripStatus.waitingConfirmation, notify: false);
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

    void handlePartnerUpdates(TripStatus expectedStatus) {
      // only reset subscription if it's null (i.e., it has been cancelled or this
      // is the first time it's being used). We enforce a business rule that
      // when we cancel subscriptions we set them to null. This allows us to
      // update the TripModel and, as a consequence, notify listeners without
      // redefining subscriptions when _redrawUIOnTripUpdate is called again.
      if (partnerSubscription == null) {
        partnerSubscription =
            firebase.database.onPartnerUpdate(partner.id, (e) {
          // if partner was set free, stop listening for his updates, as he is
          // no longer handling our trip.
          PartnerStatus partnerStatus =
              getPartnerStatusFromString(e.snapshot.value["status"]);
          if (partnerStatus != PartnerStatus.busy) {
            _cancelPartnerSubscription();
            return;
          }
          // only redraw polyline if trip status is as expected and partner
          // position has changed. The first check is necessary because it is
          // possible that local status may be updated before backend learns
          // about the update thus triggering the cancelling of this listener.
          // If we don't perform this check, we will continue redrawing the
          // polyline even though local trip state has already changed. The
          // second check is necessary as to avoid unecessary redrawing.
          double newLat = double.parse(e.snapshot.value["current_latitude"]);
          double newLng = double.parse(e.snapshot.value["current_longitude"]);
          if (trip.tripStatus == expectedStatus &&
              (newLat != partner.currentLatitude ||
                  newLng != partner.currentLongitude)) {
            // update partner coordinates
            partner.updateCurrentLatitude(newLat);
            partner.updateCurrentLongitude(newLng);
            // draw polyline from partner to origin or from partner to destination
            if (expectedStatus == TripStatus.waitingPartner) {
              googleMaps.drawPolylineFromPartnerToOrigin(context);
            } else if (expectedStatus == TripStatus.inProgress) {
              googleMaps.drawPolylineFromPartnerToDestination(context);
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
              // from partner to destination
              trip.updateStatus(newTripStatus);
              googleMaps.drawPolylineFromPartnerToDestination(context);
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

    if (trip.tripStatus == TripStatus.waitingPartner) {
      googleMaps.drawPolylineFromPartnerToOrigin(context);
      handlePartnerUpdates(TripStatus.waitingPartner);
      handleTripUpdates(TripStatus.waitingPartner);
      return;
    }

    if (trip.tripStatus == TripStatus.inProgress) {
      googleMaps.drawPolylineFromPartnerToDestination(context);
      handlePartnerUpdates(TripStatus.inProgress);
      handleTripUpdates(TripStatus.inProgress);
      return;
    }

    if (trip.tripStatus == TripStatus.noPartnersAvailable ||
        trip.tripStatus == TripStatus.lookingForPartner) {
      // alert user to wait
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showOkDialog(
          context: context,
          title: "Nenhum motorista disponível",
          content: "Aguarde um minutinho e tente novamente.",
        );
      });
      // change trip status locally so AlertDialog is not shown twice. This could
      // happen, for example, if route is modified in TripModel, thus rebuilding
      // the UI
      trip.updateStatus(TripStatus.waitingConfirmation, notify: false);
      return;
    }

    if (trip.tripStatus == TripStatus.paymentFailed) {
      await widget.googleMaps.drawPolyline(
        context: context,
        encodedPoints: trip.encodedPoints,
        topPadding: MediaQuery.of(context).size.height / 9.5,
        bottomPadding: MediaQuery.of(context).size.height / 4.8,
      );
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
      // change trip status locally so AlertDialog is not shown twice. This could
      // happen, for example, if route is modified in TripModel, thus rebuilding
      // the UI
      trip.updateStatus(TripStatus.waitingConfirmation, notify: false);
      return;
    }
    return;
  }
}
