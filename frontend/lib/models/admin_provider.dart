/// Admin provider for managing admin operations
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/services/admin_service.dart';

/// Provider for AdminService
final adminServiceProvider = Provider<AdminService>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;
  
  if (user == null) {
    throw Exception('User must be logged in to access admin service');
  }

  // Get Dio instance from authProvider - it already has auth token configured
  final authNotifier = ref.read(authProvider.notifier);
  final dio = authNotifier.getDioInstance();
  
  return AdminService(dio);
});

/// Model for admin user list item
class AdminUser {
  final String id;
  final String login;
  final String? email;
  final String? displayName;
  final String? phoneNumber;
  final String? description;
  final String? gender;
  final String userRole;
  final DateTime? registeredAt;
  final DateTime? birth;
  final bool? isBlocked;
  final DateTime? bannedUntil;
  final int buildsCount;
  final int postsCount;

  AdminUser({
    required this.id,
    required this.login,
    this.email,
    this.displayName,
    this.phoneNumber,
    this.description,
    this.gender,
    required this.userRole,
    this.registeredAt,
    this.birth,
    this.isBlocked,
    this.bannedUntil,
    this.buildsCount = 0,
    this.postsCount = 0,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    try {
      // Parse UserRole - can be string, enum value, or numeric value
      String userRoleStr = 'GUEST';
      dynamic userRoleValue = json['userRole'] ?? json['UserRole'];
      
      if (userRoleValue != null) {
        // If it's a number, convert to role name
        if (userRoleValue is int) {
          const roleMap = {
            0: 'BANNED',
            1: 'GUEST',
            2: 'UNVERIFIED',
            3: 'USER',
            4: 'VIP',
            5: 'MODERATOR',
            6: 'ADMINISTRATOR',
            7: 'OWNER',
            8: 'SYSTEM',
          };
          userRoleStr = roleMap[userRoleValue] ?? 'GUEST';
        } else {
          // If it's a string, use it directly
          userRoleStr = userRoleValue.toString().toUpperCase();
        }
      }
      
      print('AdminUser.fromJson: Parsed userRole from $userRoleValue to $userRoleStr');

      // Parse dates - handle various formats
      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) {
          try {
            // Try ISO format first
            return DateTime.parse(value);
          } catch (e) {
            try {
              // Try parsing as milliseconds since epoch
              final ms = int.tryParse(value);
              if (ms != null) {
                return DateTime.fromMillisecondsSinceEpoch(ms);
              }
            } catch (e2) {
              // Ignore
            }
            return null;
          }
        }
        if (value is int) {
          // Assume milliseconds since epoch
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return null;
      }

      // Parse counts - try different possible field names
      int parseCount(dynamic value) {
        if (value == null) return 0;
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) return int.tryParse(value) ?? 0;
        return 0;
      }

      return AdminUser(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
        login: json['login'] ?? json['Login'] ?? '',
        email: json['email'] ?? json['Email'],
        displayName: json['displayName'] ?? json['DisplayName'],
        phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'],
        description: json['description'] ?? json['Description'],
        gender: json['gender'] ?? json['Gender'],
        userRole: userRoleStr,
        registeredAt: parseDateTime(json['registeredAt'] ?? json['RegisteredAt']),
        birth: parseDateTime(json['birth'] ?? json['Birth']),
        isBlocked: json['isBlocked'] ?? json['IsBlocked'],
        bannedUntil: parseDateTime(json['bannedUntil'] ?? json['BannedUntil']),
        buildsCount: parseCount(json['buildsCount'] ?? json['BuildsCount'] ?? json['builds'] ?? json['Builds']),
        postsCount: parseCount(json['postsCount'] ?? json['PostsCount'] ?? json['posts'] ?? json['Posts']),
      );
    } catch (e, stack) {
      print('Error in AdminUser.fromJson: $e');
      print('JSON: $json');
      print('Stack: $stack');
      rethrow;
    }
  }

  String get status {
    final userRoleUpper = userRole.toUpperCase();
    
    // Check if user is banned by role
    if (userRoleUpper == 'BANNED') {
      print('AdminUser.status: User $id has BANNED role');
      return 'Banned';
    }
    // Check if user is blocked or has an active ban
    if (isBlocked == true || (bannedUntil != null && bannedUntil!.isAfter(DateTime.now()))) {
      print('AdminUser.status: User $id is blocked or banned (isBlocked: $isBlocked, bannedUntil: $bannedUntil)');
      return 'Banned';
    }
    // Check if user is unverified
    if (userRoleUpper == 'UNVERIFIED') {
      print('AdminUser.status: User $id has UNVERIFIED role');
      return 'Inactive';
    }
    // Check for GUEST role - might want to exclude from Active
    if (userRoleUpper == 'GUEST') {
      print('AdminUser.status: User $id has GUEST role');
      // GUEST users might be considered inactive, but let's count them as active for now
    }
    // All other users (USER, VIP, MODERATOR, ADMINISTRATOR, OWNER, SYSTEM) are considered Active
    print('AdminUser.status: User $id has role $userRoleUpper -> Active');
    return 'Active';
  }
}

