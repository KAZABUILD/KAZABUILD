/// Service for admin-related API calls
library;

import 'package:dio/dio.dart';
import 'package:frontend/models/api_constants.dart';

/// Service class for handling admin operations
class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  /// Gets all users with filtering (no pagination - all results)
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
      'Paging': false,
    };
    
    print('AdminService.getUsers: Getting all users (no pagination)');

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

  /// Gets all builds with filtering 
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
      'Paging': false, // Always get all builds, no pagination
    };
    
    print('AdminService.getBuilds: Getting all builds (no pagination)');

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

  /// Gets all forum posts with filtering (no pagination - all results)
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
      'Paging': false, // Always get all forum posts, no pagination
    };
    
    print('AdminService.getForumPosts: Getting all forum posts (no pagination)');

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
    // If componentTypes is null or has multiple types, use "Case" as generic
    // If componentTypes has a single type, use that type for better backend filtering
    String? typeDiscriminator;
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
    } else {
      // Use "Case" as generic discriminator when no filter or multiple types
      typeDiscriminator = 'Case';
    }
    
    final data = <String, dynamic>{
      r'$type': typeDiscriminator, // Type discriminator for polymorphic deserialization
      'Query': query ?? '',
      'SortDirection': sortDirection,
      'Paging': false, // Default to false - get all components
    };

    // Only add paging if both page and pageLength are provided and valid
    // For admin panel, we want to get all components first, then paginate on client side
    
    if (page != null && pageLength != null && page > 0 && pageLength > 0) {
      // Use a very large pageLength to get all components, then paginate on client side
      // Or set Paging to false to get all
      data['Paging'] = false; // Get all components, paginate on client side
      print('AdminService.getComponents: Getting all components (paging disabled for admin panel)');
    } else {
      print('AdminService.getComponents: No paging - getting all components');
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

  /// Deletes a build
  Future<Response> deleteBuild(String buildId) async {
    return _dio.delete('$apiBaseUrl/Builds/$buildId');
  }

  /// Deletes a forum post
  Future<Response> deleteForumPost(String postId) async {
    return _dio.delete('$apiBaseUrl/ForumPosts/$postId');
  }

  /// Deletes a component
  Future<Response> deleteComponent(String componentId) async {
    return _dio.delete('$apiBaseUrl/Components/$componentId');
  }
}

