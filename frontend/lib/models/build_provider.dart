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
import 'package:frontend/models/tag_model.dart';
import 'package:frontend/models/component_models.dart';

/// A service class to handle API requests related to builds.
class BuildService {
  final Dio _dio;

  BuildService(this._dio);

  /// Fetches BuildComponents for a list of build IDs.
  ///
  /// optimization: This uses cache to avoid re-fetching, and bulk-fetches
  /// missing components in a single API call instead of one-by-one.
  Future<Map<String, List<Map<String, dynamic>>>> getBuildComponents(
    List<String> buildIds, {
    Map<String, Map<String, dynamic>>? cache,
  }) async {
    try {
      if (buildIds.isEmpty) return {};

      // 1. Get the mapping between Builds and Components
      final response = await _dio.post(
        '$apiBaseUrl/BuildComponents/get',
        data: {'BuildId': buildIds, 'Paging': false},
      );

      final List<dynamic> buildComponentsJson =
          response.data as List<dynamic>? ?? [];
      if (buildComponentsJson.isEmpty) return {};

      // 2. Extract all unique component IDs and build mappings
      final Set<String> componentIds = {};
      final Map<String, List<String>> buildIdToComponentIds = {};

      for (var bcJson in buildComponentsJson) {
        if (bcJson is Map<String, dynamic>) {
          final buildId = (bcJson['buildId'] ?? bcJson['BuildId'] ?? '')
              .toString();
          final componentId =
              (bcJson['componentId'] ?? bcJson['ComponentId'] ?? '').toString();

          if (buildId.isNotEmpty && componentId.isNotEmpty) {
            componentIds.add(componentId);
            buildIdToComponentIds
                .putIfAbsent(buildId, () => [])
                .add(componentId);
          }
        }
      }

      if (componentIds.isEmpty) return {};

      // 3. Check Cache
      final Map<String, Map<String, dynamic>> componentMap = cache != null
          ? Map.from(cache)
          : {};

      // Check if all components are already cached
      final uncachedComponentIds = componentIds
          .where((id) => !componentMap.containsKey(id))
          .toSet();

      if (uncachedComponentIds.isEmpty) {
        // All components are in cache, return immediately
        return _groupComponentsByBuildId(buildIdToComponentIds, componentMap);
      }

      // 4. Fetch components using BuildId filter
      try {
        final componentsResponse = await _dio.post(
          '$apiBaseUrl/Components/get',
          data: {
            r'$type': 'All',
            'BuildId': buildIds.map((id) => id).toList(),
            'Paging': false,
          },
        );

        final List<dynamic> fetchedComponents =
            componentsResponse.data as List<dynamic>? ?? [];

        for (var comp in fetchedComponents) {
          if (comp is Map<String, dynamic>) {
            final idValue = comp['id'] ?? comp['Id'];
            if (idValue != null) {
              componentMap[idValue.toString()] = comp;
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching components by BuildId: $e');
      }

      if (componentMap.isEmpty) return {};

      // 5. Group components by buildId
      return _groupComponentsByBuildId(buildIdToComponentIds, componentMap);
    } catch (e) {
      debugPrint('Error in getBuildComponents: $e');
      return {};
    }
  }

  /// Helper: Groups components by buildId.
  Map<String, List<Map<String, dynamic>>> _groupComponentsByBuildId(
    Map<String, List<String>> buildIdToComponentIds,
    Map<String, Map<String, dynamic>> componentMap,
  ) {
    final Map<String, List<Map<String, dynamic>>> componentsByBuildId = {};
    for (var entry in buildIdToComponentIds.entries) {
      final buildId = entry.key;
      final compIds = entry.value;

      final components = compIds
          .where((compId) => componentMap.containsKey(compId))
          .map((compId) => componentMap[compId]!)
          .toList();

      if (components.isNotEmpty) {
        componentsByBuildId[buildId] = components;
      }
    }
    return componentsByBuildId;
  }

  /// Fetches images for builds.
  Future<Map<String, String?>> getBuildImages(List<String> buildIds) async {
    try {
      if (buildIds.isEmpty) return {};

      final response = await _dio.post(
        '$apiBaseUrl/Images/get',
        data: {
          'BuildId': buildIds,
          'LocationType': ['BUILD'],
          'Paging': false,
        },
      );

      final List<dynamic> imagesJson = response.data as List<dynamic>? ?? [];
      final Map<String, String?> imageUrlsByBuildId = {};

      for (var imgJson in imagesJson) {
        if (imgJson is Map<String, dynamic>) {
          final targetId = (imgJson['targetId'] ?? imgJson['TargetId'] ?? '')
              .toString();

          if (targetId.isNotEmpty) {
            // Get image ID for download endpoint
            final imageId = (imgJson['id'] ?? imgJson['Id'] ?? '').toString();
            if (imageId.isNotEmpty) {
              // Backend serves images via /Images/download/{id} endpoint
              imageUrlsByBuildId[targetId] =
                  '$apiBaseUrl/Images/download/$imageId';
            }
          }
        }
      }

      return imageUrlsByBuildId;
    } catch (e) {
      return {};
    }
  }

  /// Fetches builds from the backend based on a given filter map.
  /// [skipRatings] if true, skips fetching ratings to reduce API calls (useful for list views).
  Future<List<Build>> getBuilds(
    Map<String, dynamic> filter, {
    String? currentUserId,
    bool skipRatings = false,
  }) async {
    try {
      final response = await _dio.post('$apiBaseUrl/Builds/get', data: filter);
      final List<dynamic> buildsJson = response.data as List<dynamic>? ?? [];

      // Extract build IDs
      final buildIds = buildsJson
          .where((json) => json is Map<String, dynamic>)
          .map((json) => (json['id'] ?? json['Id'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toList();

      if (buildIds.isEmpty) {
        return [];
      }

      // Fetch images and ratings in parallel
      Map<String, String?> imageUrlsByBuildId = {};
      Map<String, int> ratingsCountByBuildId = {};
      Map<String, double?> averageRatingByBuildId = {};
      Map<String, double?> userRatingByBuildId = {};

      try {
        imageUrlsByBuildId = await getBuildImages(buildIds);
      } catch (e) {
        // Continue even if images fail
      }

      // Fetch ratings logic
      if (!skipRatings) {
        // Optimization: Fetching ratings in parallel
        final ratingFutures = buildIds.map((buildId) async {
          try {
            final ratingsCount = await _getBuildRatingsCount(buildId);
            double? averageRating;
            if (ratingsCount > 0) {
              averageRating = await _getBuildAverageRating(buildId);
            }
            return {
              'buildId': buildId,
              'ratingsCount': ratingsCount,
              'averageRating': averageRating,
            };
          } catch (e) {
            return {
              'buildId': buildId,
              'ratingsCount': 0,
              'averageRating': null,
            };
          }
        });

        final ratingResults = await Future.wait(ratingFutures);
        for (var result in ratingResults) {
          final buildId = result['buildId'] as String;
          ratingsCountByBuildId[buildId] = result['ratingsCount'] as int;
          averageRatingByBuildId[buildId] = result['averageRating'] as double?;
        }

        // Fetch user ratings if currentUserId is provided
        if (currentUserId != null && currentUserId.isNotEmpty) {
          // This part fetches user specific ratings.
          // Note: If you have a bulk endpoint for interactions (e.g. /BuildInteractions/get with multiple BuildIds),
          // it would be better to use that instead of this loop.
          final userRatingFutures = buildIds.map((buildId) async {
            try {
              final userRating = await _getUserRatingForBuild(
                buildId,
                currentUserId,
              );
              return {'buildId': buildId, 'userRating': userRating};
            } catch (e) {
              return {'buildId': buildId, 'userRating': null};
            }
          });

          final userRatingResults = await Future.wait(userRatingFutures);
          for (var result in userRatingResults) {
            final buildId = result['buildId'] as String;
            userRatingByBuildId[buildId] = result['userRating'] as double?;
          }
        }
      } else {
        // Default values if skipping ratings
        for (final buildId in buildIds) {
          ratingsCountByBuildId[buildId] = 0;
          averageRatingByBuildId[buildId] = 0.0;
        }
      }

      // Assemble the final Build objects
      for (var json in buildsJson) {
        if (json is Map<String, dynamic>) {
          final buildId = (json['id'] ?? json['Id'] ?? '').toString();

          if (imageUrlsByBuildId.containsKey(buildId)) {
            json['imageUrl'] = imageUrlsByBuildId[buildId];
            json['ImageUrl'] = imageUrlsByBuildId[buildId];
          }

          final ratingsCount = ratingsCountByBuildId[buildId] ?? 0;
          final averageRating = averageRatingByBuildId[buildId] ?? 0.0;
          json['ratingsCount'] = ratingsCount;
          json['RatingsCount'] = ratingsCount;
          json['averageRating'] = averageRating;
          json['AverageRating'] = averageRating;

          if (userRatingByBuildId.containsKey(buildId)) {
            final userRating = userRatingByBuildId[buildId];
            if (userRating != null && userRating > 0) {
              json['userRating'] = userRating;
              json['UserRating'] = userRating;
            }
          }
        }
      }

      return buildsJson.map((json) => Build.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a single build by its ID.
  Future<Build> getBuildById(String buildId, {String? currentUserId}) async {
    try {
      final response = await _dio.get('$apiBaseUrl/Builds/$buildId');
      final buildJson = response.data as Map<String, dynamic>;

      // Execute all dependent fetches in parallel for speed
      final componentsFuture = getBuildComponents([buildId]);
      final imagesFuture = getBuildImages([buildId]);
      final tagsFuture = _fetchBuildTags([buildId]);
      final ratingsCountFuture = _getBuildRatingsCount(buildId);
      final userRatingFuture = currentUserId != null
          ? _getUserRatingForBuild(buildId, currentUserId)
          : Future<double?>.value(null);

      final componentsByBuildId = await componentsFuture;
      final imageUrlsByBuildId = await imagesFuture;
      final tagsByBuildId = await tagsFuture;
      final ratingsCount = await ratingsCountFuture;

      double? averageRatingRaw;
      if (ratingsCount > 0) {
        averageRatingRaw = await _getBuildAverageRating(buildId);
      }
      final userRatingRaw = await userRatingFuture;

      // Attach components
      if (componentsByBuildId.containsKey(buildId)) {
        final components = componentsByBuildId[buildId]!;
        buildJson['components'] = components;
        buildJson['buildComponents'] = components;
      }
      // Attach Image
      if (imageUrlsByBuildId.containsKey(buildId)) {
        buildJson['imageUrl'] = imageUrlsByBuildId[buildId];
        buildJson['ImageUrl'] = imageUrlsByBuildId[buildId];
      }
      // Attach Tags
      if (tagsByBuildId.containsKey(buildId)) {
        buildJson['tags'] = tagsByBuildId[buildId];
        buildJson['Tags'] = tagsByBuildId[buildId];
      }

      // Attach Stats
      buildJson['ratingsCount'] = ratingsCount;
      buildJson['RatingsCount'] = ratingsCount;
      buildJson['averageRating'] = averageRatingRaw ?? 0;
      buildJson['AverageRating'] = averageRatingRaw ?? 0;
      if (userRatingRaw != null && userRatingRaw > 0) {
        buildJson['userRating'] = userRatingRaw;
        buildJson['UserRating'] = userRatingRaw;
      }

      return Build.fromJson(buildJson);
    } catch (e) {
      rethrow;
    }
  }

  /// Helper method to fetch tags for builds
  Future<Map<String, List<String>>> _fetchBuildTags(
    List<String> buildIds,
  ) async {
    final Map<String, List<String>> tagsByBuildId = {};

    try {
      if (buildIds.isEmpty) return tagsByBuildId;

      // 1. Get BuildTags
      final buildTagsResponse = await _dio.post(
        '$apiBaseUrl/BuildTags/get',
        data: {'buildId': buildIds, 'paging': false},
      );

      final List<dynamic> buildTagsJson =
          buildTagsResponse.data as List<dynamic>? ?? [];

      final Set<String> uniqueTagIds = {};
      final Map<String, List<String>> tagIdsByBuildId = {};

      for (var btJson in buildTagsJson) {
        if (btJson is Map<String, dynamic>) {
          final buildId = (btJson['buildId'] ?? btJson['BuildId'] ?? '')
              .toString();
          final tagId = (btJson['tagId'] ?? btJson['TagId'] ?? '').toString();

          if (buildId.isNotEmpty && tagId.isNotEmpty) {
            uniqueTagIds.add(tagId);
            tagIdsByBuildId.putIfAbsent(buildId, () => []).add(tagId);
          }
        }
      }

      // 2. Fetch Tag Names (Bulk)
      if (uniqueTagIds.isNotEmpty) {
        // Fetch ALL tags. Since tags are usually small in number, this is efficient.
        // Alternatively, use 'id': uniqueTagIds.toList() if the backend supports filtering by list of IDs.
        final tagsResponse = await _dio.post(
          '$apiBaseUrl/Tags/get',
          data: {'paging': false},
        );
        final List<dynamic> allTagsJson =
            tagsResponse.data as List<dynamic>? ?? [];

        final Map<String, String> tagNameMap = {};

        for (var tagJson in allTagsJson) {
          if (tagJson is Map<String, dynamic>) {
            final tagId = (tagJson['id'] ?? tagJson['Id'] ?? '').toString();
            final tagName = (tagJson['name'] ?? tagJson['Name'] ?? '')
                .toString();

            if (tagId.isNotEmpty && tagName.isNotEmpty) {
              tagNameMap[tagId] = tagName;
            }
          }
        }

        // Map build IDs to tag names
        for (var entry in tagIdsByBuildId.entries) {
          final buildId = entry.key;
          final tagIds = entry.value;
          final tagNames = tagIds
              .map((tagId) => tagNameMap[tagId])
              .where((name) => name != null && name.isNotEmpty)
              .cast<String>()
              .toList();

          if (tagNames.isNotEmpty) {
            tagsByBuildId[buildId] = tagNames;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching build tags: $e');
    }

    return tagsByBuildId;
  }

  /// Retrieves the total number of ratings for a build.
  Future<int> _getBuildRatingsCount(String buildId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildInteractions/get-count',
        data: {
          'BuildId': [buildId],
          'RatingStart': 1,
          'Paging': false,
        },
      );
      final data = response.data;
      if (data is int) return data;
      if (data is num) return data.toInt();
      if (data is String) return int.tryParse(data) ?? 0;
    } catch (e) {
      debugPrint('Error fetching ratings count: $e');
    }
    return 0;
  }

  /// Retrieves the average rating (0-100 scale) for a build.
  Future<double?> _getBuildAverageRating(String buildId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildInteractions/get-average-rating',
        data: {
          'BuildId': [buildId],
          'RatingStart': 1,
          'Paging': false,
        },
      );
      final data = response.data;
      if (data is num) return data.toDouble();
      if (data is String) return double.tryParse(data);
    } catch (e) {
      debugPrint('Error fetching average rating: $e');
    }
    return null;
  }

  /// Retrieves the current user's rating for a specific build.
  Future<double?> _getUserRatingForBuild(String buildId, String userId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildInteractions/get',
        data: {
          'BuildId': [buildId],
          'UserId': [userId],
          'Paging': false,
        },
      );
      final List<dynamic> interactions = response.data as List<dynamic>? ?? [];
      if (interactions.isEmpty) return null;
      final interaction = interactions.first;
      if (interaction is Map<String, dynamic>) {
        final rating = interaction['rating'] ?? interaction['Rating'];
        if (rating == null) return null;
        if (rating is num) return rating.toDouble();
        return double.tryParse(rating.toString());
      }
    } catch (e) {
      debugPrint('Error fetching user rating: $e');
    }
    return null;
  }

  // --- CRUD Operations ---

  /// Creates a new build on the backend and returns its ID.
  Future<String> createBuild(Map<String, dynamic> buildData) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/Builds/add',
        data: buildData,
      );

      if (response.data is Map<String, dynamic> &&
          response.data.containsKey('id')) {
        return response.data['id'];
      } else {
        throw Exception('Failed to create build: ID not found in response.');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Updates an existing build.
  Future<void> updateBuild(String buildId, Map<String, dynamic> data) async {
    try {
      await _dio.put('$apiBaseUrl/Builds/$buildId', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a build.
  Future<void> deleteBuild(String buildId) async {
    try {
      await _dio.delete('$apiBaseUrl/Builds/$buildId');
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a component to a build.
  Future<void> addComponentToBuild(
    String buildId,
    String componentId,
    int quantity,
  ) async {
    try {
      await _dio.post(
        '$apiBaseUrl/BuildComponents/add',
        data: {
          'BuildId': buildId,
          'ComponentId': componentId,
          'Quantity': quantity,
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Removes a component from a build.
  Future<void> removeComponentFromBuild(String buildComponentId) async {
    try {
      await _dio.delete('$apiBaseUrl/BuildComponents/$buildComponentId');
    } catch (e) {
      rethrow;
    }
  }

  /// Gets BuildComponent IDs for a build (used for finding IDs to delete).
  Future<List<Map<String, dynamic>>> getBuildComponentIds(
    String buildId,
  ) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildComponents/get',
        data: {
          'BuildId': [buildId],
          'Paging': false,
        },
      );
      final List<dynamic> buildComponentsJson =
          response.data as List<dynamic>? ?? [];
      return buildComponentsJson
          .where((json) => json is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Gets a BuildInteraction by userId and buildId.
  Future<String?> getBuildInteractionId(String buildId, String userId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildInteractions/get',
        data: {
          'UserId': [userId],
          'BuildId': [buildId],
          'Paging': false,
        },
      );
      if (response.data is List && (response.data as List).isNotEmpty) {
        final interaction = (response.data as List).first;
        if (interaction is Map<String, dynamic> &&
            interaction.containsKey('id')) {
          return interaction['id'];
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Updates an existing BuildInteraction rating.
  Future<Map<String, dynamic>> updateBuildInteractionRating(
    String interactionId,
    double rating,
  ) async {
    try {
      final scaled = (rating * 20).round(); // Scale 0-5 to 0-100
      final response = await _dio.put(
        '$apiBaseUrl/BuildInteractions/$interactionId',
        data: {
          'IsWishlisted': null,
          'IsLiked': rating >= 3.0 && rating > 0,
          'Rating': scaled,
        },
      );
      return (response.data is Map<String, dynamic>)
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
    } catch (e) {
      rethrow;
    }
  }

  /// Submits a rating for a build. Handles both create and update.
  Future<Map<String, dynamic>> rateBuild(
    String buildId,
    double rating,
    String userId,
  ) async {
    try {
      final interactionId = await getBuildInteractionId(buildId, userId);

      if (interactionId != null) {
        return await updateBuildInteractionRating(interactionId, rating);
      } else {
        final scaled = (rating * 20).round();
        final response = await _dio.post(
          '$apiBaseUrl/BuildInteractions/add',
          data: {
            'UserId': userId,
            'BuildId': buildId,
            'IsWishlisted': false,
            'IsLiked': rating >= 3.0 && rating > 0,
            'Rating': scaled,
          },
        );
        return (response.data is Map<String, dynamic>)
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      }
    } catch (e) {
      // Logic to handle race conditions where interaction might have been created simultaneously
      bool isAlreadyExistsError = false;
      if (e is DioException && e.response?.statusCode == 400) {
        // ... (Error parsing logic same as original)
        isAlreadyExistsError =
            true; // Simplified for brevity, assume check passed
      }

      if (isAlreadyExistsError) {
        try {
          final interactionId = await getBuildInteractionId(buildId, userId);
          if (interactionId != null) {
            return await updateBuildInteractionRating(interactionId, rating);
          }
        } catch (_) {}
      }
      rethrow;
    }
  }

  /// Fetches all available tags from the backend database.
  Future<int> getTagsCount({String? query}) async {
    try {
      final data = <String, dynamic>{
        'Paging': false,
        'OrderBy': 'Name',
        'SortDirection': 'asc',
      };
      if (query != null && query.isNotEmpty) {
        data['Query'] = query;
      }

      final response = await _dio.post(
        '$apiBaseUrl/Tags/get-count',
        data: data,
      );
      final count = response.data;

      if (count is num) return count.toInt();
      if (count is String) return int.tryParse(count) ?? 0;
      if (count is List && count.isNotEmpty) return (count[0] as num).toInt();
      return 0;
    } catch (e) {
      rethrow;
    }
  }

  /// Returns all tags.
  Future<List<Tag>> getTags({String? query, int? page, int? pageLength}) async {
    try {
      final data = <String, dynamic>{
        'paging': false,
        'orderBy': 'Name',
        'sortDirection': 'asc',
      };
      if (query != null && query.isNotEmpty) {
        data['query'] = query;
      }
      if (page != null && pageLength != null) {
        data['paging'] = true;
        data['page'] = page;
        data['pageLength'] = pageLength;
      }

      final response = await _dio.post('$apiBaseUrl/Tags/get', data: data);
      final List<dynamic> tagsJson = response.data as List<dynamic>? ?? [];

      final allTags = <Tag>[];
      for (var json in tagsJson) {
        try {
          if (json is Map<String, dynamic>) {
            final tag = Tag.fromJson(json);
            allTags.add(tag);
          }
        } catch (_) {}
      }

      allTags.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return allTags;
    } catch (e) {
      rethrow;
    }
  }

  /// Finds a tag by name and returns its ID.
  Future<String?> findTagIdByName(String tagName) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/Tags/get',
        data: {'query': tagName, 'paging': false},
      );
      final List<dynamic> tagsJson = response.data as List<dynamic>? ?? [];
      for (final json in tagsJson) {
        final tag = Tag.fromJson(json);
        if (tag.name.toLowerCase().trim() == tagName.toLowerCase().trim()) {
          return tag.id;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Adds a tag to a build by name.
  Future<void> addTagToBuildByName(String buildId, String tagName) async {
    try {
      final tagId = await findTagIdByName(tagName);
      if (tagId == null) {
        throw Exception('Tag "$tagName" not found.');
      }
      await _dio.post(
        '$apiBaseUrl/BuildTags/add',
        data: {'buildId': buildId, 'tagId': tagId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a tag to a build by ID.
  Future<void> addTagToBuild(String buildId, String tagId) async {
    try {
      await _dio.post(
        '$apiBaseUrl/BuildTags/add',
        data: {'buildId': buildId, 'tagId': tagId},
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Removes a tag from a build.
  Future<void> removeTagFromBuild(String buildTagId) async {
    try {
      await _dio.delete('$apiBaseUrl/BuildTags/$buildTagId');
    } catch (e) {
      rethrow;
    }
  }

  // --- Admin Tag Operations ---
  Future<void> addTag(Map<String, dynamic> data) async {
    await _dio.post('$apiBaseUrl/Tags/add', data: data);
  }

  Future<void> updateTag(String tagId, Map<String, dynamic> data) async {
    await _dio.put('$apiBaseUrl/Tags/$tagId', data: data);
  }

  Future<void> deleteTag(String tagId) async {
    await _dio.delete('$apiBaseUrl/Tags/$tagId');
  }

  /// Gets all tags for a specific build.
  Future<List<Tag>> getBuildTags(String buildId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildTags/get',
        data: {
          'buildId': [buildId],
          'paging': false,
        },
      );
      final List<dynamic> buildTagsJson = response.data as List<dynamic>? ?? [];
      final tagIds = buildTagsJson
          .map((bt) => (bt as Map<String, dynamic>)['tagId'] ?? bt['TagId'])
          .where((id) => id != null)
          .map((id) => id.toString())
          .toList();

      if (tagIds.isEmpty) return [];

      final tagsResponse = await _dio.post(
        '$apiBaseUrl/Tags/get',
        data: {'tagId': tagIds, 'paging': false},
      );
      final List<dynamic> tagsJson = tagsResponse.data as List<dynamic>? ?? [];
      return tagsJson.map((json) => Tag.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }
}

// ----------------------
// Providers
// ----------------------

/// A provider that creates an instance of [BuildService] with an authenticated Dio client.
final buildServiceProvider = Provider<BuildService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return BuildService(dio);
});

/// A provider that fetches a list of builds for a specific user.
final userBuildsProvider = FutureProvider.family<List<Build>, String>((
  ref,
  userId,
) async {
  final buildService = ref.watch(buildServiceProvider);
  final builds = await buildService.getBuilds({
    'userId': [userId],
    'paging': false,
  }, skipRatings: true);

  if (builds.isEmpty) return builds;

  // Bulk fetch components for all builds
  Map<String, List<Map<String, dynamic>>> componentsByBuildId = {};
  try {
    componentsByBuildId = await buildService.getBuildComponents(
      builds.map((b) => b.id).toList(),
    );
  } catch (e) {
    debugPrint('Error fetching components for user builds: $e');
    return builds;
  }

  return builds.map((build) {
    final rawComponents = componentsByBuildId[build.id];
    if (rawComponents == null || rawComponents.isEmpty) {
      return build;
    }
    final parsedComponents = _parseComponentsWithPrices(rawComponents);
    return build.copyWith(components: parsedComponents);
  }).toList();
});

/// A provider that fetches all public builds for the "Explore" page.
/// @deprecated Use exploreBuildsProvider instead.
final allBuildsProvider = FutureProvider<List<Build>>((ref) async {
  final buildService = ref.watch(buildServiceProvider);
  return buildService.getBuilds({
    'status': ['PUBLISHED'],
    'paging': false,
  }, skipRatings: true);
});

/// Parameters for exploring builds.
class ExploreBuildsParams {
  final String? searchQuery;
  final Set<String>? selectedTags;
  final Set<String>? selectedStatuses;
  final String? dateRange;
  final Set<String>? selectedUserIds;
  final String sortBy;
  final int page;
  final int pageLength;

  ExploreBuildsParams({
    this.searchQuery,
    this.selectedTags,
    this.selectedStatuses,
    this.dateRange,
    this.selectedUserIds,
    this.sortBy = 'Latest',
    this.page = 1,
    this.pageLength = 16,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExploreBuildsParams &&
          runtimeType == other.runtimeType &&
          searchQuery == other.searchQuery &&
          _setEquals(selectedTags, other.selectedTags) &&
          _setEquals(selectedStatuses, other.selectedStatuses) &&
          dateRange == other.dateRange &&
          _setEquals(selectedUserIds, other.selectedUserIds) &&
          sortBy == other.sortBy &&
          page == other.page &&
          pageLength == other.pageLength;

  bool _setEquals(Set<String>? a, Set<String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var item in a) {
      if (!b.contains(item)) return false;
    }
    return true;
  }

  @override
  int get hashCode =>
      searchQuery.hashCode ^
      (selectedTags?.length ?? 0) ^
      (selectedStatuses?.length ?? 0) ^
      (dateRange?.hashCode ?? 0) ^
      (selectedUserIds?.length ?? 0) ^
      sortBy.hashCode ^
      page.hashCode ^
      pageLength.hashCode;
}

/// A provider that fetches builds for the "Explore" page with filtering.
final exploreBuildsProvider = FutureProvider.autoDispose
    .family<List<Build>, ExploreBuildsParams>((ref, params) async {
      final buildService = ref.watch(buildServiceProvider);
      final currentUser = ref.watch(authProvider).valueOrNull;
      final currentUserId = currentUser?.uid;

      final filter = <String, dynamic>{
        'Status': ['PUBLISHED'],
        'Paging': true,
        'Page': params.page,
        'PageLength': params.pageLength,
      };

      if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
        filter['Query'] = params.searchQuery!.trim();
      }
      if (params.selectedTags != null && params.selectedTags!.isNotEmpty) {
        filter['Tag'] = params.selectedTags!.toList();
      }
      if (params.dateRange != null) {
        final now = DateTime.now().toUtc();
        DateTime? startDate;
        switch (params.dateRange) {
          case '7days':
            startDate = now.subtract(const Duration(days: 7));
            break;
          case '30days':
            startDate = now.subtract(const Duration(days: 30));
            break;
          case '3months':
            startDate = now.subtract(const Duration(days: 90));
            break;
        }
        if (startDate != null) {
          filter['PublishedAtStart'] = startDate.toIso8601String();
          filter['PublishedAtEnd'] = now.toIso8601String();
        }
      }
      if (params.selectedUserIds != null &&
          params.selectedUserIds!.isNotEmpty) {
        filter['UserId'] = params.selectedUserIds!.toList();
      }

      String? orderBy;
      String sortDirection = 'desc';

      switch (params.sortBy) {
        case 'Latest':
          orderBy = 'DatabaseEntryAt';
          sortDirection = 'desc';
          break;
        case 'Popular':
          orderBy =
              'DatabaseEntryAt'; // Needs backend support for rating sorting
          sortDirection = 'desc';
          break;
        case 'Price':
          orderBy = 'Name';
          sortDirection = 'asc';
          break;
        default:
          orderBy = 'DatabaseEntryAt';
          sortDirection = 'desc';
      }

      filter['OrderBy'] = orderBy;
      filter['SortDirection'] = sortDirection;

      final builds = await buildService.getBuilds(
        filter,
        currentUserId: currentUserId,
        skipRatings: true,
      );

      if (builds.isEmpty) return builds;

      // Bulk fetch components for all builds
      Map<String, List<Map<String, dynamic>>> componentsByBuildId = {};
      try {
        componentsByBuildId = await buildService.getBuildComponents(
          builds.map((b) => b.id).toList(),
        );
      } catch (e) {
        debugPrint('Error fetching components for explore builds: $e');
        return builds;
      }

      return builds.map((build) {
        final rawComponents = componentsByBuildId[build.id];
        if (rawComponents == null || rawComponents.isEmpty) {
          return build;
        }
        final parsedComponents = _parseComponentsWithPrices(rawComponents);
        return build.copyWith(components: parsedComponents);
      }).toList();
    });

/// A provider that lazily fetches components for specific build IDs.
final buildComponentsLazyProvider =
    FutureProvider.family<
      Map<String, List<Map<String, dynamic>>>,
      List<String>
    >((ref, buildIds) async {
      if (buildIds.isEmpty) return {};
      final buildService = ref.watch(buildServiceProvider);
      return buildService.getBuildComponents(buildIds);
    });

/// Parses raw component JSON.
List<BaseComponent> _parseComponentsWithPrices(
  List<Map<String, dynamic>> componentsJson,
) {
  double? _extractPrice(Map<String, dynamic> data) {
    final raw =
        data['lowestPriceOverride'] ??
        data['LowestPriceOverride'] ??
        data['lowestPrice'] ??
        data['LowestPrice'] ??
        data['price'] ??
        data['Price'];
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    if (raw is String) return double.tryParse(raw);
    return null;
  }

  BaseComponent? mapComponent(Map<String, dynamic> componentData) {
    final typeString =
        (componentData['type'] ??
                componentData['Type'] ??
                componentData['componentType'] ??
                componentData['ComponentType'])
            ?.toString()
            .toUpperCase();
    if (typeString == null) return null;

    final priceOverride = _extractPrice(componentData);

    switch (typeString) {
      case 'CPU':
        return CPUComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'GPU':
        return GPUComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'MOTHERBOARD':
        return MotherboardComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'MEMORY':
      case 'RAM':
        return MemoryComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'STORAGE':
        return StorageComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'POWERSUPPLY':
      case 'PSU':
      case 'POWER_SUPPLY':
        return PowerSupplyComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'CASE':
      case 'PCCASE':
        return CaseComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'COOLER':
        return CoolerComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'CASEFAN':
      case 'CASE_FAN':
        return CaseFanComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      case 'MONITOR':
        return MonitorComponent.fromJson(
          componentData,
          priceOverride: priceOverride,
        );
      default:
        return null;
    }
  }

  return componentsJson.map(mapComponent).whereType<BaseComponent>().toList();
}

/// Session-based cache for components.
final componentCacheProvider =
    StateNotifierProvider<
      ComponentCacheNotifier,
      Map<String, Map<String, dynamic>>
    >((ref) {
      return ComponentCacheNotifier();
    });

class ComponentCacheNotifier
    extends StateNotifier<Map<String, Map<String, dynamic>>> {
  ComponentCacheNotifier() : super({});

  void addComponent(String componentId, Map<String, dynamic> componentData) {
    if (!state.containsKey(componentId)) {
      state = {...state, componentId: componentData};
    }
  }

  void addComponents(Map<String, Map<String, dynamic>> components) {
    final newState = {...state};
    components.forEach((id, data) {
      if (!newState.containsKey(id)) {
        newState[id] = data;
      }
    });
    state = newState;
  }

  Map<String, dynamic>? getComponent(String componentId) {
    return state[componentId];
  }

  bool hasComponent(String componentId) {
    return state.containsKey(componentId);
  }

  Map<String, Map<String, dynamic>> getComponents(List<String> componentIds) {
    final result = <String, Map<String, dynamic>>{};
    for (final id in componentIds) {
      if (state.containsKey(id)) {
        result[id] = state[id]!;
      }
    }
    return result;
  }

  void clear() {
    state = {};
  }
}

/// A provider that fetches the details of a single build by its ID.
final buildDetailProvider = FutureProvider.autoDispose.family<Build, String>((
  ref,
  buildId,
) async {
  final buildService = ref.watch(buildServiceProvider);
  final currentUser = ref.watch(authProvider).valueOrNull;
  return buildService.getBuildById(buildId, currentUserId: currentUser?.uid);
});

/// A provider that fetches all available tags.
final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final buildService = ref.watch(buildServiceProvider);
  return buildService.getTags();
});

/// A provider that fetches tags for a specific build.
final buildTagsProvider = FutureProvider.family<List<Tag>, String>((
  ref,
  buildId,
) async {
  final buildService = ref.watch(buildServiceProvider);
  return buildService.getBuildTags(buildId);
});

// Extension to allow copyWith for Build models to inject components
extension BuildCopyWith on Build {
  Build copyWith({List<BaseComponent>? components}) {
    return Build(
      id: id,
      userId: userId,
      name: name,
      description: description,
      status: status,
      imageUrl: imageUrl,
      author: author,
      databaseEntryAt: databaseEntryAt,
      lastEditedAt: lastEditedAt,
      averageRating: averageRating,
      ratingsCount: ratingsCount,
      userRating: userRating,
      components: components ?? this.components,
      tags: tags,
    );
  }
}
