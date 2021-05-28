import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/pilot.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/screens/cashDetail.dart';
import 'package:rider_frontend/screens/confirmTrip.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/screens/addCreditCard.dart';
import 'package:rider_frontend/screens/creditCardDetail.dart';
import 'package:rider_frontend/screens/defineDropOff.dart';
import 'package:rider_frontend/screens/definePickUp.dart';
import 'package:rider_frontend/screens/deleteAccount.dart';
import 'package:rider_frontend/screens/editEmail.dart';
import 'package:rider_frontend/screens/editPhone.dart';
import 'package:rider_frontend/screens/home.dart';
import 'package:rider_frontend/screens/insertName.dart';
import 'package:rider_frontend/screens/insertNewEmail.dart';
import 'package:rider_frontend/screens/insertNewPassword.dart';
import 'package:rider_frontend/screens/insertNewPhone.dart';
import 'package:rider_frontend/screens/insertPassword.dart';
import 'package:rider_frontend/screens/insertPhone.dart';
import 'package:rider_frontend/screens/insertSmsCode.dart';
import 'package:rider_frontend/screens/insertEmail.dart';
import 'package:rider_frontend/screens/defineRoute.dart';
import 'package:rider_frontend/screens/pastTripDetail.dart';
import 'package:rider_frontend/screens/pastTrips.dart';
import 'package:rider_frontend/screens/payTrip.dart';
import 'package:rider_frontend/screens/payments.dart';
import 'package:rider_frontend/screens/pilotProfile.dart';
import 'package:rider_frontend/screens/privacy.dart';
import 'package:rider_frontend/screens/profile.dart';
import 'package:rider_frontend/screens/ratePilot.dart';
import 'package:rider_frontend/screens/settings.dart';
import 'package:rider_frontend/screens/shareLocation.dart';
import 'package:rider_frontend/screens/splash.dart';
import 'package:rider_frontend/screens/start.dart';
import 'package:rider_frontend/screens/pickMapLocation.dart';
import 'package:rider_frontend/vendors/places.dart';

