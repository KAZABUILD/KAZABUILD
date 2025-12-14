/// Service for admin-related API calls
library;

import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:frontend/models/api_constants.dart';

/// Service class for handling admin operations
class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  /// Gets users with filtering and optional pagination
  /// If page and pageLength are provided, pagination is enabled
  Future<Response> getUsers({
    String? query,
    List<String>? genders,
    List<String>? userRoles,
    int? page,
    int? pageLength,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    final data = <String, dynamic>{
      'Query': query ?? '',
      'SortDirection': sortDirection,
    };

    // Enable pagination if both page and pageLength are provided
    if (page != null && pageLength != null && page > 0 && pageLength > 0) {
      data['Paging'] = true;
      data['Page'] = page;
      data['PageLength'] = pageLength;
      print(
        'AdminService.getUsers: Getting users with pagination (page: $page, pageLength: $pageLength)',
      );
    } else {
      data['Paging'] = false;
      print('AdminService.getUsers: Getting all users (no pagination)');
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (genders != null && genders.isNotEmpty) {
      data['Gender'] = genders;
    }

    if (userRoles != null && userRoles.isNotEmpty) {
      data['UserRole'] = userRoles;
    }

    try {
      final response = await _dio.post('$apiBaseUrl/Users/get', data: data);
      return response;
    } catch (e) {
      print('Error in getUsers: $e');
      rethrow;
    }
  }

  /// Updates a user
  Future<Response> updateUser(String userId, Map<String, dynamic> data) async {
    return _dio.put('$apiBaseUrl/Users/$userId', data: data);
  }

  /// Deletes a user
  Future<Response> deleteUser(String userId) async {
    return _dio.delete('$apiBaseUrl/Users/$userId');
  }

  /// Bans a user
  /// [bannedUntil] is the date when the ban expires. If null, ban is permanent.
  /// If [bannedUntil] is in the past or null, sets permanent ban (BannedUntil = null, UserRole = BANNED)
  Future<Response> banUser(String userId, {DateTime? bannedUntil}) async {
    final data = <String, dynamic>{
      'UserRole': 0, // BANNED = 0
    };

    if (bannedUntil != null && bannedUntil.isAfter(DateTime.now())) {
      // Temporary ban - set BannedUntil
      data['BannedUntil'] = bannedUntil.toIso8601String();
    } else {
      // Permanent ban - set BannedUntil to null
      data['BannedUntil'] = null;
    }

    return updateUser(userId, data);
  }

  /// Unbans a user (removes ban)
  Future<Response> unbanUser(String userId) async {
    final data = <String, dynamic>{
      'UserRole': 1, // GUEST = 1 (or you can use USER = 3)
      'BannedUntil': null,
    };

    return updateUser(userId, data);
  }

  /// Gets builds with filtering and optional pagination
  /// If page and pageLength are provided, pagination is enabled
  Future<Response> getBuilds({
    String? query,
    List<String>? status,
    List<String>? userIds,
    int? page,
    int? pageLength,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    final data = <String, dynamic>{
      'Query': query ?? '',
      'SortDirection': sortDirection,
    };

    // Enable pagination if both page and pageLength are provided
    if (page != null && pageLength != null && page > 0 && pageLength > 0) {
      data['Paging'] = true;
      data['Page'] = page;
      data['PageLength'] = pageLength;
      print(
        'AdminService.getBuilds: Getting builds with pagination (page: $page, pageLength: $pageLength)',
      );
    } else {
      data['Paging'] = false;
      print('AdminService.getBuilds: Getting all builds (no pagination)');
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (status != null && status.isNotEmpty) {
      data['Status'] = status;
    }

    if (userIds != null && userIds.isNotEmpty) {
      data['UserId'] = userIds;
    }

    try {
      final response = await _dio.post('$apiBaseUrl/Builds/get', data: data);
      return response;
    } catch (e) {
      print('Error in getBuilds: $e');
      rethrow;
    }
  }

  /// Gets builds count with filtering (no pagination)
  /// Uses the get-count endpoint to get total count of all builds matching filters
  Future<int> getBuildsCount({
    String? query,
    List<String>? status,
    List<String>? userIds,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    final data = <String, dynamic>{
      'Query': query?.trim().isEmpty == true ? '' : (query ?? ''),
      'SortDirection': sortDirection,
      'Paging': false, // No pagination for count - we want total count
    };

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (status != null && status.isNotEmpty) {
      data['Status'] = status;
    }

    if (userIds != null && userIds.isNotEmpty) {
      data['UserId'] = userIds;
    }

    try {
      print(
        'AdminService.getBuildsCount: Calling get-count endpoint with data: $data',
      );
      final response = await _dio.post(
        '$apiBaseUrl/Builds/get-count',
        data: data,
      );
      if (response.statusCode == 200) {
        // Backend returns an integer count
        final count = response.data;
        int result = 0;
        if (count is int) {
          result = count;
        } else if (count is double) {
          result = count.toInt();
        } else if (count is String) {
          result = int.tryParse(count) ?? 0;
        } else if (count is num) {
          result = count.toInt();
        }
        print('AdminService.getBuildsCount: Received count: $result');
        return result;
      }
      throw Exception('Failed to get builds count: ${response.statusCode}');
    } catch (e) {
      print('Error in getBuildsCount: $e');
      rethrow;
    }
  }

  /// Gets forum posts with filtering and optional pagination
  /// If page and pageLength are provided, pagination is enabled
  Future<Response> getForumPosts({
    String? query,
    List<String>? topics,
    List<String>? creatorIds,
    int? page,
    int? pageLength,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    final data = <String, dynamic>{
      'Query': query ?? '',
      'SortDirection': sortDirection,
    };

    // Enable pagination if both page and pageLength are provided
    if (page != null && pageLength != null && page > 0 && pageLength > 0) {
      data['Paging'] = true;
      data['Page'] = page;
      data['PageLength'] = pageLength;
      print(
        'AdminService.getForumPosts: Getting forum posts with pagination (page: $page, pageLength: $pageLength)',
      );
    } else {
      data['Paging'] = false;
      print(
        'AdminService.getForumPosts: Getting all forum posts (no pagination)',
      );
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (topics != null && topics.isNotEmpty) {
      data['Topic'] = topics;
    }

    if (creatorIds != null && creatorIds.isNotEmpty) {
      data['CreatorId'] = creatorIds;
    }

    try {
      final response = await _dio.post(
        '$apiBaseUrl/ForumPosts/get',
        data: data,
      );
      return response;
    } catch (e) {
      print('Error in getForumPosts: $e');
      rethrow;
    }
  }

  /// Gets forum posts count with filtering (without pagination)
  Future<Response> getForumPostsCount({
    String? query,
    List<String>? topics,
    List<String>? creatorIds,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    final data = <String, dynamic>{
      'Query': query ?? '',
      'SortDirection': sortDirection,
      'Paging': false, // No pagination for count
    };

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (topics != null && topics.isNotEmpty) {
      data['Topic'] = topics;
    }

    if (creatorIds != null && creatorIds.isNotEmpty) {
      data['CreatorId'] = creatorIds;
    }

    try {
      final response = await _dio.post(
        '$apiBaseUrl/ForumPosts/get-count',
        data: data,
      );
      return response;
    } catch (e) {
      print('Error in getForumPostsCount: $e');
      rethrow;
    }
  }

  /// Gets all components with pagination and filtering
  /// Note: Backend requires a type discriminator ($type) for polymorphic deserialization
  /// When componentTypes is null or contains multiple types, we use "Case" as a generic discriminator
  /// When componentTypes has a single type, we use that type as the discriminator for better filtering
  Future<Response> getComponents({
    String? query,
    List<String>? componentTypes,
    List<String>? names,
    List<String>? manufacturers,
    int? page,
    int? pageLength,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    // Determine which type discriminator to use
    // If componentTypes is null, we need to fetch all types
    // We'll make multiple requests for each type and combine them
    String? typeDiscriminator;
    List<String>? typesToFetch;

    if (componentTypes != null && componentTypes.length == 1) {
      // Map component type to discriminator value
      final type = componentTypes[0].toUpperCase();
      final typeMap = {
        'CPU': 'CPU',
        'GPU': 'GPU',
        'MEMORY': 'Memory',
        'MOTHERBOARD': 'Motherboard',
        'STORAGE': 'Storage',
        'POWER_SUPPLY': 'PowerSupply',
        'CASE': 'Case',
        'COOLER': 'Cooler',
        'CASE_FAN': 'CaseFan',
        'MONITOR': 'Monitor',
      };
      typeDiscriminator = typeMap[type] ?? 'Case';
    } else if (componentTypes == null || componentTypes.isEmpty) {
      // When no filter, fetch all component types
      // We'll use a list of all types and make requests for each
      typesToFetch = [
        'CPU',
        'GPU',
        'Memory',
        'Motherboard',
        'Storage',
        'PowerSupply',
        'Case',
        'Cooler',
        'CaseFan',
        'Monitor',
      ];
      typeDiscriminator =
          'Case'; // Default, but we'll override for each request
    } else {
      // Multiple types - use first one as discriminator, but filter by Type field
      final type = componentTypes[0].toUpperCase();
      final typeMap = {
        'CPU': 'CPU',
        'GPU': 'GPU',
        'MEMORY': 'Memory',
        'MOTHERBOARD': 'Motherboard',
        'STORAGE': 'Storage',
        'POWER_SUPPLY': 'PowerSupply',
        'CASE': 'Case',
        'COOLER': 'Cooler',
        'CASE_FAN': 'CaseFan',
        'MONITOR': 'Monitor',
      };
      typeDiscriminator = typeMap[type] ?? 'Case';
    }

    // Enable pagination if both page and pageLength are provided
    final pageLengthValue = pageLength ?? 20;
    final usePagination =
        page != null && pageLength != null && page > 0 && pageLengthValue > 0;

    // If we need to fetch all types, make multiple requests
    if (typesToFetch != null) {
      // When fetching all types, we can't easily paginate across all types
      // So we'll fetch all and let client-side handle it, or fetch with pagination per type
      // For simplicity, if pagination is requested with "All", we'll fetch first page of each type
      final allComponents = <Map<String, dynamic>>[];

      if (usePagination) {
        // With pagination and "All" types, fetch first page of each type
        // This is a simplified approach - ideally we'd need to calculate which types to fetch
        for (final type in typesToFetch) {
          try {
            final data = <String, dynamic>{
              r'$type': type,
              'Query': query ?? '',
              'SortDirection': sortDirection,
              'Paging': true,
              'Page': 1, // Fetch first page of each type
              'PageLength': (pageLengthValue / typesToFetch.length)
                  .ceil(), // Distribute pageLength across types
            };

            if (orderBy != null && orderBy.isNotEmpty) {
              data['OrderBy'] = orderBy;
            }

            if (names != null && names.isNotEmpty) {
              data['Name'] = names;
            }

            if (manufacturers != null && manufacturers.isNotEmpty) {
              data['Manufacturer'] = manufacturers;
            }

            final response = await _dio.post(
              '$apiBaseUrl/Components/get',
              data: data,
            );
            if (response.data is List) {
              allComponents.addAll(
                (response.data as List).cast<Map<String, dynamic>>(),
              );
            }
          } catch (e) {
            print('Error fetching $type components: $e');
            // Continue with other types
          }
        }
      } else {
        // No pagination - fetch all components of all types
        for (final type in typesToFetch) {
          try {
            final data = <String, dynamic>{
              r'$type': type,
              'Query': query ?? '',
              'SortDirection': sortDirection,
              'Paging': false,
            };

            if (orderBy != null && orderBy.isNotEmpty) {
              data['OrderBy'] = orderBy;
            }

            if (names != null && names.isNotEmpty) {
              data['Name'] = names;
            }

            if (manufacturers != null && manufacturers.isNotEmpty) {
              data['Manufacturer'] = manufacturers;
            }

            final response = await _dio.post(
              '$apiBaseUrl/Components/get',
              data: data,
            );
            if (response.data is List) {
              allComponents.addAll(
                (response.data as List).cast<Map<String, dynamic>>(),
              );
            }
          } catch (e) {
            print('Error fetching $type components: $e');
            // Continue with other types
          }
        }
      }

      // Return combined response
      return Response(
        data: allComponents,
        statusCode: 200,
        requestOptions: RequestOptions(
          path: '$apiBaseUrl/Components/get',
          method: 'POST',
        ),
        headers: Headers(),
        isRedirect: false,
        redirects: [],
        statusMessage: 'OK',
      );
    }

    final data = <String, dynamic>{
      r'$type':
          typeDiscriminator, // Type discriminator for polymorphic deserialization
      'Query': query ?? '',
      'SortDirection': sortDirection,
    };

    // Enable pagination if both page and pageLength are provided
    if (usePagination) {
      data['Paging'] = true;
      data['Page'] = page;
      data['PageLength'] = pageLength;
      print(
        'AdminService.getComponents: Getting components with pagination (page: $page, pageLength: $pageLength)',
      );
    } else {
      data['Paging'] = false;
      print(
        'AdminService.getComponents: Getting all components (no pagination)',
      );
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (componentTypes != null && componentTypes.isNotEmpty) {
      data['Type'] = componentTypes;
    }

    if (names != null && names.isNotEmpty) {
      data['Name'] = names;
    }

    if (manufacturers != null && manufacturers.isNotEmpty) {
      data['Manufacturer'] = manufacturers;
    }

    try {
      final response = await _dio.post(
        '$apiBaseUrl/Components/get',
        data: data,
      );
      return response;
    } catch (e) {
      print('Error in getComponents: $e');
      rethrow;
    }
  }

  /// Gets components count with filtering (without pagination)
  /// Uses the same filtering logic as getComponents but returns only the count
  Future<Response> getComponentsCount({
    String? query,
    List<String>? componentTypes,
    List<String>? names,
    List<String>? manufacturers,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    // Determine which type discriminator to use (same logic as getComponents)
    String? typeDiscriminator;
    List<String>? typesToFetch;

    if (componentTypes != null && componentTypes.length == 1) {
      final type = componentTypes[0].toUpperCase();
      final typeMap = {
        'CPU': 'CPU',
        'GPU': 'GPU',
        'MEMORY': 'Memory',
        'MOTHERBOARD': 'Motherboard',
        'STORAGE': 'Storage',
        'POWER_SUPPLY': 'PowerSupply',
        'CASE': 'Case',
        'COOLER': 'Cooler',
        'CASE_FAN': 'CaseFan',
        'MONITOR': 'Monitor',
      };
      typeDiscriminator = typeMap[type] ?? 'Case';
    } else if (componentTypes == null || componentTypes.isEmpty) {
      typesToFetch = [
        'CPU',
        'GPU',
        'Memory',
        'Motherboard',
        'Storage',
        'PowerSupply',
        'Case',
        'Cooler',
        'CaseFan',
        'Monitor',
      ];
      typeDiscriminator = 'Case';
    } else {
      final type = componentTypes[0].toUpperCase();
      final typeMap = {
        'CPU': 'CPU',
        'GPU': 'GPU',
        'MEMORY': 'Memory',
        'MOTHERBOARD': 'Motherboard',
        'STORAGE': 'Storage',
        'POWER_SUPPLY': 'PowerSupply',
        'CASE': 'Case',
        'COOLER': 'Cooler',
        'CASE_FAN': 'CaseFan',
        'MONITOR': 'Monitor',
      };
      typeDiscriminator = typeMap[type] ?? 'Case';
    }

    // If we need to fetch all types, sum counts from all types
    if (typesToFetch != null) {
      int totalCount = 0;
      for (final type in typesToFetch) {
        try {
          final data = <String, dynamic>{
            r'$type': type,
            'Query': query ?? '',
            'SortDirection': sortDirection,
            'Paging': false, // No pagination for count
          };

          if (orderBy != null && orderBy.isNotEmpty) {
            data['OrderBy'] = orderBy;
          }

          if (names != null && names.isNotEmpty) {
            data['Name'] = names;
          }

          if (manufacturers != null && manufacturers.isNotEmpty) {
            data['Manufacturer'] = manufacturers;
          }

          final response = await _dio.post(
            '$apiBaseUrl/Components/get-count',
            data: data,
          );
          if (response.statusCode == 200) {
            final count = response.data;
            if (count is num) {
              totalCount += count.toInt();
            }
          }
        } catch (e) {
          print('Error fetching $type components count: $e');
          // Continue with other types
        }
      }

      return Response(
        data: totalCount,
        statusCode: 200,
        requestOptions: RequestOptions(
          path: '$apiBaseUrl/Components/get-count',
          method: 'POST',
        ),
        headers: Headers(),
        isRedirect: false,
        redirects: [],
        statusMessage: 'OK',
      );
    }

    // Single type or filtered types
    final data = <String, dynamic>{
      r'$type': typeDiscriminator,
      'Query': query ?? '',
      'SortDirection': sortDirection,
      'Paging': false, // No pagination for count
    };

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (componentTypes != null && componentTypes.isNotEmpty) {
      data['Type'] = componentTypes;
    }

    if (names != null && names.isNotEmpty) {
      data['Name'] = names;
    }

    if (manufacturers != null && manufacturers.isNotEmpty) {
      data['Manufacturer'] = manufacturers;
    }

    try {
      final response = await _dio.post(
        '$apiBaseUrl/Components/get-count',
        data: data,
      );
      return response;
    } catch (e) {
      print('Error in getComponentsCount: $e');
      rethrow;
    }
  }

  /// Gets all guides with pagination and filtering
  /// Note: Guides endpoint may not exist in backend yet
  Future<Response> getGuides({
    String? query,
    List<String>? categories,
    int? page,
    int? pageLength,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    final data = <String, dynamic>{
      'Query': query ?? '',
      'SortDirection': sortDirection,
    };

    if (page != null && pageLength != null && page > 0 && pageLength > 0) {
      data['Paging'] = true;
      data['Page'] = page;
      data['PageLength'] = pageLength;
      print(
        'AdminService.getGuides: Pagination enabled (page: $page, len: $pageLength)',
      );
    } else {
      data['Paging'] = false;
    }

    if (orderBy != null && orderBy.isNotEmpty) {
      data['OrderBy'] = orderBy;
    }

    if (categories != null && categories.isNotEmpty) {
      data['Category'] = categories;
    }

    try {
      final response = await _dio.post('$apiBaseUrl/UserGuide/get', data: data);
      return response;
    } catch (e) {
      print('Error in getGuides: $e');
      rethrow;
    }
  }

  /// Creates a new guide
  Future<Response> createGuide(Map<String, dynamic> data) async {
    return _dio.post('$apiBaseUrl/UserGuide/add', data: data);
  }

  /// Updates an existing guide
  Future<Response> updateGuide(
    String guideId,
    Map<String, dynamic> data,
  ) async {
    return _dio.put('$apiBaseUrl/UserGuide/$guideId', data: data);
  }

  /// Deletes a guide
  Future<Response> deleteGuide(String guideId) async {
    return _dio.delete('$apiBaseUrl/UserGuide/$guideId');
  }

  /// Recursively deletes comments and their images
  /// This handles parent-child relationships by deleting leaf comments first
  Future<void> deleteCommentsRecursively(
    List<Map<String, dynamic>> commentMaps,
  ) async {
    if (commentMaps.isEmpty) return;

    print(
      'deleteCommentsRecursively: Processing ${commentMaps.length} comments',
    );

    // Extract comment IDs (keep original format, don't normalize)
    final Map<String, String> commentIdMap =
        {}; // original -> original (for consistency)
    final Set<String> allCommentIds = {};

    for (var comment in commentMaps) {
      final commentId = (comment['id'] ?? comment['Id'] ?? '')
          .toString()
          .trim();
      if (commentId.isEmpty) {
        print(
          'deleteCommentsRecursively: Warning - found comment with empty ID',
        );
        continue;
      }
      commentIdMap[commentId] = commentId;
      allCommentIds.add(commentId);
    }

    print(
      'deleteCommentsRecursively: Found ${allCommentIds.length} unique comment IDs',
    );

    // Build parent-to-children map
    final Map<String, List<String>> parentToChildren = {};
    for (var comment in commentMaps) {
      final commentId = (comment['id'] ?? comment['Id'] ?? '')
          .toString()
          .trim();
      if (commentId.isEmpty || !allCommentIds.contains(commentId)) continue;

      // Try multiple possible field names for parent comment ID
      final parentCommentIdRaw =
          comment['parentCommentId'] ?? comment['ParentCommentId'];

      if (parentCommentIdRaw != null) {
        final parentId = parentCommentIdRaw.toString().trim();

        // Only add if parent is in our set of comments to delete
        if (allCommentIds.contains(parentId)) {
          parentToChildren.putIfAbsent(parentId, () => []).add(commentId);
          print(
            'deleteCommentsRecursively: Found parent-child relationship: $parentId -> $commentId',
          );
        }
      }
    }

    print(
      'deleteCommentsRecursively: Found ${parentToChildren.length} parent comments with children',
    );

    // Delete comments recursively (leaf comments first)
    final Set<String> deletedIds = {};
    int maxIterations = 200;
    int iteration = 0;

    while (deletedIds.length < allCommentIds.length &&
        iteration < maxIterations) {
      iteration++;
      print(
        'deleteCommentsRecursively: Iteration $iteration - Deleted: ${deletedIds.length}/${allCommentIds.length}',
      );

      final List<String> toDelete = [];

      // Find comments that can be deleted (no children or all children already deleted)
      for (var commentId in allCommentIds) {
        if (deletedIds.contains(commentId)) continue;
        final children = parentToChildren[commentId] ?? [];
        if (children.isEmpty ||
            children.every((childId) => deletedIds.contains(childId))) {
          toDelete.add(commentId);
        }
      }

      print(
        'deleteCommentsRecursively: Found ${toDelete.length} comments ready to delete',
      );

      if (toDelete.isEmpty) {
        print(
          'deleteCommentsRecursively: No comments can be deleted. This might indicate a circular reference or missing parent.',
        );
        // Try to delete remaining comments anyway (might have circular references)
        for (var commentId in allCommentIds) {
          if (deletedIds.contains(commentId)) continue;
          try {
            print(
              'deleteCommentsRecursively: Attempting to force-delete comment $commentId',
            );
            await _dio.delete('$apiBaseUrl/UserComments/$commentId');
            deletedIds.add(commentId);
            print(
              'deleteCommentsRecursively: Successfully force-deleted comment $commentId',
            );
          } catch (e) {
            print(
              'deleteCommentsRecursively: Error force-deleting comment $commentId: $e',
            );
          }
        }
        break;
      }

      // Delete all eligible comments
      for (var commentId in toDelete) {
        if (deletedIds.contains(commentId)) continue;
        try {
          print('deleteCommentsRecursively: Deleting comment $commentId');
          await _dio.delete('$apiBaseUrl/UserComments/$commentId');
          deletedIds.add(commentId);
          print(
            'deleteCommentsRecursively: Successfully deleted comment $commentId',
          );
        } catch (e) {
          print(
            'deleteCommentsRecursively: Error deleting comment $commentId: $e',
          );
          // If deletion fails, it might be because child comments still exist
          // Try to delete children first
          final children = parentToChildren[commentId] ?? [];
          for (var childId in children) {
            if (!deletedIds.contains(childId)) {
              try {
                print(
                  'deleteCommentsRecursively: Attempting to delete child comment $childId first',
                );
                await _dio.delete('$apiBaseUrl/UserComments/$childId');
                deletedIds.add(childId);
                print(
                  'deleteCommentsRecursively: Successfully deleted child comment $childId',
                );
              } catch (childError) {
                print(
                  'deleteCommentsRecursively: Error deleting child comment $childId: $childError',
                );
              }
            }
          }
          // Try again to delete the parent
          try {
            await _dio.delete('$apiBaseUrl/UserComments/$commentId');
            deletedIds.add(commentId);
            print(
              'deleteCommentsRecursively: Successfully deleted comment $commentId after deleting children',
            );
          } catch (retryError) {
            print(
              'deleteCommentsRecursively: Still failed to delete comment $commentId after deleting children: $retryError',
            );
          }
        }
      }
    }

    if (deletedIds.length < allCommentIds.length) {
      print(
        'deleteCommentsRecursively: Warning - Could not delete all comments. Deleted: ${deletedIds.length}/${allCommentIds.length}',
      );
      print(
        'deleteCommentsRecursively: Remaining comment IDs: ${allCommentIds.where((id) => !deletedIds.contains(id)).toList()}',
      );
    } else {
      print(
        'deleteCommentsRecursively: Successfully deleted all ${deletedIds.length} comments',
      );
    }
  }

  /// Deletes all BuildInteractions for a build
  Future<void> deleteBuildInteractions(String buildId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/BuildInteractions/get',
        data: {
          'BuildId': [buildId],
          'Paging': false,
        },
      );
      final List<dynamic> interactions = response.data as List<dynamic>? ?? [];
      if (interactions.isEmpty) return;

      for (var interaction in interactions) {
        if (interaction is Map<String, dynamic>) {
          final interactionId = (interaction['id'] ?? interaction['Id'] ?? '')
              .toString();
          if (interactionId.isNotEmpty) {
            try {
              await _dio.delete('$apiBaseUrl/BuildInteractions/$interactionId');
            } catch (e) {
              print('Error deleting build interaction $interactionId: $e');
            }
          }
        }
      }
    } catch (e) {
      print('Error getting build interactions for deletion: $e');
    }
  }

  /// Deletes all comments for a build (and their images)
  Future<void> deleteBuildComments(String buildId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/UserComments/get',
        data: {
          'BuildId': [buildId],
          'CommentTargetType': ['BUILD'],
          'Paging': false,
        },
      );
      final List<dynamic> comments = response.data as List<dynamic>? ?? [];
      if (comments.isEmpty) return;

      final List<Map<String, dynamic>> commentMaps = [];
      for (var comment in comments) {
        if (comment is Map<String, dynamic>) {
          commentMaps.add(comment);
        }
      }

      await deleteCommentsRecursively(commentMaps);
    } catch (e) {
      print('Error getting build comments for deletion: $e');
    }
  }

  /// Deletes all comments for a forum post (and their images)
  Future<void> deleteForumPostComments(String postId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/UserComments/get',
        data: {
          'ForumPostId': [postId],
          'CommentTargetType': ['FORUM'],
          'Paging': false,
        },
      );
      final List<dynamic> comments = response.data as List<dynamic>? ?? [];
      if (comments.isEmpty) return;

      final List<Map<String, dynamic>> commentMaps = [];
      for (var comment in comments) {
        if (comment is Map<String, dynamic>) {
          commentMaps.add(comment);
        }
      }

      await deleteCommentsRecursively(commentMaps);
    } catch (e) {
      print('Error getting forum post comments for deletion: $e');
    }
  }

  /// Deletes all comments for a component (and their images)
  Future<void> deleteComponentComments(String componentId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/UserComments/get',
        data: {
          'ComponentId': [componentId],
          'CommentTargetType': ['COMPONENT'],
          'Paging': false,
        },
      );
      final List<dynamic> comments = response.data as List<dynamic>? ?? [];
      if (comments.isEmpty) return;

      final List<Map<String, dynamic>> commentMaps = [];
      for (var comment in comments) {
        if (comment is Map<String, dynamic>) {
          commentMaps.add(comment);
        }
      }

      await deleteCommentsRecursively(commentMaps);
    } catch (e) {
      print('Error getting component comments for deletion: $e');
    }
  }

  /// Deletes a build
  Future<Response> deleteBuild(String buildId) async {
    await deleteBuildInteractions(buildId); // First, delete all interactions
    await deleteBuildComments(
      buildId,
    ); // Then, delete all comments and their images
    return _dio.delete(
      '$apiBaseUrl/Builds/$buildId',
    ); // Finally, delete the build
  }

  /// Deletes a forum post
  Future<Response> deleteForumPost(String postId) async {
    await deleteForumPostComments(
      postId,
    ); // First, delete all comments and their images
    return _dio.delete(
      '$apiBaseUrl/ForumPosts/$postId',
    ); // Then delete the forum post
  }

  /// Updates a component
  /// Requires componentType to add the correct type discriminator ($type) for polymorphic deserialization
  Future<Response> updateComponent(
    String componentId,
    Map<String, dynamic> data, {
    required String componentType,
  }) async {
    // Map component type to discriminator value (same as in getComponents)
    final type = componentType.toUpperCase();
    final typeMap = {
      'CPU': 'CPU',
      'GPU': 'GPU',
      'MEMORY': 'Memory',
      'MOTHERBOARD': 'Motherboard',
      'STORAGE': 'Storage',
      'POWER_SUPPLY': 'PowerSupply',
      'CASE': 'Case',
      'COOLER': 'Cooler',
      'CASE_FAN': 'CaseFan',
      'MONITOR': 'Monitor',
    };
    final typeDiscriminator = typeMap[type] ?? 'Case';

    // Create a new map with $type as the first property (order matters for some JSON parsers)
    // .NET uses "$type" as the default discriminator property name for polymorphic deserialization
    final updateData = <String, dynamic>{
      '\$type': typeDiscriminator, // Use escape sequence, not raw string
    };

    // Add all other data fields
    updateData.addAll(data);

    // Convert to JSON string manually to ensure $type is properly escaped
    final jsonString = jsonEncode(updateData);

    return _dio.put(
      '$apiBaseUrl/Components/$componentId',
      data: jsonString,
      options: Options(
        headers: {'Content-Type': 'application/json'},
        contentType: 'application/json',
      ),
    );
  }

  /// Deletes a component
  Future<Response> deleteComponent(String componentId) async {
    await deleteComponentComments(
      componentId,
    ); // First, delete all comments and their images
    return _dio.delete(
      '$apiBaseUrl/Components/$componentId',
    ); // Then delete the component
  }

  /// ─────────────── Quiz management (User Preferences + Answers) ───────────────
  Future<Response> getQuizQuestions({List<String>? parentAnswerIds}) async {
    final data = <String, dynamic>{
      'Paging': false,
      'Query': '',
      'SortDirection': 'asc',
      'OrderBy': 'DatabaseEntryAt',
    };
    if (parentAnswerIds != null && parentAnswerIds.isNotEmpty) {
      data['UserPreferenceAnswerId'] = parentAnswerIds;
    }
    try {
      return await _dio.post('$apiBaseUrl/UserPreferences/get', data: data);
    } catch (e) {
      print('Error in getQuizQuestions: $e');
      rethrow;
    }
  }

  Future<Response> createQuizQuestion({
    required String question,
    String? parentAnswerId,
  }) async {
    final data = <String, dynamic>{'Question': question};
    if (parentAnswerId != null && parentAnswerId.isNotEmpty) {
      data['UserPreferenceAnswerId'] = parentAnswerId;
    }
    return _dio.post('$apiBaseUrl/UserPreferences/add', data: data);
  }

  Future<Response> updateQuizQuestion(
    String questionId, {
    String? question,
    String? parentAnswerId,
  }) async {
    final data = <String, dynamic>{};
    if (question != null) {
      data['Question'] = question;
    }
    if (parentAnswerId != null && parentAnswerId.isNotEmpty) {
      data['UserPreferenceAnswerId'] = parentAnswerId;
    }
    return _dio.put('$apiBaseUrl/UserPreferences/$questionId', data: data);
  }

  Future<Response> deleteQuizQuestion(String questionId) async {
    return _dio.delete('$apiBaseUrl/UserPreferences/$questionId');
  }

  Future<Response> getQuizAnswers({List<String>? questionIds}) async {
    final data = <String, dynamic>{
      'Paging': false,
      'Query': '',
      'SortDirection': 'asc',
    };
    if (questionIds != null && questionIds.isNotEmpty) {
      data['UserPreferenceId'] = questionIds;
    }
    try {
      return await _dio.post(
        '$apiBaseUrl/UserPreferenceAnswers/get',
        data: data,
      );
    } catch (e) {
      print('Error in getQuizAnswers: $e');
      rethrow;
    }
  }

  Future<Response> createQuizAnswer({
    required String questionId,
    required String answer,
  }) async {
    final data = {'UserPreferenceId': questionId, 'Answer': answer};
    return _dio.post('$apiBaseUrl/UserPreferenceAnswers/add', data: data);
  }

  Future<Response> updateQuizAnswer(
    String answerId, {
    String? questionId,
    String? answer,
  }) async {
    final data = <String, dynamic>{};
    if (questionId != null && questionId.isNotEmpty) {
      data['UserPreferenceId'] = questionId;
    }
    if (answer != null) {
      data['Answer'] = answer;
    }
    return _dio.put('$apiBaseUrl/UserPreferenceAnswers/$answerId', data: data);
  }

  Future<Response> deleteQuizAnswer(String answerId) async {
    return _dio.delete('$apiBaseUrl/UserPreferenceAnswers/$answerId');
  }
}
