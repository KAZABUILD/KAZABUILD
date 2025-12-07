import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'filter_models.dart';
import 'component_models.dart';
import 'component_provider.dart';

final availableFiltersProvider = FutureProvider.family<List<FilterDefinition>, ComponentType>((ref, type) async {
  // Get the template schema
  final templates = _componentFilterSchemas[type] ?? [];
  
  // Fetch all components for this type to extract unique values
  // This ensures filters only show options that actually exist in the database
  final service = ref.watch(componentServiceProvider);
  final components = await service.getComponents(type);
  
  return templates.map((def) {
    // Only populate options for select/dropdown filters
    if (def.type == FilterInputType.select) {
      final options = _extractUniqueValues(components, def.key);
      
      // Sort options alphabetically
      options.sort((a, b) => a.toString().compareTo(b.toString()));
      
      return FilterDefinition(
        key: def.key,
        label: def.label,
        type: def.type,
        options: options,
        min: def.min,
        max: def.max,
        unit: def.unit,
        formatValue: def.formatValue,
      );
    }
    return def;
  }).toList();
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

// Helper function to format MB values to GB
String _formatMbToGb(dynamic value) {
  if (value is num) {
    return (value / 1024).toStringAsFixed(0);
  }
  return value.toString();
}

List<dynamic> _extractUniqueValues(List<BaseComponent> components, String key) {
  final values = <dynamic>{};
  
  for (final c in components) {
    final val = _getPropertyValue(c, key);
    if (val != null) {
      if (val is List) {
        values.addAll(val);
      } else {
        values.add(val);
      }
    }
  }
  
  return values.toList();
}

dynamic _getPropertyValue(BaseComponent c, String key) {
  // Common properties
  switch (key) {
    case 'Manufacturer':
      return c.manufacturer;
  }

  // Component-specific properties
  if (c is GPUComponent) {
    switch (key) {
      case 'Chipset': return c.chipset;
      case 'VideoMemoryType': return c.videoMemoryType;
      case 'FrameSync': return c.frameSync;
      case 'CoolingType': return c.coolingType;
    }
  } else if (c is CPUComponent) {
    switch (key) {
      case 'Series': return c.series;
      case 'SocketType': return c.socketType;
      case 'Microarchitecture': return c.microarchitecture;
      case 'CoreFamily': return c.coreFamily;
      case 'Lithography': return c.lithography;
      case 'MemoryType': return c.memoryType;
      case 'PackagingType': return c.packagingType;
    }
  } else if (c is MotherboardComponent) {
    switch (key) {
      case 'SocketType': return c.socketType;
      case 'FormFactor': return c.formFactor;
      case 'ChipsetType': return c.chipsetType;
      case 'RAMType': return c.ramType;
      case 'AudioChipset': return c.audioChipset;
      case 'WirelessNetworkingStandard': return c.wirelessNetworkingStandard;
      case 'MainPowerType': return c.mainPowerType;
    }
  } else if (c is MemoryComponent) {
    switch (key) {
      case 'RAMType': return c.ramType;
      case 'FormFactor': return c.formFactor;
      case 'Timings': return c.timings;
      case 'ECC': return c.ecc;
      case 'RegisteredType': return c.registeredType;
    }
  } else if (c is StorageComponent) {
    switch (key) {
      case 'Series': return c.series;
      case 'Type': return c.driveType; // Mapped 'Type' to 'DriveType'
      case 'FormFactor': return c.formFactor;
      case 'Interface': return c.interface;
    }
  } else if (c is PowerSupplyComponent) {
    switch (key) {
      case 'FormFactor': return c.formFactor;
      case 'EfficiencyRating': return c.efficiencyRating;
      case 'ModularityType': return c.modularityType;
    }
  } else if (c is CaseComponent) {
    switch (key) {
      case 'FormFactor': return c.formFactor;
      case 'SidePanelType': return c.sidePanelType;
    }
  } else if (c is CaseFanComponent) {
    switch (key) {
      case 'LEDType': return c.ledType;
      case 'ConnectorType': return c.connectorType;
      case 'ControllerType': return c.controllerType;
      case 'FlowDirection': return c.flowDirection;
    }
  } else if (c is MonitorComponent) {
    switch (key) {
      case 'PanelType': return c.panelType;
      case 'AdaptiveSyncType': return c.adaptiveSyncType;
      case 'HighDynamicRangeType': return c.highDynamicRangeType;
    }
  }
  
  return null;
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
