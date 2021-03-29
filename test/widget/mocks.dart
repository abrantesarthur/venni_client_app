import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/models.dart';
import 'package:rider_frontend/models/route.dart';
import 'package:rider_frontend/models/userData.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/places.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}

class MockFirebaseModel extends Mock implements FirebaseModel {}

class MockDatabaseReference extends Mock implements DatabaseReference {}

class MockDataSnapshot extends Mock implements DataSnapshot {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class MockUserCredential extends Mock implements UserCredential {}

class MockUser extends Mock implements User {}

class MockUserDataModel extends Mock implements UserDataModel {}

class MockRouteModel extends Mock implements RouteModel {}

class MockGeocodingResult extends Mock implements GeocodingResult {}

class MockAddress extends Mock implements Address {}

class MockPlaces extends Mock implements Places {}

MockFirebaseModel mockFirebaseModel = MockFirebaseModel();
MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
MockFirebaseDatabase mockFirebaseDatabase = MockFirebaseDatabase();
MockNavigatorObserver mockNavigatorObserver = MockNavigatorObserver();
MockUserCredential mockUserCredential = MockUserCredential();
MockUser mockUser = MockUser();
MockUserDataModel mockUserDataModel = MockUserDataModel();
MockRouteModel mockRouteModel = MockRouteModel();
MockGeocodingResult mockGeocodingResult = MockGeocodingResult();
MockGeocodingResult mockUserGeocoding = MockGeocodingResult();
MockAddress mockAddress = MockAddress();
MockPlaces mockPlaces = MockPlaces();
