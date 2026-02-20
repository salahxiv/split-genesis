const currencySymbols = <String, String>{
  'USD': '\$',
  'EUR': '\u20AC',
  'GBP': '\u00A3',
  'JPY': '\u00A5',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CHF': 'CHF',
  'CNY': '\u00A5',
  'INR': '\u20B9',
  'MXN': 'MX\$',
};

String formatCurrency(double amount, [String currency = 'USD']) {
  final symbol = currencySymbols[currency] ?? currency;
  if (currency == 'JPY') {
    return '$symbol${amount.round()}';
  }
  return '$symbol${amount.toStringAsFixed(2)}';
}

String getCurrencySymbol(String currency) {
  return currencySymbols[currency] ?? currency;
}
