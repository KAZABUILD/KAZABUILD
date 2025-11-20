/// This file defines the state management for fetching PC components from the backend.
///
/// It uses Riverpod to create providers that handle fetching lists of `BaseComponent`
/// objects, abstracting the API logic away from the UI widgets. It supports
/// server-side filtering and pagination through the `ComponentFilter` class.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/component_models.dart';

const int _defaultComponentPageLength = 50;
const int _bulkFetchPageLength = 250;

String _mapTypeToDiscriminator(ComponentType type) {
  switch (type) {
    case ComponentType.cpu:
      return 'CPU';
    case ComponentType.gpu:
      return 'GPU';
    case ComponentType.motherboard:
      return 'Motherboard';
    case ComponentType.ram:
      return 'Memory';
    case ComponentType.storage:
      return 'Storage';
    case ComponentType.psu:
      return 'PowerSupply';
    case ComponentType.cooler:
      return 'Cooler';
    case ComponentType.pcCase:
      return 'Case';
    case ComponentType.caseFan:
      return 'CaseFan';
    case ComponentType.monitor:
      return 'Monitor';
  }
}

String _mapTypeToBackendEnum(ComponentType type) {
  switch (type) {
    case ComponentType.cpu:
      return 'CPU';
    case ComponentType.gpu:
      return 'GPU';
    case ComponentType.motherboard:
      return 'MOTHERBOARD';
    case ComponentType.ram:
      return 'MEMORY';
    case ComponentType.storage:
      return 'STORAGE';
    case ComponentType.psu:
      return 'POWER_SUPPLY';
    case ComponentType.cooler:
      return 'COOLER';
    case ComponentType.pcCase:
      return 'CASE';
    case ComponentType.caseFan:
      return 'CASE_FAN';
    case ComponentType.monitor:
      return 'MONITOR';
  }
}

@immutable
class ComponentPageResult {
  final List<BaseComponent> items;
  final int page;
  final int pageLength;
  final bool hasMore;

  ComponentPageResult({
    required List<BaseComponent> items,
    required this.page,
    required this.pageLength,
    required this.hasMore,
  }) : items = List.unmodifiable(items);
}

/// A service class to handle API requests related to PC components.
class ComponentService {
  final Dio _dio;

  ComponentService(this._dio);

  /// Fetches all available components of a specific type by traversing each page.
  Future<List<BaseComponent>> getComponents(ComponentType componentType) async {
    final List<BaseComponent> allComponents = [];
    var page = 1;
    var hasMore = true;

    while (hasMore) {
      final pageResult = await getComponentsPage(
        componentType,
        page: page,
        pageLength: _bulkFetchPageLength,
      );

      allComponents.addAll(pageResult.items);
      hasMore = pageResult.hasMore && pageResult.items.isNotEmpty;
      page++;
    }

    return allComponents;
  }

