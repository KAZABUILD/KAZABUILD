import 'package:frontend/models/component_models.dart';

/// Defines which component types need to be checked for compatibility with each other.
/// The map is bidirectional - if A needs to check B, then B also needs to check A.
class CompatibilityRules {
  /// Map of component type to the list of types it must be compatible with.
  static const Map<ComponentType, Set<ComponentType>> rules = {
    ComponentType.cpu: {ComponentType.motherboard, ComponentType.cooler},
    ComponentType.motherboard: {
      ComponentType.cpu,
      ComponentType.cooler,
      ComponentType.ram,
      ComponentType.storage,
      ComponentType.gpu,
      ComponentType.psu,
      ComponentType.pcCase,
    },
    ComponentType.cooler: {
      ComponentType.cpu,
      ComponentType.motherboard,
      ComponentType.pcCase,
    },
    ComponentType.ram: {ComponentType.motherboard},
    ComponentType.storage: {ComponentType.motherboard},
    ComponentType.gpu: {ComponentType.motherboard, ComponentType.pcCase},
    ComponentType.psu: {ComponentType.motherboard},
    ComponentType.pcCase: {
      ComponentType.motherboard,
      ComponentType.gpu,
      ComponentType.cooler,
      ComponentType.caseFan,
    },
    ComponentType.caseFan: {ComponentType.pcCase},
    ComponentType.monitor: {
      // No compatibility constraints
    },
  };

  /// Returns the set of component types that the given type must be compatible with.
  static Set<ComponentType> getRequiredCompatibilities(ComponentType type) {
    return rules[type] ?? {};
  }

  /// Checks if two component types need to be compatible with each other.
  static bool needsCompatibilityCheck(
    ComponentType type1,
    ComponentType type2,
  ) {
    final requirements = rules[type1];
    return requirements != null && requirements.contains(type2);
  }

  /// Given a component type and a list of selected components,
  /// returns only the components that this type needs to be compatible with.
  static List<BaseComponent> getRelevantComponents(
    ComponentType typeToCheck,
    List<BaseComponent> selectedComponents,
  ) {
    final requiredTypes = getRequiredCompatibilities(typeToCheck);
    return selectedComponents
        .where((c) => requiredTypes.contains(c.type))
        .toList();
  }

  /// Given a component type, returns the IDs of selected components
  /// that this type needs to be compatible with.
  static List<String> getRelevantComponentIds(
    ComponentType typeToCheck,
    List<BaseComponent> selectedComponents,
  ) {
    return getRelevantComponents(
      typeToCheck,
      selectedComponents,
    ).map((c) => c.id).toList();
  }
}
