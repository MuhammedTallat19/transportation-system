import 'package:intl/intl.dart';

/// Formats integer minor units (piastres/cents) for display only — NFR-18.
class CurrencyFormatter {
  CurrencyFormatter._();

  static String format(int amountCents,
      {String currency = 'EGP', String? locale}) {
    final major = amountCents / 100;
    final symbol = currency == 'EGP' ? 'EGP' : currency;
    final formatter = NumberFormat.currency(
      locale: locale ?? 'en_EG',
      symbol: symbol,
      decimalDigits: 2,
    );
    return formatter.format(major);
  }
}
