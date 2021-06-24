import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:mockito/mockito.dart';
import 'package:rider_frontend/models/address.dart';
import 'package:rider_frontend/models/connectivity.dart';
import 'package:rider_frontend/models/partner.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/models/googleMaps.dart';
import 'package:rider_frontend/models/trip.dart';
import 'package:rider_frontend/models/user.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
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

class MockPartnerModel extends Mock implements PartnerModel {}

class MockGoogleMapsModel extends Mock implements GoogleMapsModel {}

class MockConnectivityModel extends Mock implements ConnectivityModel {}

class MockGeocodingResult extends Mock implements GeocodingResult {}

class MockUserPosition extends Mock implements Position {}

class MockAddress extends Mock implements Address {}

class MockPlaces extends Mock implements Places {}

class MockClientPaymentMethod extends Mock implements ClientPaymentMethod {}

MockFirebaseModel mockFirebaseModel = MockFirebaseModel();
MockFirebaseAuth mockFirebaseAuth = MockFirebaseAuth();
MockFirebaseDatabase mockFirebaseDatabase = MockFirebaseDatabase();
MockDatabaseReference mockDatabaseReference = MockDatabaseReference();
MockNavigatorObserver mockNavigatorObserver = MockNavigatorObserver();
MockUserCredential mockUserCredential = MockUserCredential();
MockUser mockUser = MockUser();
MockUserModel mockUserModel = MockUserModel();
MockTripModel mockTripModel = MockTripModel();
MockPartnerModel mockPartnerModel = MockPartnerModel();
MockGoogleMapsModel mockGoogleMapsModel = MockGoogleMapsModel();
MockConnectivityModel mockConnectivityModel = MockConnectivityModel();
MockGeocodingResult mockGeocodingResult = MockGeocodingResult();
MockGeocodingResult mockUserGeocoding = MockGeocodingResult();
MockUserPosition mockUserPosition = MockUserPosition();
MockAddress mockAddress = MockAddress();
MockPlaces mockPlaces = MockPlaces();
MockClientPaymentMethod mockClientPaymentMethod = MockClientPaymentMethod();

void main() {}
