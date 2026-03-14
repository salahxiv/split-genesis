const currencySymbols = <String, String>{
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'JPY': '¥',
  'CAD': 'CA\$',
  'AUD': 'A\$',
  'CHF': 'CHF',
  'CNY': '¥',
  'INR': '₹',
  'MXN': 'MX\$',
  'BRL': 'R\$',
  'SEK': 'kr',
  'NOK': 'kr',
  'DKK': 'kr',
  'PLN': 'zł',
  'CZK': 'Kč',
  'HUF': 'Ft',
  'RON': 'lei',
  'TRY': '₺',
  'RUB': '₽',
  'KRW': '₩',
  'SGD': 'S\$',
  'HKD': 'HK\$',
  'NZD': 'NZ\$',
  'ZAR': 'R',
};

String formatCurrency(double amount, [String currency = 'USD']) {
  final symbol = currencySymbols[currency] ?? currency;
  if (currency == 'JPY' || currency == 'KRW' || currency == 'HUF') {
    return '$symbol${amount.round()}';
  }
  return '$symbol${amount.toStringAsFixed(2)}';
}

String getCurrencySymbol(String currency) {
  return currencySymbols[currency] ?? currency;
}

/// Currency converter using EUR as the base currency.
/// TODO: live rates — replace static rates with an API call (e.g. ECB, Fixer.io)
class CurrencyConverter {
  CurrencyConverter._();

  /// Exchange rates relative to EUR (1 EUR = X currency).
  static const Map<String, double> _ratesFromEur = {
    'EUR': 1.0,
    'USD': 1.08,
    'GBP': 0.86,
    'JPY': 161.5,
    'CAD': 1.47,
    'AUD': 1.66,
    'CHF': 0.97,
    'CNY': 7.83,
    'INR': 90.1,
    'MXN': 18.4,
    'BRL': 5.35,
    'SEK': 11.3,
    'NOK': 11.5,
    'DKK': 7.46,
    'PLN': 4.27,
    'CZK': 25.3,
    'HUF': 395.0,
    'RON': 4.97,
    'TRY': 35.0,
    'RUB': 98.0,
    'KRW': 1450.0,
    'SGD': 1.46,
    'HKD': 8.45,
    'NZD': 1.80,
    'ZAR': 20.2,
  };

  /// Convert [amountCents] from [fromCurrency] to EUR cents.
  /// Returns amountCents unchanged if the currency is unknown (fail-open).
  static int toEurCents(int amountCents, String fromCurrency) {
    if (fromCurrency == 'EUR') return amountCents;
    final rate = _ratesFromEur[fromCurrency];
    if (rate == null || rate == 0) return amountCents; // unknown currency — pass through
    return (amountCents / rate).round();
  }

  /// Convert [eurCents] from EUR to [toCurrency] cents.
  static int fromEurCents(int eurCents, String toCurrency) {
    if (toCurrency == 'EUR') return eurCents;
    final rate = _ratesFromEur[toCurrency];
    if (rate == null) return eurCents; // unknown currency — pass through
    return (eurCents * rate).round();
  }

  /// Convert [amountCents] from [fromCurrency] to [toCurrency].
  static int convert(int amountCents, String fromCurrency, String toCurrency) {
    if (fromCurrency == toCurrency) return amountCents;
    final eurCents = toEurCents(amountCents, fromCurrency);
    return fromEurCents(eurCents, toCurrency);
  }

  /// Whether a currency code is known.
  static bool isSupported(String currency) => _ratesFromEur.containsKey(currency);

  /// Sorted list of supported currency codes.
  static List<String> get supportedCurrencies =>
      _ratesFromEur.keys.toList()..sort();
}
