import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(locale: 'en', symbol: 'RM ', decimalDigits: 2);
final _currencyCompact = NumberFormat.currency(locale: 'en', symbol: 'RM ', decimalDigits: 0);

/// Formats an amount in sen (1/100 RM). Whole amounts drop the decimals.
String formatMoney(int cents, {bool forceDecimals = false}) {
  final value = cents / 100;
  if (!forceDecimals && cents % 100 == 0) return _currencyCompact.format(value);
  return _currency.format(value);
}

String formatDate(DateTime date) => DateFormat('EEE, d MMM yyyy').format(date);
String formatShortDate(DateTime date) => DateFormat('d MMM yyyy').format(date);

/// API dates are plain `YYYY-MM-DD` strings.
String toApiDate(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
DateTime fromApiDate(String value) => DateTime.parse(value);
