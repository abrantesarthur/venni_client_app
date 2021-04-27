import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/driver.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
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

class MockUserModel extends Mock implements UserModel {}

class MockTripModel extends Mock implements TripModel {}

class MockDriverModel extends Mock implements DriverModel {}

class MockGoogleMapsModel extends Mock implements GoogleMapsModel {}

class MockGeocodingResult extends Mock implements GeocodingResult {}

class MockAddress extends Mock implements Address {}

class MockPlaces extends Mock implements Places {}

MockFirebaseModel mockFirebaseModel = MockFirebaseModel();
MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
MockFirebaseDatabase mockFirebaseDatabase = MockFirebaseDatabase();
MockNavigatorObserver mockNavigatorObserver = MockNavigatorObserver();
MockUserCredential mockUserCredential = MockUserCredential();
MockUser mockUser = MockUser();
MockUserModel mockUserModel = MockUserModel();
MockTripModel mockTripModel = MockTripModel();
MockDriverModel mockDriverModel = MockDriverModel();
MockGoogleMapsModel mockGoogleMapsModel = MockGoogleMapsModel();
MockGeocodingResult mockGeocodingResult = MockGeocodingResult();
MockGeocodingResult mockUserGeocoding = MockGeocodingResult();
MockAddress mockAddress = MockAddress();
MockPlaces mockPlaces = MockPlaces();
