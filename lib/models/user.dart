import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/geolocator.dart';

class ProfileImage {
  final ImageProvider<Object> file;
  final String name;

  ProfileImage({@required this.file, @required this.name});
}

class UserModel extends ChangeNotifier {
  GeocodingResult _geocoding;
  ProfileImage _profileImage;
  String _rating;
  PaymentMethodName _defaultPaymentMethod;
  String _defaultCreditCardID;
  List<CreditCard> _creditCards;

  GeocodingResult get geocoding => _geocoding;
  ProfileImage get profileImage => _profileImage;
  String get rating => _rating;
  PaymentMethodName get defaultPaymentMethod => _defaultPaymentMethod;
  String get defaultCreditCardID => _defaultCreditCardID;
  List<CreditCard> get creditCards => _creditCards;

  UserModel();

  void setProfileImage(ProfileImage img) {
    _profileImage = img;
    notifyListeners();
  }

  void setGeocoding(GeocodingResult g) {
    _geocoding = g;
    notifyListeners();
  }

  void setRating(String r) {
    _rating = r;
    notifyListeners();
  }

  void fromClientInterface(ClientInterface c) {
    if (c != null) {
      _rating = c.rating;
      _defaultPaymentMethod = c.defaultPaymentMethod.name;
      _defaultCreditCardID = c.defaultPaymentMethod.creditCardID;
      _creditCards = c.creditCards;
      notifyListeners();
    }
  }

  void addCreditCard(CreditCard card) {
    if (card != null) {
      _creditCards.add(card);
      notifyListeners();
    }
  }

  Future<void> downloadData(FirebaseModel firebase) async {
    // download user image file
    // TODO: there is aproblem with getProfileImage. it's not returning. fix it
    firebase.storage
        .getUserProfileImage(uid: firebase.auth.currentUser.uid)
        .then((value) => this.setProfileImage(value));

    // get user rating
    ClientInterface client =
        await firebase.database.getClientData(firebase.auth.currentUser.uid);
    this.fromClientInterface(client);
  }

  Future<Position> getPosition() async {
    Position userPos;
    try {
      userPos = await determineUserPosition();
    } catch (_) {
      return null;
    }
    return userPos;
  }

  Future<void> getGeocoding({Position pos}) async {
    Position userPos = pos;
    if (userPos == null) {
      // get user position
      userPos = await getPosition();
      if (userPos == null) {
        // don't update geocoding if fail to get position.
        return;
      }
    }

    // get user geocoding
    GeocodingResponse geocoding = await Geocoding().searchByPosition(userPos);
    GeocodingResult geocodingResult;
    if (geocoding != null &&
        geocoding.results != null &&
        geocoding.results.length > 0) {
      geocodingResult = geocoding.results[0];
    }
    // set user position
    setGeocoding(geocodingResult);
  }
}
