/// This file defines the main PC builder interface, the "Build Now" page.
///
/// It allows users to view and manage a list of PC component slots. Users can
/// add components by navigating to the `PartPickerPage`, remove them, and see
/// a running total of the price and estimated wattage.
/// The state of the build is managed using Riverpod, with `BuildNotifier` holding
/// the list of selected components. The page is responsive, adapting its layout
/// for mobile and desktop screens.
/// for mobile and desktop screens.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/compatibility_map.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/currency_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/services/cookie_storage_service.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

/// Manages the state of the PC build, which is a list of component slots.
///
/// This notifier handles adding, updating, and removing components from the current build.
/// It holds the central "source of truth" for the user's in-progress PC.
class BuildNotifier extends StateNotifier<List<PcComponent>> {
  final CookieStorageService? _cookieStorage;
  final bool _isUserLoggedIn;

  /// Initializes the build with a default set of empty component slots.
  /// Optionally loads saved build state from cookies if user is logged in.
  BuildNotifier({
    CookieStorageService? cookieStorage,
    bool isUserLoggedIn = false,
  }) : _cookieStorage = cookieStorage,
       _isUserLoggedIn = isUserLoggedIn,
       super(_initialState) {
    // Note: We don't load build state here because it's async.
    // Instead, restoreBuildStateFromCookies() will be called from the UI
    // after the notifier is created and ComponentService is available.
  }

  /// Defines the default template for a new PC build, listing all necessary component types.
  static final List<PcComponent> _initialState = [
    PcComponent(name: 'CPU', type: ComponentType.cpu),
    PcComponent(name: 'Motherboard', type: ComponentType.motherboard),
    PcComponent(name: 'CPU Cooler', type: ComponentType.cooler),
    PcComponent(name: 'Memory (RAM)', type: ComponentType.ram),
    PcComponent(name: 'Storage', type: ComponentType.storage),
    PcComponent(name: 'GPU (Video Card)', type: ComponentType.gpu),
    PcComponent(name: 'Power Supply', type: ComponentType.psu),
    PcComponent(name: 'Case', type: ComponentType.pcCase),
    PcComponent(name: 'Monitor', type: ComponentType.monitor),
  ];

  /// Adds or updates a component in the build.
  ///
  /// It finds the correct component slot by its [ComponentType] and replaces
  /// the `selectedProduct` with the new one. This triggers a state update.
  void addComponent(BaseComponent newProduct) {
    final currentState = List<PcComponent>.from(state);
    final componentIndex = currentState.indexWhere(
      (c) => c.type == newProduct.type,
    );

    if (componentIndex != -1) {
      currentState[componentIndex].selectedProduct = newProduct;
      state = currentState;
      // Save build state to cookies when component is added (fire and forget)
      _saveBuildStateToCookies();
    }
  }

  /// Removes a selected component from a slot, setting it back to null.
  ///
  /// Finds the component slot by its [ComponentType] and clears the `selectedProduct`.
  void removeComponent(ComponentType type) {
    final currentState = List<PcComponent>.from(state);
    final componentIndex = currentState.indexWhere((c) => c.type == type);

    if (componentIndex != -1) {
      currentState[componentIndex].selectedProduct = null;
      state = currentState;
      // Save build state to cookies when component is removed
      _saveBuildStateToCookies();
    }
  }

  /// Resets the build to its initial empty state.
  void clearBuild() {
    state = _initialState
        .map((c) => PcComponent(name: c.name, type: c.type))
        .toList();
    // Clear saved build state from cookies
    _cookieStorage?.clearBuildState();
  }

  /// Prefills the builder with the provided [components], typically sourced from
  /// an existing community build.
  void loadComponentsFromBuild(List<BaseComponent> components) {
    // Clear saved build state from cookies first to prevent old components from being restored
    _cookieStorage?.clearBuildState();
    
    final updatedState = _initialState
        .map((c) => PcComponent(name: c.name, type: c.type))
        .toList();

    for (final component in components) {
      final availableSlotIndex = updatedState.indexWhere(
        (slot) => slot.type == component.type && slot.selectedProduct == null,
      );

      if (availableSlotIndex != -1) {
        updatedState[availableSlotIndex].selectedProduct = component;
        continue;
      }

      final duplicates = updatedState
          .where((slot) => slot.type == component.type)
          .length;
      final displayName = duplicates == 0
          ? _componentDisplayName(component.type)
          : '${_componentDisplayName(component.type)} ${duplicates + 1}';
      updatedState.add(
        PcComponent(
          name: displayName,
          type: component.type,
          selectedProduct: component,
        ),
      );
    }

    state = updatedState;
    // Save to cookies
    _saveBuildStateToCookies();
  }

  /// Prefills the builder with components and fetches their prices.
  /// This is the preferred method when loading from explore/quiz pages.
  Future<void> loadComponentsFromBuildWithPrices(
    List<BaseComponent> components,
    ComponentService componentService,
  ) async {
    if (components.isEmpty) {
      return;
    }

    // Fetch prices for all components
    final componentIds = components
        .map((c) => c.id)
        .where((id) => id.isNotEmpty)
        .toList();
    Map<String, double?> priceMap = {};

    if (componentIds.isNotEmpty) {
      try {
        priceMap = await componentService.getLowestPricesForComponents(
          componentIds,
        );
      } catch (e) {
        debugPrint('Failed to fetch prices for components: $e');
      }
    }

    // Create updated components with prices
    final updatedState = _initialState
        .map((c) => PcComponent(name: c.name, type: c.type))
        .toList();

    for (final component in components) {
      // Create a new component with price override if available
      final priceOverride = priceMap[component.id];
      final componentWithPrice = priceOverride != null
          ? _cloneComponentWithPrice(component, priceOverride)
          : component;

      final availableSlotIndex = updatedState.indexWhere(
        (slot) =>
            slot.type == componentWithPrice.type &&
            slot.selectedProduct == null,
      );

      if (availableSlotIndex != -1) {
        updatedState[availableSlotIndex].selectedProduct = componentWithPrice;
        continue;
      }

      final duplicates = updatedState
          .where((slot) => slot.type == componentWithPrice.type)
          .length;
      final displayName = duplicates == 0
          ? _componentDisplayName(componentWithPrice.type)
          : '${_componentDisplayName(componentWithPrice.type)} ${duplicates + 1}';
      updatedState.add(
        PcComponent(
          name: displayName,
          type: componentWithPrice.type,
          selectedProduct: componentWithPrice,
        ),
      );
    }

    state = updatedState;
    _saveBuildStateToCookies();
  }

