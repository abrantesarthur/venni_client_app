import 'package:flutter/material.dart';
import 'package:rider_frontend/vendors/firebaseFunctions/interfaces.dart';

enum DeleteReason {
  badTripExperience,
  badAppExperience,
  hasAnotherAccount,
  doesntUseService,
  another,
}

enum PaymentMethodType {
  credit_card,
  cash,
}

extension PaymentMethodTypeExtension on PaymentMethodType {
  static PaymentMethodType fromString(String s) {
    switch (s) {
      case "credit_card":
        return PaymentMethodType.credit_card;
      case "cash":
        return PaymentMethodType.cash;
      default:
        return null;
    }
  }
}

class ClientPaymentMethod {
  final PaymentMethodType type;
  final String creditCardID;

  ClientPaymentMethod({@required this.type, this.creditCardID});

  factory ClientPaymentMethod.fromJson(Map json) {
    return json != null
        ? ClientPaymentMethod(
            type: PaymentMethodTypeExtension.fromString(json["default"]),
            creditCardID: json["card_id"],
          )
        : null;
  }
}

enum CardBrand {
  mastercard,
  visa,
  elo,
  amex,
  discover,
  aura,
  jcb,
  hipercard,
  diners,
}

extension CardBrandExtension on CardBrand {
  static CardBrand fromString(String brand) {
    switch (brand) {
      case "mastercard":
        return CardBrand.mastercard;
      case "visa":
        return CardBrand.visa;
      case "elo":
        return CardBrand.elo;
      case "amex":
        return CardBrand.amex;
      case "discover":
        return CardBrand.discover;
      case "aura":
        return CardBrand.aura;
      case "jcb":
        return CardBrand.jcb;
      case "hipercard":
        return CardBrand.hipercard;
      case "diners":
        return CardBrand.diners;
      default:
        return null;
    }
  }

  String getString() {
    if (this != null) {
      return this.toString().substring(10);
    }
    return "";
  }
}

class CreditCard {
  final String id;
  final String holderName;
  final String firstDigits;
  final String lastDigits;
  final String expirationDate;
  final CardBrand brand;

  CreditCard({
    @required this.id,
    @required this.holderName,
    @required this.firstDigits,
    @required this.lastDigits,
    @required this.expirationDate,
    @required this.brand,
  });

  factory CreditCard.fromJson(Map json) {
    return json != null
        ? CreditCard(
            id: json["id"],
            holderName: json["holder_name"],
            firstDigits: json["first_digits"],
            lastDigits: json["last_digits"],
            expirationDate: json["expiration_date"],
            brand: CardBrandExtension.fromString(json["brand"]),
          )
        : null;
  }
}

class ClientInterface {
  final String id;
  final String rating;
  final ClientPaymentMethod defaultPaymentMethod;
  final List<CreditCard> creditCards;
  final String unpaidTripID;
  Trip unpaidTrip;
  ClientInterface({
    @required this.id,
    @required this.rating,
    @required this.defaultPaymentMethod,
    @required this.creditCards,
    @required this.unpaidTripID,
  });

  void setUnpaidTrip(Trip unpaidTrip) {
    this.unpaidTrip = unpaidTrip;
  }

  factory ClientInterface.fromJson(Map json) {
    if (json == null) {
      return null;
    }

    List<CreditCard> creditCards = [];
    if (json["cards"] != null) {
      json["cards"].keys.forEach((cardID) {
        CreditCard card = CreditCard.fromJson(json["cards"][cardID]);
        creditCards.add(card);
      });
    }

    return ClientInterface(
      id: json["uid"],
      rating: json["rating"],
      defaultPaymentMethod:
          ClientPaymentMethod.fromJson(json["payment_method"]),
      creditCards: creditCards,
      unpaidTripID: json["unpaid_past_trip_id"],
    );
  }
}