  /// Fetches a single page of components for the provided [componentType].
  Future<ComponentPageResult> getComponentsPage(
    ComponentType componentType, {
    int page = 1,
    int pageLength = _defaultComponentPageLength,
  }) async {
    final url = '$apiBaseUrl/Components/get';
    final body = _buildRequestBody(
      componentType,
      page: page,
      pageLength: pageLength,
    );

    if (kDebugMode) {
      print('Sending request to $url');
      print('Request body: $body');
    }

    try {
      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> data = response.data;

        if (kDebugMode) {
          print(
            'Received ${data.length} components for type: $componentType (page $page)',
          );
        }

        final parsedComponents = _parseComponents(data, componentType);

        if (kDebugMode) {
          print(
            'Successfully parsed ${parsedComponents.length} out of ${data.length} components for type: $componentType',
          );
        }

        final hasMore = parsedComponents.length == pageLength;

        return ComponentPageResult(
          items: parsedComponents,
          page: page,
          pageLength: pageLength,
          hasMore: hasMore,
        );
      } else {
        if (kDebugMode) {
          print(
            'Failed to load components: Status code ${response.statusCode}',
          );
          print('Response data: ${response.data}');
        }
        throw Exception(
          'Failed to load components: Status code ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException when fetching components: ${e.message}');
        if (e.response != null) {
          print('Response status: ${e.response?.statusCode}');
          print('Response data: ${e.response?.data}');
          try {
            final responseData = e.response?.data;
            if (responseData is Map<String, dynamic>) {
              print('Validation errors:');
              responseData.forEach((key, value) {
                print('  $key: $value');
              });
            }
          } catch (_) {}
        }
      }
      rethrow;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching components: $e');
      }
      rethrow;
    }
  }

  Map<String, dynamic> _buildRequestBody(
    ComponentType componentType, {
    required int page,
    required int pageLength,
  }) {
    return {
      r'$type': _mapTypeToDiscriminator(componentType),
      'Type': [_mapTypeToBackendEnum(componentType)],
      'Paging': true,
      'Page': page,
      'PageLength': pageLength,
    };
  }

  List<BaseComponent> _parseComponents(
    List<dynamic> data,
    ComponentType componentType,
  ) {
    return data
        .map((json) {
          try {
            final typeString = (json['type'] ?? json['Type'])
                ?.toString()
                .toUpperCase();
            if (kDebugMode && typeString == null) {
              print(
                'Warning: Component missing type field for $componentType: ${json.keys}',
              );
            }
            switch (typeString) {
              case 'CPU':
                return CPUComponent.fromJson(json);
              case 'GPU':
                return GPUComponent.fromJson(json);
              case 'MOTHERBOARD':
                return MotherboardComponent.fromJson(json);
              case 'MEMORY':
              case 'RAM':
                return MemoryComponent.fromJson(json);
              case 'STORAGE':
                return StorageComponent.fromJson(json);
              case 'POWERSUPPLY':
              case 'PSU':
              case 'POWER_SUPPLY':
                return PowerSupplyComponent.fromJson(json);
              case 'CASE':
              case 'PCCASE':
                return CaseComponent.fromJson(json);
              case 'COOLER':
                return CoolerComponent.fromJson(json);
              case 'CASEFAN':
              case 'CASE_FAN':
                return CaseFanComponent.fromJson(json);
              case 'MONITOR':
                return MonitorComponent.fromJson(json);
              default:
                if (kDebugMode) {
                  print(
                    'Unsupported component type received for $componentType: $typeString',
                  );
                  print('Component data: ${json['name'] ?? json['Name']}');
                }
                return null;
            }
          } catch (e, stackTrace) {
            if (kDebugMode) {
              print('Error parsing component: $e');
              print('Component JSON: $json');
              print('Stack trace: $stackTrace');
            }
            return null;
          }
        })
        .whereType<BaseComponent>()
        .toList();
  }

  /// Fetches all components of all types from the backend.
  Future<List<BaseComponent>> getAllComponents() async {
    // Fetch all component types in parallel
    final results = await Future.wait([
      getComponents(ComponentType.cpu),
      getComponents(ComponentType.gpu),
      getComponents(ComponentType.motherboard),
      getComponents(ComponentType.ram),
      getComponents(ComponentType.storage),
      getComponents(ComponentType.psu),
      getComponents(ComponentType.cooler),
      getComponents(ComponentType.caseFan),
      getComponents(ComponentType.pcCase),
      getComponents(ComponentType.monitor),
    ]);

    // Flatten the list of lists into a single list
    return results.expand((list) => list).toList();
  }
}

/// Provider for ComponentService using authenticated Dio.
final componentServiceProvider = Provider.autoDispose<ComponentService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return ComponentService(dio);
});

/// Provider that fetches components by type (with caching, loading/error support).
final componentsProvider = FutureProvider.autoDispose
    .family<List<BaseComponent>, ComponentType>((ref, type) {
      final componentService = ref.watch(componentServiceProvider);
      return componentService.getComponents(type);
    });

/// Provider that fetches all components (all types combined).
final allComponentsProvider = FutureProvider.autoDispose<List<BaseComponent>>((
  ref,
) {
  final componentService = ref.watch(componentServiceProvider);
  return componentService.getAllComponents();
});

@immutable
class ComponentPagingState {
  static const Object _sentinel = Object();

  final List<BaseComponent> items;
  final bool isLoading;
  final bool isRefreshing;
  final bool hasMore;
  final int currentPage;
  final bool hasLoadedAtLeastOnce;
  final String? errorMessage;
  final bool isLoadMoreError;

  bool get isInitialLoading => !hasLoadedAtLeastOnce && isLoading;

  ComponentPagingState({
    required List<BaseComponent> items,
    required this.isLoading,
    required this.isRefreshing,
    required this.hasMore,
    required this.currentPage,
    required this.hasLoadedAtLeastOnce,
    required this.isLoadMoreError,
    this.errorMessage,
  }) : items = List.unmodifiable(items);

  factory ComponentPagingState.initial() => ComponentPagingState(
    items: const [],
    isLoading: false,
    isRefreshing: false,
    hasMore: true,
    currentPage: 0,
    hasLoadedAtLeastOnce: false,
    errorMessage: null,
    isLoadMoreError: false,
  );

  ComponentPagingState copyWith({
    List<BaseComponent>? items,
    bool? isLoading,
    bool? isRefreshing,
    bool? hasMore,
    int? currentPage,
    bool? hasLoadedAtLeastOnce,
    bool? isLoadMoreError,
    Object? errorMessage = _sentinel,
  }) {
    return ComponentPagingState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      hasLoadedAtLeastOnce: hasLoadedAtLeastOnce ?? this.hasLoadedAtLeastOnce,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isLoadMoreError: isLoadMoreError ?? this.isLoadMoreError,
    );
  }
}

