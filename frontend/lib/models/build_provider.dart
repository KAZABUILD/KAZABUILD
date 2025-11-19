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

/// A service class to handle API requests related to builds.
class BuildService {
  final Dio _dio;

  BuildService(this._dio);

  /// Fetches BuildComponents for a list of build IDs
  /// Uses cache to avoid re-fetching the same components
  Future<Map<String, List<Map<String, dynamic>>>> getBuildComponents(
    List<String> buildIds, {
    Map<String, Map<String, dynamic>>? cache,
  }) async {
    try {
      if (buildIds.isEmpty) return {};
      
      final response = await _dio.post('$apiBaseUrl/BuildComponents/get', data: {
        'BuildId': buildIds,
        'Paging': false,
      });
      
      final List<dynamic> buildComponentsJson = response.data as List<dynamic>? ?? [];
      if (buildComponentsJson.isEmpty) return {};
      
      // Extract all unique component IDs
      final Set<String> componentIds = {};
      final Map<String, List<String>> buildIdToComponentIds = {};
      
      for (var bcJson in buildComponentsJson) {
        if (bcJson is Map<String, dynamic>) {
          final buildId = (bcJson['buildId'] ?? bcJson['BuildId'] ?? '').toString();
          final componentId = (bcJson['componentId'] ?? bcJson['ComponentId'] ?? '').toString();
          
          if (buildId.isNotEmpty && componentId.isNotEmpty) {
            componentIds.add(componentId);
            buildIdToComponentIds.putIfAbsent(buildId, () => []).add(componentId);
          }
        }
      }
      
      if (componentIds.isEmpty) return {};
      
      // Use cache if provided, otherwise create empty map
      final Map<String, Map<String, dynamic>> componentMap = cache != null ? Map.from(cache) : {};
      
      // Filter out components that are already in cache
      final componentIdsToFetch = componentIds.where((id) => !componentMap.containsKey(id)).toList();
      
      if (componentIdsToFetch.isEmpty) {
        // All components are in cache, return them
        return _groupComponentsByBuildId(buildIdToComponentIds, componentMap);
      }
      
      // Fetch only missing components in small batches with delays
      const int batchSize = 3;
      final componentIdsList = componentIdsToFetch;
      
      for (int i = 0; i < componentIdsList.length; i += batchSize) {
        final batch = componentIdsList.skip(i).take(batchSize).toList();
        
        // Fetch batch in parallel
        final batchResults = await Future.wait(
          batch.map((componentId) async {
            try {
              final componentResponse = await _dio.get('$apiBaseUrl/Components/$componentId');
              
              if (componentResponse.data is Map<String, dynamic>) {
                final compJson = componentResponse.data as Map<String, dynamic>;
                final idValue = compJson['id'] ?? compJson['Id'];
                
                String? compId;
                if (idValue == null) {
                  compId = componentId;
                } else if (idValue is String) {
                  compId = idValue.isEmpty ? componentId : idValue;
                } else {
                  compId = idValue.toString();
                }
                
                if (compId.isNotEmpty) {
                  return MapEntry(compId, compJson);
                }
              }
              return null;
            } on DioException catch (e) {
              // Retry once on 429 with delay
              if (e.response?.statusCode == 429) {
                await Future.delayed(const Duration(milliseconds: 1500));
                try {
                  final componentResponse = await _dio.get('$apiBaseUrl/Components/$componentId');
                  if (componentResponse.data is Map<String, dynamic>) {
                    final compJson = componentResponse.data as Map<String, dynamic>;
                    final idValue = compJson['id'] ?? compJson['Id'];
                    String? compId;
                    if (idValue == null) {
                      compId = componentId;
                    } else if (idValue is String) {
                      compId = idValue.isEmpty ? componentId : idValue;
                    } else {
                      compId = idValue.toString();
                    }
                    if (compId.isNotEmpty) {
                      return MapEntry(compId, compJson);
                    }
                  }
                } catch (_) {
                  // Ignore retry errors
                }
              }
              return null;
            } catch (e) {
              return null;
            }
          }),
        );
        
        // Add successful results to map
        for (var result in batchResults) {
          if (result != null) {
            componentMap[result.key] = result.value;
          }
        }
        
        // Delay between batches to avoid rate limiting
        if (i + batchSize < componentIdsList.length) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
      
      if (componentMap.isEmpty) return {};
      
      // Group components by buildId
      return _groupComponentsByBuildId(buildIdToComponentIds, componentMap);
    } catch (e) {
      return {};
    }
  }

  /// Groups components by buildId
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

  /// Fetches images for builds
  Future<Map<String, String?>> getBuildImages(List<String> buildIds) async {
    try {
      if (buildIds.isEmpty) return {};
      
      final response = await _dio.post('$apiBaseUrl/Images/get', data: {
        'BuildId': buildIds,
        'LocationType': ['BUILD'],
        'Paging': false,
      });
      
      final List<dynamic> imagesJson = response.data as List<dynamic>? ?? [];
      final Map<String, String?> imageUrlsByBuildId = {};
      
      for (var imgJson in imagesJson) {
        if (imgJson is Map<String, dynamic>) {
          final targetId = (imgJson['targetId'] ?? imgJson['TargetId'] ?? '').toString();
          
          if (targetId.isNotEmpty) {
            // Get image ID for download endpoint
            final imageId = (imgJson['id'] ?? imgJson['Id'] ?? '').toString();
            if (imageId.isNotEmpty) {
              // Backend serves images via /Images/download/{id} endpoint
              imageUrlsByBuildId[targetId] = '$apiBaseUrl/Images/download/$imageId';
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
  Future<List<Build>> getBuilds(Map<String, dynamic> filter, {String? currentUserId, bool skipRatings = false}) async {
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
        // If fetching images fails, continue with empty map
        // This ensures builds are still displayed even without images
      }
      
      // Fetch ratings for all builds in parallel (skip if skipRatings is true)
      if (!skipRatings) {
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
            debugPrint('Error fetching ratings for build $buildId: $e');
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
          final userRatingFutures = buildIds.map((buildId) async {
            try {
              final userRating = await _getUserRatingForBuild(buildId, currentUserId);
              return {
                'buildId': buildId,
                'userRating': userRating,
              };
            } catch (e) {
              debugPrint('Error fetching user rating for build $buildId: $e');
              return {
                'buildId': buildId,
                'userRating': null,
              };
            }
          });
          
          final userRatingResults = await Future.wait(userRatingFutures);
          for (var result in userRatingResults) {
            final buildId = result['buildId'] as String;
            userRatingByBuildId[buildId] = result['userRating'] as double?;
          }
        }
      } else {
        // If skipping ratings, set default values (0 for count, 0.0 for average)
        for (final buildId in buildIds) {
          ratingsCountByBuildId[buildId] = 0;
          averageRatingByBuildId[buildId] = 0.0;
        }
      }
      
      // Add imageUrl and rating data to build JSON
      for (var json in buildsJson) {
        if (json is Map<String, dynamic>) {
          final buildId = (json['id'] ?? json['Id'] ?? '').toString();
          
          if (imageUrlsByBuildId.containsKey(buildId)) {
            json['imageUrl'] = imageUrlsByBuildId[buildId];
            json['ImageUrl'] = imageUrlsByBuildId[buildId];
          }
          
          // Add rating metadata
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
      
      final builds = buildsJson.map((json) => Build.fromJson(json)).toList();
      
      return builds;
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches a single build by its ID.
  Future<Build> getBuildById(String buildId, {String? currentUserId}) async {
    try {
      final response = await _dio.get('$apiBaseUrl/Builds/$buildId');
      final buildJson = response.data as Map<String, dynamic>;

      // Fetch related data in parallel
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

      if (componentsByBuildId.containsKey(buildId)) {
        final components = componentsByBuildId[buildId]!;
        buildJson['components'] = components;
        buildJson['buildComponents'] = components;
      }
      if (imageUrlsByBuildId.containsKey(buildId)) {
        buildJson['imageUrl'] = imageUrlsByBuildId[buildId];
        buildJson['ImageUrl'] = imageUrlsByBuildId[buildId];
      }
      if (tagsByBuildId.containsKey(buildId)) {
        buildJson['tags'] = tagsByBuildId[buildId];
        buildJson['Tags'] = tagsByBuildId[buildId];
      }

      // Attach rating metadata so UI can show accurate stats
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
  Future<Map<String, List<String>>> _fetchBuildTags(List<String> buildIds) async {
    final Map<String, List<String>> tagsByBuildId = {};
    
    try {
      if (buildIds.isEmpty) return tagsByBuildId;
      
      // Get all BuildTags for these builds
      final buildTagsResponse = await _dio.post('$apiBaseUrl/BuildTags/get', data: {
        'buildId': buildIds,
        'paging': false,
      });
      
      final List<dynamic> buildTagsJson = buildTagsResponse.data as List<dynamic>? ?? [];
      
      // Extract all unique tag IDs from BuildTags
      final Set<String> uniqueTagIds = {};
      final Map<String, List<String>> tagIdsByBuildId = {};
      
      for (var btJson in buildTagsJson) {
        if (btJson is Map<String, dynamic>) {
          final buildId = (btJson['buildId'] ?? btJson['BuildId'] ?? '').toString();
          final tagId = (btJson['tagId'] ?? btJson['TagId'] ?? '').toString();
          
          if (buildId.isNotEmpty && tagId.isNotEmpty) {
            uniqueTagIds.add(tagId);
            tagIdsByBuildId.putIfAbsent(buildId, () => []).add(tagId);
          }
        }
      }
      
      // Fetch tag names for all unique tag IDs
      if (uniqueTagIds.isNotEmpty) {
        // Fetch all tags from backend
        final tagsResponse = await _dio.post('$apiBaseUrl/Tags/get', data: {
          'paging': false,
        });
        final List<dynamic> allTagsJson = tagsResponse.data as List<dynamic>? ?? [];
        
        // Create a map of tagId -> tagName
        final Map<String, String> tagNameMap = {};
        
        // Try to match tags by ID first
        for (var tagJson in allTagsJson) {
          if (tagJson is Map<String, dynamic>) {
            final tagId = (tagJson['id'] ?? tagJson['Id'] ?? '').toString();
            final tagName = (tagJson['name'] ?? tagJson['Name'] ?? '').toString();
            
            if (tagId.isNotEmpty && tagName.isNotEmpty && uniqueTagIds.contains(tagId)) {
              tagNameMap[tagId] = tagName;
            }
          }
        }
        
        // If we couldn't find all tags (backend doesn't return Id for non-admin),
        // try to fetch each tag individually by ID
        final missingTagIds = uniqueTagIds.where((id) => !tagNameMap.containsKey(id)).toList();
        if (missingTagIds.isNotEmpty) {
          // Try to fetch tags individually with a small delay to avoid rate limiting
          for (final tagId in missingTagIds) {
            try {
              await Future.delayed(const Duration(milliseconds: 100));
              final tagResponse = await _dio.get('$apiBaseUrl/Tags/$tagId');
              if (tagResponse.data is Map<String, dynamic>) {
                final tagJson = tagResponse.data as Map<String, dynamic>;
                final tagName = (tagJson['name'] ?? tagJson['Name'] ?? '').toString();
                if (tagName.isNotEmpty) {
                  tagNameMap[tagId] = tagName;
                }
              }
            } catch (e) {
              // Skip if individual tag fetch fails
              continue;
            }
          }
        }
        
        // Now map build IDs to tag names
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

  /// Retrieves the total number of ratings (excluding unrated interactions) for a build.
  Future<int> _getBuildRatingsCount(String buildId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/BuildInteractions/get-count', data: {
        'BuildId': [buildId],
        'RatingStart': 1,
        'Paging': false,
      });
      final data = response.data;
      if (data is int) return data;
      if (data is num) return data.toInt();
      if (data is String) {
        return int.tryParse(data) ?? 0;
      }
    } catch (e) {
      debugPrint('BuildService._getBuildRatingsCount error: $e');
    }
    return 0;
  }

  /// Retrieves the average rating (0-100 scale) for a build.
  Future<double?> _getBuildAverageRating(String buildId) async {
    try {
      final response =
          await _dio.post('$apiBaseUrl/BuildInteractions/get-average-rating', data: {
        'BuildId': [buildId],
        'RatingStart': 1,
        'Paging': false,
      });
      final data = response.data;
      if (data is num) return data.toDouble();
      if (data is String) {
        return double.tryParse(data);
      }
    } catch (e) {
      debugPrint('BuildService._getBuildAverageRating error: $e');
    }
    return null;
  }

  /// Retrieves the current user's rating for a specific build (0-100 scale).
  Future<double?> _getUserRatingForBuild(String buildId, String userId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/BuildInteractions/get', data: {
        'BuildId': [buildId],
        'UserId': [userId],
        'Paging': false,
      });
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
      debugPrint('BuildService._getUserRatingForBuild error: $e');
    }
    return null;
  }

  /// Creates a new build on the backend and returns its ID.
  Future<String> createBuild(Map<String, dynamic> buildData) async {
    try {
      final response = await _dio.post('$apiBaseUrl/Builds/add', data: buildData);
      
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
      await _dio.post('$apiBaseUrl/BuildComponents/add', data: {
        'BuildId': buildId,
        'ComponentId': componentId,
        'Quantity': quantity
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Removes a component from a build by BuildComponent ID.
  Future<void> removeComponentFromBuild(String buildComponentId) async {
    try {
      await _dio.delete('$apiBaseUrl/BuildComponents/$buildComponentId');
    } catch (e) {
      rethrow;
    }
  }

  /// Gets BuildComponent IDs for a build (to get the BuildComponent ID for deletion).
  Future<List<Map<String, dynamic>>> getBuildComponentIds(String buildId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/BuildComponents/get', data: {
        'BuildId': [buildId],
        'Paging': false,
      });
      final List<dynamic> buildComponentsJson = response.data as List<dynamic>? ?? [];
      return buildComponentsJson
          .where((json) => json is Map<String, dynamic>)
          .map((json) => json as Map<String, dynamic>)
          .toList();
    } catch (e) {
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
  /// If rating is 0, it effectively removes the rating (sets it to 0, which is excluded from calculations)
  Future<Map<String, dynamic>> updateBuildInteractionRating(String interactionId, double rating) async {
    try {
      // Backend expects 0-100 scale; UI works with 0-5 stars
      // Rating of 0 means remove rating
      final scaled = (rating * 20).round();
      final response = await _dio.put('$apiBaseUrl/BuildInteractions/$interactionId', data: {
        'IsWishlisted': null,
        'IsLiked': rating >= 3.0 && rating > 0, // Consider 3+ stars as liked, but not if rating is 0
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
  /// If rating is 0, it removes the rating (sets it to 0, which is excluded from calculations)
  Future<Map<String, dynamic>> rateBuild(String buildId, double rating, String userId) async {
    try {
      // First, check if an interaction already exists
      final interactionId = await getBuildInteractionId(buildId, userId);
      
      if (interactionId != null) {
        // Interaction exists, update it
        return await updateBuildInteractionRating(interactionId, rating);
      } else {
        // No interaction exists, create a new one
        // Backend expects 0-100 scale; UI works with 0-5 stars
        final scaled = (rating * 20).round();
        final response = await _dio.post('$apiBaseUrl/BuildInteractions/add', data: {
          'UserId': userId,
          'BuildId': buildId,
          'IsWishlisted': false,
          'IsLiked': rating >= 3.0 && rating > 0, // Consider 3+ stars as liked, but not if rating is 0
          'Rating': scaled,
        });
        return (response.data is Map<String, dynamic>)
            ? response.data as Map<String, dynamic>
            : <String, dynamic>{};
      }
    } catch (e) {
      // If it's an "already exists" error, try to update instead
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

  /// Fetches all available tags from the backend database seeds.
  /// Returns all tags without filtering, sorted by name.
  Future<List<Tag>> getTags({String? query, int? page, int? pageLength}) async {
    try {
      final data = <String, dynamic>{
        'paging': false, // Get all tags from database
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
      debugPrint('BuildService.getTags: Received ${tagsJson.length} tags from backend');
      
      // Parse all tags from backend (database seeds)
      // Note: Backend may not return Id for non-admin users, but we can use name to find Id when needed
      final allTags = <Tag>[];
      for (var json in tagsJson) {
        try {
          if (json is Map<String, dynamic>) {
            debugPrint('BuildService.getTags: Parsing tag: ${json['name'] ?? json['Name']}');
            final tag = Tag.fromJson(json);
            allTags.add(tag);
          }
        } catch (e, stack) {
          debugPrint('BuildService.getTags: Error parsing tag: $e');
          debugPrint('BuildService.getTags: Tag JSON: $json');
          debugPrint('BuildService.getTags: Stack: $stack');
        }
      }
      debugPrint('BuildService.getTags: Successfully parsed ${allTags.length} tags');
      
      // Sort by name alphabetically
      allTags.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      
      return allTags;
    } catch (e, stack) {
      // Log error but don't return empty list - let the error propagate
      debugPrint('BuildService.getTags: Error fetching tags: $e');
      debugPrint('BuildService.getTags: Stack: $stack');
      rethrow; // Re-throw to let provider handle the error
    }
  }

  /// Finds a tag by name and returns its ID, or null if not found
  Future<String?> findTagIdByName(String tagName) async {
    try {
      final response = await _dio.post('$apiBaseUrl/Tags/get', data: {
        'query': tagName,
        'paging': false,
      });
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

  /// Adds a tag to a build by tag name (will find or suggest creating the tag)
  Future<void> addTagToBuildByName(String buildId, String tagName) async {
    try {
      final tagId = await findTagIdByName(tagName);
      if (tagId == null) {
        throw Exception('Tag "$tagName" not found in backend. Please create it first through admin panel.');
      }
      
      await _dio.post('$apiBaseUrl/BuildTags/add', data: {
        'buildId': buildId,
        'tagId': tagId,
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Adds a tag to a build by tag ID
  Future<void> addTagToBuild(String buildId, String tagId) async {
    try {
      await _dio.post('$apiBaseUrl/BuildTags/add', data: {
        'buildId': buildId,
        'tagId': tagId,
      });
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

  /// Updates a tag (admin only).
  Future<void> updateTag(String tagId, Map<String, dynamic> data) async {
    try {
      await _dio.put('$apiBaseUrl/Tags/$tagId', data: data);
    } catch (e) {
      rethrow;
    }
  }

  /// Deletes a tag (admin only).
  Future<void> deleteTag(String tagId) async {
    try {
      await _dio.delete('$apiBaseUrl/Tags/$tagId');
    } catch (e) {
      rethrow;
    }
  }

  /// Gets all tags for a specific build.
  Future<List<Tag>> getBuildTags(String buildId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/BuildTags/get', data: {
        'buildId': [buildId],
        'paging': false,
      });
      final List<dynamic> buildTagsJson = response.data as List<dynamic>? ?? [];
      final tagIds = buildTagsJson
          .map((bt) {
            final map = bt as Map<String, dynamic>;
            return map['tagId'] ?? map['TagId'];
          })
          .where((id) => id != null)
          .map((id) => id.toString())
          .toList();
      
      if (tagIds.isEmpty) return [];
      
      final tagsResponse = await _dio.post('$apiBaseUrl/Tags/get', data: {
        'tagId': tagIds,
        'paging': false,
      });
      final List<dynamic> tagsJson = tagsResponse.data as List<dynamic>? ?? [];
      return tagsJson.map((json) => Tag.fromJson(json)).toList();
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
  // Skip ratings for list views to reduce API calls
  return buildService.getBuilds({'userId': [userId], 'paging': false}, skipRatings: true);
});

/// A provider that fetches all public builds for the "Explore" page.
/// @deprecated Use exploreBuildsProvider instead for server-side pagination
final allBuildsProvider = FutureProvider<List<Build>>((ref) async {
  final buildService = ref.watch(buildServiceProvider);
  // Fetch only published builds and disable paging to get all of them.
  // Skip ratings for list views to reduce API calls
  return buildService.getBuilds({'status': ['PUBLISHED'], 'paging': false}, skipRatings: true);
});

/// Parameters for exploring builds with server-side pagination, search, filtering, and sorting
class ExploreBuildsParams {
  final String? searchQuery;
  final Set<String>? selectedTags;
  final Set<String>? selectedStatuses;
  final String? dateRange; // '7days', '30days', '3months', null
  final Set<String>? selectedUserIds; // User IDs to filter by
  final String sortBy; // 'Latest', 'Popular', 'Price'
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

/// A provider that fetches builds for the "Explore" page with server-side pagination, search, filtering, and sorting.
final exploreBuildsProvider = FutureProvider.family<List<Build>, ExploreBuildsParams>((ref, params) async {
  final buildService = ref.watch(buildServiceProvider);
  
  // Get current user ID for fetching user ratings
  final currentUser = ref.watch(authProvider).valueOrNull;
  final currentUserId = currentUser?.uid;
  
  // Build the filter map for the API
  final filter = <String, dynamic>{
    'Status': ['PUBLISHED'], // Only show published builds
    'Paging': true,
    'Page': params.page,
    'PageLength': params.pageLength,
  };

  // Add search query if provided
  if (params.searchQuery != null && params.searchQuery!.isNotEmpty) {
    filter['Query'] = params.searchQuery!.trim();
  }

  // Add tag filter if provided
  if (params.selectedTags != null && params.selectedTags!.isNotEmpty) {
    filter['Tag'] = params.selectedTags!.toList();
  }

  // Add date range filter if provided
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

  // Add user filter if provided
  if (params.selectedUserIds != null && params.selectedUserIds!.isNotEmpty) {
    filter['UserId'] = params.selectedUserIds!.toList();
  }

  // Note: Explore page only shows PUBLISHED builds
  // If status filter is provided, it should only include PUBLISHED
  // For now, we always filter by PUBLISHED only
  // The status filter in the UI is kept for consistency but only PUBLISHED builds are shown

  // Map sort options to backend OrderBy fields
  String? orderBy;
  String sortDirection = 'desc';
  
  switch (params.sortBy) {
    case 'Latest':
      orderBy = 'DatabaseEntryAt';
      sortDirection = 'desc';
      break;
    case 'Popular':
      // For popular, we'll sort by averageRating descending
      // Note: Backend might not have this field directly, but we'll try
      // If it doesn't work, we may need backend support
      orderBy = 'DatabaseEntryAt'; // Fallback to latest if rating sorting not available
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

  // Always set OrderBy and SortDirection
  filter['OrderBy'] = orderBy;
  filter['SortDirection'] = sortDirection;

  // Skip ratings for list views to reduce API calls and avoid rate limiting
  // Ratings will be fetched when user views build detail page
  return buildService.getBuilds(filter, currentUserId: currentUserId, skipRatings: true);
});

/// A provider that lazily fetches components for specific build IDs.
/// This is used for lazy loading components only when builds are visible.
final buildComponentsLazyProvider = FutureProvider.family<Map<String, List<Map<String, dynamic>>>, List<String>>((ref, buildIds) async {
  if (buildIds.isEmpty) return {};
  final buildService = ref.watch(buildServiceProvider);
  return buildService.getBuildComponents(buildIds);
});

/// Session-based cache for components.
/// Stores fetched components in memory to avoid re-fetching the same component.
final componentCacheProvider = StateNotifierProvider<ComponentCacheNotifier, Map<String, Map<String, dynamic>>>((ref) {
  return ComponentCacheNotifier();
});

class ComponentCacheNotifier extends StateNotifier<Map<String, Map<String, dynamic>>> {
  ComponentCacheNotifier() : super({});

  /// Adds a component to the cache
  void addComponent(String componentId, Map<String, dynamic> componentData) {
    if (!state.containsKey(componentId)) {
      state = {...state, componentId: componentData};
    }
  }

  /// Adds multiple components to the cache
  void addComponents(Map<String, Map<String, dynamic>> components) {
    final newState = {...state};
    components.forEach((id, data) {
      if (!newState.containsKey(id)) {
        newState[id] = data;
      }
    });
    state = newState;
  }

  /// Gets a component from cache, returns null if not found
  Map<String, dynamic>? getComponent(String componentId) {
    return state[componentId];
  }

  /// Checks if a component is in cache
  bool hasComponent(String componentId) {
    return state.containsKey(componentId);
  }

  /// Gets multiple components from cache, returns only cached ones
  Map<String, Map<String, dynamic>> getComponents(List<String> componentIds) {
    final result = <String, Map<String, dynamic>>{};
    for (final id in componentIds) {
      if (state.containsKey(id)) {
        result[id] = state[id]!;
      }
    }
    return result;
  }

  /// Clears the cache
  void clear() {
    state = {};
  }
}

/// A provider that fetches the details of a single build by its ID.
final buildDetailProvider = FutureProvider.family<Build, String>((ref, buildId) async {
  final buildService = ref.watch(buildServiceProvider);
  final currentUser = ref.watch(authProvider).valueOrNull;
  // Use the new, more direct method to fetch a single build.
  return buildService.getBuildById(buildId, currentUserId: currentUser?.uid);
});

/// A provider that fetches all available tags.
final tagsProvider = FutureProvider<List<Tag>>((ref) async {
  final buildService = ref.watch(buildServiceProvider);
  return buildService.getTags();
});

/// A provider that fetches tags for a specific build.
final buildTagsProvider = FutureProvider.family<List<Tag>, String>((ref, buildId) async {
  final buildService = ref.watch(buildServiceProvider);
  return buildService.getBuildTags(buildId);
});