/**
 * https://github.com/flutter/flutter/issues/41383#issuecomment-549432413
 * zhouhao27's solution for xcode problems with import firebase_auth
 * 
 */

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;
  bool _error = false;
  FirebaseModel firebaseModel;
  TripModel tripModel;
  UserModel user;
  ConnectivityModel connectivity;
  GoogleMapsModel googleMaps;
  PilotModel pilot;
  FirebaseAuth firebaseAuth;
  FirebaseDatabase firebaseDatabase;
  FirebaseStorage firebaseStorage;
  FirebaseFunctions firebaseFunctions;

  @override
  void initState() {
    initializeApp();
    super.initState();
  }

  @override
  void dispose() {
    if (googleMaps != null) {
      googleMaps.dispose();
    }
    super.dispose();
  }

  Future<void> initializeApp() async {
    // TODO: load user info or think about how to store in device (like credit card, photo, trip-request etc)
    // TODO: decide whether to set firebase.database.setPersistenceEnabled(true)
    await initializeFlutterFire();
  }

  // Define an async function to initialize FlutterFire
  Future<void> initializeFlutterFire() async {
    try {
      /*
        By default, initializeApp references the FirebaseOptions object that
        read the configuration from GoogleService-Info.plist on iOS and
        google-services.json on Android. Which such files we end up picking
        depends on which value we pass to the --flavor flag of futter run 
        reference: https://firebase.google.com/docs/projects/multiprojects */
      if (Firebase.apps.length == 0) {
        await Firebase.initializeApp();
      }

      // insantiate authentication, database, and storage
      firebaseAuth = FirebaseAuth.instance;
      firebaseDatabase = FirebaseDatabase.instance;
      firebaseStorage = FirebaseStorage.instance;
      firebaseFunctions = FirebaseFunctions.instance;

      // check if cloud functions are being emulated locally
      if (AppConfig.env.values.emulateCloudFunctions) {
        firebaseFunctions.useFunctionsEmulator(
            origin: AppConfig.env.values.cloudFunctionsBaseURL);
      }

      // set default authentication language as brazilian portuguese
      await firebaseAuth.setLanguageCode("pt_br");

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

  // TODO: README How to test locally taking DEV flavor into account. Explain that need to run emulator locally.
  // TODO: Find a way of using xcode flavors so that it's not necessary to manually switch bundle id in xcode when running in dev or prod.
  // TODO: make sure that phone authentication works in android in both development and production mode
  // TODO: add lockScreen variable to all relevant screens
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
  // TODO: implement prod flavor https://medium.com/@animeshjain/build-flavors-in-flutter-android-and-ios-with-different-firebase-projects-per-flavor-27c5c5dac10b

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
      // initialize firebaseModel. This will add a listener for user changes.
      firebaseModel = FirebaseModel(
        firebaseAuth: firebaseAuth,
        firebaseDatabase: firebaseDatabase,
        firebaseStorage: firebaseStorage,
        firebaseFunctions: firebaseFunctions,
      );

      // initialize models
      tripModel = TripModel();
      user = UserModel();
      googleMaps = GoogleMapsModel();
      pilot = PilotModel();
      connectivity = ConnectivityModel();
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
          ChangeNotifierProvider<TripModel>(
            create: (context) => tripModel,
          ),
          ChangeNotifierProvider<UserModel>(
            create: (context) => user,
          ),
          ChangeNotifierProvider<GoogleMapsModel>(
            create: (context) => googleMaps,
          ),
          ChangeNotifierProvider<PilotModel>(
            create: (context) => pilot,
          ),
          ChangeNotifierProvider<ConnectivityModel>(
            create: (context) => connectivity,
          ),
        ], // pass user model down
        builder: (context, child) {
          FirebaseModel firebase = Provider.of<FirebaseModel>(
            context,
            listen: false,
          );

          return MaterialApp(
            theme: ThemeData(fontFamily: "OpenSans"),
            // start screen depends on whether user is registered
            initialRoute:
                firebase.isRegistered ? Home.routeName : Start.routeName,
            // pass appropriate arguments to routes
            onGenerateRoute: (RouteSettings settings) {
              // if Home is pushed
              if (settings.name == Home.routeName) {
                final HomeArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return Home(
                    firebase: args.firebase,
                    trip: args.trip,
                    user: args.user,
                    googleMaps: args.googleMaps,
                    connectivity: args.connectivity,
                  );
                });
              }

              // if InsertPhone is pushed
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
                    mode: args.mode,
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
                    mode: args.mode,
                  );
                });
              }

              // if DefineDropOff is pushed
              if (settings.name == DefineDropOff.routeName) {
                return MaterialPageRoute(builder: (context) {
                  return DefineDropOff(places: Places());
                });
              }

              // if DefinePickUp is pushed
              if (settings.name == DefinePickUp.routeName) {
                return MaterialPageRoute(builder: (context) {
                  return DefinePickUp(places: Places());
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

              // if ConfirmTrip is pushed
              if (settings.name == ConfirmTrip.routeName) {
                final ConfirmTripArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return ConfirmTrip(
                    firebase: args.firebase,
                    trip: args.trip,
                    user: args.user,
                  );
                });
              }

              // if ShareLocation is pushed
              if (settings.name == ShareLocation.routeName) {
                final ShareLocationArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return ShareLocation(
                    push: args.push,
                  );
                });
              }

              // if PastTrips is pushed
              if (settings.name == PastTrips.routeName) {
                final PastTripsArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return PastTrips(
                    firebase: args.firebase,
                    connectivity: args.connectivity,
                  );
                });
              }

              // if PastTripDetail is pushed
              if (settings.name == PastTripDetail.routeName) {
                final PastTripDetailArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return PastTripDetail(
                    pastTrip: args.pastTrip,
                    firebase: args.firebase,
                  );
                });
              }

              // if CreditCardDetail is pushed
              if (settings.name == CreditCardDetail.routeName) {
                final CreditCardDetailArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return CreditCardDetail(
                    creditCard: args.creditCard,
                  );
                });
              }

              // if Payments is pushed
              if (settings.name == Payments.routeName) {
                final PaymentsArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return Payments(mode: args.mode);
                });
              }

              // if PayTrip is pushed
              if (settings.name == PayTrip.routeName) {
                final PayTripArguments args = settings.arguments;
                return MaterialPageRoute(builder: (context) {
                  return PayTrip(
                    firebase: args.firebase,
                    cardID: args.cardID,
                  );
                });
              }

              assert(false, 'Need to implement ${settings.name}');
              return null;
            },
            routes: {
              Home.routeName: (context) => Home(
                    firebase: firebaseModel,
                    trip: tripModel,
                    user: user,
                    googleMaps: googleMaps,
                    connectivity: connectivity,
                  ),
              Start.routeName: (context) => Start(),
              Settings.routeName: (context) => Settings(),
              Profile.routeName: (context) => Profile(),
              Privacy.routeName: (context) => Privacy(),
              DeleteAccount.routeName: (context) => DeleteAccount(),
              EditEmail.routeName: (context) => EditEmail(),
              EditPhone.routeName: (context) => EditPhone(),
              InsertNewPhone.routeName: (context) => InsertNewPhone(),
              InsertNewEmail.routeName: (context) => InsertNewEmail(),
              InsertNewPassword.routeName: (context) => InsertNewPassword(),
              PilotProfile.routeName: (context) => PilotProfile(),
              RatePilot.routeName: (context) => RatePilot(),
              AddCreditCard.routeName: (context) => AddCreditCard(),
              CashDetail.routeName: (context) => CashDetail(),
            },
          );
        });
  }
}