  /// Helper to create a copy of a component with a price override.
  BaseComponent _cloneComponentWithPrice(
    BaseComponent component,
    double price,
  ) {
    // Since BaseComponent subclasses are immutable, we need to re-parse from JSON
    // This is a workaround - ideally components would have a copyWith method
    final json = _componentToJson(component);
    json['lowestPriceOverride'] = price;

    switch (component.type) {
      case ComponentType.cpu:
        return CPUComponent.fromJson(json, priceOverride: price);
      case ComponentType.gpu:
        return GPUComponent.fromJson(json, priceOverride: price);
      case ComponentType.motherboard:
        return MotherboardComponent.fromJson(json, priceOverride: price);
      case ComponentType.ram:
        return MemoryComponent.fromJson(json, priceOverride: price);
      case ComponentType.storage:
        return StorageComponent.fromJson(json, priceOverride: price);
      case ComponentType.psu:
        return PowerSupplyComponent.fromJson(json, priceOverride: price);
      case ComponentType.pcCase:
        return CaseComponent.fromJson(json, priceOverride: price);
      case ComponentType.cooler:
        return CoolerComponent.fromJson(json, priceOverride: price);
      case ComponentType.caseFan:
        return CaseFanComponent.fromJson(json, priceOverride: price);
      case ComponentType.monitor:
        return MonitorComponent.fromJson(json, priceOverride: price);
    }
  }

  /// Converts a component to a basic JSON map for re-parsing with price.
  Map<String, dynamic> _componentToJson(BaseComponent component) {
    return {
      'id': component.id,
      'name': component.name,
      'manufacturer': component.manufacturer,
      'type': component.type.name.toUpperCase(),
      'imageUrl': component.imageUrl,
      'databaseEntryAt': component.databaseEntryAt.toIso8601String(),
      'lastEditedAt': component.lastEditedAt.toIso8601String(),
    };
  }

  static String _componentDisplayName(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return 'CPU';
      case ComponentType.gpu:
        return 'GPU';
      case ComponentType.motherboard:
        return 'Motherboard';
      case ComponentType.ram:
        return 'Memory (RAM)';
      case ComponentType.storage:
        return 'Storage';
      case ComponentType.psu:
        return 'Power Supply';
      case ComponentType.cooler:
        return 'CPU Cooler';
      case ComponentType.caseFan:
        return 'Case Fan';
      case ComponentType.pcCase:
        return 'Case';
      case ComponentType.monitor:
        return 'Monitor';
    }
  }

  /// Saves the current build state to cookies.
  Future<void> _saveBuildStateToCookies() async {
    final cookieStorage = _cookieStorage;
    if (cookieStorage == null || !_isUserLoggedIn) {
      debugPrint(
        '⚠️ Build state NOT saved: cookieStorage=${cookieStorage != null}, loggedIn=$_isUserLoggedIn',
      );
      return;
    }

    try {
      final components = state
          .where((pcComponent) => pcComponent.selectedProduct != null)
          .map((pcComponent) {
            final component = pcComponent.selectedProduct!;
            return {
              'id': component.id,
              'name': component.name,
              'manufacturer': component.manufacturer,
              'type': component.type.name,
              'imageUrl': component.imageUrl,
            };
          })
          .toList();

      await cookieStorage.saveBuildState(components);
      debugPrint(
        '✅ Build state saved to cookies: ${components.length} components',
      );
      if (components.isNotEmpty) {
        debugPrint(
          '   Components: ${components.map((c) => c['name']).join(', ')}',
        );
      }
    } catch (e) {
      debugPrint('❌ Error saving build state to cookies: $e');
    }
  }

  /// Loads the saved build state from cookies.
  /// This method fetches full component data from the API and restores the build state.
  Future<void> _loadBuildStateFromCookies() async {
    final cookieStorage = _cookieStorage;
    if (cookieStorage == null || !_isUserLoggedIn) {
      debugPrint(
        '⚠️ Build state NOT loaded: cookieStorage=${cookieStorage != null}, loggedIn=$_isUserLoggedIn',
      );
      return;
    }

    try {
      final savedComponents = await cookieStorage.getBuildState();
      if (savedComponents == null || savedComponents.isEmpty) {
        debugPrint('ℹ️ No saved build state found in cookies');
        return;
      }

      debugPrint(
        '✅ Found saved build state: ${savedComponents.length} components',
      );

      // We need to fetch component data from API, but we don't have direct access to ComponentService here
      // So we'll store the component IDs and let the UI handle restoration
      // For now, we'll create a method that can be called with ComponentService
      _savedComponentIds = savedComponents
          .map(
            (c) => {
              'id': c['id'] as String? ?? '',
              'type': c['type'] as String? ?? '',
              'name': c['name'] as String? ?? '',
            },
          )
          .where((c) => c['id']!.isNotEmpty)
          .toList();

      debugPrint(
        '📦 Saved component IDs for restoration: ${_savedComponentIds.length}',
      );
      for (final comp in _savedComponentIds) {
        debugPrint('   - ${comp['name']} (${comp['type']}, ID: ${comp['id']})');
      }
    } catch (e) {
      debugPrint('❌ Error loading build state from cookies: $e');
    }
  }

  /// List of saved component IDs that need to be restored
  List<Map<String, dynamic>> _savedComponentIds = [];

  /// Restores build state from saved component IDs.
  /// This should be called with ComponentService to fetch full component data.
  /// First loads saved component IDs from cookies, then fetches full component data and restores.
  Future<void> restoreBuildStateFromCookies(
    ComponentService componentService,
  ) async {
    // First, load saved component IDs from cookies if not already loaded
    if (_savedComponentIds.isEmpty) {
      await _loadBuildStateFromCookies();
    }

    if (_savedComponentIds.isEmpty) {
      return;
    }

    try {
      debugPrint(
        '🔄 Restoring build state from ${_savedComponentIds.length} saved components...',
      );
      final updatedState = List<PcComponent>.from(_initialState);
      int restoredCount = 0;

      for (final savedComp in _savedComponentIds) {
        final componentId = (savedComp['id'] as String?) ?? '';
        final componentTypeStr = (savedComp['type'] as String?) ?? '';

        if (componentId.isEmpty || componentTypeStr.isEmpty) {
          continue;
        }

        try {
          // Fetch full component data from API
          final component = await componentService.getComponentById(
            componentId,
          );

          // Find the matching slot
          final componentType = ComponentType.values.firstWhere(
            (type) => type.name == componentTypeStr,
            orElse: () => ComponentType.cpu,
          );

          final componentIndex = updatedState.indexWhere(
            (c) => c.type == componentType,
          );
          if (componentIndex != -1) {
            updatedState[componentIndex].selectedProduct = component;
            restoredCount++;
            debugPrint('✅ Restored: ${component.name}');
          }
        } catch (e) {
          debugPrint(
            '⚠️ Failed to restore component ${savedComp['name']} (ID: $componentId): $e',
          );
          // Continue with other components
        }
      }

      if (restoredCount > 0) {
        state = updatedState;
        debugPrint(
          '✅ Build state restored: $restoredCount/${_savedComponentIds.length} components',
        );
        // Clear saved IDs after successful restoration
        _savedComponentIds = [];
      } else {
        debugPrint('⚠️ No components were restored');
      }
    } catch (e) {
      debugPrint('❌ Error restoring build state: $e');
    }
  }

  /// Saves the current build to the backend.
  Future<String> saveBuild(
    WidgetRef ref,
    String name,
    String description, {
    List<String>? tagIds,
  }) async {
    final buildService = ref.read(buildServiceProvider);
    final userId = ref.read(authProvider).valueOrNull?.uid;

    if (userId == null) {
      throw Exception('You must be logged in to save a build.');
    }

    // 1. Create the main build entry.
    // Backend expects PascalCase property names and Description is required (cannot be empty)
    final newBuildId = await buildService.createBuild({
      'UserId': userId,
      'Name': name.trim(),
      'Description': description.trim().isEmpty
          ? 'No description provided.'
          : description.trim(),
      'Status': 'DRAFT',
    });

    // 2. Add each selected component to the newly created build in parallel
    final selectedComponents = state
        .where((slot) => slot.selectedProduct != null)
        .toList();
    debugPrint(
      'saveBuild: Found ${selectedComponents.length} selected components in state',
    );

    if (selectedComponents.isNotEmpty) {
      final componentFutures = selectedComponents.map((componentSlot) async {
        final component = componentSlot.selectedProduct!;
        final componentId = component.id;

        debugPrint(
          'saveBuild: Processing component ${component.name} (ID: $componentId, Type: ${component.type})',
        );

        if (componentId.isEmpty) {
          debugPrint(
            'saveBuild: ERROR - Component ${component.name} has empty ID! Skipping.',
          );
          return;
        }

        try {
          await buildService.addComponentToBuild(newBuildId, componentId, 1);
          debugPrint(
            'saveBuild: Successfully added component ${component.name} to build',
          );
        } catch (e) {
          debugPrint(
            'saveBuild: ERROR adding component ${component.name} to build: $e',
          );
          // Don't throw - continue with other components
        }
      }).toList();

      // Wait for all components to be added in parallel
      await Future.wait(componentFutures, eagerError: false);
    }

    // 3. Add tags to the build if provided (in parallel)
    if (tagIds != null && tagIds.isNotEmpty) {
      final tagFutures = tagIds.map((tagName) async {
        try {
          final tagId = await buildService.findTagIdByName(tagName);
          if (tagId != null) {
            await buildService.addTagToBuild(newBuildId, tagId);
          }
        } catch (e) {
          debugPrint('saveBuild: ERROR adding tag $tagName to build: $e');
          // Continue with other tags even if one fails
        }
      }).toList();

      // Wait for all tags to be added in parallel
      await Future.wait(tagFutures, eagerError: false);
    }

    return newBuildId;
  }

  /// Publishes a build by updating its status.
  Future<void> publishBuild(WidgetRef ref, String buildId) async {
    final buildService = ref.read(buildServiceProvider);
    try {
      // Update build status to PUBLISHED
      await buildService.updateBuild(buildId, {'status': 'PUBLISHED'});
    } catch (e) {
      debugPrint('Error in publishBuild: $e');
      rethrow;
    }
  }
}

