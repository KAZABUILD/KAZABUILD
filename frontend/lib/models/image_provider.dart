/// This file provides services and providers for fetching images from the backend.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';

/// Service for fetching images from the backend.
class ImageService {
  final Dio _dio;

  ImageService(this._dio);

  /// Fetches images for a specific component.
  /// Returns the first image ID if available, null otherwise.
  Future<String?> getComponentImageId(String componentId) async {
    try {
      final url = '$apiBaseUrl/Images/get';
      final body = {
        'locationType': ['COMPONENT'], // camelCase property name
        'componentId': [componentId], // camelCase property name
        'paging': false, // camelCase property name
      };

      if (kDebugMode) {
        print('Fetching images for component: $componentId');
      }

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> images = response.data;
        if (images.isNotEmpty) {
          final imageId =
              images[0]['id']?.toString() ?? images[0]['Id']?.toString();
          if (kDebugMode) {
            print('Found image for component $componentId: $imageId');
          }
          return imageId;
        }
      }

      if (kDebugMode) {
        print('No images found for component: $componentId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching component image: $e');
      }
      return null;
    }
  }

  /// Fetches images for multiple components with batching and retry logic.
  /// Returns a map of componentId -> imageId.
  Future<Map<String, String?>> getComponentImageIds(
    List<String> componentIds,
  ) async {
    // Filter out empty, null, or whitespace-only IDs
    final validComponentIds = componentIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();

    if (validComponentIds.isEmpty) {
      if (kDebugMode) {
        print('⚠️ No valid component IDs provided (all were empty/null)');
      }
      return {};
    }

    if (kDebugMode && validComponentIds.length != componentIds.length) {
      print(
        '⚠️ Filtered out ${componentIds.length - validComponentIds.length} empty component IDs',
      );
      print('   Valid IDs: ${validComponentIds.length}');
    }

    // Backend has no rate limiting for /images/get, so we can fetch all at once
    // But still use reasonable batch size to avoid overwhelming the server
    const batchSize = 50;
    final result = <String, String?>{};

    // Process in batches for better performance
    for (int i = 0; i < validComponentIds.length; i += batchSize) {
      final batch = validComponentIds.skip(i).take(batchSize).toList();

      try {
        final batchResult = await _fetchComponentImagesBatch(batch);
        result.addAll(batchResult);

        // Small delay between batches to be nice to the server
        if (i + batchSize < componentIds.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching batch of component images: $e');
        }
        // Add null entries for failed batch
        for (final id in batch) {
          result[id] = null;
        }
      }
    }

    return result;
  }

  /// Fetches images for a single batch of components with retry logic.
  Future<Map<String, String?>> _fetchComponentImagesBatch(
    List<String> componentIds, {
    int maxRetries = 3,
  }) async {
    // Filter out empty IDs (should already be filtered, but double-check)
    final validIds = componentIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();
    if (validIds.isEmpty) {
      if (kDebugMode) {
        print('⚠️ _fetchComponentImagesBatch: No valid component IDs in batch');
      }
      return {};
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = '$apiBaseUrl/Images/get';

        // Backend expects camelCase property names (per Swagger docs)
        // Enum values are strings: COMPONENT, BUILD, etc.
        final body = {
          'locationType': ['COMPONENT'], // camelCase property name
          'componentId':
              validIds, // camelCase property name, Array of Guid strings
          'paging': false, // camelCase property name
        };

        if (kDebugMode && attempt == 0) {
          print(
            'Fetching images for ${validIds.length} components (attempt ${attempt + 1})',
          );
          print('Request body: $body');
          print('Component IDs: $validIds');
          if (validIds.length != componentIds.length) {
            print(
              '⚠️ Filtered out ${componentIds.length - validIds.length} empty IDs from batch',
            );
          }
        }

        final response = await _dio.post(url, data: body);

        if (kDebugMode && response.statusCode != 200) {
          print('Non-200 response: ${response.statusCode}');
          print('Response data: ${response.data}');
        }

        if (response.statusCode == 200 && response.data is List) {
          final List<dynamic> images = response.data;
          final Map<String, String?> imageMap = {};

          if (kDebugMode && attempt == 0) {
            print('✅ Received ${images.length} image records from API');
            if (images.isEmpty) {
              print('⚠️ No images found in response');
            } else {
              print(
                'Sample image record keys: ${images.first?.keys?.toList() ?? 'null'}',
              );
              print('Sample image record: ${images.first}');
            }
          }

          // Group images by component ID
          for (final image in images) {
            // Backend returns TargetId - check both camelCase and PascalCase
            final targetId =
                image['targetId']?.toString() ?? image['TargetId']?.toString();
            // Backend returns Id - check both camelCase and PascalCase
            final imageId = image['id']?.toString() ?? image['Id']?.toString();

            if (kDebugMode && attempt == 0) {
              print('  📷 Image record: targetId=$targetId, imageId=$imageId');
              print('     All keys: ${image.keys.toList()}');
            }

            if (targetId != null && imageId != null) {
              // Try to find matching component ID (case-insensitive)
              String? matchedComponentId;
              try {
                matchedComponentId = componentIds.firstWhere(
                  (id) => id.toLowerCase() == targetId.toLowerCase(),
                  orElse: () => '',
                );
              } catch (e) {
                // No match found
                matchedComponentId = null;
              }

              if (matchedComponentId != null && matchedComponentId.isNotEmpty) {
                // Only set the first image for each component
                if (!imageMap.containsKey(matchedComponentId)) {
                  imageMap[matchedComponentId] = imageId;
                  if (kDebugMode && attempt == 0) {
                    print(
                      '  ✅ Mapped: componentId=$matchedComponentId -> imageId=$imageId',
                    );
                  }
                }
              } else if (kDebugMode && attempt == 0) {
                print('  ⚠️ No matching component ID for targetId=$targetId');
                print('     Looking for: ${componentIds.join(", ")}');
              }
            } else if (kDebugMode && attempt == 0) {
              print('  ⚠️ Missing targetId or imageId in response');
            }
          }

          if (kDebugMode && attempt == 0) {
            print(
              '📊 Final mapping: Found ${imageMap.length} out of ${componentIds.length} component images',
            );
            imageMap.forEach((componentId, imageId) {
              print('  $componentId -> $imageId');
            });
            if (imageMap.isEmpty && images.isNotEmpty) {
              print(
                '⚠️ WARNING: Images returned but no matching targetIds found',
              );
              print('   Expected component IDs: $validIds');
              print(
                '   Received targetIds from API: ${images.map((img) => img['targetId'] ?? img['TargetId']).whereType<String>().toList()}',
              );
            }
          }

          // Ensure all valid component IDs are in the map (with null if no image)
          final result = <String, String?>{};
          for (final componentId in validIds) {
            result[componentId] = imageMap[componentId];
          }

          return result;
        }

        // If not 200, return empty map for this batch
        return {for (var id in validIds) id: null};
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // Handle rate limiting (429)
        if (statusCode == 429) {
          final retryAfter = _getRetryAfterDelay(e.response?.headers, attempt);

          if (kDebugMode) {
            print(
              'Rate limited (429). Waiting ${retryAfter.inSeconds}s before retry ${attempt + 1}/$maxRetries',
            );
          }

          // Wait before retrying
          await Future.delayed(retryAfter);
          continue; // Retry
        }

        // For other errors, wait a bit and retry
        if (attempt < maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (attempt + 1));
          if (kDebugMode) {
            print(
              'Error ${statusCode ?? 'unknown'}. Retrying in ${delay.inMilliseconds}ms',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        // Last attempt failed
        if (kDebugMode) {
          print(
            'Failed to fetch component images after $maxRetries attempts: ${e.message}',
          );
        }
        return {for (var id in validIds) id: null};
      } catch (e) {
        if (attempt < maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (attempt + 1));
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          print('Error fetching component images: $e');
        }
        return {for (var id in validIds) id: null};
      }
    }

    return {for (var id in validIds) id: null};
  }

  /// Extracts retry delay from response headers or calculates exponential backoff.
  Duration _getRetryAfterDelay(Headers? headers, int attempt) {
    // Try to get Retry-After header
    if (headers != null) {
      final retryAfter =
          headers.value('retry-after') ?? headers.value('Retry-After');
      if (retryAfter != null) {
        final seconds = int.tryParse(retryAfter);
        if (seconds != null && seconds > 0) {
          return Duration(seconds: seconds);
        }
      }
    }

    // Exponential backoff: 2^attempt seconds, max 30 seconds
    final delaySeconds = (1 << attempt).clamp(1, 30);
    return Duration(seconds: delaySeconds);
  }

  /// Fetches images for a specific build.
  /// Returns the first image ID if available, null otherwise.
  Future<String?> getBuildImageId(String buildId) async {
    try {
      final url = '$apiBaseUrl/Images/get';
      final body = {
        'locationType': ['BUILD'], // camelCase property name
        'buildId': [buildId], // This should be an array
        'paging': false, // camelCase property name
      };

      if (kDebugMode) {
        print('Fetching images for build: $buildId');
      }

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> images = response.data;
        if (images.isNotEmpty) {
          final imageId =
              images[0]['id']?.toString() ?? images[0]['Id']?.toString();
          if (kDebugMode) {
            print('Found image for build $buildId: $imageId');
          }
          return imageId;
        }
      }

      if (kDebugMode) {
        print('No images found for build: $buildId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching build image: $e');
      }
      return null;
    }
  }

  /// Fetches images for multiple builds with batching and retry logic.
  /// Returns a map of buildId -> imageId.
  Future<Map<String, String?>> getBuildImageIds(List<String> buildIds) async {
    // Filter out empty, null, or whitespace-only IDs
    final validBuildIds = buildIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();

    if (validBuildIds.isEmpty) {
      if (kDebugMode) {
        print('⚠️ No valid build IDs provided (all were empty/null)');
      }
      return {};
    }

    if (kDebugMode && validBuildIds.length != buildIds.length) {
      print(
        '⚠️ Filtered out ${buildIds.length - validBuildIds.length} empty build IDs',
      );
      print('   Valid IDs: ${validBuildIds.length}');
    }

    // Backend has no rate limiting for /images/get, so we can fetch all at once
    // But still use reasonable batch size to avoid overwhelming the server
    const batchSize = 50;
    final result = <String, String?>{};

    // Process in batches for better performance
    for (int i = 0; i < validBuildIds.length; i += batchSize) {
      final batch = validBuildIds.skip(i).take(batchSize).toList();

      try {
        final batchResult = await _fetchBuildImagesBatch(batch);
        result.addAll(batchResult);

        // Small delay between batches to be nice to the server
        if (i + batchSize < buildIds.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching batch of build images: $e');
        }
        // Add null entries for failed batch
        for (final id in batch) {
          result[id] = null;
        }
      }
    }

    return result;
  }

  /// Fetches images for a single batch of builds with retry logic.
  Future<Map<String, String?>> _fetchBuildImagesBatch(
    List<String> buildIds, {
    int maxRetries = 3,
  }) async {
    // Filter out empty IDs (should already be filtered, but double-check)
    final validIds = buildIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();
    if (validIds.isEmpty) {
      if (kDebugMode) {
        print('⚠️ _fetchBuildImagesBatch: No valid build IDs in batch');
      }
      return {};
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = '$apiBaseUrl/Images/get';

        // Backend expects camelCase property names (per Swagger docs)
        // Enum values are strings: COMPONENT, BUILD, etc.
        final body = {
          'locationType': ['BUILD'], // camelCase property name
          'buildId': validIds, // camelCase property name, Array of Guid strings
          'paging': false, // camelCase property name
        };

        if (kDebugMode && attempt == 0) {
          print(
            'Fetching images for ${validIds.length} builds (attempt ${attempt + 1})',
          );
          print('Request body: $body');
          print('Build IDs: $validIds');
          if (validIds.length != buildIds.length) {
            print(
              '⚠️ Filtered out ${buildIds.length - validIds.length} empty IDs from batch',
            );
          }
        }

        final response = await _dio.post(url, data: body);

        if (kDebugMode) {
          print('API Response Status: ${response.statusCode}');
          print('API Response Type: ${response.data.runtimeType}');
          print('API Response Data: ${response.data}');
        }

        if (kDebugMode && response.statusCode != 200) {
          print('Non-200 response: ${response.statusCode}');
          print('Response data: ${response.data}');
        }

        if (response.statusCode == 200) {
          // Handle both List and other response types
          final List<dynamic> images;
          if (response.data is List) {
            images = response.data as List<dynamic>;
          } else {
            if (kDebugMode && attempt == 0) {
              print(
                '⚠️ Unexpected response type: ${response.data.runtimeType}',
              );
              print('Response data: ${response.data}');
            }
            images = [];
          }

          final Map<String, String?> imageMap = {};

          if (kDebugMode && attempt == 0) {
            print(
              '✅ Received ${images.length} image records from API for builds',
            );
            if (images.isEmpty) {
              print('⚠️ No build images found in response');
              print('Request was: locationType=BUILD, buildId=$validIds');
            } else {
              print(
                'Sample image record keys: ${images.first?.keys?.toList() ?? 'null'}',
              );
              print('Sample image record: ${images.first}');
            }
          }

          // Group images by build ID
          for (final image in images) {
            // Backend returns the build ID in either 'targetId' or 'buildId'.
            // Check for both camelCase and PascalCase versions of these keys.
            final targetId =
                image['targetId']?.toString() ??
                image['TargetId']?.toString() ??
                image['buildId']?.toString() ??
                image['BuildId']?.toString();
            // Backend returns Id - check both camelCase and PascalCase
            final imageId = image['id']?.toString() ?? image['Id']?.toString();

            if (kDebugMode && attempt == 0) {
              print(
                '  📷 Build image record: targetId=$targetId, imageId=$imageId',
              );
              print('     All keys: ${image.keys.toList()}');
            }

            if (targetId != null && imageId != null) {
              // Try to find matching build ID (case-insensitive)
              String? matchedBuildId;
              try {
                matchedBuildId = buildIds.firstWhere(
                  (id) => id.toLowerCase() == targetId.toLowerCase(),
                  orElse: () => '',
                );
              } catch (e) {
                // No match found
                matchedBuildId = null;
              }

              if (matchedBuildId != null && matchedBuildId.isNotEmpty) {
                // Only set the first image for each build
                if (!imageMap.containsKey(matchedBuildId)) {
                  imageMap[matchedBuildId] = imageId;
                  if (kDebugMode && attempt == 0) {
                    print(
                      '  ✅ Mapped: buildId=$matchedBuildId -> imageId=$imageId',
                    );
                  }
                }
              } else if (kDebugMode && attempt == 0) {
                print('  ⚠️ No matching build ID for targetId=$targetId');
                print('     Looking for: ${buildIds.join(", ")}');
              }
            } else if (kDebugMode && attempt == 0) {
              print('  ⚠️ Missing targetId or imageId in response');
            }
          }

          if (kDebugMode && attempt == 0) {
            print(
              '📊 Final mapping: Found ${imageMap.length} out of ${buildIds.length} build images',
            );
            imageMap.forEach((buildId, imageId) {
              print('  $buildId -> $imageId');
            });
            if (imageMap.isEmpty && images.isNotEmpty) {
              print(
                '⚠️ WARNING: Images returned but no matching targetIds found',
              );
              print('   Expected build IDs: $validIds');
              print(
                '   Received targetIds from API: ${images.map((img) => img['targetId'] ?? img['TargetId']).whereType<String>().toList()}',
              );
            }
          }

          // Ensure all valid build IDs are in the map (with null if no image)
          final result = <String, String?>{};
          for (final buildId in validIds) {
            result[buildId] = imageMap[buildId];
          }

          return result;
        }

        // If not 200, return empty map for this batch
        return {for (var id in validIds) id: null};
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;

        // Handle rate limiting (429)
        if (statusCode == 429) {
          final retryAfter = _getRetryAfterDelay(e.response?.headers, attempt);

          if (kDebugMode) {
            print(
              'Rate limited (429). Waiting ${retryAfter.inSeconds}s before retry ${attempt + 1}/$maxRetries',
            );
          }

          // Wait before retrying
          await Future.delayed(retryAfter);
          continue; // Retry
        }

        // For other errors, wait a bit and retry
        if (attempt < maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (attempt + 1));
          if (kDebugMode) {
            print(
              'Error ${statusCode ?? 'unknown'}. Retrying in ${delay.inMilliseconds}ms',
            );
          }
          await Future.delayed(delay);
          continue;
        }

        // Last attempt failed
        if (kDebugMode) {
          print(
            'Failed to fetch build images after $maxRetries attempts: ${e.message}',
          );
        }
        return {for (var id in validIds) id: null};
      } catch (e) {
        if (attempt < maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (attempt + 1));
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          print('Error fetching build images: $e');
        }
        return {for (var id in validIds) id: null};
      }
    }

    return {for (var id in validIds) id: null};
  }

  /// Fetches the primary image ID for a user guide.
  Future<String?> getGuideImageId(String guideId) async {
    if (guideId.isEmpty) return null;

    try {
      final url = '$apiBaseUrl/Images/get';
      final body = {
        'locationType': ['GUIDE'],
        'userGuideId': [guideId],
        'paging': false,
      };

      if (kDebugMode) {
        print('Fetching images for guide: $guideId');
      }

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> images = response.data;
        if (images.isNotEmpty) {
          final imageId =
              images[0]['id']?.toString() ?? images[0]['Id']?.toString();
          if (kDebugMode) {
            print('Found image for guide $guideId: $imageId');
          }
          return imageId;
        }
      }

      if (kDebugMode) {
        print('No images found for guide: $guideId');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching guide image: $e');
      }
      return null;
    }
  }

  /// Fetches images for multiple guides with batching and retry logic.
  Future<Map<String, String?>> getGuideImageIds(List<String> guideIds) async {
    final validGuideIds = guideIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();

    if (validGuideIds.isEmpty) {
      if (kDebugMode) {
        print('⚠️ No valid guide IDs provided (all were empty/null)');
      }
      return {};
    }

    if (kDebugMode && validGuideIds.length != guideIds.length) {
      print(
        '⚠️ Filtered out ${guideIds.length - validGuideIds.length} empty guide IDs',
      );
    }

    const batchSize = 50;
    final result = <String, String?>{};

    for (int i = 0; i < validGuideIds.length; i += batchSize) {
      final batch = validGuideIds.skip(i).take(batchSize).toList();

      try {
        final batchResult = await _fetchGuideImagesBatch(batch);
        result.addAll(batchResult);

        if (i + batchSize < guideIds.length) {
          await Future.delayed(const Duration(milliseconds: 100));
        }
      } catch (e) {
        if (kDebugMode) {
          print('Error fetching batch of guide images: $e');
        }
        for (final id in batch) {
          result[id] = null;
        }
      }
    }

    return result;
  }

  Future<Map<String, String?>> _fetchGuideImagesBatch(
    List<String> guideIds, {
    int maxRetries = 3,
  }) async {
    final validIds = guideIds
        .where((id) => id.isNotEmpty && id.trim().isNotEmpty)
        .toList();
    if (validIds.isEmpty) {
      if (kDebugMode) {
        print('⚠️ _fetchGuideImagesBatch: No valid guide IDs in batch');
      }
      return {};
    }

    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final url = '$apiBaseUrl/Images/get';
        final body = {
          'locationType': ['GUIDE'],
          'userGuideId': validIds,
          'paging': false,
        };

        if (kDebugMode && attempt == 0) {
          print(
            'Fetching images for ${validIds.length} guides (attempt ${attempt + 1})',
          );
          print('Request body: $body');
        }

        final response = await _dio.post(url, data: body);

        if (response.statusCode == 200) {
          final List<dynamic> images = response.data is List
              ? response.data as List<dynamic>
              : [];
          final Map<String, String?> imageMap = {};

          for (final image in images) {
            final targetId =
                image['targetId']?.toString() ??
                image['TargetId']?.toString() ??
                image['userGuideId']?.toString() ??
                image['UserGuideId']?.toString();
            final imageId = image['id']?.toString() ?? image['Id']?.toString();

            if (targetId != null && imageId != null) {
              String? matchedGuideId;
              try {
                matchedGuideId = guideIds.firstWhere(
                  (id) => id.toLowerCase() == targetId.toLowerCase(),
                  orElse: () => '',
                );
              } catch (_) {
                matchedGuideId = null;
              }

              if (matchedGuideId != null && matchedGuideId.isNotEmpty) {
                imageMap.putIfAbsent(matchedGuideId, () => imageId);
              }
            }
          }

          final result = <String, String?>{};
          for (final guideId in validIds) {
            result[guideId] = imageMap[guideId];
          }

          return result;
        }

        return {for (var id in validIds) id: null};
      } on DioException catch (e) {
        final statusCode = e.response?.statusCode;
        if (statusCode == 429) {
          final retryAfter = _getRetryAfterDelay(e.response?.headers, attempt);
          if (kDebugMode) {
            print(
              'Guide images rate limited. Waiting ${retryAfter.inSeconds}s',
            );
          }
          await Future.delayed(retryAfter);
          continue;
        }

        if (attempt < maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (attempt + 1));
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          print(
            'Failed to fetch guide images after $maxRetries attempts: ${e.message}',
          );
        }
        return {for (var id in validIds) id: null};
      } catch (e) {
        if (attempt < maxRetries - 1) {
          final delay = Duration(milliseconds: 500 * (attempt + 1));
          await Future.delayed(delay);
          continue;
        }

        if (kDebugMode) {
          print('Error fetching guide images: $e');
        }
        return {for (var id in validIds) id: null};
      }
    }

    return {for (var id in validIds) id: null};
  }

  /// Constructs the download URL for an image ID.
  /// Fetches images for a forum post.
  /// Returns a list of image URLs.
  Future<List<String>> getForumPostImages(String postId) async {
    try {
      final url = '$apiBaseUrl/Images/get';
      final body = {
        'locationType': ['FORUM'],
        'forumPostId': [postId],
        'paging': false,
      };

      if (kDebugMode) {
        print('Fetching images for forum post: $postId');
      }

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> images = response.data;
        final List<String> imageUrls = [];

        for (var imgJson in images) {
          if (imgJson is Map<String, dynamic>) {
            final imageId = (imgJson['id'] ?? imgJson['Id'] ?? '').toString();
            if (imageId.isNotEmpty) {
              imageUrls.add('$apiBaseUrl/Images/download/$imageId');
            }
          }
        }

        if (kDebugMode) {
          print('Found ${imageUrls.length} images for forum post $postId');
        }
        return imageUrls;
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching forum post images: $e');
      }
      return [];
    }
  }

  /// Fetches images for a comment.
  /// Returns a list of image URLs.
  Future<List<String>> getCommentImages(String commentId) async {
    try {
      final url = '$apiBaseUrl/Images/get';
      final body = {
        'locationType': ['COMMENT'],
        'userCommentId': [commentId],
        'paging': false,
      };

      if (kDebugMode) {
        print('Fetching images for comment: $commentId');
      }

      final response = await _dio.post(url, data: body);

      if (response.statusCode == 200 && response.data is List) {
        final List<dynamic> images = response.data;
        final List<String> imageUrls = [];

        for (var imgJson in images) {
          if (imgJson is Map<String, dynamic>) {
            final imageId = (imgJson['id'] ?? imgJson['Id'] ?? '').toString();
            if (imageId.isNotEmpty) {
              imageUrls.add('$apiBaseUrl/Images/download/$imageId');
            }
          }
        }

        if (kDebugMode) {
          print('Found ${imageUrls.length} images for comment $commentId');
        }
        return imageUrls;
      }

      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching comment images: $e');
      }
      return [];
    }
  }

  /// Fetches images for a message.
  /// Returns a list of image URLs.
  Future<List<String>> getMessageImages(String messageId) async {
    try {
      final url = '$apiBaseUrl/Images/get';
      final body = {
        'locationType': ['MESSAGE'],
        'MessageId': [messageId],
        'paging': false,
      };

      if (kDebugMode) {
        print('🔍 Fetching images for message: $messageId');
        print('📤 Request body: $body');
      }

      final response = await _dio.post(url, data: body);

      if (kDebugMode) {
        print('📥 Response status: ${response.statusCode}');
        print('📥 Response data type: ${response.data.runtimeType}');
        print('📥 Response data: ${response.data}');
      }

      if (response.statusCode == 200) {
        List<dynamic> images = [];
        
        if (response.data is List) {
          images = response.data as List<dynamic>;
        } else if (response.data is Map) {
          // Sometimes backend returns wrapped in an object
          final data = response.data as Map<String, dynamic>;
          if (data.containsKey('data') && data['data'] is List) {
            images = data['data'] as List<dynamic>;
          }
        }

        final List<String> imageUrls = [];

        for (var imgJson in images) {
          if (imgJson is Map<String, dynamic>) {
            final imageId = (imgJson['id'] ?? imgJson['Id'] ?? '').toString();
            if (imageId.isNotEmpty) {
              final imageUrl = '$apiBaseUrl/Images/download/$imageId';
              imageUrls.add(imageUrl);
              if (kDebugMode) {
                print('✅ Found image ID: $imageId, URL: $imageUrl');
              }
            }
          }
        }

        if (kDebugMode) {
          print('📊 Total images found: ${imageUrls.length} for message $messageId');
        }
        return imageUrls;
      }

      if (kDebugMode) {
        print('⚠️ Unexpected status code: ${response.statusCode}');
      }
      return [];
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('❌ Error fetching message images: $e');
        print('Stack trace: $stackTrace');
      }
      return [];
    }
  }

  static String getImageUrl(String? imageId) {
    if (imageId == null || imageId.isEmpty) return '';
    return '$apiBaseUrl/Images/download/$imageId';
  }
}

