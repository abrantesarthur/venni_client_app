import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseDatabase/methods.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/methods.dart';
import 'package:rider_frontend/vendors/geocoding.dart';
import 'package:rider_frontend/vendors/geolocator.dart';

class ProfileImage {
  final ImageProvider<Object> file;
  final String name;

  ProfileImage({@required this.file, @required this.name});
}

class UserModel extends ChangeNotifier {
  String _id;
  GeocodingResult _geocoding;
  Position _position;
  StreamSubscription _positionSubscription;
  ProfileImage _profileImage;
  String _rating;
  ClientPaymentMethod _defaultPaymentMethod =
      ClientPaymentMethod(type: PaymentMethodType.cash);
  List<CreditCard> _creditCards;
  Trip _unpaidTrip;

  String get id => _id;
  GeocodingResult get geocoding => _geocoding;
  Position get position => _position;
  ProfileImage get profileImage => _profileImage;
  String get rating => _rating;
  ClientPaymentMethod get defaultPaymentMethod => _defaultPaymentMethod;
  List<CreditCard> get creditCards => _creditCards;
  Trip get unpaidTrip => _unpaidTrip;

  UserModel();

  void clear() {
    _id = null;
    _geocoding = null;
    _position = null;
    _positionSubscription = null;
    _profileImage = null;
    _rating = null;
    _defaultPaymentMethod = null;
    _creditCards = null;
    _unpaidTrip = null;
    notifyListeners();
  }

  void setProfileImage(
    ProfileImage img, {
    bool notify = true,
  }) {
    _profileImage = img;
    if (notify) {
      notifyListeners();
    }
  }

  void setRating(String r) {
    _rating = r;
    notifyListeners();
  }

  void setDefaultPaymentMethod(ClientPaymentMethod cpm, {bool notify = true}) {
    _defaultPaymentMethod = cpm;
    if (notify) {
      notifyListeners();
    }
  }

  void setUnpaidTrip(Trip t, {bool notify = true}) {
    _unpaidTrip = t;
    if (notify) {
      notifyListeners();
    }
  }

  void fromClientInterface(
    ClientInterface c, {
    bool notify = true,
  }) {
    if (c != null) {
      _id = c.id;
      _rating = c.rating;
      _defaultPaymentMethod = c.defaultPaymentMethod;
      _creditCards = c.creditCards;
      _unpaidTrip = c.unpaidTrip;
      if (notify) {
        notifyListeners();
      }
    }
  }

  void addCreditCard(CreditCard card) {
    if (card != null) {
      _creditCards.add(card);
      notifyListeners();
    }
  }

  CreditCard getCreditCardByID(String cardID) {
    for (var i = 0; i < this._creditCards.length; i++) {
      if (this._creditCards[i].id == cardID) {
        return this._creditCards[i];
      }
    }
    return null;
  }

  void removeCreditCardByID(String cardID) {
    if (cardID != null) {
      // remove card from client's list of cards
      this._creditCards.removeWhere((card) => card.id == cardID);
      // if removed card is the default payment method
      if (this._defaultPaymentMethod.type == PaymentMethodType.credit_card &&
          this._defaultPaymentMethod.creditCardID == cardID) {
        // set cash as default
        this._defaultPaymentMethod = ClientPaymentMethod(
            type: PaymentMethodType.cash, creditCardID: null);
      }
      notifyListeners();
    }
  }

  Future<void> downloadData(
    FirebaseModel firebase, {
    bool notify = true,
  }) async {
    // download user image file
    firebase.storage
        .getUserProfileImage(uid: firebase.auth.currentUser.uid)
        .then((value) => this.setProfileImage(value, notify: false));

    ClientInterface client = await firebase.database.getClientData(firebase);
    this.fromClientInterface(client, notify: notify);
  }

  Future<Position> getPosition({bool notify = true}) async {
    Position userPos;
    try {
      userPos = await determineUserPosition();
    } catch (_) {
      userPos = null;
    }
    _position = userPos;
    if (notify) {
      notifyListeners();
    }

    return _position;
  }

  // cancel position subscription if it exists
  void cancelPositionChangeSubscription() {
    if (_positionSubscription != null) {
      _positionSubscription.cancel();
    }
  }

  // updates user geocoding whenever they move at least 50 meters
  void updateGeocodingOnPositionChange() {
    try {
      Stream<Position> userPositionStream = Geolocator.getPositionStream(
        desiredAccuracy: LocationAccuracy.best,
        distanceFilter: 50,
      );
      // cancel previous subscription if it exists
      cancelPositionChangeSubscription();
      // subscribe to changes in position, updating position and gocoding on changes
      _positionSubscription = userPositionStream.listen((position) async {
        _position = position;
        await getGeocoding(position, notify: false);
        notifyListeners();
      });
    } catch (_) {}
  }

  // getGeocoding updates _geocoding. On failure, _geocoding is set to null.
  Future<void> getGeocoding(Position pos, {bool notify = true}) async {
    if (pos == null) {
      // don't update geocoding position is null
      return;
    }

    // get user geocoding
    GeocodingResponse geocoding;
    geocoding = await Geocoding().searchByPosition(pos);
    GeocodingResult geocodingResult;
    if (geocoding != null &&
        geocoding.results != null &&
        geocoding.results.length > 0) {
      geocodingResult = geocoding.results[0];
    }
    // set user position
    _geocoding = geocodingResult;
    if (notify) {
      notifyListeners();
    }
  }

  // getPaymentMethodSvgPath returns defaultPaymentMethod's svg path
  String getPaymentMethodSvgPath(BuildContext context) {
    if (_defaultPaymentMethod.type == PaymentMethodType.cash) {
      return "images/money.svg";
    }

    CreditCard creditCard;
    _creditCards.forEach((cc) {
      if (cc.id == _defaultPaymentMethod.creditCardID) {
        creditCard = cc;
      }
    });
    if (creditCard != null) {
      return "images/" + creditCard.brand.getString() + ".svg";
    }
    // if we don't find a credit card locally, there's been a mismatch
    // betwen local and remote state. Fix this by resetting payment method
    // to cash.
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    this.setDefaultPaymentMethod(
      ClientPaymentMethod(type: PaymentMethodType.cash),
      notify: false,
    );
    firebase.functions.setDefaultPaymentMethod();
    return "images/money.svg";
  }

  String getPaymentMethodDescription(BuildContext context) {
    if (_defaultPaymentMethod.type == PaymentMethodType.cash) {
      return "Dinheiro";
    }

    CreditCard creditCard;
    _creditCards.forEach((cc) {
      if (cc.id == _defaultPaymentMethod.creditCardID) {
        creditCard = cc;
      }
    });
    if (creditCard != null) {
      return "•••• " + creditCard.lastDigits;
    }
    // if we don't find a credit card locally, there's been a mismatch
    // betwen local and remote state. Fix this by resetting payment method
    // to cash.
    FirebaseModel firebase = Provider.of<FirebaseModel>(context, listen: false);
    this.setDefaultPaymentMethod(
      ClientPaymentMethod(type: PaymentMethodType.cash),
      notify: false,
    );
    firebase.functions.setDefaultPaymentMethod();

    return "Dinheiro";
  }
}
