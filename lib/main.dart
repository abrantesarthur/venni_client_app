import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userPosition.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertName.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/screens/insertPhone.dart';
import 'package:rider_frontend/screens/insertSmsCode.dart';
import 'package:rider_frontend/screens/insertEmail.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/screens/pickMapLocation.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/geolocator.dart';
import 'package:rider_frontend/vendors/places.dart';

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 * 
 */

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;
  bool _error = false;
  FirebaseModel firebaseModel;
  RouteModel routeModel;
  UserPositionModel userPositionModel;

  @override
  void initState() {
    initializeApp();
    super.initState();
  }

  Future<void> initializeApp() async {
    await initializeUserPosition();
    await initializeFlutterFire();
  }

  Future<void> initializeUserPosition() async {
    // get user position
    Position userPos = await determineUserPosition();

    // get user geocoding
    GeocodingResponse geocoding = await Geocoding().searchByPosition(userPos);

    GeocodingResult geocodingResult = geocoding.results[0];

    // set usertPositionModel
    userPositionModel = UserPositionModel(geocoding: geocodingResult);
  }

  // Define an async function to initialize FlutterFire
  Future<void> initializeFlutterFire() async {
    try {
      // Wait for Firebase to initialize and set `_initialized` state to true
      await Firebase.initializeApp();
      // set default language as brazilian portuguese
      await FirebaseAuth.instance.setLanguageCode("pt_br");
      setState(() {
        _initialized = true;
        _error = false;
      });
    } catch (e) {
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  // TODO: get google api key from the environment in AppDelegate.swift
  // TODO: if user taps never when phone first launhes and asks to share location, it remains in venni screen forever
  // TODO: think about callign directions API only in backend
  // TODO: load user position here, instead of home
  // TODO: make sure client cannot write to database (cloud functions do that)
  // TODO: change the database rules to not allow anyone to edit it
  // TODO: when deploying the app, register a release certificate fingerprint
  //    in firebase instead of the debug certificate fingerprint
  //    (https://developers.google.com/android/guides/client-auth)
  // TODO: persist authentication state https://firebase.flutter.dev/docs/auth/usage
  // TODO: change navigation transitions
  // TODO: do integration testing
  // TODO: review entire user registration flow
  // TODO: overflow happens if a "O email já está sendo usado." warning happens
  // TODO:  make sure that user logs out when account is deleted or disactivated in firebase
  // TODO: decide on which logos to use

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        home: Scaffold(
          body: Container(
            color: Colors.white,
            child: Center(
              child: Text(
                "Algo deu errado :/\nReinicie o App.",
                style: TextStyle(
                  color: Colors.black,
                  fontFamily: "OpenSans",
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Show a loader until FlutterFire is initialized
    if (_initialized) {
      // initialize firebaseModel. This will add a listener for user changes only
      // if user is registered. Otherwise, we will go through the registration
      // process and manually add listener for user status changes at the end
      // of the registration.
      firebaseModel = FirebaseModel(
        firebaseAuth: FirebaseAuth.instance,
        firebaseDatabase: FirebaseDatabase.instance,
      );

      routeModel = RouteModel();
    } else {
      return Splash();
    }

    // if everything is setup, show Home screen or Start screen, depending
    // on whether user is signed in
    return MultiProvider(
        providers: [
          ChangeNotifierProvider<FirebaseModel>(
            create: (context) => firebaseModel,
          ),
          ChangeNotifierProvider<RouteModel>(
            create: (context) => routeModel,
          ),
          ChangeNotifierProvider<UserPositionModel>(
            create: (context) => userPositionModel,
          )
        ], // pass user model down
        builder: (context, child) {
          return MaterialApp(
            theme: ThemeData(fontFamily: "OpenSans"),
            // start screen depends on whether user is registered
            initialRoute:
                firebaseModel.isRegistered ? Home.routeName : Start.routeName,
            // pass appropriate arguments to routes
            onGenerateRoute: (RouteSettings settings) {
              if (settings.name == InsertPhone.routeName) {
                return MaterialPageRoute(builder: (context) {
                  return InsertPhone(); // TODO: move to routes
                });
              }
              // if InsertSmsCode is pushed
              if (settings.name == InsertSmsCode.routeName) {
                final InsertSmsCodeArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return InsertSmsCode(
                    verificationId: args.verificationId,
                    resendToken: args.resendToken,
                    phoneNumber: args.phoneNumber,
                  );
                });
              }
              // if InsertEmail is pushed
              if (settings.name == InsertEmail.routeName) {
                final InsertEmailArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return InsertEmail(userCredential: args.userCredential);
                });
              }
              // if InsertName is pushed
              if (settings.name == InsertName.routeName) {
                final InsertNameArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return InsertName(
                    userCredential: args.userCredential,
                    userEmail: args.userEmail,
                  );
                });
              }

              // if InsertPassword is pushed
              if (settings.name == InsertPassword.routeName) {
                final InsertPasswordArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return InsertPassword(
                    userCredential: args.userCredential,
                    userEmail: args.userEmail,
                    name: args.name,
                    surname: args.surname,
                  );
                });
              }

              // if DefineRoute is pushed
              if (settings.name == DefineRoute.routeName) {
                DefineRouteArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return DefineRoute(
                    routeModel: args.routeModel,
                    userGeocoding: args.userGeocoding,
                  );
                });
              }

              // if DefineDropOff is pushed
              if (settings.name == DefineDropOff.routeName) {
                final DefineDropOffArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return DefineDropOff(
                    chosenDropOffAddress: args.chosenDropOffAddress,
                    userGeocoding: args.userGeocoding,
                    places: Places(),
                  );
                });
              }

              // if DefinePickUp is pushed
              if (settings.name == DefinePickUp.routeName) {
                final DefinePickUpArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return DefinePickUp(
                    chosenPickUpAddress: args.chosenPickUpAddress,
                    userGeocoding: args.userGeocoding,
                    places: Places(),
                  );
                });
              }

              // if PickRoute is pushed
              if (settings.name == PickMapLocation.routeName) {
                final PickMapLocationArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return PickMapLocation(
                      initialPosition: args.initialPosition,
                      isDropOff: args.isDropOff);
                });
              }

              assert(false, 'Need to implement ${settings.name}');
              return null;
            },
            routes: {
              Start.routeName: (context) => Start(),
              Home.routeName: (context) => Home(),
            },
          );
        });
  }
}
