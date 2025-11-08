/// This file defines the state management for fetching PC builds from the backend.
///
/// It uses Riverpod to create providers that handle fetching lists of `Build`
/// objects, abstracting the API logic away from the UI widgets.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/explore_build_model.dart';

/// A service class to handle API requests related to builds.
class BuildService {
  final Dio _dio;

  BuildService(this._dio);

  /// Fetches builds from the backend based on a given filter map.
  Future<List<Build>> getBuilds(Map<String, dynamic> filter) async {
    try {
      debugPrint('Fetching builds with filter: $filter');
      final response = await _dio.post('$apiBaseUrl/Builds/get', data: filter);
      debugPrint('Get builds response status: ${response.statusCode}');
      
      final List<dynamic> buildsJson = response.data as List<dynamic>? ?? [];
      debugPrint('Received ${buildsJson.length} builds from backend');
      
      // Log component and image information from JSON before parsing
      for (var json in buildsJson) {
        if (json is Map<String, dynamic>) {
          final components = json['components'] ?? json['Components'];
          final imageUrl = json['imageUrl'] ?? json['ImageUrl'];
          final buildId = json['id'] ?? json['Id'];
          final buildName = json['name'] ?? json['Name'];
          debugPrint('Build $buildId ($buildName):');
          if (components != null) {
            debugPrint('  Components in JSON: ${components is List ? components.length : 'not a list'}');
            if (components is List && components.isNotEmpty) {
              debugPrint('  First component: ${components[0]}');
            }
          } else {
            debugPrint('  NO components in JSON');
          }
          if (imageUrl != null) {
            debugPrint('  ImageUrl in JSON: $imageUrl');
          } else {
            debugPrint('  NO imageUrl in JSON');
          }
        }
      }
      
      final builds = buildsJson.map((json) {
        final build = Build.fromJson(json);
        debugPrint('Build ${build.id} (${build.name}): parsed ${build.components.length} components, imageUrl=${build.imageUrl}');
        if (build.components.isNotEmpty) {
          debugPrint('  Components: ${build.components.map((c) => '${c.type}: ${c.name}').join(', ')}');
        } else {
          debugPrint('  ⚠️ WARNING: Build has 0 components after parsing!');
          // Extra logging for debugging
          final componentsInJson = json['components'] ?? json['Components'];
          if (componentsInJson != null) {
            debugPrint('  ⚠️ But JSON had components: ${componentsInJson is List ? componentsInJson.length : 'not a list'}');
            if (componentsInJson is List && componentsInJson.isNotEmpty) {
              debugPrint('  ⚠️ First component in JSON: ${componentsInJson[0]}');
            }
          }
        }
        return build;
      }).toList();
      
      // Log build statuses
      for (var build in builds) {
        debugPrint('Build ${build.id}: status=${build.status}, name=${build.name}, components=${build.components.length}');
      }
      
      return builds;
    } catch (e) {
      debugPrint('Error fetching builds: $e');
      if (e is DioException && e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Response status: ${e.response?.statusCode}');
      }
      // In case of an error, rethrow it to be handled by the provider.
      rethrow;
    }
  }