/// Provider for admin users list
/// Using autoDispose to prevent memory leaks and ensure proper cleanup
/// Note: Map equality is checked by Riverpod, but we need to ensure stable references
final adminUsersProvider = FutureProvider.autoDispose.family<List<AdminUser>, Map<String, dynamic>>((ref, params) async {
  try {
    final adminService = ref.watch(adminServiceProvider);
    
    // Create a stable string representation for logging
    final paramStr = 'query:${params['query']}, page:${params['page']}, pageLength:${params['pageLength']}';
    print('AdminUsersProvider: Fetching users with params: $paramStr');
    
    // Fetch only the requested page
    final page = params['page'] as int? ?? 1;
    final pageLength = params['pageLength'] as int? ?? 20;
    
    print('AdminUsersProvider: Fetching page $page with pageLength $pageLength');
    
    final response = await adminService.getUsers(
      query: params['query'] as String?,
      genders: params['genders'] as List<String>?,
      userRoles: params['userRoles'] as List<String>?,
      page: page,
      pageLength: pageLength,
      orderBy: params['orderBy'] as String?,
      sortDirection: params['sortDirection'] as String? ?? 'asc',
    );
    
    print('AdminUsersProvider: Response status: ${response.statusCode}');
    print('AdminUsersProvider: Response data type: ${response.data.runtimeType}');

    if (response.statusCode == 200) {
      final data = response.data;
      
      // Handle both array and object responses
      List<dynamic> userList;
      if (data is List) {
        userList = data;
        print('AdminUsersProvider: Got list with ${userList.length} users');
      } else if (data is Map && data.containsKey('data')) {
        userList = data['data'] as List;
        print('AdminUsersProvider: Got map with data key, ${userList.length} users');
      } else {
        print('AdminUsersProvider: Unexpected response format: $data (type: ${data.runtimeType})');
        throw Exception('Unexpected response format: $data');
      }
      
      // Parse users
      final users = <AdminUser>[];
      final userIds = <String>[];
      
      for (var i = 0; i < userList.length; i++) {
        try {
          final userJson = userList[i] as Map<String, dynamic>;
          final user = AdminUser.fromJson(userJson);
          users.add(user);
          userIds.add(user.id);
        } catch (e, stack) {
          print('Error parsing user at index $i: $e');
          print('User data: ${userList[i]}');
          print('Stack: $stack');
          // Continue with other users instead of failing completely
        }
      }
      
      // Fetch builds and posts counts for all users in parallel
      final Map<String, int> buildsCounts = {};
      final Map<String, int> postsCounts = {};
      
      try {
        // Get all builds for these users (without pagination to get accurate count)
        final buildsResponse = await adminService.getBuilds(
          userIds: userIds,
          page: null,
          pageLength: null,
        );
        if (buildsResponse.statusCode == 200) {
          final buildsData = buildsResponse.data;
          List<dynamic> buildsList = [];
          if (buildsData is List) {
            buildsList = buildsData;
          } else if (buildsData is Map && buildsData.containsKey('data')) {
            buildsList = buildsData['data'] as List;
          }
          
          // Count builds per user
          for (var build in buildsList) {
            if (build is Map<String, dynamic>) {
              final userId = (build['userId'] ?? build['UserId'] ?? '').toString();
              if (userId.isNotEmpty) {
                buildsCounts[userId] = (buildsCounts[userId] ?? 0) + 1;
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching builds counts: $e');
      }
      
      try {
        // Get all posts for these users (without pagination to get accurate count)
        final postsResponse = await adminService.getForumPosts(
          creatorIds: userIds,
          page: null,
          pageLength: null,
        );
        if (postsResponse.statusCode == 200) {
          final postsData = postsResponse.data;
          List<dynamic> postsList = [];
          if (postsData is List) {
            postsList = postsData;
          } else if (postsData is Map && postsData.containsKey('data')) {
            postsList = postsData['data'] as List;
          }
          
          // Count posts per user
          for (var post in postsList) {
            if (post is Map<String, dynamic>) {
              final creatorId = (post['creatorId'] ?? post['CreatorId'] ?? post['userId'] ?? post['UserId'] ?? '').toString();
              if (creatorId.isNotEmpty) {
                postsCounts[creatorId] = (postsCounts[creatorId] ?? 0) + 1;
              }
            }
          }
        }
      } catch (e) {
        print('Error fetching posts counts: $e');
      }
      
      // Update users with counts
      for (var i = 0; i < users.length; i++) {
        final user = users[i];
        final buildsCount = buildsCounts[user.id] ?? 0;
        final postsCount = postsCounts[user.id] ?? 0;
        
        users[i] = AdminUser(
          id: user.id,
          login: user.login,
          email: user.email,
          displayName: user.displayName,
          phoneNumber: user.phoneNumber,
          description: user.description,
          gender: user.gender,
          userRole: user.userRole,
          registeredAt: user.registeredAt,
          birth: user.birth,
          isBlocked: user.isBlocked,
          bannedUntil: user.bannedUntil,
          buildsCount: buildsCount,
          postsCount: postsCount,
        );
      }
      
      print('AdminUsersProvider: Successfully parsed ${users.length} users');
      return users;
    } else {
      throw Exception('Failed to load users: ${response.statusCode} - ${response.statusMessage}');
    }
  } catch (e, stackTrace) {
    print('Error in adminUsersProvider: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Model for admin build list item
class AdminBuild {
  final String id;
  final String? userId;
  final String? name;
  final String? description;
  final String status;
  final DateTime? publishedAt;
  final DateTime? databaseEntryAt;
  final DateTime? lastEditedAt;

  AdminBuild({
    required this.id,
    this.userId,
    this.name,
    this.description,
    required this.status,
    this.publishedAt,
    this.databaseEntryAt,
    this.lastEditedAt,
  });

  factory AdminBuild.fromJson(Map<String, dynamic> json) {
    try {
      // Parse BuildStatus - can be string or enum value
      String statusStr = 'DRAFT';
      if (json['status'] != null) {
        statusStr = json['status'].toString().toUpperCase();
      } else if (json['Status'] != null) {
        statusStr = json['Status'].toString().toUpperCase();
      }

      // Parse dates - handle various formats
      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            try {
              final ms = int.tryParse(value);
              if (ms != null) {
                return DateTime.fromMillisecondsSinceEpoch(ms);
              }
            } catch (e2) {
              // Ignore
            }
            return null;
          }
        }
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return null;
      }

      return AdminBuild(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
        userId: json['userId']?.toString() ?? json['UserId']?.toString(),
        name: json['name'] ?? json['Name'],
        description: json['description'] ?? json['Description'],
        status: statusStr,
        publishedAt: parseDateTime(json['publishedAt'] ?? json['PublishedAt']),
        databaseEntryAt: parseDateTime(json['databaseEntryAt'] ?? json['DatabaseEntryAt']),
        lastEditedAt: parseDateTime(json['lastEditedAt'] ?? json['LastEditedAt']),
      );
    } catch (e, stack) {
      print('Error in AdminBuild.fromJson: $e');
      print('JSON: $json');
      print('Stack: $stack');
      rethrow;
    }
  }
}

/// Provider for admin builds list
/// Using autoDispose to prevent memory leaks and ensure proper cleanup
final adminBuildsProvider = FutureProvider.autoDispose.family<List<AdminBuild>, Map<String, dynamic>>((ref, params) async {
  try {
    final adminService = ref.watch(adminServiceProvider);
    
    // Create a stable string representation for logging
    final paramStr = 'query:${params['query']}, status:${params['status']}, page:${params['page']}, pageLength:${params['pageLength']}';
    print('AdminBuildsProvider: Fetching builds with params: $paramStr');
    
    // Ensure page and pageLength are always provided for pagination
    final page = params['page'] as int? ?? 1;
    final pageLength = params['pageLength'] as int? ?? 20;
    
    print('AdminBuildsProvider: page=$page, pageLength=$pageLength');
    
    final response = await adminService.getBuilds(
      query: params['query'] as String?,
      status: params['status'] as List<String>?,
      userIds: params['userIds'] as List<String>?,
      page: page,
      pageLength: pageLength,
      orderBy: params['orderBy'] as String?,
      sortDirection: params['sortDirection'] as String? ?? 'asc',
    );

    print('AdminBuildsProvider: Response status: ${response.statusCode}');
    print('AdminBuildsProvider: Response data type: ${response.data.runtimeType}');

    if (response.statusCode == 200) {
      final data = response.data;
      
      // Handle both array and object responses
      List<dynamic> buildList;
      if (data is List) {
        buildList = data;
        print('AdminBuildsProvider: Got list with ${buildList.length} builds');
      } else if (data is Map && data.containsKey('data')) {
        buildList = data['data'] as List;
        print('AdminBuildsProvider: Got map with data key, ${buildList.length} builds');
      } else {
        print('AdminBuildsProvider: Unexpected response format: $data (type: ${data.runtimeType})');
        throw Exception('Unexpected response format: $data');
      }
      
      // Parse builds
      final builds = <AdminBuild>[];
      for (var i = 0; i < buildList.length; i++) {
        try {
          final build = AdminBuild.fromJson(buildList[i] as Map<String, dynamic>);
          builds.add(build);
        } catch (e, stack) {
          print('Error parsing build at index $i: $e');
          print('Build data: ${buildList[i]}');
          print('Stack: $stack');
          // Continue with other builds instead of failing completely
        }
      }
      
      print('AdminBuildsProvider: Successfully parsed ${builds.length} builds');
      return builds;
    } else {
      throw Exception('Failed to load builds: ${response.statusCode} - ${response.statusMessage}');
    }
  } catch (e, stackTrace) {
    print('Error in adminBuildsProvider: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Model for admin forum post list item
class AdminForumPost {
  final String id;
  final String? creatorId;
  final String? title;
  final String? content;
  final String? topic;
  final DateTime? postedAt;
  final DateTime? databaseEntryAt;
  final DateTime? lastEditedAt;

  AdminForumPost({
    required this.id,
    this.creatorId,
    this.title,
    this.content,
    this.topic,
    this.postedAt,
    this.databaseEntryAt,
    this.lastEditedAt,
  });

  factory AdminForumPost.fromJson(Map<String, dynamic> json) {
    try {
      // Parse dates - handle various formats
      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            try {
              final ms = int.tryParse(value);
              if (ms != null) {
                return DateTime.fromMillisecondsSinceEpoch(ms);
              }
            } catch (e2) {
              // Ignore
            }
            return null;
          }
        }
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return null;
      }

      return AdminForumPost(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
        creatorId: json['creatorId']?.toString() ?? json['CreatorId']?.toString(),
        title: json['title'] ?? json['Title'],
        content: json['content'] ?? json['Content'],
        topic: json['topic'] ?? json['Topic'],
        postedAt: parseDateTime(json['postedAt'] ?? json['PostedAt']),
        databaseEntryAt: parseDateTime(json['databaseEntryAt'] ?? json['DatabaseEntryAt']),
        lastEditedAt: parseDateTime(json['lastEditedAt'] ?? json['LastEditedAt']),
      );
    } catch (e, stack) {
      print('Error in AdminForumPost.fromJson: $e');
      print('JSON: $json');
      print('Stack: $stack');
      rethrow;
    }
  }
}

/// Provider for admin forum posts list
/// Using autoDispose to prevent memory leaks and ensure proper cleanup
/// Provider for total forum posts count (uses get-count endpoint)
final adminForumPostsTotalCountProvider = FutureProvider.autoDispose.family<int, Map<String, dynamic>>((ref, params) async {
  try {
    final adminService = ref.watch(adminServiceProvider);
    
    print('adminForumPostsTotalCountProvider: Fetching total count with params: $params');
    
    final response = await adminService.getForumPostsCount(
      query: params['query'] as String?,
      topics: params['topics'] as List<String>?,
      creatorIds: params['creatorIds'] as List<String>?,
      orderBy: params['orderBy'] as String?,
      sortDirection: params['sortDirection'] as String? ?? 'asc',
    );

    print('adminForumPostsTotalCountProvider: Response status: ${response.statusCode}');
    print('adminForumPostsTotalCountProvider: Response data: ${response.data}');

    if (response.statusCode == 200) {
      final count = response.data;
      int totalCount = 0;
      
      if (count is num) {
        totalCount = count.toInt();
      } else if (count is String) {
        totalCount = int.tryParse(count) ?? 0;
      } else if (count is List && count.isNotEmpty) {
        // Backend returns IEnumerable<int>, might be a list
        totalCount = (count[0] as num).toInt();
      }
      
      print('adminForumPostsTotalCountProvider: Returning total count: $totalCount');
      return totalCount;
    } else {
      print('adminForumPostsTotalCountProvider: Response status not 200: ${response.statusCode}');
      return 0;
    }
  } catch (e, stack) {
    print('Error in adminForumPostsTotalCountProvider: $e');
    print('Stack: $stack');
    return 0;
  }
});

final adminForumPostsProvider = FutureProvider.autoDispose.family<List<AdminForumPost>, Map<String, dynamic>>((ref, params) async {
  try {
    final adminService = ref.watch(adminServiceProvider);
    
    // Create a stable string representation for logging
    final paramStr = 'query:${params['query']}, topics:${params['topics']}, page:${params['page']}, pageLength:${params['pageLength']}';
    print('AdminForumPostsProvider: Fetching posts with params: $paramStr');
    
    // Ensure page and pageLength are always provided for pagination
    final page = params['page'] as int? ?? 1;
    final pageLength = params['pageLength'] as int? ?? 20;
    
    print('AdminForumPostsProvider: page=$page, pageLength=$pageLength');
    
    final response = await adminService.getForumPosts(
      query: params['query'] as String?,
      topics: params['topics'] as List<String>?,
      creatorIds: params['creatorIds'] as List<String>?,
      page: page,
      pageLength: pageLength,
      orderBy: params['orderBy'] as String?,
      sortDirection: params['sortDirection'] as String? ?? 'asc',
    );

    print('AdminForumPostsProvider: Response status: ${response.statusCode}');
    print('AdminForumPostsProvider: Response data type: ${response.data.runtimeType}');

    if (response.statusCode == 200) {
      final data = response.data;
      
      // Handle both array and object responses
      List<dynamic> postList;
      if (data is List) {
        postList = data;
        print('AdminForumPostsProvider: Got list with ${postList.length} posts');
      } else if (data is Map && data.containsKey('data')) {
        postList = data['data'] as List;
        print('AdminForumPostsProvider: Got map with data key, ${postList.length} posts');
      } else {
        print('AdminForumPostsProvider: Unexpected response format: $data (type: ${data.runtimeType})');
        throw Exception('Unexpected response format: $data');
      }
      
      // Parse posts
      final posts = <AdminForumPost>[];
      for (var i = 0; i < postList.length; i++) {
        try {
          final post = AdminForumPost.fromJson(postList[i] as Map<String, dynamic>);
          posts.add(post);
        } catch (e, stack) {
          print('Error parsing post at index $i: $e');
          print('Post data: ${postList[i]}');
          print('Stack: $stack');
          // Continue with other posts instead of failing completely
        }
      }
      
      print('AdminForumPostsProvider: Successfully parsed ${posts.length} posts');
      return posts;
    } else {
      throw Exception('Failed to load forum posts: ${response.statusCode} - ${response.statusMessage}');
    }
  } catch (e, stackTrace) {
    print('Error in adminForumPostsProvider: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Model for admin component list item
class AdminComponent {
  final String id;
  final String? name;
  final String? manufacturer;
  final String componentType;
  final DateTime? release;
  final int? numberOfParts;
  final String? note;

  AdminComponent({
    required this.id,
    this.name,
    this.manufacturer,
    required this.componentType,
    this.release,
    this.numberOfParts,
    this.note,
  });

  factory AdminComponent.fromJson(Map<String, dynamic> json) {
    try {
      // Parse ComponentType - can be string or enum value
      String componentTypeStr = 'Unknown';
      if (json['componentType'] != null) {
        componentTypeStr = json['componentType'].toString().toUpperCase();
      } else if (json['Type'] != null) {
        componentTypeStr = json['Type'].toString().toUpperCase();
      } else if (json['type'] != null) {
        componentTypeStr = json['type'].toString().toUpperCase();
      }

      // Parse dates - handle various formats
      DateTime? parseDateTime(dynamic value) {
        if (value == null) return null;
        if (value is DateTime) return value;
        if (value is String) {
          try {
            return DateTime.parse(value);
          } catch (e) {
            try {
              final ms = int.tryParse(value);
              if (ms != null) {
                return DateTime.fromMillisecondsSinceEpoch(ms);
              }
            } catch (e2) {
              // Ignore
            }
            return null;
          }
        }
        if (value is int) {
          return DateTime.fromMillisecondsSinceEpoch(value);
        }
        return null;
      }

      return AdminComponent(
        id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
        name: json['name'] ?? json['Name'],
        manufacturer: json['manufacturer'] ?? json['Manufacturer'],
        componentType: componentTypeStr,
        release: parseDateTime(json['release'] ?? json['Release']),
        numberOfParts: json['numberOfParts'] ?? json['NumberOfParts'],
        note: json['note'] ?? json['Note'],
      );
    } catch (e, stack) {
      print('Error in AdminComponent.fromJson: $e');
      print('JSON: $json');
      print('Stack: $stack');
      rethrow;
    }
  }
}

/// Provider for admin components list
/// Using autoDispose to prevent memory leaks and ensure proper cleanup
/// Provider for total components count (uses get-count endpoint)
final adminComponentsTotalCountProvider = FutureProvider.autoDispose.family<int, Map<String, dynamic>>((ref, params) async {
  try {
    final adminService = ref.watch(adminServiceProvider);
    
    print('adminComponentsTotalCountProvider: Fetching total count with params: $params');
    
    final response = await adminService.getComponentsCount(
      query: params['query'] as String?,
      componentTypes: params['componentTypes'] as List<String>?,
      names: params['names'] as List<String>?,
      manufacturers: params['manufacturers'] as List<String>?,
      orderBy: params['orderBy'] as String?,
      sortDirection: params['sortDirection'] as String? ?? 'asc',
    );

    print('adminComponentsTotalCountProvider: Response status: ${response.statusCode}');
    print('adminComponentsTotalCountProvider: Response data: ${response.data}');

    if (response.statusCode == 200) {
      final count = response.data;
      int totalCount = 0;
      
      if (count is num) {
        totalCount = count.toInt();
      } else if (count is String) {
        totalCount = int.tryParse(count) ?? 0;
      }
      
      print('adminComponentsTotalCountProvider: Returning total count: $totalCount');
      return totalCount;
    } else {
      print('adminComponentsTotalCountProvider: Response status not 200: ${response.statusCode}');
      return 0;
    }
  } catch (e, stack) {
    print('Error in adminComponentsTotalCountProvider: $e');
    print('Stack: $stack');
    return 0;
  }
});

final adminComponentsProvider = FutureProvider.autoDispose.family<List<AdminComponent>, Map<String, dynamic>>((ref, params) async {
  try {
    final adminService = ref.watch(adminServiceProvider);
    
    // Create a stable string representation for logging
    final paramStr = 'query:${params['query']}, componentTypes:${params['componentTypes']}, page:${params['page']}, pageLength:${params['pageLength']}';
    print('AdminComponentsProvider: Fetching components with params: $paramStr');
    
    final response = await adminService.getComponents(
      query: params['query'] as String?,
      componentTypes: params['componentTypes'] as List<String>?,
      names: params['names'] as List<String>?,
      manufacturers: params['manufacturers'] as List<String>?,
      page: params['page'] as int?,
      pageLength: params['pageLength'] as int?,
      orderBy: params['orderBy'] as String?,
      sortDirection: params['sortDirection'] as String? ?? 'asc',
    );

    print('AdminComponentsProvider: Response status: ${response.statusCode}');
    print('AdminComponentsProvider: Response data type: ${response.data.runtimeType}');

    if (response.statusCode == 200) {
      final data = response.data;
      
      // Handle both array and object responses
      List<dynamic> componentList;
      if (data is List) {
        componentList = data;
        print('AdminComponentsProvider: Got list with ${componentList.length} components');
      } else if (data is Map && data.containsKey('data')) {
        componentList = data['data'] as List;
        print('AdminComponentsProvider: Got map with data key, ${componentList.length} components');
      } else {
        print('AdminComponentsProvider: Unexpected response format: $data (type: ${data.runtimeType})');
        throw Exception('Unexpected response format: $data');
      }
      
      // Parse components
      final components = <AdminComponent>[];
      for (var i = 0; i < componentList.length; i++) {
        try {
          final component = AdminComponent.fromJson(componentList[i] as Map<String, dynamic>);
          components.add(component);
        } catch (e, stack) {
          print('Error parsing component at index $i: $e');
          print('Component data: ${componentList[i]}');
          print('Stack: $stack');
          // Continue with other components instead of failing completely
        }
      }
      
      print('AdminComponentsProvider: Successfully parsed ${components.length} components');
      return components;
    } else {
      throw Exception('Failed to load components: ${response.statusCode} - ${response.statusMessage}');
    }
  } catch (e, stackTrace) {
    print('Error in adminComponentsProvider: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Quiz question DTO for admin panel
class AdminQuizQuestion {
  final String id;
  final String question;
  final String? parentAnswerId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? note;

  AdminQuizQuestion({
    required this.id,
    required this.question,
    this.parentAnswerId,
    this.createdAt,
    this.updatedAt,
    this.note,
  });

  factory AdminQuizQuestion.fromJson(Map<String, dynamic> json) {
    return AdminQuizQuestion(
      id: json['id']?.toString() ?? json['Id']?.toString() ?? '',
      question: json['question'] ?? json['Question'] ?? '',
      parentAnswerId:
          json['userPreferenceAnswerId']?.toString() ?? json['UserPreferenceAnswerId']?.toString(),
      createdAt: _parseDateTime(json['databaseEntryAt'] ?? json['DatabaseEntryAt']),
      updatedAt: _parseDateTime(json['lastEditedAt'] ?? json['LastEditedAt']),
      note: json['note'] ?? json['Note'],
    );
  }
}

/// Quiz answer DTO for admin panel
class AdminQuizAnswer {
  final String id;
  final String questionId;
  final String answer;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? note;

  AdminQuizAnswer({
    required this.id,
    required this.questionId,
    required this.answer,
    this.createdAt,
    this.updatedAt,
    this.note,
  });

  factory AdminQuizAnswer.fromJson(Map<String, dynamic> json) {
    // Some endpoints return the answer ID as `UserPreferenceAnswerId`
    // instead of the usual `Id`/`id`. Capture all variants so we can
    // safely edit/delete answers in the same session.
    final rawId = json['id'] ??
        json['Id'] ??
        json['userPreferenceAnswerId'] ??
        json['UserPreferenceAnswerId'];
    final rawQuestionId =
        json['userPreferenceId'] ?? json['UserPreferenceId'] ?? '';

    return AdminQuizAnswer(
      id: rawId?.toString() ?? '',
      questionId: rawQuestionId.toString(),
      answer: json['answer'] ?? json['Answer'] ?? '',
      createdAt: _parseDateTime(json['databaseEntryAt'] ?? json['DatabaseEntryAt']),
      updatedAt: _parseDateTime(json['lastEditedAt'] ?? json['LastEditedAt']),
      note: json['note'] ?? json['Note'],
    );
  }
}

class AdminQuizData {
  final List<AdminQuizQuestion> questions;
  final List<AdminQuizAnswer> answers;

  AdminQuizData({required this.questions, required this.answers});
}

final adminQuizDataProvider = FutureProvider.autoDispose<AdminQuizData>((ref) async {
  final adminService = ref.watch(adminServiceProvider);

  try {
    final questionsResponse = await adminService.getQuizQuestions();
    final answersResponse = await adminService.getQuizAnswers();

    final questionsData = questionsResponse.data;
    final answersData = answersResponse.data;

    List<dynamic> questionList;
    if (questionsData is List) {
      questionList = questionsData;
    } else if (questionsData is Map && questionsData.containsKey('data')) {
      questionList = questionsData['data'] as List<dynamic>;
    } else {
      questionList = [];
    }

    List<dynamic> answerList;
    if (answersData is List) {
      answerList = answersData;
    } else if (answersData is Map && answersData.containsKey('data')) {
      answerList = answersData['data'] as List<dynamic>;
    } else {
      answerList = [];
    }

    final questions = questionList
        .whereType<Map<String, dynamic>>()
        .map(AdminQuizQuestion.fromJson)
        .toList();

    final answers = answerList
        .whereType<Map<String, dynamic>>()
        .map(AdminQuizAnswer.fromJson)
        .toList();

    return AdminQuizData(questions: questions, answers: answers);
  } catch (e, stack) {
    print('Error in adminQuizDataProvider: $e');
    print(stack);
    rethrow;
  }
});

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      final ms = int.tryParse(value);
      if (ms != null) {
        return DateTime.fromMillisecondsSinceEpoch(ms);
      }
    }
  }
  if (value is int) {
    return DateTime.fromMillisecondsSinceEpoch(value);
  }
  return null;
}

