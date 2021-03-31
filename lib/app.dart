import 'dart:html';
import 'dart:io' as dartIo;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:rider_frontend/config/config.dart';
import 'package:rider_frontend/vendors/firebase.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userData.dart';
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
import 'package:rider_frontend/screens/privacy.dart';
import 'package:rider_frontend/screens/profile.dart';
import 'package:rider_frontend/screens/settings.dart';
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

class App extends StatefulWidget {
  _AppState createState() => _AppState();
}

class _AppState extends State<App> {
  bool _initialized = false;
  bool _error = false;
  FirebaseModel firebaseModel;
  RouteModel routeModel;
  UserDataModel userDataModel;
  FirebaseAuth firebaseAuth;
  FirebaseDatabase firebaseDatabase;
  FirebaseStorage firebaseStorage;

  @override
  void initState() {
    initializeApp();
    super.initState();
  }

  Future<void> initializeApp() async {
    // TODO: load user info or think about how to store in device (like credit card, photo, ride-request etc)
    // TODO: decide whether to set firebase.database.setPersistenceEnabled(true)

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
    userDataModel = UserDataModel(geocoding: geocodingResult);
  }

  // Define an async function to initialize FlutterFire
  Future<void> initializeFlutterFire() async {
    try {
      // if running in production mode
      if (AppConfig.env.flavor == Flavor.PROD) {
        /*
        By default, initializeApp references the FirebaseOptions object that
        read the configuration from GoogleService-Info.plist on iOS and
        google-services.json on Android. In our case, these files target the
        venni-rider-staging project.
        reference: https://firebase.google.com/docs/projects/multiprojects */
        await Firebase.initializeApp();

        // insantiate authentication, database, and storage
        firebaseAuth = FirebaseAuth.instance;
        firebaseDatabase = FirebaseDatabase.instance;
        firebaseStorage = FirebaseStorage.instance;
      } else {
        /* If running on Dev mode, we manually instantiate the FirebaesOptions to
        target the venni-rider-development project instead of donwnloading 
        configuration files. It's also worth noting that, in this case, the 
        RealtimeDatabase, Cloud Functions and Database are accessed locally 
        through the Firebase Emulator Suite.
        reference: https://firebase.flutter.dev/docs/core/usage/ */
        FirebaseApp app = await Firebase.initializeApp(
          name: "venni-rider-development",
          options: FirebaseOptions(
            appId: "1:528515096365:ios:2f4ce7c826e3fde52bbda4",
            apiKey: "AIzaSyB3XWRvzLTbSOiXOEocSh646slpxk0sh_4",
            messagingSenderId: "528515096365",
            projectId: "venni-rider-development",
            storageBucket: "venni-rider-development.appspot.com",
          ),
        );

        // instantiate authentication
        firebaseAuth = FirebaseAuth.instanceFor(app: app);
        // authentication targets emulator
        await firebaseAuth
            .useEmulator("http://localhost:" + AppConfig.env.values.authPort);

        // instantiate database targetting emulator
        firebaseDatabase = FirebaseDatabase(
          app: Firebase.app(),
          databaseURL: dartIo.Platform.isAndroid
              ? 'http://10.0.2.2:' + AppConfig.env.values.databasePort
              : 'http://localhost:' + AppConfig.env.values.databasePort,
        );

        // instantiate storage (the only resource not running locally)
        firebaseStorage = FirebaseStorage.instanceFor(app: app);
      }

      // set default authentication language as brazilian portuguese
      await firebaseAuth.setLanguageCode("pt_br");

      // if user is logged in
      if (firebaseAuth.currentUser != null) {
        // download user data
        _downloadUserData(firebaseAuth.currentUser.uid);
      }

      setState(() {
        _initialized = true;
        _error = false;
      });
    } catch (e) {
      print(e);
      // Set `_error` state to true if Firebase initialization fails
      setState(() {
        _error = true;
      });
    }
  }

  Future<void> _downloadUserData(String uid) async {
    // download user image file
    ProfileImage profileImage = await firebaseStorage.getProfileImage(uid: uid);

    if (profileImage != null) {
      userDataModel.setProfileImage(
        file: profileImage.file,
        name: profileImage.name,
      );
    }

    // get user rating
    double rating = await firebaseDatabase.getUserRating(uid);
    if (rating != null) {
      userDataModel.setUserRating(rating);
    }
  }

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
        firebaseAuth: FirebaseAuth.instance,
        firebaseDatabase: firebaseDatabase,
        firebaseStorage: FirebaseStorage.instance,
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
          ChangeNotifierProvider<UserDataModel>(
            create: (context) => userDataModel,
          )
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

              assert(false, 'Need to implement ${settings.name}');
              return null;
            },
            routes: {
              Start.routeName: (context) => Start(),
              Home.routeName: (context) => Home(),
              Settings.routeName: (context) => Settings(),
              Profile.routeName: (context) => Profile(),
              Privacy.routeName: (context) => Privacy(),
              DeleteAccount.routeName: (context) => DeleteAccount(),
              EditEmail.routeName: (context) => EditEmail(),
              EditPhone.routeName: (context) => EditPhone(),
              InsertNewPhone.routeName: (context) => InsertNewPhone(),
              InsertNewEmail.routeName: (context) => InsertNewEmail(),
              InsertNewPassword.routeName: (context) => InsertNewPassword(),
            },
          );
        });
  }
}
