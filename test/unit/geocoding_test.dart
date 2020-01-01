import 'package:flutter_test/flutter_test.dart';
import 'package:rider_frontend/vendors/geocoding.dart';

void main() {
  group("GeocodingResult", () {
    test("fromJson with null json", () {
      GeocodingResult gr = GeocodingResult.fromJson(null);
      expect(gr, isNull);
    });

    test("fromJson with empty json", () {
      GeocodingResult gr = GeocodingResult.fromJson({});
      expect(gr.addressComponents, isNull);
      expect(gr.formattedAddress, isNull);
      expect(gr.latitude, isNull);
      expect(gr.longitude, isNull);
      expect(gr.placeID, isNull);
    });

    test("fromJson works correctly", () {
      Object json = {
        "address_components": [
          {
            "types": ["street_number"],
            "long_name": "168",
            "short_name": "168",
          },
          {
            "types": ["route"],
            "long_name": "Rua Floriano Peixoto",
            "short_name": "Rua Floriano Peixoto",
          },
        ],
        "formatted_address": "Rua Floriano Peixoto, 151. Paracatu - MG",
        "geometry": {
          "location": {
            "lat": 90.0,
            "lng": 180.0,
          }
        },
        "place_id": "arandomplaceid"
      };

      GeocodingResult gr = GeocodingResult.fromJson(json);
      expect(
        gr.addressComponents.addressComponents.length,
        equals(2),
      );
      expect(
        gr.addressComponents.addressComponents.first.longName,
        equals("168"),
      );
      expect(
        gr.addressComponents.addressComponents[1].longName,
        equals("Rua Floriano Peixoto"),
      );
      expect(
        gr.addressComponents.addressComponents[1].types.length,
        equals(1),
      );
      expect(
        gr.addressComponents.addressComponents[1].types.first,
        equals("route"),
      );
      expect(
        gr.formattedAddress,
        equals("Rua Floriano Peixoto, 151. Paracatu - MG"),
      );
      expect(gr.latitude, equals(90.0));
      expect(gr.longitude, equals(180.0));
      expect(gr.placeID, equals("arandomplaceid"));
    });
  });

  group("AddrComponent", () {
    test("fromJson with null json", () {
      AddrComponent gr = AddrComponent.fromJson(null);
      expect(gr, isNull);
    });

    test("fromJson with empty json", () {
      AddrComponent ac = AddrComponent.fromJson({});
      expect(ac.longName, isNull);
      expect(ac.shortName, isNull);
      expect(ac.types, isNull);
    });

    test("fromJson works correctly", () {
      Object json = {
        "types": ["street_number"],
        "long_name": "168",
        "short_name": "168",
      };

      AddrComponent ac = AddrComponent.fromJson(json);
      expect(ac.longName, equals("168"));
      expect(ac.shortName, equals("168"));
      expect(ac.types.length, equals(1));
      expect(ac.types.first, equals("street_number"));
    });
  });

  group("AddressComponents", () {
    test("buildAddressMainText with all fields", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["route"],
            "long_name": "Rua Presbiteriana",
            "short_name": "Presbiteriana",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["street_number"],
            "long_name": "50",
            "short_name": "50",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["sublocality_level_1"],
            "long_name": "Vila Mariana",
            "short_name": "Vila Mariana",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(acs.buildAddressMainText(),
          equals("Rua Presbiteriana, 50 - Vila Mariana"));
    });

    test("buildAddressMainText without street_number", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["route"],
            "long_name": "Rua Presbiteriana",
            "short_name": "Presbiteriana",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["sublocality_level_1"],
            "long_name": "Vila Mariana",
            "short_name": "Vila Mariana",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(acs.buildAddressMainText(),
          equals("Rua Presbiteriana - Vila Mariana"));
    });

    test("buildAddressMainText without without sublocality", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["route"],
            "long_name": "Rua Presbiteriana",
            "short_name": "Presbiteriana",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["street_number"],
            "long_name": "50",
            "short_name": "50",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(acs.buildAddressMainText(), equals("Rua Presbiteriana, 50"));
    });

    test("buildAddressMainText with only street_number", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["route"],
            "long_name": "Rua Presbiteriana",
            "short_name": "Presbiteriana",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(acs.buildAddressMainText(), equals("Rua Presbiteriana"));
    });

    test("buildAddressMainText with only sublocality", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["sublocality_level_1"],
            "long_name": "Vila Mariana",
            "short_name": "Vila Mariana",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(acs.buildAddressMainText(), equals("Vila Mariana"));
    });

    test("buildAddressSecondaryText with all fields", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_2"],
            "long_name": "Paracatu",
            "short_name": "Paracatu",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_1"],
            "long_name": "Minas Gerais",
            "short_name": "MG",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["country"],
            "long_name": "Brasil",
            "short_name": "BR",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Paracatu - MG. 38600000, Brasil"),
      );
    });

    test("buildAddressSecondaryText without city with country", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_1"],
            "long_name": "Minas Gerais",
            "short_name": "MG",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["country"],
            "long_name": "Brasil",
            "short_name": "BR",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Minas Gerais, Brasil"),
      );
    });
    test("buildAddressSecondaryText withou city without country", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_1"],
            "long_name": "Minas Gerais",
            "short_name": "MG",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Minas Gerais"),
      );
    });

    test("buildAddressSecondaryText without city without state", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["country"],
            "long_name": "Brasil",
            "short_name": "BR",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Brasil"),
      );
    });

    test("buildAddressSecondaryText without state with country", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_2"],
            "long_name": "Paracatu",
            "short_name": "Paracatu",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["country"],
            "long_name": "Brasil",
            "short_name": "BR",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Paracatu, Brasil"),
      );
    });

    test("buildAddressSecondaryText without state without country", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_2"],
            "long_name": "Paracatu",
            "short_name": "Paracatu",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Paracatu"),
      );
    });

    test("buildAddressSecondaryText default", () {
      List<AddrComponent> acList = [
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_2"],
            "long_name": "Paracatu",
            "short_name": "Paracatu",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["administrative_area_level_1"],
            "long_name": "Minas Gerais",
            "short_name": "MG",
          },
        ),
        AddrComponent.fromJson(
          {
            "types": ["postal_code"],
            "long_name": "38600000",
            "short_name": "38600000",
          },
        ),
      ];

      AddressComponents acs = AddressComponents(acList);

      expect(
        acs.buildAddressSecondaryText(),
        equals("Paracatu - MG"),
      );
    });
  });
}
