class NumberRegExpHelper {
  NumberRegExpHelper._();
  static final RegExp signedInt = RegExp(r'^\d{0,9}');
  static final RegExp unsignedInt = RegExp(r'^-?\d{0,9}');
  static final RegExp signedFractional = RegExp(r'^\d{0,6}\.?\d{0,3}');
  static final RegExp unsignedFractional = RegExp(r'^-?\d{0,6}\.?\d{0,3}');

  static RegExp inputRegex(bool allowNegative, bool allowDecimal) {
    if (allowNegative == false) {
      if (allowDecimal) {
        return signedFractional;
      } else {
        return signedInt;
      }
    } else {
      if (allowDecimal) {
        return unsignedFractional;
      } else {
        return unsignedInt;
      }
    }
  }
}