/// Provider for ImageService using authenticated Dio.
final imageServiceProvider = Provider<ImageService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return ImageService(dio);
});

/// Provider that maps component IDs to image IDs.
final componentImageMapProvider =
    FutureProvider.family<Map<String, String?>, List<String>>((
      ref,
      componentIds,
    ) async {
      final imageService = ref.watch(imageServiceProvider);
      return await imageService.getComponentImageIds(componentIds);
    });

/// Provider that maps build IDs to image IDs.
/// Using autoDispose to ensure it refetches when not listened to anymore.
/// The family parameter is a record containing the build IDs and a key to force re-fetch.
final buildImageMapProvider = FutureProvider.autoDispose
    .family<Map<String, String?>, ({List<String> buildIds, int key})>((
      ref,
      params,
    ) async {
      final imageService = ref.watch(imageServiceProvider);
      // We only need the buildIds for the service call. The key is for forcing re-evaluation.
      return await imageService.getBuildImageIds(params.buildIds);
    });

/// Provider for fetching forum post images
final forumPostImagesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, postId) async {
      final imageService = ref.watch(imageServiceProvider);
      return await imageService.getForumPostImages(postId);
    });

/// Provider for fetching comment images
final commentImagesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, commentId) async {
      final imageService = ref.watch(imageServiceProvider);
      return await imageService.getCommentImages(commentId);
    });

/// Provider for fetching message images
final messageImagesProvider = FutureProvider.autoDispose
    .family<List<String>, String>((ref, messageId) async {
      final imageService = ref.watch(imageServiceProvider);
      return await imageService.getMessageImages(messageId);
    });
