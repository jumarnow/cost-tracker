import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

final NumberFormat _rupiahFmt = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp',
  decimalDigits: 0, // Typical Rupiah display has no decimals
);

final NumberFormat _rupiahPlain = NumberFormat.decimalPattern('id_ID');

String formatRupiah(num amount, {bool includeSymbol = true}) {
  if (includeSymbol) return _rupiahFmt.format(amount);
  return _rupiahPlain.format(amount);
}

double parseRupiahToDouble(String input) {
  // Remove any non-digit characters (dots, spaces, Rp, commas)
  final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
  if (digits.isEmpty) return 0;
  return double.parse(digits);
}

class RupiahThousandsFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (raw.isEmpty) {
      return const TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }
    final formatted = _rupiahPlain.format(int.parse(raw));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
