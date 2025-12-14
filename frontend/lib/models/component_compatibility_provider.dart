/// This file defines the state management for ComponentCompatibility operations.
///
/// It uses Riverpod to create providers that handle fetching and managing
/// component compatibilities from the backend.
library;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/component_compatibility_model.dart';

/// A service class to handle API requests related to component compatibilities.
class ComponentCompatibilityService {
  final Dio _dio;

  ComponentCompatibilityService(this._dio);

  /// Creates a new component compatibility on the backend.
  /// Admin only.
  Future<String> createComponentCompatibility({
    required String componentId,
    required String compatibleComponentId,
  }) async {
    try {
      final response = await _dio.post('$apiBaseUrl/ComponentCompatibilities/add', data: {
        'componentId': componentId,
        'compatibleComponentId': compatibleComponentId,
      });

      if (response.data is Map<String, dynamic> && response.data.containsKey('id')) {
        return response.data['id'];
      } else {
        throw Exception('Failed to create component compatibility: ID not found in response.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing component compatibility's note.
  /// Admin only.
  Future<void> updateComponentCompatibility(String id, {String? note}) async {
    try {
      await _dio.put('$apiBaseUrl/ComponentCompatibilities/$id', data: {
        if (note != null) 'note': note,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a single component compatibility by its ID.
  Future<ComponentCompatibility> getComponentCompatibility(String id) async {
    try {
      final response = await _dio.get('$apiBaseUrl/ComponentCompatibilities/$id');
      return ComponentCompatibility.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches component compatibilities from the backend based on a given filter map.
  Future<List<ComponentCompatibility>> getComponentCompatibilities({
    List<String>? componentIds,
    List<String>? compatibleComponentIds,
    String? query,
    String? orderBy,
    String sortDirection = 'asc',
    bool paging = false,
    int? page,
    int? pageLength,
  }) async {
    try {
      final data = <String, dynamic>{
        'paging': paging,
        'sortDirection': sortDirection,
      };

      if (componentIds != null && componentIds.isNotEmpty) {
        data['componentId'] = componentIds;
      }
      if (compatibleComponentIds != null && compatibleComponentIds.isNotEmpty) {
        data['compatibleComponentId'] = compatibleComponentIds;
      }
      if (query != null && query.isNotEmpty) {
        data['query'] = query;
      }
      if (orderBy != null && orderBy.isNotEmpty) {
        data['orderBy'] = orderBy;
      }
      if (paging && page != null && pageLength != null) {
        data['page'] = page;
        data['pageLength'] = pageLength;
      }

      final response = await _dio.post('$apiBaseUrl/ComponentCompatibilities/get', data: data);
      final List<dynamic> compatibilitiesJson = response.data as List<dynamic>? ?? [];

      return compatibilitiesJson
          .map((json) => ComponentCompatibility.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a component compatibility.
  /// Admin only.
  Future<void> deleteComponentCompatibility(String id) async {
    try {
      await _dio.delete('$apiBaseUrl/ComponentCompatibilities/$id');
    } catch (e) {
      rethrow;
    }
  }

  /// Gets all compatible component IDs for a given component.
  /// Fetches compatibilities in both directions to ensure all links are found.
  Future<List<String>> getCompatibleComponentIds(String componentId) async {
    try {
      final results = await Future.wait([
        getComponentCompatibilities(
          componentIds: [componentId],
          paging: false,
        ),
        getComponentCompatibilities(
          compatibleComponentIds: [componentId],
          paging: false,
        ),
      ]);

      final forwardCompatibilities = results[0];
      final backwardCompatibilities = results[1];

      final ids = <String>{};

      for (var c in forwardCompatibilities) {
        if (c.compatibleComponentId.isNotEmpty) {
          ids.add(c.compatibleComponentId);
        }
      }

      for (var c in backwardCompatibilities) {
        if (c.componentId.isNotEmpty) {
          ids.add(c.componentId);
        }
      }

      return ids.toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if two components are compatible.
  /// Checks both directions.
  Future<bool> areComponentsCompatible(String componentId1, String componentId2) async {
    try {
      final results = await Future.wait([
        getComponentCompatibilities(
          componentIds: [componentId1],
          compatibleComponentIds: [componentId2],
          paging: false,
        ),
        getComponentCompatibilities(
          componentIds: [componentId2],
          compatibleComponentIds: [componentId1],
          paging: false,
        ),
      ]);
      
      return results[0].isNotEmpty || results[1].isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Gets all components that are compatible with the given component.
  /// Returns a map of compatibility ID to compatible component ID.
  /// Note: Returns only forward direction compatibilities to maintain map structure safely.
  Future<Map<String, String>> getCompatibleComponents(String componentId) async {
    try {
      final compatibilities = await getComponentCompatibilities(
        componentIds: [componentId],
        paging: false,
      );
      final Map<String, String> result = {};
      for (var compatibility in compatibilities) {
        result[compatibility.id] = compatibility.compatibleComponentId;
      }
      return result;
    } catch (e) {
      return {};
    }
  }
}

/// A provider that creates an instance of [ComponentCompatibilityService] with an authenticated Dio client.
final componentCompatibilityServiceProvider = Provider<ComponentCompatibilityService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return ComponentCompatibilityService(dio);
});

/// A provider that fetches a single component compatibility by its ID.
final componentCompatibilityProvider = FutureProvider.family<ComponentCompatibility, String>(
  (ref, id) async {
    final service = ref.watch(componentCompatibilityServiceProvider);
    return service.getComponentCompatibility(id);
  },
);

/// A provider that fetches component compatibilities based on filters.
final componentCompatibilitiesProvider = FutureProvider.family<List<ComponentCompatibility>, Map<String, dynamic>>(
  (ref, filters) async {
    final service = ref.watch(componentCompatibilityServiceProvider);
    return service.getComponentCompatibilities(
      componentIds: filters['componentIds'] as List<String>?,
      compatibleComponentIds: filters['compatibleComponentIds'] as List<String>?,
      query: filters['query'] as String?,
      orderBy: filters['orderBy'] as String?,
      sortDirection: filters['sortDirection'] as String? ?? 'asc',
      paging: filters['paging'] as bool? ?? false,
      page: filters['page'] as int?,
      pageLength: filters['pageLength'] as int?,
    );
  },
);

/// A provider that fetches compatible component IDs for a given component.
final compatibleComponentIdsProvider = FutureProvider.family<List<String>, String>(
  (ref, componentId) async {
    final service = ref.watch(componentCompatibilityServiceProvider);
    return service.getCompatibleComponentIds(componentId);
  },
);

/// A provider that checks if two components are compatible.
final componentsCompatibilityCheckProvider = FutureProvider.family<bool, Map<String, String>>(
  (ref, componentIds) async {
    final service = ref.watch(componentCompatibilityServiceProvider);
    final componentId1 = componentIds['componentId1']!;
    final componentId2 = componentIds['componentId2']!;
    return service.areComponentsCompatible(componentId1, componentId2);
  },
);