/// The global Riverpod provider for accessing the [BuildNotifier].
///
/// Widgets can use this provider to watch the build state and call methods
/// to modify the build.
final buildProvider = StateNotifierProvider<BuildNotifier, List<PcComponent>>((
  ref,
) {
  // Watch auth state to react to login/logout changes
  final authState = ref.watch(authProvider);
  final isUserLoggedIn = authState.valueOrNull != null;

  // Create cookie storage service
  final cookieStorage = CookieStorageService();

  return BuildNotifier(
    cookieStorage: cookieStorage,
    isUserLoggedIn: isUserLoggedIn,
  );
});

/// Represents a single slot in the PC build list (e.g., CPU, GPU).
class PcComponent {
  /// The display name of the component slot (e.g., "CPU", "Motherboard").
  final String name;

  /// The type of the component, used for filtering and identification.
  final ComponentType type;

  /// The actual component selected by the user. It is nullable if no part is chosen.
  BaseComponent? selectedProduct;

  /// A flag to indicate if the selected component is compatible with the rest of the build.
  // TODO: Implement compatibility check logic to update this flag.
  bool isCompatible;

  PcComponent({
    required this.name,
    required this.type,
    this.selectedProduct,
    this.isCompatible = true,
  });
}

/// The main UI widget for the "Build Now" page.
class BuildNowPage extends ConsumerStatefulWidget {
  const BuildNowPage({super.key});

  @override
  ConsumerState<BuildNowPage> createState() => _BuildNowPageState();
}

