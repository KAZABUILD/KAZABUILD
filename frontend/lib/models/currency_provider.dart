/// This file defines the state management for currency selection and conversion
/// within the application, using the Riverpod state management library.
///
/// It includes:
/// - [Currency]: An enum representing the available currencies.
/// - [CurrencyData]: A data class holding the symbol and exchange rate for a currency.
/// - [currencyDetails]: A map containing the data for each currency.
/// - [CurrencyNotifier]: A `StateNotifier` to manage the currently selected currency.
/// - [currencyProvider]: A global `StateNotifierProvider` to make the currency
///   state accessible throughout the app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An enumeration of the currencies supported by the application.
// The original comment "ig euro is better option to dollar" suggests a future preference.
enum Currency { PLN, EUR, TRY }

/// A data class that holds the details for a specific currency.
class CurrencyData {
  /// The currency symbol (e.g., 'zł', '€', '₺').
  final String symbol;

  /// The exchange rate relative to a base currency (e.g., USD).
  final double exchangeRate;

  /// Creates an instance of [CurrencyData].
  CurrencyData({required this.symbol, required this.exchangeRate});
}

/// A map that stores the details for each supported currency.
///
// TODO: Replace these hardcoded exchange rates with real-time data fetched from a currency conversion API.
final Map<Currency, CurrencyData> currencyDetails = {
  Currency.PLN: CurrencyData(symbol: 'zł', exchangeRate: 1.0),
  Currency.EUR: CurrencyData(symbol: '€', exchangeRate: 1.0),
  Currency.TRY: CurrencyData(symbol: '₺', exchangeRate: 1.0),
};

/// Manages the state of the currently selected currency.
///
/// This notifier holds the current [Currency] enum value and provides a method
/// to update it.
class CurrencyNotifier extends StateNotifier<Currency> {
  /// Initializes the notifier with a default currency.
  /// The default currency is set to Polish Złoty (PLN).
  CurrencyNotifier() : super(Currency.PLN);

  /// Updates the state with a new currency, which will notify all listeners.
  void setCurrency(Currency newCurrency) {
    state = newCurrency;
  }
}

/// A global provider that exposes the [CurrencyNotifier] to the entire app.
///
/// Widgets can use this provider to watch the currently selected currency
/// and to get access to the notifier to change the currency.
final currencyProvider = StateNotifierProvider<CurrencyNotifier, Currency>((
  ref,
) {
  return CurrencyNotifier();
});
