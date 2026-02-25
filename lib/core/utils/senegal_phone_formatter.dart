import 'package:flutter/services.dart';

class SenegalPhoneFormatter extends TextInputFormatter {
  static const List<String> validPrefixes = ['77', '76', '75', '78', '70'];

  /// Nettoie un numéro (supprime +, espaces, etc.)
  static String normalize(String value) {
    String digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('221')) {
      digits = digits.substring(3);
    }
    return digits;
  }

  /// Valide un numéro sénégalais formaté par ce formatter
  static bool isValid(String? value) {
    if (value == null || value.trim().isEmpty) return false;

    final digits = normalize(value);

    if (digits.length != 9) return false;

    final prefix = digits.substring(0, 2);
    return validPrefixes.contains(prefix);
  }

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String digits = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (digits.startsWith('221')) {
      digits = digits.substring(3);
    }

    if (digits.length > 9) {
      digits = digits.substring(0, 9);
    }

    if (digits.length >= 2 &&
        !validPrefixes.contains(digits.substring(0, 2))) {
      return oldValue;
    }

    String formatted = '+221';

    if (digits.isNotEmpty) {
      formatted += ' ';
      for (int i = 0; i < digits.length; i++) {
        if (i == 2 || i == 5 || i == 7) formatted += ' ';
        formatted += digits[i];
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
