/// Service for admin-related API calls
library;

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
      print('AdminService.getUsers: Getting users with pagination (page: $page, pageLength: $pageLength)');
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
      print('AdminService.getBuilds: Getting builds with pagination (page: $page, pageLength: $pageLength)');
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
      print('AdminService.getForumPosts: Getting forum posts with pagination (page: $page, pageLength: $pageLength)');
    } else {
      data['Paging'] = false;
      print('AdminService.getForumPosts: Getting all forum posts (no pagination)');
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
      final response = await _dio.post('$apiBaseUrl/ForumPosts/get', data: data);
      return response;
    } catch (e) {
      print('Error in getForumPosts: $e');
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
      typesToFetch = ['CPU', 'GPU', 'Memory', 'Motherboard', 'Storage', 'PowerSupply', 'Case', 'Cooler', 'CaseFan', 'Monitor'];
      typeDiscriminator = 'Case'; // Default, but we'll override for each request
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
    final usePagination = page != null && pageLength != null && page > 0 && pageLengthValue > 0;
    
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
              'PageLength': (pageLengthValue / typesToFetch.length).ceil(), // Distribute pageLength across types
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
            
            final response = await _dio.post('$apiBaseUrl/Components/get', data: data);
            if (response.data is List) {
              allComponents.addAll((response.data as List).cast<Map<String, dynamic>>());
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
            
            final response = await _dio.post('$apiBaseUrl/Components/get', data: data);
            if (response.data is List) {
              allComponents.addAll((response.data as List).cast<Map<String, dynamic>>());
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
      r'$type': typeDiscriminator, // Type discriminator for polymorphic deserialization
      'Query': query ?? '',
      'SortDirection': sortDirection,
    };

    // Enable pagination if both page and pageLength are provided
    if (usePagination) {
      data['Paging'] = true;
      data['Page'] = page;
      data['PageLength'] = pageLength;
      print('AdminService.getComponents: Getting components with pagination (page: $page, pageLength: $pageLength)');
    } else {
      data['Paging'] = false;
      print('AdminService.getComponents: Getting all components (no pagination)');
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
      final response = await _dio.post('$apiBaseUrl/Components/get', data: data);
      return response;
    } catch (e) {
      print('Error in getComponents: $e');
      rethrow;
    }
  }

  /// Gets all guides with pagination and filtering
  /// Note: Guides endpoint may not exist in backend yet
  Future<Response> getGuides({
    String? query,
    String? category,
    int? page,
    int? pageLength,
    String? orderBy,
    String sortDirection = 'asc',
  }) async {
    
    // For now, return empty list
    throw UnimplementedError('Guides endpoint not yet available in backend');
  }


  /// Recursively deletes comments and their images
  /// This handles parent-child relationships by deleting leaf comments first
  Future<void> deleteCommentsRecursively(List<Map<String, dynamic>> commentMaps) async {
    if (commentMaps.isEmpty) return;

    print('deleteCommentsRecursively: Processing ${commentMaps.length} comments');
    
    // Extract comment IDs (keep original format, don't normalize)
    final Map<String, String> commentIdMap = {}; // original -> original (for consistency)
    final Set<String> allCommentIds = {};
    
    for (var comment in commentMaps) {
      final commentId = (comment['id'] ?? comment['Id'] ?? '').toString().trim();
      if (commentId.isEmpty) {
        print('deleteCommentsRecursively: Warning - found comment with empty ID');
        continue;
      }
      commentIdMap[commentId] = commentId;
      allCommentIds.add(commentId);
    }

    print('deleteCommentsRecursively: Found ${allCommentIds.length} unique comment IDs');

    // Build parent-to-children map
    final Map<String, List<String>> parentToChildren = {};
    for (var comment in commentMaps) {
      final commentId = (comment['id'] ?? comment['Id'] ?? '').toString().trim();
      if (commentId.isEmpty || !allCommentIds.contains(commentId)) continue;
      
      // Try multiple possible field names for parent comment ID
      final parentCommentIdRaw = comment['parentCommentId'] ?? 
                                  comment['ParentCommentId'];
      
      if (parentCommentIdRaw != null) {
        final parentId = parentCommentIdRaw.toString().trim();
        
        // Only add if parent is in our set of comments to delete
        if (allCommentIds.contains(parentId)) {
          parentToChildren.putIfAbsent(parentId, () => []).add(commentId);
          print('deleteCommentsRecursively: Found parent-child relationship: $parentId -> $commentId');
        }
      }
    }

    print('deleteCommentsRecursively: Found ${parentToChildren.length} parent comments with children');

    // Delete comments recursively (leaf comments first)
    final Set<String> deletedIds = {};
    int maxIterations = 200;
    int iteration = 0;

    while (deletedIds.length < allCommentIds.length && iteration < maxIterations) {
      iteration++;
      print('deleteCommentsRecursively: Iteration $iteration - Deleted: ${deletedIds.length}/${allCommentIds.length}');
      
      final List<String> toDelete = [];
      
      // Find comments that can be deleted (no children or all children already deleted)
      for (var commentId in allCommentIds) {
        if (deletedIds.contains(commentId)) continue;
        final children = parentToChildren[commentId] ?? [];
        if (children.isEmpty || children.every((childId) => deletedIds.contains(childId))) {
          toDelete.add(commentId);
        }
      }
      
      print('deleteCommentsRecursively: Found ${toDelete.length} comments ready to delete');
      
      if (toDelete.isEmpty) {
        print('deleteCommentsRecursively: No comments can be deleted. This might indicate a circular reference or missing parent.');
        // Try to delete remaining comments anyway (might have circular references)
        for (var commentId in allCommentIds) {
          if (deletedIds.contains(commentId)) continue;
          try {
            print('deleteCommentsRecursively: Attempting to force-delete comment $commentId');
            await _dio.delete('$apiBaseUrl/UserComments/$commentId');
            deletedIds.add(commentId);
            print('deleteCommentsRecursively: Successfully force-deleted comment $commentId');
          } catch (e) {
            print('deleteCommentsRecursively: Error force-deleting comment $commentId: $e');
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
          print('deleteCommentsRecursively: Successfully deleted comment $commentId');
        } catch (e) {
          print('deleteCommentsRecursively: Error deleting comment $commentId: $e');
          // If deletion fails, it might be because child comments still exist
          // Try to delete children first
          final children = parentToChildren[commentId] ?? [];
          for (var childId in children) {
            if (!deletedIds.contains(childId)) {
              try {
                print('deleteCommentsRecursively: Attempting to delete child comment $childId first');
                await _dio.delete('$apiBaseUrl/UserComments/$childId');
                deletedIds.add(childId);
                print('deleteCommentsRecursively: Successfully deleted child comment $childId');
              } catch (childError) {
                print('deleteCommentsRecursively: Error deleting child comment $childId: $childError');
              }
            }
          }
          // Try again to delete the parent
          try {
            await _dio.delete('$apiBaseUrl/UserComments/$commentId');
            deletedIds.add(commentId);
            print('deleteCommentsRecursively: Successfully deleted comment $commentId after deleting children');
          } catch (retryError) {
            print('deleteCommentsRecursively: Still failed to delete comment $commentId after deleting children: $retryError');
          }
        }
      }
    }
    
    if (deletedIds.length < allCommentIds.length) {
      print('deleteCommentsRecursively: Warning - Could not delete all comments. Deleted: ${deletedIds.length}/${allCommentIds.length}');
      print('deleteCommentsRecursively: Remaining comment IDs: ${allCommentIds.where((id) => !deletedIds.contains(id)).toList()}');
    } else {
      print('deleteCommentsRecursively: Successfully deleted all ${deletedIds.length} comments');
    }
  }

  /// Deletes all BuildInteractions for a build
  Future<void> deleteBuildInteractions(String buildId) async {
    try {
      final response = await _dio.post('$apiBaseUrl/BuildInteractions/get', data: {
        'BuildId': [buildId],
        'Paging': false,
      });
      final List<dynamic> interactions = response.data as List<dynamic>? ?? [];
      if (interactions.isEmpty) return;

      for (var interaction in interactions) {
        if (interaction is Map<String, dynamic>) {
          final interactionId = (interaction['id'] ?? interaction['Id'] ?? '').toString();
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
      final response = await _dio.post('$apiBaseUrl/UserComments/get', data: {
        'BuildId': [buildId],
        'CommentTargetType': ['BUILD'],
        'Paging': false,
      });
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
      final response = await _dio.post('$apiBaseUrl/UserComments/get', data: {
        'ForumPostId': [postId],
        'CommentTargetType': ['FORUM'],
        'Paging': false,
      });
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
      final response = await _dio.post('$apiBaseUrl/UserComments/get', data: {
        'ComponentId': [componentId],
        'CommentTargetType': ['COMPONENT'],
        'Paging': false,
      });
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
    await deleteBuildComments(buildId); // Then, delete all comments and their images
    return _dio.delete('$apiBaseUrl/Builds/$buildId'); // Finally, delete the build
  }

  /// Deletes a forum post
  Future<Response> deleteForumPost(String postId) async {
    await deleteForumPostComments(postId); // First, delete all comments and their images
    return _dio.delete('$apiBaseUrl/ForumPosts/$postId'); // Then delete the forum post
  }

  /// Deletes a component
  Future<Response> deleteComponent(String componentId) async {
    await deleteComponentComments(componentId); // First, delete all comments and their images
    return _dio.delete('$apiBaseUrl/Components/$componentId'); // Then delete the component
  }
}