class ComponentPagingNotifier extends StateNotifier<ComponentPagingState> {
  ComponentPagingNotifier(
    this._service,
    this._componentType, {
    this.pageLength = _defaultComponentPageLength,
  }) : super(ComponentPagingState.initial());

  final ComponentService _service;
  final ComponentType _componentType;
  final int pageLength;
  bool _isDisposed = false;

  Future<void> ensurePage(int page) {
    final safePage = page < 1 ? 1 : page;
    if (state.isLoading && state.currentPage == safePage) {
      return Future.value();
    }
    if (state.hasLoadedAtLeastOnce &&
        state.currentPage == safePage &&
        !state.isRefreshing) {
      return Future.value();
    }
    return _loadPage(reset: true, targetPage: safePage);
  }

  Future<void> goToPage(int page) => _loadPage(reset: true, targetPage: page);

  Future<void> refresh() {
    final targetPage = state.currentPage > 0 ? state.currentPage : 1;
    return _loadPage(reset: true, targetPage: targetPage);
  }

  Future<void> loadMore() {
    if (!state.hasMore) return Future.value();
    final nextPage = state.currentPage + 1;
    return _loadPage(reset: true, targetPage: nextPage);
  }

  Future<void> retry() {
    final targetPage = state.currentPage > 0 ? state.currentPage : 1;
    return _loadPage(reset: true, targetPage: targetPage);
  }

  Future<void> _loadPage({required bool reset, int? targetPage}) async {
    if (_isDisposed) return;
    if (state.isLoading) return;
    if (!reset && !state.hasMore) return;

    final nextPage = (targetPage ?? (reset ? 1 : state.currentPage + 1)).clamp(
      1,
      0x7fffffff,
    );
    final previousItems = state.items;

    state = state.copyWith(
      isLoading: true,
      isRefreshing: reset && state.hasLoadedAtLeastOnce,
      errorMessage: reset ? null : state.errorMessage,
      isLoadMoreError: false,
    );

    try {
      final pageResult = await _service.getComponentsPage(
        _componentType,
        page: nextPage,
        pageLength: pageLength,
      );

      final updatedItems = reset
          ? pageResult.items
          : [...previousItems, ...pageResult.items];

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
        isRefreshing: false,
        hasMore: pageResult.hasMore && pageResult.items.isNotEmpty,
        currentPage: nextPage,
        hasLoadedAtLeastOnce: true,
        errorMessage: null,
        isLoadMoreError: false,
      );
    } catch (e) {
      final message = e is DioException
          ? (e.message ?? 'Failed to load components')
          : e.toString();

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: message,
        isLoadMoreError: !reset && previousItems.isNotEmpty,
      );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

final componentPagingProvider = StateNotifierProvider.autoDispose
    .family<ComponentPagingNotifier, ComponentPagingState, ComponentType>((
      ref,
      type,
    ) {
      final service = ref.watch(componentServiceProvider);
      return ComponentPagingNotifier(service, type);
    });

/// Service for fetching component compatibility information.
class ComponentCompatibilityService {
  final Dio _dio;

  ComponentCompatibilityService(this._dio);

