/// Defines the core data models for the dynamic filtering system.
///
/// These models describe the structure of available filters (definitions) and
/// the user's current selections (active filters).
library;

import 'package:flutter/foundation.dart';

/// The type of input widget to render for a filter.
enum FilterInputType {
  /// A text input field.
  text,

  /// A dropdown or multi-select dropdown.
  select,

  /// A range slider for numeric values (min-max).
  range,

  /// A boolean switch or chip (Any/Yes/No).
  boolean,
}

/// Defines the metadata for a single filterable field.
@immutable
class FilterDefinition {
  /// The key used in the JSON request to the backend (e.g., "Manufacturer", "MinAirflow").
  final String key;

  /// The human-readable label to display in the UI (e.g., "Manufacturer", "Min Airflow").
  final String label;

  /// The type of input widget to use for this filter.
  final FilterInputType type;

  /// A list of available options for `select` type filters.
  /// Can be simple strings or objects.
  final List<dynamic>? options;

  /// The minimum value for `range` type filters.
  final double? min;

  /// The maximum value for `range` type filters.
  final double? max;

  /// The unit of measurement for `range` type filters (e.g., "mm", "dBA", "W").
  final String? unit;

  /// A function to format the display value (e.g., adding units).
  final String Function(dynamic)? formatValue;

  const FilterDefinition({
    required this.key,
    required this.label,
    required this.type,
    this.options,
    this.min,
    this.max,
    this.unit,
    this.formatValue,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FilterDefinition &&
        other.key == key &&
        other.label == label &&
        other.type == type &&
        listEquals(other.options, options) &&
        other.min == min &&
        other.max == max &&
        other.unit == unit;
  }

  @override
  int get hashCode {
    return Object.hash(
      key,
      label,
      type,
      options != null ? Object.hashAll(options!) : null,
      min,
      max,
      unit,
    );
  }
}

/// Represents the user's current selection for a specific filter.
@immutable
class ActiveFilter {
  /// The key of the filter definition this selection corresponds to.
  final String key;

  /// The selected value(s).
  /// - For `text`: A `String`.
  /// - For `select`: A `List<String>` (or other types) for multi-select, or a single value.
  /// - For `range`: A `RangeValues` object (start, end).
  /// - For `boolean`: A `bool` (true/false).
  final dynamic value;

  const ActiveFilter({
    required this.key,
    required this.value,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActiveFilter && other.key == key && other.value == value;
  }

  @override
  int get hashCode => Object.hash(key, value);
}

