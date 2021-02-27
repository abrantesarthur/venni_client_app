import 'package:flutter_test/flutter_test.dart';
import 'package:rider_frontend/utils/utils.dart';

void main() {
  group("phoneNumberIsValid", () {
    test("return true for valid number", () {
      String validNumber = "(38) 99860-1275";
      expect(phoneNumberIsValid(validNumber), true);
    });

    test("return false for invalid number", () {
      String validNumber = "(38) 998601275";
      expect(phoneNumberIsValid(validNumber), false);
    });

    test("return false for empty number", () {
      String validNumber = "";
      expect(phoneNumberIsValid(validNumber), false);
    });
  });
}