  /// Fetches compatible component IDs for a given component ID.
  /// Returns a set of component IDs that are compatible with the given component.
  Future<Set<String>> getCompatibleComponentIds(String componentId) async {
    try {
      // Validate GUID format before making request
      if (componentId.isEmpty || componentId.trim().isEmpty) {
        if (kDebugMode) {
          print('Empty componentId provided');
        }
        return {};
      }

      // Validate GUID format
      final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (!guidPattern.hasMatch(componentId)) {
        if (kDebugMode) {
          print('Invalid GUID format for componentId: $componentId');
        }
        return {};
      }

      final url = '$apiBaseUrl/ComponentCompatibilities/get';
      // Backend expects List<Guid>?, so we send the GUID as a string in an array
      // JSON serialization will handle the conversion
      final body = {
        'ComponentId': [componentId], // Backend will parse this as List<Guid>
        'Paging': false,
      };

      if (kDebugMode) {
        print('Fetching compatible components for: $componentId');
      }

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> compatibilities = response.data;
        final compatibleIds = compatibilities
            .map(
              (c) => (c['compatibleComponentId'] ?? c['CompatibleComponentId'])
                  ?.toString(),
            )
            .whereType<String>()
            .toSet();

        if (kDebugMode) {
          print(
            'Found ${compatibleIds.length} compatible components for $componentId',
          );
        }

        return compatibleIds;
      }

      if (kDebugMode) {
        print(
          'Unexpected response status or format: ${response.statusCode}, data type: ${response.data.runtimeType}',
        );
      }

      return {};
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching compatible components for $componentId: $e');
        if (e is DioException) {
          print('Status code: ${e.response?.statusCode}');
          print('Response data: ${e.response?.data}');
        }
      }
      return {};
    }
  }

  /// Fetches compatible component IDs for multiple components.
  /// Returns a map of componentId -> Set of compatible component IDs.
  Future<Map<String, Set<String>>> getCompatibleComponentIdsBatch(
    List<String> componentIds,
  ) async {
    if (componentIds.isEmpty) return {};

    final Map<String, Set<String>> result = {};

    // Fetch compatibilities for each component
    for (final componentId in componentIds) {
      try {
        final compatibleIds = await getCompatibleComponentIds(componentId);
        result[componentId] = compatibleIds;
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching compatibilities for $componentId: $e');
        }
        result[componentId] = {};
      }
    }

    return result;
  }

  /// Checks if a component is compatible with any of the selected components in the build.
  /// Returns true if the component is compatible with at least one selected component.
  Future<bool> isCompatibleWithBuild(
    String componentId,
    List<String> selectedComponentIds,
  ) async {
    if (selectedComponentIds.isEmpty)
      return true; // No selection means all are compatible

    // Get all compatible IDs for this component
    final compatibleIds = await getCompatibleComponentIds(componentId);

    // Check if any selected component is in the compatible list
    return selectedComponentIds.any(
      (selectedId) => compatibleIds.contains(selectedId),
    );
  }

  /// Batch checks compatibility for multiple components with selected components.
  /// Returns a map of componentId -> isCompatible.
  /// This is more efficient than checking each component individually.
  Future<Map<String, bool>> batchCheckCompatibilityWithBuild(
    List<String> componentIds,
    List<String> selectedComponentIds,
  ) async {
    if (selectedComponentIds.isEmpty) {
      // If no selection, all components are compatible
      return {for (var id in componentIds) id: true};
    }

    if (componentIds.isEmpty) return {};

    // Filter out invalid/empty component IDs
    final validComponentIds = componentIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();

    if (validComponentIds.isEmpty) return {};

    final Map<String, bool> result = {};

    // Fetch compatibilities sequentially to avoid rate limiting
    // Process one at a time with delays to be respectful to the server
    for (final componentId in validComponentIds) {
      try {
        // Validate GUID format before making request
        if (!_isValidGuid(componentId)) {
          if (kDebugMode) {
            print('Invalid GUID format for componentId: $componentId');
          }
          result[componentId] = false;
          continue;
        }

        final compatibleIds = await getCompatibleComponentIds(componentId);
        final isCompatible = selectedComponentIds.any(
          (selectedId) => compatibleIds.contains(selectedId),
        );
        result[componentId] = isCompatible;

        // Add delay between requests to avoid rate limiting
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        if (kDebugMode) {
          print('Error checking compatibility for $componentId: $e');
        }
        result[componentId] = false;
        // Continue with next component even if one fails
      }
    }

    return result;
  }

  /// Validates if a string is a valid GUID format
  bool _isValidGuid(String guid) {
    final guidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return guidPattern.hasMatch(guid);
  }
}

/// Provider for ComponentCompatibilityService using authenticated Dio.
final componentCompatibilityServiceProvider =
    Provider.autoDispose<ComponentCompatibilityService>((ref) {
      final dio = ref.watch(authProvider.notifier).getDioInstance();
      return ComponentCompatibilityService(dio);
    });

/// Provider that gets compatible component IDs for a single component.
final compatibleComponentIdsProvider = FutureProvider.autoDispose
    .family<Set<String>, String>((ref, componentId) async {
      final service = ref.watch(componentCompatibilityServiceProvider);
      return await service.getCompatibleComponentIds(componentId);
    });

/// Provider that checks if a component is compatible with selected components.
/// Takes componentId and selectedComponentIds, returns true if compatible.
final componentCompatibilityCheckProvider = FutureProvider.autoDispose
    .family<bool, ({String componentId, List<String> selectedIds})>((
      ref,
      params,
    ) async {
      final service = ref.watch(componentCompatibilityServiceProvider);

      if (params.selectedIds.isEmpty)
        return true; // No selection means compatible

      return await service.isCompatibleWithBuild(
        params.componentId,
        params.selectedIds,
      );
    });

/// Provider that batch checks compatibility for multiple components.
/// Takes list of componentIds and selectedComponentIds, returns map of componentId -> isCompatible.
/// This is more efficient than checking each component individually.
final batchCompatibilityCheckProvider = FutureProvider.autoDispose
    .family<
      Map<String, bool>,
      ({List<String> componentIds, List<String> selectedIds})
    >((ref, params) async {
      final service = ref.watch(componentCompatibilityServiceProvider);

      return await service.batchCheckCompatibilityWithBuild(
        params.componentIds,
        params.selectedIds,
      );
    });
