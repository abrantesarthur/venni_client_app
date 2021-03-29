// phoneNumberIsValid returns true if phone has format (##) ##### ####
// TODO: test
bool phoneNumberIsValid(String phoneNumber) {
  if (phoneNumber == null) {
    return false;
  }
  String pattern = r'^\([\d]{2}\) [\d]{5}-[\d]{4}$';
  RegExp regExp = new RegExp(pattern);
  if (regExp.hasMatch(phoneNumber)) {
    return true;
  }
  return false;
}

extension EmailExtension on String {
  bool isValid() {
    return RegExp(
            r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$')
        .hasMatch(this);
  }
}

extension PasswordExtension on String {
  bool containsLetter() {
    return RegExp(r'[a-zA-Z]+').hasMatch(this);
  }

  bool containsDigit() {
    return RegExp(r'\d+').hasMatch(this);
  }
}

extension PhoneNumberExtension on String {
  String withCountryCode() {
    return this
        .replaceRange(3, 5, "")
        .replaceRange(5, 7, "")
        .replaceRange(10, 11, "");
  }

  String withoutCountryCode() {
    return this
        .replaceRange(0, 3, "")
        .replaceRange(0, 0, "(")
        .replaceRange(3, 3, ") ")
        .replaceRange(10, 10, "-");
  }
}
