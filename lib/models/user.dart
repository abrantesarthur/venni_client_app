import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import 'package:rider_frontend/models/firebase.dart';
import 'package:rider_frontend/vendors/firebaseStorage.dart';
import 'package:rider_frontend/vendors/firebaseDatabase.dart';
import 'package:rider_frontend/vendors/firebaseFunctions.dart';
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
  ClientPaymentMethod _defaultPaymentMethod;
  List<CreditCard> _creditCards;

  GeocodingResult get geocoding => _geocoding;
  ProfileImage get profileImage => _profileImage;
  String get rating => _rating;
  ClientPaymentMethod get defaultPaymentMethod => _defaultPaymentMethod;
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

  void setDefaultPaymentMethod(ClientPaymentMethod cpm, {bool notify = true}) {
    _defaultPaymentMethod = cpm;
    if (notify) {
      notifyListeners();
    }
  }

  void fromClientInterface(ClientInterface c) {
    if (c != null) {
      _rating = c.rating;
      _defaultPaymentMethod = c.defaultPaymentMethod;
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
