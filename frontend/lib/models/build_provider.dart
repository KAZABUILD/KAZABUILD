/// This file defines the state management for fetching PC builds from the backend.
///
/// It uses Riverpod to create providers that handle fetching lists of `Build`
/// objects, abstracting the API logic away from the UI widgets.
library;

import 'package:dio/dio.dart';
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
      final response = await _dio.post('$apiBaseUrl/Builds/get', data: filter);

      final List<dynamic> buildsJson = response.data as List<dynamic>? ?? [];
      return buildsJson.map((json) => Build.fromJson(json)).toList();
    } catch (e) {
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
      final response = await _dio.post('$apiBaseUrl/Builds/add', data: buildData);
      // The backend returns an object like: {"build": "...", "id": "..."}
      if (response.data is Map<String, dynamic> && response.data.containsKey('id')) {
        return response.data['id'];
      } else {
        throw Exception('Failed to create build: ID not found in response.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing build on the backend.
  Future<void> updateBuild(String buildId, Map<String, dynamic> data) async {
    try {
      await _dio.put('$apiBaseUrl/Builds/$buildId', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a component to an existing build.
  Future<void> addComponentToBuild(String buildId, String componentId, int quantity) async {
    try {
      await _dio.post('$apiBaseUrl/BuildComponents/add', data: {'buildId': buildId, 'componentId': componentId, 'quantity': quantity});
    } catch (e) { rethrow; }
  }

  /// Submits a rating for a build and returns the updated rating aggregate
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
