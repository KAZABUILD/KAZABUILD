import 'package:flutter_riverpod/flutter_riverpod.dart';

// ig euro is better option to dollar
enum Currency { PLN, EUR, TRY }

class CurrencyData {
  final String symbol;
  final double exchangeRate;

  CurrencyData({required this.symbol, required this.exchangeRate});
}

//we will use api later for real exchange rate
final Map<Currency, CurrencyData> currencyDetails = {
  Currency.PLN: CurrencyData(symbol: 'zł', exchangeRate: 1.0),
  Currency.EUR: CurrencyData(symbol: '€', exchangeRate: 1.0),
  Currency.TRY: CurrencyData(symbol: '₺', exchangeRate: 1.0),
};

//default currency is pln
class CurrencyNotifier extends StateNotifier<Currency> {
  CurrencyNotifier() : super(Currency.PLN);

  void setCurrency(Currency newCurrency) {
    state = newCurrency;
  }
}

final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((
  ref,
) {
  return CurrencyNotifier();
});