class _BuildNowPageState extends ConsumerState<BuildNowPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();
  String? _buildLink; // Build link will be generated after saving a build
  bool _hasRestoredBuildState = false;

  @override
  void initState() {
    super.initState();
    // Restore build state after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _restoreBuildStateIfNeeded();
    });
  }

  /// Restores build state from cookies if user is logged in and state hasn't been restored yet
  Future<void> _restoreBuildStateIfNeeded() async {
    if (_hasRestoredBuildState) return;

    final authState = ref.read(authProvider);
    final isUserLoggedIn = authState.valueOrNull != null;

    if (!isUserLoggedIn) {
      return;
    }

    // Check if build already has components (e.g., loaded from "Open in Builder")
    // If so, skip restoration to avoid overwriting
    final buildState = ref.read(buildProvider);
    final hasComponents = buildState.any((component) => component.selectedProduct != null);
    if (hasComponents) {
      _hasRestoredBuildState = true;
      return;
    }

    try {
      final buildNotifier = ref.read(buildProvider.notifier);
      final componentService = ref.read(componentServiceProvider);
      await buildNotifier.restoreBuildStateFromCookies(componentService);
      _hasRestoredBuildState = true;
    } catch (e) {
      debugPrint('Error restoring build state: $e');
    }
  }

  /// Generates a build sharing link from the build ID
  String _generateBuildLink(String buildId) {
    if (kIsWeb) {
      // For web, use the current origin or a fixed domain
      // You can replace 'kazabuild.com' with your actual domain
      return 'https://kazabuild.com/build/$buildId';
    } else {
      // For mobile, use relative path
      return '/build/$buildId';
    }
  }

  bool _isBuildEmpty(List<PcComponent> components) {
    return components.every((component) => component.selectedProduct == null);
  }

  double _totalPrice(List<PcComponent> components) {
    return components.fold(
      0.0,
      (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
    );
  }

  int _estimatedWattage(List<PcComponent> components) {
    return components.fold(0, (sum, item) {
      final product = item.selectedProduct;
      if (product is CPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      if (product is GPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      if (product is MotherboardComponent) {
        return sum + 40;
      }
      if (product is MemoryComponent) {
        return sum + (5 * product.moduleQuantity);
      }
      if (product is StorageComponent) {
        return sum + 10;
      }
      return sum;
    });
  }

  /// Validates build compatibility based on component-type-specific rules.
  // Future<Map<ComponentType, bool>> _validateBuildCompatibility(
  //   List<PcComponent> components,
  //   WidgetRef ref,
  // ) async {
  //   final selectedComponents = components
  //       .where((c) => c.selectedProduct != null)
  //       .map((c) => c.selectedProduct!)
  //       .toList();

  //   if (selectedComponents.length < 2) {
  //     // Not enough components to check compatibility
  //     return {for (var c in components) c.type: true};
  //   }

  //   final compatibilityService = ref.read(
  //     componentCompatibilityServiceProvider,
  //   );
  //   final Map<ComponentType, bool> result = {};

  //   for (final component in components) {
  //     if (component.selectedProduct == null) {
  //       result[component.type] = true;
  //       continue;
  //     }

  //     final relevantComponents = CompatibilityRules.getRelevantComponents(
  //       component.type,
  //       selectedComponents
  //           .where((c) => c.id != component.selectedProduct!.id)
  //           .toList(),
  //     );

  //     if (relevantComponents.isEmpty) {
  //       result[component.type] = true;
  //       continue;
  //     }

  //     // Check if this component is compatible with all relevant components
  //     try {
  //       final compatibleIds = await compatibilityService
  //           .getCompatibleComponentIds(component.selectedProduct!.id);

  //       final isCompatible = relevantComponents.every(
  //         (relevant) => compatibleIds.contains(relevant.id),
  //       );
  //       result[component.type] = isCompatible;
  //     } catch (e) {
  //       result[component.type] = false;
  //     }
  //   }

  //   return result;
  // }

  // String _compatibilityStatus(List<PcComponent> components) {
  //   final selectedComponents = components
  //       .where((c) => c.selectedProduct != null)
  //       .toList();
  //   if (selectedComponents.isEmpty) {
  //     return 'Compatibility: No issues found';
  //   }
  //   bool allCompatible = selectedComponents.every((c) => c.isCompatible);
  //   return allCompatible
  //       ? 'Compatibility: No issues found'
  //       : 'Compatibility: Issues found!';
  // }

  IconData _getComponentIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.developer_board; // Or Icons.memory
      case ComponentType.gpu:
        return Icons.extension; // Or specific GPU icon if available
      case ComponentType.motherboard:
        return Icons.settings_input_component; // Motherboard-ish
      case ComponentType.ram:
        return Icons.memory;
      case ComponentType.storage:
        return Icons.storage;
      case ComponentType.psu:
        return Icons.power;
      case ComponentType.cooler:
        return Icons.cyclone; // Fan
      case ComponentType.caseFan:
        return Icons.mode_fan_off;
      case ComponentType.pcCase:
        return Icons.computer;
      case ComponentType.monitor:
        return Icons.monitor;
    }
  }

  Color _getComponentIconColor(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return const Color(0xFFFF6B6B); // Vibrant Red
      case ComponentType.gpu:
        return const Color(0xFF4ECDC4); // Vibrant Cyan/Turquoise
      case ComponentType.motherboard:
        return const Color(0xFFFFD93D); // Vibrant Yellow
      case ComponentType.ram:
        return const Color(0xFF95E1D3); // Vibrant Mint Green
      case ComponentType.storage:
        return const Color(0xFFFF8B94); // Vibrant Pink
      case ComponentType.psu:
        return const Color(0xFFFFA07A); // Vibrant Coral
      case ComponentType.cooler:
        return const Color(0xFF87CEEB); // Vibrant Sky Blue
      case ComponentType.caseFan:
        return const Color(0xFFBA55D3); // Vibrant Medium Orchid
      case ComponentType.pcCase:
        return const Color(0xFF20B2AA); // Vibrant Light Sea Green
      case ComponentType.monitor:
        return const Color(0xFFFF69B4); // Vibrant Hot Pink
    }
  }

  void _showSnackBar({
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _scaffoldMessengerKey.currentState?.clearSnackBars();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  Future<String?> _showSaveBuildDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedTagIds = <String>{};

    // Use a ValueNotifier to preserve image state outside the dialog
    final selectedImageNotifier = ValueNotifier<XFile?>(null);
    final imagePathNotifier = ValueNotifier<String?>(null);

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.saveBuild),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.buildName,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.pleaseEnterName
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.tags,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final tagsAsync = ref.watch(tagsProvider);
                        return tagsAsync.when(
                          data: (tags) {
                            if (tags.isEmpty) {
                              return Text(
                                AppLocalizations.of(context)!.noTagsAvailable,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) {
                                final isSelected = selectedTagIds.contains(
                                  tag.name,
                                );
                                return FilterChip(
                                  label: Text(tag.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedTagIds.add(tag.name);
                                      } else {
                                        selectedTagIds.remove(tag.name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) => Text(
                            '${AppLocalizations.of(context)!.errorLoadingTags}: ${getUserFriendlyError(error)}',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Build Image (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<XFile?>(
                      valueListenable: selectedImageNotifier,
                      builder: (context, selectedImage, _) {
                        if (selectedImage == null) {
                          return OutlinedButton.icon(
                            onPressed: () async {
                              debugPrint('Select Image button pressed');
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1920,
                                maxHeight: 1080,
                                imageQuality: 90,
                              );
                              if (image != null) {
                                debugPrint('Image selected: ${image.path}');
                                setDialogState(() {
                                  selectedImageNotifier.value = image;
                                  imagePathNotifier.value = image.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('Select Image'),
                          );
                        }
                        return Column(
                          children: [
                            FutureBuilder<Uint8List>(
                              future: selectedImage.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (snapshot.hasData) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: const Icon(Icons.image, size: 50),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                debugPrint('Remove Image button pressed');
                                setDialogState(() {
                                  selectedImageNotifier.value = null;
                                  imagePathNotifier.value = null;
                                });
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Remove Image'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSave == true) {
      try {
        final newBuildId = await ref
            .read(buildProvider.notifier)
            .saveBuild(
              ref,
              nameController.text,
              descriptionController.text,
              tagIds: selectedTagIds.toList(),
            );

        // Upload image if one was selected
        final imageFile = selectedImageNotifier.value;
        final imagePathValue = imagePathNotifier.value;

        if (imageFile != null) {
          try {
            debugPrint('_showSaveBuildDialog: Uploading image...');
            final dio = ref.read(authProvider.notifier).getDioInstance();

            // Check if it's a blob URL - if so, read bytes directly
            MultipartFile filePart;
            if (imagePathValue != null && imagePathValue.startsWith('blob:')) {
              // For blob URLs, read the file bytes directly
              debugPrint(
                '_showSaveBuildDialog: Image is blob URL, reading bytes...',
              );
              final bytes = await imageFile.readAsBytes();
              filePart = MultipartFile.fromBytes(
                bytes,
                filename: imageFile.name,
              );
            } else if (imagePathValue != null && imagePathValue.isNotEmpty) {
              // For real file paths, use fromFile
              debugPrint(
                '_showSaveBuildDialog: Image is file path: $imagePathValue',
              );
              filePart = await MultipartFile.fromFile(
                imagePathValue,
                filename: imageFile.name,
              );
            } else {
              // Fallback: read bytes from XFile
              debugPrint(
                '_showSaveBuildDialog: Reading image bytes from XFile...',
              );
              final bytes = await imageFile.readAsBytes();
              filePart = MultipartFile.fromBytes(
                bytes,
                filename: imageFile.name,
              );
            }

            final formData = FormData.fromMap({
              'File': filePart,
              'TargetId': newBuildId,
              'LocationType': 'BUILD',
              'Name': 'build_image_${imageFile.name}',
            });

            debugPrint('_showSaveBuildDialog: Sending image upload request...');
            await dio.post('$apiBaseUrl/Images/add', data: formData);
            debugPrint('_showSaveBuildDialog: Image uploaded successfully');
          } catch (e) {
            // Log error but continue with saving
            debugPrint('_showSaveBuildDialog: Error uploading image: $e');
            // Don't show error to user - image is optional
          }
        }

        // Generate and store the build link
        if (mounted) {
          setState(() {
            _buildLink = _generateBuildLink(newBuildId);
          });
        }

        _showSnackBar(
          message: AppLocalizations.of(context)!.buildSuccessfullySaved,
          backgroundColor: Colors.green,
        );
        return newBuildId;
      } catch (e) {
        _showSnackBar(
          message: '${AppLocalizations.of(context)!.failedToSaveBuild}: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = ref.watch(buildProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 950;

    // Smooth dark background to match the screenshot better
    final backgroundColor = theme.brightness == Brightness.dark
        ? const Color(0xFF0F0915)
        : theme.colorScheme.background;

    final selectedCurrency = ref.watch(currencyProvider);
    final currencyData = currencyDetails[selectedCurrency]!;
    final totalPrice = _totalPrice(components) * currencyData.exchangeRate;
    final estimatedWattage = _estimatedWattage(components);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer(showProfileArea: true),
        backgroundColor: backgroundColor,
        body: Column(
          children: [
            CustomNavigationBar(scaffoldKey: _scaffoldKey),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 32.0, bottom: 32.0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1600),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Title Section with gradient/glow effect
                          ShaderMask(
                            shaderCallback: (bounds) => const LinearGradient(
                              colors: [
                                Color(0xFF00E676), // Bright Green
                                Color.fromARGB(
                                  255,
                                  17,
                                  105,
                                  62,
                                ), // Dark Green accent
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ).createShader(bounds),
                            child: Text(
                              AppLocalizations.of(context)!.pcBuilder,
                              style: const TextStyle(
                                fontSize: 56, // Slightly larger
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            AppLocalizations.of(context)!.configurePcBuild,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.7),
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 40),
                          _TopBar(
                            theme: theme,
                            buildLink: _buildLink,
                            components: components,
                            currencyData: currencyData,
                            estimatedWattage: estimatedWattage,
                            onNew: _startNewBuild,
                            onPost: _publishBuild,
                            isMobile: isMobile,
                            onShowSnackBar: _showSnackBar,
                          ),
                          const SizedBox(height: 24),
                          // _CompatibilityBar(
                          //   theme: theme,
                          //   statusMessage: _compatibilityStatus(components),
                          // ),
                          const SizedBox(height: 24),
                          _PriceAndSaveBar(
                            theme: theme,
                            totalPrice: totalPrice,
                            currencyData: currencyData,
                            onSave: _showSaveBuildDialog,
                            onShareToExplore: _publishBuild,
                            isMobile: isMobile,
                          ),
                          const SizedBox(height: 32),
                          // Clear All Button Section
                          if (!_isBuildEmpty(components))
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  onPressed: () async {
                                    final bool?
                                    shouldClear = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text(
                                          'Clear All Components',
                                        ),
                                        content: const Text(
                                          'Are you sure you want to remove all selected components from your build?',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.of(
                                              context,
                                            ).pop(false),
                                            child: const Text('Cancel'),
                                          ),
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.of(context).pop(true),
                                            style: TextButton.styleFrom(
                                              foregroundColor: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                            ),
                                            child: const Text('Clear All'),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (shouldClear == true && mounted) {
                                      ref
                                          .read(buildProvider.notifier)
                                          .clearBuild();
                                      _showSnackBar(
                                        message: 'All components cleared',
                                        backgroundColor: Colors.green,
                                      );
                                    }
                                  },
                                  icon: Icon(
                                    Icons.clear_all_rounded,
                                    size: 18,
                                    color: theme.colorScheme.error,
                                  ),
                                  label: Text(
                                    'Clear All',
                                    style: TextStyle(
                                      color: theme.colorScheme.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          if (!_isBuildEmpty(components))
                            const SizedBox(height: 16),
                          _ComponentTable(
                            theme: theme,
                            components: components,
                            onRemove: (i) => ref
                                .read(buildProvider.notifier)
                                .removeComponent(components[i].type),
                            onAdd: (i) async {
                              final targetType = components[i].type.name;
                              final selected = await context
                                  .push<BaseComponent?>(
                                    '/parts/$targetType',
                                    extra: components,
                                  );
                              if (selected != null && mounted) {
                                if (selected.id.isEmpty) {
                                  _showSnackBar(
                                    message:
                                        'Selected component has no ID. Try another.',
                                    backgroundColor: Colors.red,
                                  );
                                  return;
                                }
                                ref
                                    .read(buildProvider.notifier)
                                    .addComponent(selected);
                              }
                            },
                            isMobile: isMobile,
                            getIcon: _getComponentIcon,
                            getIconColor: _getComponentIconColor,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Clears the current build, with a confirmation dialog if it's not empty.
  Future<void> _startNewBuild() async {
    final components = ref.read(buildProvider);
    if (_isBuildEmpty(components)) {
      ref.read(buildProvider.notifier).clearBuild();
      return;
    }

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.startNewBuild),
        content: Text(AppLocalizations.of(context)!.unsavedChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.clearBuild),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      ref.read(buildProvider.notifier).clearBuild();
    }
  }

  /// Shows a dialog to get build name, description, and image, then saves and publishes it.
  Future<String?> _showPostBuildDialog() async {
    debugPrint('_showPostBuildDialog: Starting dialog');

    // Check if widget is mounted before opening dialog
    if (!mounted) {
      debugPrint(
        '_showPostBuildDialog: Widget not mounted, cannot show dialog',
      );
      return null;
    }

    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedTagIds = <String>{};

    // Use a ValueNotifier to preserve image state outside the dialog
    final selectedImageNotifier = ValueNotifier<XFile?>(null);
    final imagePathNotifier = ValueNotifier<String?>(null);

    debugPrint('_showPostBuildDialog: Showing dialog');
    final bool? shouldPost = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.postBuild),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText:
                            '${AppLocalizations.of(context)!.buildName} *',
                        hintText: AppLocalizations.of(context)!.enterBuildName,
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? AppLocalizations.of(context)!.pleaseEnterName
                          : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(
                        labelText: AppLocalizations.of(context)!.description,
                        hintText: AppLocalizations.of(context)!.describeBuild,
                      ),
                      maxLines: 4,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      AppLocalizations.of(context)!.tags,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Consumer(
                      builder: (context, ref, child) {
                        final tagsAsync = ref.watch(tagsProvider);
                        return tagsAsync.when(
                          data: (tags) {
                            if (tags.isEmpty) {
                              return Text(
                                AppLocalizations.of(context)!.noTagsAvailable,
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                ),
                              );
                            }
                            return Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: tags.map((tag) {
                                // Store tag name instead of ID for easier matching
                                final isSelected = selectedTagIds.contains(
                                  tag.name,
                                );
                                return FilterChip(
                                  label: Text(tag.name),
                                  selected: isSelected,
                                  onSelected: (selected) {
                                    setDialogState(() {
                                      if (selected) {
                                        selectedTagIds.add(tag.name);
                                      } else {
                                        selectedTagIds.remove(tag.name);
                                      }
                                    });
                                  },
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const CircularProgressIndicator(),
                          error: (error, stack) => Text(
                            '${AppLocalizations.of(context)!.errorLoadingTags}: ${getUserFriendlyError(error)}',
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Build Image (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ValueListenableBuilder<XFile?>(
                      valueListenable: selectedImageNotifier,
                      builder: (context, selectedImage, _) {
                        if (selectedImage == null) {
                          return OutlinedButton.icon(
                            onPressed: () async {
                              debugPrint('Select Image button pressed');
                              final ImagePicker picker = ImagePicker();
                              final XFile? image = await picker.pickImage(
                                source: ImageSource.gallery,
                                maxWidth: 1920,
                                maxHeight: 1080,
                                imageQuality: 90,
                              );
                              if (image != null) {
                                debugPrint('Image selected: ${image.path}');
                                setDialogState(() {
                                  selectedImageNotifier.value = image;
                                  imagePathNotifier.value = image.path;
                                });
                              }
                            },
                            icon: const Icon(Icons.image),
                            label: const Text('Select Image'),
                          );
                        }
                        return Column(
                          children: [
                            FutureBuilder<Uint8List>(
                              future: selectedImage.readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: const Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  );
                                }
                                if (snapshot.hasData) {
                                  return Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                }
                                return Container(
                                  height: 150,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.grey),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: const Icon(Icons.image, size: 50),
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            TextButton.icon(
                              onPressed: () {
                                debugPrint('Remove Image button pressed');
                                setDialogState(() {
                                  selectedImageNotifier.value = null;
                                  imagePathNotifier.value = null;
                                });
                              },
                              icon: const Icon(Icons.delete),
                              label: const Text('Remove Image'),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  debugPrint('Post Build button pressed in dialog');
                  debugPrint('Form key current state: ${formKey.currentState}');
                  if (formKey.currentState!.validate()) {
                    debugPrint('Form is valid, closing dialog with true');
                    debugPrint('Build name: ${nameController.text}');
                    debugPrint(
                      'Build description length: ${descriptionController.text.length}',
                    );
                    debugPrint(
                      'Selected image: ${selectedImageNotifier.value?.path ?? 'none'}',
                    );
                    Navigator.of(context).pop(true);
                  } else {
                    debugPrint(
                      'Form validation failed - name is empty or invalid',
                    );
                  }
                },
                child: Text(AppLocalizations.of(context)!.postBuild),
              ),
            ],
          );
        },
      ),
    );

    // If user cancelled, return early
    debugPrint(
      '_showPostBuildDialog: Dialog returned: $shouldPost, mounted: $mounted',
    );
    if (shouldPost != true || !mounted) {
      debugPrint(
        '_showPostBuildDialog: User cancelled or widget not mounted, returning null',
      );
      return null;
    }
    debugPrint('_showPostBuildDialog: Proceeding with build publish');

    // Store values before async operations
    final buildName = nameController.text.trim();
    final buildDescription = descriptionController.text.trim();
    final imageFile = selectedImageNotifier.value;
    final imagePathValue = imagePathNotifier.value;

    debugPrint(
      '_showPostBuildDialog: Stored values - name: "$buildName", description: "${buildDescription.length} chars", image: ${imageFile?.path ?? 'none'}',
    );

    // Don't show loading snackbar here - it causes context issues
    // We'll show a success message after publishing or navigate directly

    try {
      // 1. Save the build first to get the build ID
      debugPrint(
        '_showPostBuildDialog: Saving build with name: $buildName, description length: ${buildDescription.length}',
      );
      final newBuildId = await ref
          .read(buildProvider.notifier)
          .saveBuild(
            ref,
            buildName,
            buildDescription,
            tagIds: selectedTagIds.toList(),
          );
      debugPrint('_showPostBuildDialog: Build saved with ID: $newBuildId');

      if (!mounted) {
        debugPrint(
          '_showPostBuildDialog: Widget not mounted after save, returning null',
        );
        return null;
      }

      // Generate and store the build link
      setState(() {
        _buildLink = _generateBuildLink(newBuildId);
      });

      // 2. Upload image if one was selected
      if (imageFile != null) {
        try {
          debugPrint('_showPostBuildDialog: Uploading image...');
          final dio = ref.read(authProvider.notifier).getDioInstance();

          // Check if it's a blob URL - if so, read bytes directly
          MultipartFile filePart;
          if (imagePathValue != null && imagePathValue.startsWith('blob:')) {
            // For blob URLs, read the file bytes directly
            debugPrint(
              '_showPostBuildDialog: Image is blob URL, reading bytes...',
            );
            final bytes = await imageFile.readAsBytes();
            filePart = MultipartFile.fromBytes(bytes, filename: imageFile.name);
          } else if (imagePathValue != null && imagePathValue.isNotEmpty) {
            // For real file paths, use fromFile
            debugPrint(
              '_showPostBuildDialog: Image is file path: $imagePathValue',
            );
            filePart = await MultipartFile.fromFile(
              imagePathValue,
              filename: imageFile.name,
            );
          } else {
            // Fallback: read bytes from XFile
            debugPrint(
              '_showPostBuildDialog: Reading image bytes from XFile...',
            );
            final bytes = await imageFile.readAsBytes();
            filePart = MultipartFile.fromBytes(bytes, filename: imageFile.name);
          }

          final formData = FormData.fromMap({
            'File': filePart,
            'TargetId': newBuildId,
            'LocationType': 'BUILD',
            'Name': 'build_image_${imageFile.name}',
          });

          debugPrint('_showPostBuildDialog: Sending image upload request...');
          await dio.post('$apiBaseUrl/Images/add', data: formData);
          debugPrint('_showPostBuildDialog: Image uploaded successfully');
        } catch (e) {
          // Log error but continue with publishing
          debugPrint('_showPostBuildDialog: Image upload error: $e');
          // Don't show snackbar here - causes context issues
          // Image upload failure is not critical, build will still be published
        }
      } else {
        debugPrint(
          '_showPostBuildDialog: No image selected, skipping image upload',
        );
      }

      if (!mounted) {
        debugPrint(
          '_showPostBuildDialog: Widget not mounted after image upload, returning null',
        );
        return null;
      }

      // 3. Publish the build
      debugPrint('_showPostBuildDialog: Publishing build: $newBuildId');
      try {
        await ref.read(buildProvider.notifier).publishBuild(ref, newBuildId);
        debugPrint('_showPostBuildDialog: Build published successfully');
      } catch (e) {
        debugPrint('_showPostBuildDialog: Error publishing build: $e');
        _showSnackBar(
          message: 'Failed to publish build: ${e.toString()}',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
        return null;
      }

      if (!mounted) {
        debugPrint(
          '_showPostBuildDialog: Widget not mounted after publish, returning null',
        );
        return null;
      }

      // 4. Invalidate providers to refresh explore builds
      ref.invalidate(allBuildsProvider);
      final userId = ref.read(authProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.invalidate(userBuildsProvider(userId));
      }

      // 5. Don't show snackbar here - widget might be disposed
      // Success message will be shown in _publishBuild after dialog returns
      return newBuildId;
    } catch (e, stackTrace) {
      debugPrint('_showPostBuildDialog: Error publishing build: $e');
      debugPrint('_showPostBuildDialog: Stack trace: $stackTrace');

      // Show error message to user
      _showSnackBar(
        message: 'Failed to publish build: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );

      return null;
    }
  }

  /// Saves and then publishes the build to the Explore page.
  void _publishBuild() async {
    debugPrint('_publishBuild called');

    // Check if user is logged in
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      debugPrint('User not logged in');
      _showSnackBar(
        message: 'Please log in to publish your build.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    debugPrint('User logged in: ${user.uid}');

    // Check if build has at least one component
    final components = ref.read(buildProvider);
    if (_isBuildEmpty(components)) {
      debugPrint('Build is empty');
      _showSnackBar(
        message:
            'Please add at least one component to your build before posting.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    debugPrint('Build has ${components.length} components');

    // Show the post build dialog
    debugPrint('Showing post build dialog...');
    final result = await _showPostBuildDialog();
    debugPrint('Post build dialog returned: $result');

    // Show success message if build was published successfully
    if (result != null) {
      _showSnackBar(
        message: 'Build successfully published',
        backgroundColor: Colors.green,
      );
    }
  }
}

/// The top bar of the builder page, containing the build link and action buttons.
class _TopBar extends StatelessWidget {
  final ThemeData theme;
  final String? buildLink; // Nullable - will be null until build is saved
  final List<PcComponent> components;
  final CurrencyData currencyData;
  final int estimatedWattage;
  final VoidCallback onNew;
  final VoidCallback onPost;
  final bool isMobile;
  final void Function({
    required String message,
    Color? backgroundColor,
    Duration duration,
  })
  onShowSnackBar;

  const _TopBar({
    required this.theme,
    this.buildLink, // Nullable
    required this.components,
    required this.currencyData,
    required this.estimatedWattage,
    required this.onNew,
    required this.onPost,
    required this.isMobile,
    required this.onShowSnackBar,
  });

  /// Generates a Reddit-compatible markdown table of the current build.
  String _generateRedditMarkup() {
    final buffer = StringBuffer();
    buffer.writeln('**Component** | **Product** | **Price**');
    buffer.writeln(':----|:----|:----');
    for (final component in components) {
      if (component.selectedProduct != null) {
        final product = component.selectedProduct!;
        buffer.writeln(
          '**${component.name}** | ${product.name} | \$${product.lowestPrice?.toStringAsFixed(2) ?? '-'}',
        );
      }
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;
    final containerColor = isDark
        ? const Color(0xFF13111A)
        : Colors.white; // Slightly lighter than bg
    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Colors.grey.withValues(alpha: 0.2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Link Section
              Expanded(
                flex: 2,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F0915)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.link_rounded,
                        size: 20,
                        color: buildLink != null
                            ? (isDark
                                  ? Colors.grey.shade400
                                  : theme.colorScheme.primary)
                            : (isDark
                                  ? Colors.grey.shade600
                                  : Colors.grey.shade400),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: buildLink != null
                              ? () {
                                  // Extract build ID from link and navigate to build detail page
                                  final link = buildLink!;
                                  String? buildId;

                                  // Handle both full URL and relative path formats
                                  if (link.contains('/build/')) {
                                    final parts = link.split('/build/');
                                    if (parts.length > 1) {
                                      buildId = parts[1]
                                          .split('?')
                                          .first; // Remove query params if any
                                    }
                                  } else if (link.startsWith('/build/')) {
                                    buildId = link
                                        .replaceFirst('/build/', '')
                                        .split('?')
                                        .first;
                                  }

                                  if (buildId != null && buildId.isNotEmpty) {
                                    // Navigate to build detail page
                                    context.go('/build/$buildId');
                                  } else {
                                    // Fallback: try to use the link as-is
                                    onShowSnackBar(
                                      message: 'Invalid build link',
                                    );
                                  }
                                }
                              : null,
                          child: MouseRegion(
                            cursor: buildLink != null
                                ? SystemMouseCursors.click
                                : SystemMouseCursors.basic,
                            child: Text(
                              buildLink ?? 'Save build to generate link',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: buildLink != null
                                    ? (isDark
                                          ? AppColorsDark.buttonBlue
                                          : theme.colorScheme.primary)
                                    : (isDark
                                          ? Colors.grey.shade600
                                          : Colors.grey.shade400),
                                fontSize: 14,
                                fontFamily:
                                    'RobotoMono', // Monospace for link looks techy
                                fontStyle: buildLink == null
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                                decoration: buildLink != null
                                    ? TextDecoration.underline
                                    : null,
                                decorationColor: buildLink != null
                                    ? (isDark
                                          ? AppColorsDark.buttonBlue
                                          : theme.colorScheme.primary)
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: buildLink != null
                              ? () {
                                  Clipboard.setData(
                                    ClipboardData(text: buildLink!),
                                  );
                                  onShowSnackBar(message: 'Build link copied!');
                                }
                              : null, // Disable if no link
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Icon(
                              Icons.copy_rounded,
                              size: 18,
                              color: buildLink != null
                                  ? (isDark
                                        ? Colors.grey.shade400
                                        : theme.colorScheme.primary)
                                  : Colors.grey.shade500, // Disabled color
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (!isMobile) ...[
                const SizedBox(width: 32),
                // Markup Section
                Text(
                  'Markup:',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 12),
                _MarkupButton(
                  icon: Icons.code,
                  tooltip: 'Reddit Markup',
                  onTap: () {
                    Clipboard.setData(
                      ClipboardData(text: _generateRedditMarkup()),
                    );
                    onShowSnackBar(message: 'Reddit markup copied!');
                  },
                ),
                const SizedBox(width: 8),
                _MarkupButton(
                  icon: Icons.description_outlined,
                  tooltip: 'Text Markup',
                  onTap: () {
                    onShowSnackBar(message: 'Text format copied!');
                  },
                ),
                const Spacer(),

                // New Build Button (Text Button Style)
                TextButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: const Text('New Build'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 24),

                // Wattage Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColorsDark.buttonGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColorsDark.buttonGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt_rounded,
                        color: AppColorsDark.buttonGreen,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Est: ${estimatedWattage}W',
                        style: const TextStyle(
                          color: AppColorsDark.buttonGreen,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          if (isMobile) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Wattage Badge Mobile
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColorsDark.buttonGreen.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.bolt,
                        color: AppColorsDark.buttonGreen,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Est: ${estimatedWattage}W',
                        style: const TextStyle(
                          color: AppColorsDark.buttonGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Build'),
                  style: TextButton.styleFrom(foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkupButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _MarkupButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, size: 20, color: AppColorsDark.buttonGreen),
        ),
      ),
    );
  }
}

// class _CompatibilityBar extends StatelessWidget {
//   final ThemeData theme;
//   final String statusMessage;

//   const _CompatibilityBar({required this.theme, required this.statusMessage});

//   @override
//   Widget build(BuildContext context) {
//     final bool hasIssues =
//         statusMessage.toLowerCase().contains('issues found') &&
//         !statusMessage.toLowerCase().contains('no issues');
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//       decoration: BoxDecoration(
//         color: hasIssues
//             ? AppColorsDark.error.withValues(alpha: 0.1)
//             : const Color(0xFF0C4F2A).withValues(alpha: 0.3),
//         borderRadius: BorderRadius.circular(8),
//         border: Border.all(
//           color: hasIssues
//               ? AppColorsDark.error.withValues(alpha: 0.5)
//               : const Color(0xFF0C4F2A),
//           width: 1,
//         ),
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             hasIssues
//                 ? Icons.cancel_outlined
//                 : Icons.check_circle_outline_rounded,
//             color: hasIssues ? AppColorsDark.error : AppColorsDark.buttonGreen,
//             size: 20,
//           ),
//           const SizedBox(width: 10),
//           Text(
//             statusMessage,
//             style: TextStyle(
//               color: hasIssues
//                   ? AppColorsDark.error
//                   : AppColorsDark.buttonGreen,
//               fontWeight: FontWeight.w600,
//               fontSize: 14,
//               letterSpacing: 0.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

class _PriceAndSaveBar extends ConsumerWidget {
  final ThemeData theme;
  final double totalPrice;
  final CurrencyData currencyData;
  final VoidCallback onSave;
  final VoidCallback onShareToExplore;
  final bool isMobile;

  const _PriceAndSaveBar({
    required this.theme,
    required this.totalPrice,
    required this.currencyData,
    required this.onSave,
    required this.onShareToExplore,
    required this.isMobile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF13111A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : Colors.grey.withValues(alpha: 0.2),
        ),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Price Section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PRICE',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalPrice.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyData.symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Buttons Section (Mobile - Stacked)
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2B40),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: const Text('Save List'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onShareToExplore,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColorsDark.buttonGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.share_rounded, size: 18),
                            SizedBox(width: 6),
                            Text('Share'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL PRICE',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          totalPrice.toStringAsFixed(2),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currencyData.symbol,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const Spacer(),
                // Save List Button (DRAFT)
                ElevatedButton(
                  onPressed: onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(
                      0xFF2D2B40,
                    ), // Softer dark button
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: const Text('Save List'),
                ),
                const SizedBox(width: 12),
                // Share to Explore Button (PUBLISHED)
                ElevatedButton(
                  onPressed: onShareToExplore,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColorsDark.buttonGreen, // Green for share/publish
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.share_rounded, size: 18),
                      SizedBox(width: 8),
                      Text('Share to Explore'),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

/// The main table widget that lists all component slots in the build.
class _ComponentTable extends StatelessWidget {
  final ThemeData theme;
  final List<PcComponent> components;
  final Function(int) onRemove;
  final Function(int) onAdd;
  final bool isMobile;
  final IconData Function(ComponentType) getIcon;
  final Color Function(ComponentType) getIconColor;

  const _ComponentTable({
    required this.theme,
    required this.components,
    required this.onRemove,
    required this.onAdd,
    required this.isMobile,
    required this.getIcon,
    required this.getIconColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = theme.brightness == Brightness.dark;

    if (isMobile) {
      return Column(
        children: [
          ...List.generate(components.length, (index) {
            final component = components[index];
            final product = component.selectedProduct;
            final isSelected = product != null;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF13111A) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? AppColorsDark.buttonPurple.withValues(alpha: 0.3)
                      : Colors.white.withValues(alpha: 0.05),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1B29)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            getIcon(component.type),
                            color: getIconColor(component.type),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              component.name,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey.shade300
                                    : Colors.grey.shade800,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (isSelected) ...[
                              const SizedBox(height: 4),
                              Text(
                                product.name,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  height: 1.2,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (isSelected)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${product.manufacturer} • ${_getShortSpec(product)}',
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${product.lowestPrice?.toStringAsFixed(2) ?? '-'} PLN',
                                style: const TextStyle(
                                  color: Color(0xFF4DD0E1),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              color: Colors.grey.shade500,
                              tooltip: 'Change',
                              onPressed: () => onAdd(index),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: Colors.grey.shade500,
                              tooltip: 'Remove',
                              onPressed: () => onRemove(index),
                            ),
                          ],
                        ),
                      ],
                    )
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '-',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        InkWell(
                          onTap: () => onAdd(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsDark.buttonPurple.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColorsDark.buttonPurple.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: AppColorsDark.buttonPurple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add ${component.name}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColorsDark.buttonPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            );
          }),
        ],
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                flex: 2,
                child: Text(
                  'COMPONENT',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              Expanded(
                flex: 4,
                child: Text(
                  'SELECTION',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(
                  'PRICE',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 100), // Action Column
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(components.length, (index) {
          final component = components[index];
          final product = component.selectedProduct;
          final isSelected = product != null;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF13111A)
                  : Colors.white, // Lighter than background
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColorsDark.buttonPurple.withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.05),
              ),
            ),
            child: Row(
              children: [
                // Icon / Image Section (Component Column)
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark
                              ? const Color(0xFF1E1B29)
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            getIcon(component.type),
                            color: getIconColor(component.type),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        component.name,
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade300
                              : Colors.grey.shade800,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Name and Description Section (Selection Column)
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isSelected && product.imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Image.network(
                              product.imageUrl,
                              height: 40,
                              width: 40,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const SizedBox(),
                            ),
                          ),
                        ),
                      if (isSelected)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${product.manufacturer} • ${_getShortSpec(product)}',
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        )
                      else
                        InkWell(
                          onTap: () => onAdd(index),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: AppColorsDark.buttonPurple.withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppColorsDark.buttonPurple.withValues(
                                  alpha: 0.3,
                                ),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_rounded,
                                  size: 16,
                                  color: AppColorsDark.buttonPurple,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add ${component.name}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: AppColorsDark.buttonPurple,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Price
                SizedBox(
                  width: 100,
                  child: Text(
                    isSelected
                        ? '${product.lowestPrice?.toStringAsFixed(2) ?? '-'} PLN'
                        : '-',
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: Color(0xFF4DD0E1), // Cyan accent color
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),

                // Action Buttons
                SizedBox(
                  width: 100,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (isSelected) ...[
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 20),
                          color: Colors.grey.shade500,
                          tooltip: 'Change',
                          onPressed: () => onAdd(index),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          color: Colors.grey.shade500,
                          tooltip: 'Remove',
                          onPressed: () => onRemove(index),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _getShortSpec(BaseComponent product) {
    if (product is CPUComponent) {
      return '${product.coreTotal} Cores • ${product.socketType}';
    } else if (product is GPUComponent) {
      return '${product.videoMemoryAmount}GB • ${product.chipset}';
    } else if (product is MemoryComponent) {
      return '${product.capacity}GB ${product.ramType}';
    }
    return product.type.name.toUpperCase();
  }
}