  /// Fetches a single build by its ID.
  Future<Build> getBuildById(String buildId) async {
    try {
      final response = await _dio.get('$apiBaseUrl/Builds/$buildId');
      // The response data is a single JSON object for the build.
      return Build.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  /// Creates a new build on the backend and returns its ID.
  Future<String> createBuild(Map<String, dynamic> buildData) async {
    try {
      debugPrint('BuildService.createBuild: Creating build with data: $buildData');
      final response = await _dio.post('$apiBaseUrl/Builds/add', data: buildData);
      debugPrint('BuildService.createBuild: Response status: ${response.statusCode}');
      debugPrint('BuildService.createBuild: Response data: ${response.data}');
      
      // The backend returns an object like: {"build": "...", "id": "..."}
      if (response.data is Map<String, dynamic> && response.data.containsKey('id')) {
        final buildId = response.data['id'];
        debugPrint('BuildService.createBuild: Build created with ID: $buildId');
        return buildId;
      } else {
        debugPrint('BuildService.createBuild: ERROR - ID not found in response');
        throw Exception('Failed to create build: ID not found in response.');
      }
    } catch (e) {
      debugPrint('BuildService.createBuild: Error: $e');
      if (e is DioException && e.response != null) {
        debugPrint('BuildService.createBuild: Response data: ${e.response?.data}');
        debugPrint('BuildService.createBuild: Response status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  /// Updates an existing build on the backend.
  Future<void> updateBuild(String buildId, Map<String, dynamic> data) async {
    try {
      debugPrint('Updating build $buildId with data: $data');
      final response = await _dio.put('$apiBaseUrl/Builds/$buildId', data: data);
      debugPrint('Update build response: ${response.statusCode} - ${response.data}');
    } catch (e) {
      debugPrint('Error updating build: $e');
      if (e is DioException && e.response != null) {
        debugPrint('Response data: ${e.response?.data}');
        debugPrint('Response status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  /// Adds a component to an existing build.
  Future<void> addComponentToBuild(String buildId, String componentId, int quantity) async {
    try {
      debugPrint('BuildService.addComponentToBuild: Adding component $componentId to build $buildId');
      final response = await _dio.post('$apiBaseUrl/BuildComponents/add', data: {
        'buildId': buildId, 
        'componentId': componentId, 
        'quantity': quantity
      });
      debugPrint('BuildService.addComponentToBuild: Component added successfully. Response status: ${response.statusCode}');
    } catch (e) {
      debugPrint('BuildService.addComponentToBuild: Error adding component: $e');
      if (e is DioException && e.response != null) {
        debugPrint('BuildService.addComponentToBuild: Response data: ${e.response?.data}');
        debugPrint('BuildService.addComponentToBuild: Response status: ${e.response?.statusCode}');
      }
      rethrow;
    }
  }

  /// Gets a BuildInteraction by userId and buildId
  Future<String?> getBuildInteractionId(String buildId, String userId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/BuildInteractions/get', data: {
        'UserId': [userId],
        'BuildId': [buildId],
        'Paging': false,
      });
      if (response.data is List && (response.data as List).isNotEmpty) {
        final interaction = (response.data as List).first;
        if (interaction is Map<String, dynamic> && interaction.containsKey('id')) {
          return interaction['id'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Updates an existing BuildInteraction rating
  Future<Map<String, dynamic>> updateBuildInteractionRating(String interactionId, double rating) async {
    try {
      // Backend expects 0-100 scale; UI works with 0-5 stars
      final scaled = (rating * 20).round();
      final response = await _dio.put('$apiBaseUrl/BuildInteractions/$interactionId', data: {
        'IsWishlisted': null,
        'IsLiked': rating >= 3.0, // Consider 3+ stars as liked
        'Rating': scaled,
      });
      return (response.data is Map<String, dynamic>)
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (e) {
      rethrow;
    }
  }

  /// Submits a rating for a build and returns the updated rating aggregate
  /// Handles both creating new interactions and updating existing ones
  Future<Map<String, dynamic>> rateBuild(String buildId, double rating, String userId) async {
    try {
      // Backend expects 0-100 scale; UI works with 0-5 stars
      final scaled = (rating * 20).round();
      final response = await _dio.post('$apiBaseUrl/BuildInteractions/add', data: {
        'UserId': userId,
        'BuildId': buildId,
        'IsWishlisted': false,
        'IsLiked': rating >= 3.0, // Consider 3+ stars as liked
        'Rating': scaled,
      });
      return (response.data is Map<String, dynamic>)
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (e) {
      // Check if it's an "already exists" error (400 Bad Request)
      bool isAlreadyExistsError = false;
      
      if (e is DioException) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 400) {
          // Try to extract error message from response
          final responseData = e.response?.data;
          String errorMessage = '';
          
          // Try different ways to extract the error message
          if (responseData is Map) {
            errorMessage = (responseData['message'] ?? 
                           responseData['Message'] ?? 
                           responseData['error'] ?? 
                           responseData['Error'] ??
                           '').toString().toLowerCase();
          } else if (responseData is String) {
            errorMessage = responseData.toLowerCase();
          }
          
          // Also check the exception message
          if (errorMessage.isEmpty) {
            errorMessage = (e.message ?? '').toLowerCase();
          }
          
          // Check if it's the "already exists" error
          isAlreadyExistsError = errorMessage.contains('already exists') || 
                                errorMessage.contains('interaction already') ||
                                errorMessage.contains('build already interacted');
        }
      }
      
      if (isAlreadyExistsError) {
        // Get the existing interaction ID and update it instead
        try {
          final interactionId = await getBuildInteractionId(buildId, userId);
          if (interactionId != null) {
            return await updateBuildInteractionRating(interactionId, rating);
          }
        } catch (updateError) {
          // If update also fails, rethrow the original error
          rethrow;
        }
      }
      rethrow;
    }
  }
}

/// A provider that creates an instance of [BuildService] with an authenticated Dio client.
final buildServiceProvider = Provider<BuildService>((ref) {
  // Get the authorized Dio instance from the authProvider to make authenticated requests.
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return BuildService(dio);
});

/// A provider that fetches a list of builds for a specific user.
///
/// It uses `FutureProvider.family` to pass the `userId` as a parameter.
/// This allows us to fetch builds for any user, not just the logged-in one.
final userBuildsProvider = FutureProvider.family<List<Build>, String>((ref, userId) async {
  final buildService = ref.watch(buildServiceProvider);
  // We want all builds for the profile page, so no paging.
  return buildService.getBuilds({'userId': [userId], 'paging': false});
});

/// A provider that fetches all public builds for the "Explore" page.
final allBuildsProvider = FutureProvider<List<Build>>((ref) async {
  final buildService = ref.watch(buildServiceProvider);
  // Fetch only published builds and disable paging to get all of them.
  return buildService.getBuilds({'status': ['PUBLISHED'], 'paging': false});
});

/// A provider that fetches the details of a single build by its ID.
final buildDetailProvider = FutureProvider.family<Build, String>((ref, buildId) async {
  final buildService = ref.watch(buildServiceProvider);
  // Use the new, more direct method to fetch a single build.
  return buildService.getBuildById(buildId);
});
