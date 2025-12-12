import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'filter_models.dart';
import 'component_models.dart';
import 'component_provider.dart';

final availableFiltersProvider =
    FutureProvider.family<List<FilterDefinition>, ComponentType>(
        (ref, type) async {
  final service = ref.watch(componentServiceProvider);
  try {
    final backendFields = await service.getComponentFiltersRaw(type);
    final filters = _mapBackendFieldsToDefinitions(backendFields);
    if (filters.isNotEmpty) {
      return filters;
    }
  } catch (e) {
    // Fall back to legacy static filters if backend parsing fails
  }

  // Fallback to legacy static definitions to keep UI usable
  return _componentFilterSchemas[type] ?? [];
});

final activeFiltersProvider = StateNotifierProvider.autoDispose.family<ActiveFiltersNotifier, Map<String, dynamic>, ComponentType>((ref, type) {
  return ActiveFiltersNotifier();
});

class ActiveFiltersNotifier extends StateNotifier<Map<String, dynamic>> {
  ActiveFiltersNotifier() : super({});

  void setFilter(String key, dynamic value) {
    if (value == null ||
        (value is String && value.isEmpty) ||
        (value is List && value.isEmpty)) {
      final newState = Map<String, dynamic>.from(state);
      newState.remove(key);
      state = newState;
    } else {
      state = {...state, key: value};
    }
  }

  void clearAll() {
    state = {};
  }
}

List<FilterDefinition> _mapBackendFieldsToDefinitions(
  Map<String, dynamic> fields,
) {
  final List<FilterDefinition> definitions = [];

  fields.forEach((rawKey, rawValue) {
    if (rawValue is! Map) return;
    final field = Map<String, dynamic>.from(rawValue);

    final typeValue = field['type'] ?? field['Type'];
    final typeString = typeValue?.toString().toLowerCase();

    FilterInputType? inputType;
    if (typeValue is int) {
      switch (typeValue) {
        case 0:
          inputType = FilterInputType.select;
          break;
        case 1:
          inputType = FilterInputType.range;
          break;
        case 2:
          inputType = FilterInputType.range; // Date mapped to year range
          break;
        case 3:
          inputType = FilterInputType.boolean;
          break;
      }
    } else if (typeString != null) {
      if (typeString.contains('string')) inputType = FilterInputType.select;
      if (typeString.contains('numeric')) inputType = FilterInputType.range;
      if (typeString.contains('date')) inputType = FilterInputType.range;
      if (typeString.contains('bool')) inputType = FilterInputType.boolean;
    }
    if (inputType == null) return;

    List<dynamic>? options;
    double? min;
    double? max;
    String Function(dynamic)? formatValue;
    String? unit;

    if (inputType == FilterInputType.select) {
      final rawOptions =
          field['stringValues'] ?? field['StringValues'] ?? <dynamic>[];
      if (rawOptions is List) {
        options = rawOptions.where((e) => e != null).map((e) => e.toString()).toSet().toList();
      }
    } else if (inputType == FilterInputType.range) {
      if ((field['minNumeric'] ?? field['MinNumeric']) != null &&
          (field['maxNumeric'] ?? field['MaxNumeric']) != null) {
        min = (field['minNumeric'] ?? field['MinNumeric']).toDouble();
        max = (field['maxNumeric'] ?? field['MaxNumeric']).toDouble();
      } else if ((field['minDate'] ?? field['MinDate']) != null &&
          (field['maxDate'] ?? field['MaxDate']) != null) {
        try {
          final minDate = DateTime.parse(
              (field['minDate'] ?? field['MinDate']).toString());
          final maxDate = DateTime.parse(
              (field['maxDate'] ?? field['MaxDate']).toString());
          min = minDate.year.toDouble();
          max = maxDate.year.toDouble();
          unit = 'Year';
          formatValue = (val) => val.toStringAsFixed(0);
        } catch (_) {}
      }
    }

    final label = _humanizeKey(rawKey);

    definitions.add(
      FilterDefinition(
        key: rawKey,
        label: label,
        type: inputType,
        options: options,
        min: min,
        max: max,
        unit: unit,
        formatValue: formatValue,
      ),
    );
  });

    // Keep a stable order by label for UX
    definitions.sort((a, b) => a.label.compareTo(b.label));

    // Add Compatibility filter
    definitions.insert(
      0,
      const FilterDefinition(
        key: 'Compatibility',
        label: 'Compatibility',
        type: FilterInputType.boolean,
      ),
    );

    return definitions;
  }

