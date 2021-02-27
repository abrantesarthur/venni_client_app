// phoneNumberIsValid returns true if phone has format (##) ##### ####
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
