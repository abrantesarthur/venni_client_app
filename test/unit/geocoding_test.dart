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
}