String _humanizeKey(String key) {
  final withSpaces =
      key.replaceAllMapped(RegExp(r'(?<=[a-z0-9])(?=[A-Z])'), (m) => ' ');
  return withSpaces.replaceAll('.', ' ').trim();
}

// Helper function to format MB values to GB
String _formatMbToGb(dynamic value) {
  if (value is num) {
    return (value / 1024).toStringAsFixed(0);
  }
  return value.toString();
}

final Map<ComponentType, List<FilterDefinition>> _componentFilterSchemas = {
  ComponentType.gpu: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'Chipset',
      label: 'Chipset',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'VideoMemoryAmount',
      label: 'VRAM',
      type: FilterInputType.range,
      min: 2048, // 2 GB
      max: 24576, // 24 GB
      unit: 'GB',
      formatValue: _formatMbToGb,
    ),
    const FilterDefinition(
      key: 'Length',
      label: 'Length',
      type: FilterInputType.range,
      min: 150,
      max: 400,
      unit: 'mm',
    ),
  ],
  ComponentType.cpu: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'Series',
      label: 'Series',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'CoreTotal',
      label: 'Core Count',
      type: FilterInputType.range,
      min: 4,
      max: 32,
    ),
  ],
  ComponentType.motherboard: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'SocketType',
      label: 'Socket',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'FormFactor',
      label: 'Form Factor',
      type: FilterInputType.select,
    ),
  ],
  ComponentType.ram: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'RAMType',
      label: 'Memory Type',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'Capacity',
      label: 'Capacity',
      type: FilterInputType.range,
      min: 8192, // 8 GB
      max: 131072, // 128 GB
      unit: 'GB',
      formatValue: _formatMbToGb,
    ),
  ],
  ComponentType.storage: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'Type',
      label: 'Type',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'Capacity',
      label: 'Capacity',
      type: FilterInputType.range,
      min: 250,
      max: 4000,
      unit: 'GB',
    ),
  ],
  ComponentType.psu: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'EfficiencyRating',
      label: 'Efficiency',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'PowerOutput',
      label: 'Wattage',
      type: FilterInputType.range,
      min: 450,
      max: 1600,
      unit: 'W',
    ),
  ],
  ComponentType.pcCase: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'FormFactor',
      label: 'Form Factor',
      type: FilterInputType.select,
    ),
  ],
  ComponentType.cooler: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'RadiatorSize',
      label: 'Radiator Size',
      type: FilterInputType.select,
    ),
  ],
  ComponentType.caseFan: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'Size',
      label: 'Size',
      type: FilterInputType.range,
      min: 80,
      max: 200,
      unit: 'mm',
    ),
  ],
  ComponentType.monitor: [
    const FilterDefinition(
      key: 'Manufacturer',
      label: 'Manufacturer',
      type: FilterInputType.select,
    ),
    const FilterDefinition(
      key: 'ScreenSize',
      label: 'Screen Size',
      type: FilterInputType.range,
      min: 21,
      max: 49,
      unit: 'inch',
    ),
    const FilterDefinition(
      key: 'MaxRefreshRate',
      label: 'Refresh Rate',
      type: FilterInputType.range,
      min: 60,
      max: 360,
      unit: 'Hz',
    ),
  ],
};
