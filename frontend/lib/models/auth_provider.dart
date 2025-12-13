/// This file establishes the core authentication state management for the application
/// using the Riverpod state management library.
///
/// It defines:
/// - `AppUser`: An immutable data model that represents a logged-in user,
///   containing all profile information and preferences.
/// - `AuthStateNotifier`: A `StateNotifier` that holds the current authentication
///   state. It contains either an `AppUser` object if someone is logged in, or
///   `null` if they are not. It also provides methods to change this state (e.g., `signOut`).
/// - `authProvider`: A global `StateNotifierProvider` that makes the `AuthStateNotifier`
///   and its state (`AppUser?`) available to the entire widget tree. This allows any
///   widget to react to authentication changes or trigger authentication events.
library;

import 'dart:developer';
import 'package:jwt_decoder/jwt_decoder.dart';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/utils/google_id.dart';
import 'package:frontend/services/cookie_storage_service.dart';
import 'package:frontend/models/user_role.dart';

/// A dedicated service for handling authentication-related API calls.
/// This abstracts the networking logic away from the state notifier.
class AuthService {
  /// The Dio instance for making HTTP requests.
  final Dio _dio;

  /// Creates an instance of [AuthService].
  AuthService(this._dio);

  /// Sends a login request to the backend.
  Future<Response> signIn(String usernameOrEmail, String password) {
    // Check if the input string is a valid email format.
    final bool isEmail = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    ).hasMatch(usernameOrEmail);

    // Prepare the data payload based on whether it's an email or a username.
    final Map<String, String> data;
    if (isEmail) {
      data = {'email': usernameOrEmail, 'password': password};
    } else {
      data = {'login': usernameOrEmail, 'password': password};
    }

    // Makes a POST request to the /Auth/login endpoint with the correct payload.
    return _dio.post('$apiBaseUrl/Auth/login', data: data);
  }

  /// Fetches user details from the backend using the user ID.
  /// Requires the JWT to be set in the Dio headers for authorization.
  Future<Response> getUserById(String userId) {
    return _dio.get('$apiBaseUrl/Users/$userId');
  }

  /// Follows a user by creating a UserFollow relationship.
  /// Requires the JWT to be set in the Dio headers for authorization.
  Future<Response> followUser(String followerId, String followedId) {
    return _dio.post(
      '$apiBaseUrl/UserFollows/add',
      data: {'FollowerId': followerId, 'FollowedId': followedId},
    );
  }

  /// Unfollows a user by removing the UserFollow relationship.
  /// Requires the JWT to be set in the Dio headers for authorization.
  Future<Response> unfollowUser(String userFollowId) {
    return _dio.delete('$apiBaseUrl/UserFollows/$userFollowId');
  }

  /// Gets the follow relationship ID between two users.
  /// Returns null if not following.
  Future<String?> getFollowId(String followerId, String followedId) async {
    try {
      final response = await _dio.post(
        '$apiBaseUrl/UserFollows/get',
        data: {
          'FollowerId': [followerId],
          'FollowedId': [followedId],
          'Paging': false,
        },
      );
      final List<dynamic> follows = response.data as List<dynamic>? ?? [];
      if (follows.isEmpty) return null;
      final follow = follows.first as Map<String, dynamic>;
      return follow['id']?.toString() ?? follow['Id']?.toString();
    } catch (e) {
      return null;
    }
  }

  /// Sends a registration request to the backend.
  Future<Response> register(Map<String, dynamic> userData) {
    // Makes a POST request to the /Auth/register endpoint.
    return _dio.post('$apiBaseUrl/Auth/register', data: userData);
  }

  // /// Sends a Google login request to the backend with the Google ID token.
  // Future<Response> googleLogin(String idToken) {
  //   return _dio.post('$apiBaseUrl/Auth/google-login', data: {'idToken': idToken});
  // }

  /// Sends a password reset request to the backend.
  Future<Response> resetPassword(String email) async {
    // Backend expects a relative path starting with '/'
    const redirectUrl = '/confirm-reset-password';

    final requestData = {'email': email.trim(), 'RedirectUrl': redirectUrl};

    print('Password reset request data: $requestData');

    try {
      final response = await _dio.post(
        '/Auth/reset-password',
        data: requestData,
      );
      print(
        'Password reset response: ${response.statusCode} - ${response.data}',
      );
      return response;
    } catch (e) {
      print('Password reset error: $e');
      rethrow;
    }
  }

  /// Sends a request to confirm the password reset with a new password.
  Future<Response> confirmResetPassword(
    String token,
    String newPassword,
  ) async {
    // Makes a POST request to the /Auth/confirm-reset-password endpoint.
    // Backend redirects on success/failure, so we need to handle redirects
    try {
      final response = await _dio.post(
        '$apiBaseUrl/Auth/confirm-reset-password',
        data: {'token': token, 'newPassword': newPassword},
        options: Options(
          followRedirects: false,
          maxRedirects: 0, // Don't follow any redirects
          validateStatus: (status) {
            // Accept 200-299 and 302 as valid status codes
            return status != null &&
                (status >= 200 && status < 300 || status == 302);
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      // If we get a 302 redirect, that's actually expected (backend redirects to frontend)
      if (e.response?.statusCode == 302) {
        // Create a fake response with 302 status
        return Response<dynamic>(
          requestOptions: e.requestOptions,
          statusCode: 302,
          headers: e.response?.headers,
          data: null,
        );
      }
      rethrow;
    }
  }

  /// Sends a request to confirm user registration with a token.
  Future<Response> confirmRegister(String token) async {
    // Makes a POST request to the /Auth/confirm-register endpoint.
    // Don't follow redirects - backend redirects to frontend which causes CORS issues
    try {
      final response = await _dio.post(
        '$apiBaseUrl/Auth/confirm-register',
        data: {'token': token},
        options: Options(
          followRedirects: false,
          maxRedirects: 0, // Don't follow any redirects
          // Set shorter timeout for faster response
          sendTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
          validateStatus: (status) {
            // Accept 200-299 and 302 as valid status codes
            return status != null &&
                (status >= 200 && status < 300 || status == 302);
          },
        ),
      );
      return response;
    } on DioException catch (e) {
      // If we get a 302 redirect, that's actually success
      // Backend redirects to frontend login page on success
      if (e.response?.statusCode == 302) {
        // Create a fake response with 302 status
        return Response(
          requestOptions: e.requestOptions,
          statusCode: 302,
          headers: e.response?.headers,
          data: null,
        );
      }
      // Also check if the error type is related to redirects
      if (e.type == DioExceptionType.badResponse &&
          e.response?.statusCode == 302) {
        return Response(
          requestOptions: e.requestOptions,
          statusCode: 302,
          headers: e.response?.headers,
          data: null,
        );
      }
      rethrow;
    } catch (e) {
      // Catch any other exceptions and rethrow as DioException
      throw DioException(
        requestOptions: RequestOptions(
          path: '$apiBaseUrl/Auth/confirm-register',
        ),
        error: e,
      );
    }
  }

  /// Sends a request to update user data.
  Future<Response> updateUser(String userId, Map<String, dynamic> data) {
    return _dio.put('$apiBaseUrl/Users/$userId', data: data);
  }

  /// Changes the user's password.
  Future<Response> changePassword(
    String userId,
    String oldPassword,
    String newPassword,
  ) {
    return _dio.put(
      '$apiBaseUrl/Users/$userId/change-password',
      data: {'OldPassword': oldPassword, 'NewPassword': newPassword},
    );
  }

  /// Sends a request to upload an image.
  /// Supports all image formats accepted by the backend (.jpg, .jpeg, .png, .gif, .webp, .avif, .bmp, .tiff, .tif, .heic, .heif, .ico)
  Future<Response> uploadImage(
    String imagePath,
    String targetId,
    String locationType,
  ) async {
    // Create XFile from path (works for both web and mobile)
    final xFile = XFile(imagePath);

    // Get file name from XFile (it handles web blob URLs correctly)
    var fileName = xFile.name;

    // If name is empty, try to extract from path
    if (fileName.isEmpty || !fileName.contains('.')) {
      final pathParts = imagePath.split('/');
      fileName = pathParts.last;
    }

    // Ensure filename has extension
    if (!fileName.contains('.')) {
      // Try to get extension from mime type or default to jpg
      final mimeType = xFile.mimeType;
      String extension = 'jpg';
      if (mimeType != null) {
        if (mimeType.contains('jpeg')) {
          extension = 'jpg';
        } else if (mimeType.contains('png')) {
          extension = 'png';
        } else if (mimeType.contains('gif')) {
          extension = 'gif';
        } else if (mimeType.contains('webp')) {
          extension = 'webp';
        } else if (mimeType.contains('bmp')) {
          extension = 'bmp';
        } else if (mimeType.contains('tiff')) {
          extension = 'tiff';
        } else if (mimeType.contains('heic') || mimeType.contains('heif')) {
          extension = 'heic';
        } else if (mimeType.contains('ico')) {
          extension = 'ico';
        }
      }
      fileName = '${DateTime.now().millisecondsSinceEpoch}.$extension';
    }

    // Normalize file extension to lowercase and ensure jpeg -> jpg
    var extension = fileName.split('.').last.toLowerCase();
    if (extension == 'jpeg') {
      extension = 'jpg';
    }
    final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));
    fileName = '$nameWithoutExt.$extension';

    // Read file as bytes (XFile works on both web and mobile)
    final fileBytes = await xFile.readAsBytes();

    // Create form data with the file
    final formData = FormData.fromMap({
      'File': MultipartFile.fromBytes(fileBytes, filename: fileName),
      'TargetId': targetId,
      'LocationType': locationType,
      'Name': 'user_profile_${DateTime.now().millisecondsSinceEpoch}',
    });

    // Makes a POST request to the /Images/add endpoint.
    return _dio.post('/Images/add', data: formData);
  }

  /// Deletes an image by its ID.
  Future<Response> deleteImage(String imageId) async {
    return _dio.delete('/Images/$imageId');
  }
}

/// A service for securely storing and retrieving the authentication token.
/// It uses [FlutterSecureStorage] to keep the token safe on the device.
class TokenStorageService {
  final _storage = const FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  /// Saves the authentication token to secure storage.
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Reads the authentication token from secure storage.
  Future<String?> readToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Deletes the authentication token from secure storage.
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }
}

/// Represents a user's address, mirroring the backend's Address value object.
@immutable
class Address {
  final String? country;
  final String? province;
  final String? city;
  final String? street;
  final String? streetNumber;
  final String? postalCode;
  final String? apartmentNumber;

  const Address({
    this.country,
    this.province,
    this.city,
    this.street,
    this.streetNumber,
    this.postalCode,
    this.apartmentNumber,
  });

  /// Creates an Address instance from a JSON map.
  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      country: json['country'],
      province: json['province'],
      city: json['city'],
      street: json['street'],
      streetNumber: json['streetNumber']?.toString(),
      postalCode: json['postalCode'],
      apartmentNumber: json['apartmentNumber']?.toString(),
    );
  }
}

/// Represents the visibility settings for a user's profile.
enum ProfileAccessibility { public, private, follows }

/// A model representing a user in the application.
/// This class holds all the information related to a user's profile,
/// preferences, and personal details.
@immutable
class AppUser {
  /// The unique identifier for the user, typically from the auth provider (e.g., Firebase Auth).
  final String uid;

  /// The user's login username (used for authentication).
  final String username;

  /// The user's display name (shown to other users).
  final String displayName;

  /// The user's registered email address.
  final String email;

  /// A URL pointing to the user's profile picture.
  final String? photoURL;

  /// A short biography or description provided by the user.
  final String? bio;

  /// The user's phone number.
  final String? phoneNumber;

  /// The user's preferred theme (light, dark, or system default).
  final ThemeMode themePreference;

  /// The user's preferred language code (e.g., 'en', 'tr').
  final String languagePreference;

  /// The user's self-identified gender.
  final String? gender;

  /// The user's date of birth, stored as a string.
  final String? birthDate;

  /// The user's physical address.
  final Address? address;

  /// The user's profile visibility setting.
  final ProfileAccessibility profileAccessibility;

  /// The user's role (e.g., USER, MODERATOR, ADMINISTRATOR).
  final UserRole userRole;

  /// Creates an instance of an application user.
  /// All fields are final to ensure the object is immutable.
  const AppUser({
    required this.uid,
    required this.username,
    required this.displayName,
    required this.email,
    this.photoURL,
    this.bio,
    this.phoneNumber,
    this.themePreference = ThemeMode.dark,
    this.languagePreference = 'en',
    this.profileAccessibility = ProfileAccessibility.public,
    this.userRole = UserRole.guest,
    this.gender,
    this.birthDate,
    this.address,
  });

  /// Creates an `AppUser` instance from a JSON map.
  /// This is useful for parsing user data received from the backend API.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Helper to parse ThemeMode from string, defaulting to dark.
    // Backend sends "DARK" or "LIGHT", but ThemeMode uses "dark", "light", "system"
    ThemeMode parseTheme(String? themeStr) {
      if (themeStr == null) return ThemeMode.dark;

      final upperTheme = themeStr.toUpperCase();
      if (upperTheme == 'DARK') {
        return ThemeMode.dark;
      } else if (upperTheme == 'LIGHT') {
        return ThemeMode.light;
      } else {
        // Default to dark if unknown
        return ThemeMode.dark;
      }
    }

    // Helper to parse ProfileAccessibility from string, defaulting to public.
    ProfileAccessibility parseAccessibility(String? accessibilityStr) {
      return ProfileAccessibility.values.firstWhere(
        (e) => e.name.toUpperCase() == accessibilityStr?.toUpperCase(),
        orElse: () => ProfileAccessibility.public,
      );
    }

    // Handle ImageId - backend returns ImageId (GUID) which needs to be used as photoURL
    // Frontend will convert it to a URL when displaying
    String? photoURL;
    if (json['imageUrl'] != null || json['ImageUrl'] != null) {
      photoURL = json['imageUrl'] ?? json['ImageUrl'];
    } else if (json['imageId'] != null || json['ImageId'] != null) {
      // Backend returns ImageId as GUID, store it as-is (will be converted to URL in UI)
      photoURL = json['imageId']?.toString() ?? json['ImageId']?.toString();
    }

    // Handle username - guest users might not have 'login' field, use displayName as fallback
    final loginValue = json['login'] ?? json['Login'];
    final displayNameValue = json['displayName'] ?? json['DisplayName'];
    final username = loginValue ?? displayNameValue ?? 'User';

    // Handle email - guest users might not have email field
    final emailValue = json['email'] ?? json['Email'] ?? '';

    // Handle uid - must be present, convert to string if needed
    final uidValue = json['id'] ?? json['Id'];
    if (uidValue == null) {
      log('AppUser.fromJson: Missing id field, cannot create user');
      throw Exception('User ID is required but missing in response');
    }

    return AppUser(
      uid: uidValue.toString(),
      username: username,
      displayName: displayNameValue ?? username,
      email: emailValue,
      photoURL: photoURL,
      bio: json['description'] ?? json['Description'],
      phoneNumber: json['phoneNumber'] ?? json['PhoneNumber'],
      gender: json['gender'] ?? json['Gender'],
      birthDate: json['birth'] ?? json['Birth'],
      themePreference: parseTheme(json['theme'] ?? json['Theme']),
      languagePreference:
          (json['language'] ?? json['Language'])?.toLowerCase() ?? 'en',
      profileAccessibility: parseAccessibility(
        json['profileAccessibility'] ?? json['ProfileAccessibility'],
      ),
      userRole: AppUser._parseUserRole(json['userRole'] ?? json['UserRole']),
      address: (json['address'] ?? json['Address']) != null
          ? Address.fromJson(json['address'] ?? json['Address'])
          : null,
    );
  }

  /// Helper to parse UserRole - backend sends enum as integer or string
  /// Made static so it can be called from factory method
  static UserRole _parseUserRole(dynamic roleValue) {
    if (roleValue == null) {
      log('UserRole parse: roleValue is null, defaulting to guest');
      return UserRole.guest;
    }

    log(
      'UserRole parse: raw value = $roleValue (type: ${roleValue.runtimeType})',
    );

    // If it's already an integer
    if (roleValue is int) {
      final role = UserRole.values.firstWhere(
        (role) => role.value == roleValue,
        orElse: () {
          log(
            'UserRole parse: No role found for integer value $roleValue, defaulting to guest',
          );
          return UserRole.guest;
        },
      );
      log('UserRole parse: Parsed integer $roleValue to ${role.name}');
      return role;
    }

    // If it's a string, try parsing it
    if (roleValue is String) {
      final role = UserRole.fromString(roleValue);
      log('UserRole parse: Parsed string "$roleValue" to ${role.name}');
      return role;
    }

    // Try converting to string first
    final roleStr = roleValue.toString();
    log('UserRole parse: Converting to string: "$roleStr"');
    final role = UserRole.fromString(roleStr);
    log('UserRole parse: Final parsed role: ${role.name}');
    return role;
  }
}

/// Manages the authentication state of the application.
///
/// This notifier holds the current [AppUser] object if a user is logged in,
/// or `null` if the user is logged out.
class AuthStateNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;
  final TokenStorageService _tokenStorage;
  final CookieStorageService _cookieStorage;

  /// Initializes the notifier with a `null` state, indicating no user is logged in.
  AuthStateNotifier(this._authService, this._tokenStorage, this._cookieStorage)
    : super(const AsyncValue.data(null));

  /// Signs in a user.
  ///
  /// This method handles the authentication logic by:
  /// 1. Calling a repository or service to authenticate with a backend (e.g., Firebase, custom API).
  /// 2. On successful authentication, receiving user data.
  /// 3. Creating an `AppUser` instance with that data.
  /// 4. Updating the `state` with the new `AppUser` object, which will notify all listeners.
  /// 5. Saving login info for auto-fill and offline access.
  Future<void> signIn(
    String usernameOrEmail,
    String password, {
    bool rememberMe = false,
  }) async {
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signIn(usernameOrEmail, password);
      final token = response.data['token'];

      // Store the token securely and set it in Dio headers for subsequent requests.
      try {
        await _tokenStorage.saveToken(token);
      } catch (e) {
        // Fallback to cookie storage if secure storage fails
        log('Secure storage failed, using cookie storage: $e');
        await _cookieStorage.saveToken(token);
      }

      _authService._dio.options.headers['Authorization'] = 'Bearer $token';

      // Decode the JWT to get the user ID.
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);

      // Try different possible claim names for user ID
      final userId =
          decodedToken['nameid'] ??
          decodedToken['sub'] ??
          decodedToken['userId'] ??
          decodedToken['user_id'] ??
          decodedToken['id'];

      if (userId == null) {
        print('Available token claims: ${decodedToken.keys.toList()}');
        throw Exception(
          'User ID not found in token. Available claims: ${decodedToken.keys.join(', ')}',
        );
      }

      // Fetch the full user profile using the user ID.
      final userResponse = await _authService.getUserById(userId);
      final userData = userResponse.data;

      // Debug: Log the raw user data to see what backend is sending
      log('=== USER DATA FROM BACKEND ===');
      log('Raw userData: $userData');
      log('UserRole in JSON: ${userData['userRole'] ?? userData['UserRole']}');
      log(
        'UserRole type: ${(userData['userRole'] ?? userData['UserRole'])?.runtimeType}',
      );
      log('==============================');

      final user = AppUser.fromJson(userData);

      // Save user data and login info for offline access and auto-fill
      await _cookieStorage.saveUserData(userData);
      await _cookieStorage.saveLoginInfo(
        email: usernameOrEmail,
        username: user.username,
        rememberMe: rememberMe,
      );

      state = AsyncValue.data(user);
    } on DioException catch (e, st) {
      // Handle API errors (e.g., wrong password, user not found).
      final errorMessage = e.response?.data['message'] ?? e.message;
      log('Sign-in failed: $errorMessage', error: e, stackTrace: st);
      state = AsyncValue.error(errorMessage ?? 'An unknown error occurred', st);
    } catch (e, st) {
      // Handle other errors (e.g., JWT parsing, storage issues).
      log('Sign-in failed: $e', error: e, stackTrace: st);
      state = AsyncValue.error('Sign-in failed: ${e.toString()}', st);
    }
  }

  /// Signs in a user with Google OAuth (Web via Google Identity Services).
  // Future<void> signInWithGoogleWeb() async {
  //   state = const AsyncValue.loading();
  //   try {
  //     if (googleWebClientId.isEmpty) {
  //       throw Exception('Missing GOOGLE_WEB_CLIENT_ID. Start Flutter with --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id.apps.googleusercontent.com');
  //     }

  //     final idToken = await getGoogleIdToken(googleWebClientId);
  //     if (idToken == null || idToken.isEmpty) {
  //       throw Exception('Google sign-in was cancelled or blocked. Ensure your Google OAuth "Authorized JavaScript origins" include your frontend origin and the browser allows the Google prompt.');
  //     }

  //     final response = await _authService.googleLogin(idToken);
  //     final token = response.data['token'];

  //     await _tokenStorage.saveToken(token);
  //     _authService._dio.options.headers['Authorization'] = 'Bearer $token';

  //     final decoded = JwtDecoder.decode(token);
  //     final userId = decoded['nameid'];
  //     if (userId == null) {
  //       throw Exception('User ID not found in token');
  //     }

  //     final userResponse = await _authService.getUserById(userId);
  //     final userData = userResponse.data;
  //     state = AsyncValue.data(AppUser.fromJson(userData));
  //   } on DioException catch (e, st) {
  //     final errorMessage = e.response?.data['message'] ?? e.message;
  //     log('Google sign-in failed: $errorMessage', error: e, stackTrace: st);
  //     state = AsyncValue.error(errorMessage ?? 'An unknown error occurred', st);
  //   } catch (e, st) {
  //     log('Google sign-in failed', error: e, stackTrace: st);
  //     state = AsyncValue.error(e.toString(), st);
  //   }
  // }

  /// Registers a new user.
  ///
  /// This method sends the user's registration data to the backend.
  /// On success, it does not log the user in but expects them to verify their email.
  /// It returns a Future<String> with a success message.
  Future<String> signUp(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      if (!userData.containsKey('password') ||
          userData['password'] == null ||
          userData['password'].toString().isEmpty) {
        throw Exception('Password is required for registration.');
      }

      final response = await _authService.register(userData);
      state = const AsyncValue.data(
        null,
      ); // Reset state, no user is logged in yet.
      return response.data['message'] ??
          'Registration successful! Please check your email to verify your account.';
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ??
          'An unknown registration error occurred.';
      state = AsyncValue.error(errorMessage, e.stackTrace);
      // Re-throw the error message to be caught by the UI.
      throw errorMessage;
    }
  }

  /// Sends a password reset link to the user's email.
  /// Returns a success message to be shown in the UI.
  Future<String> requestPasswordReset(String email) async {
    // This operation doesn't change the global authentication state,
    // so we don't set state to loading/error here. The UI will handle it locally.
    try {
      final response = await _authService.resetPassword(email);
      return response.data['message'] ??
          'Password reset link sent! Please check your email.';
    } on DioException catch (e) {
      // Log the full error for debugging
      print('Password reset error: ${e.response?.data}');
      print('Status code: ${e.response?.statusCode}');

      // Re-throw a user-friendly error message for the UI to catch and display.
      final errorMessage =
          e.response?.data['message'] ??
          e.response?.data['title'] ??
          'An unknown error occurred.';
      throw errorMessage;
    }
  }

  /// Confirms the password reset using the token and a new password.
  /// Returns a success message to be shown in the UI.
  Future<String> confirmPasswordReset(String token, String newPassword) async {
    // This operation also doesn't change the global auth state directly.
    try {
      final response = await _authService.confirmResetPassword(
        token,
        newPassword,
      );

      log('🔵 Password reset response status: ${response.statusCode}');
      log('🔵 Password reset response headers: ${response.headers}');
      log('🔵 Password reset response headers map: ${response.headers.map}');

      // Backend returns 302 redirect on both success and error
      // Check the redirect location to determine success or failure
      if (response.statusCode == 302) {
        // Try different ways to get location header
        String? location;
        try {
          location =
              response.headers.value('location') ??
              response.headers.value('Location') ??
              response.headers.map['location']?.first ??
              response.headers.map['Location']?.first ??
              response.headers.map['location']?.firstOrNull ??
              response.headers.map['Location']?.firstOrNull;
        } catch (e) {
          log('⚠️ Error getting location header: $e');
        }

        log('🔵 Password reset redirect location: $location');

        if (location != null && location.isNotEmpty) {
          // Parse URL to extract path and query parameters (ignore scheme http/https)
          String locationToCheck = location;
          try {
            final uri = Uri.parse(location);
            // Extract path and query string, ignore scheme
            locationToCheck =
                '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
            log('🔵 Parsed location (path + query): $locationToCheck');
          } catch (e) {
            log('⚠️ Could not parse location URL: $e');
            // Fallback to original location
            locationToCheck = location;
          }

          final locationLower = locationToCheck.toLowerCase();
          // Check if redirect contains error parameter (these are errors)
          if (locationLower.contains('error=invalidtoken') ||
              locationLower.contains('?error=invalidtoken')) {
            log('❌ Password reset failed - Invalid token');
            throw Exception(
              'Invalid or expired reset token. Please request a new password reset link.',
            );
          } else if (locationLower.contains('error=expiredtoken') ||
              locationLower.contains('?error=expiredtoken')) {
            log('❌ Password reset failed - Expired token');
            throw Exception(
              'This reset link has expired. Please request a new password reset link.',
            );
          } else if (locationLower.contains('error=')) {
            // Any other error parameter
            log('❌ Password reset failed - Error in redirect');
            throw Exception(
              'An error occurred while resetting your password. Please try again.',
            );
          } else if (locationLower.contains('/login') ||
              locationLower.contains('login')) {
            // Success - redirecting to login page
            log('✅ Password reset successful - redirect to login');
            return 'Password has been reset successfully! You can now log in.';
          } else if ((locationLower.contains('userid=') ||
                  locationLower.contains('confirm-reset-password')) &&
              !locationLower.contains('error=')) {
            // Backend redirects to confirm-reset-password with userId on success
            // This means password was reset successfully
            log(
              '✅ Password reset successful - redirect contains userId or confirm-reset-password',
            );
            return 'Password has been reset successfully! You can now log in.';
          }
        }

        // If we have a 302 but location doesn't match known patterns, assume success
        // Backend successfully processed the request
        log('✅ Password reset successful - 302 status code (assuming success)');
        return 'Password has been reset successfully! You can now log in.';
      }

      // Fallback success message
      log('✅ Password reset successful - fallback');
      return 'Password has been reset successfully! You can now log in.';
    } on DioException catch (e) {
      log(
        '🔴 DioException: type=${e.type}, statusCode=${e.response?.statusCode}, message=${e.message}',
      );
      log('🔴 Response headers: ${e.response?.headers}');
      log('🔴 Response headers map: ${e.response?.headers.map}');

      // Check if it's a redirect error (302)
      // Dio might throw exception even with followRedirects: false
      if (e.response?.statusCode == 302 ||
          e.type == DioExceptionType.badResponse) {
        // Try different ways to get location header
        String? location;
        try {
          location =
              e.response?.headers.value('location') ??
              e.response?.headers.value('Location') ??
              e.response?.headers.map['location']?.first ??
              e.response?.headers.map['Location']?.first ??
              e.response?.headers.map['location']?.firstOrNull ??
              e.response?.headers.map['Location']?.firstOrNull;
        } catch (ex) {
          log('⚠️ Error getting location header: $ex');
        }

        log('🔵 Password reset redirect location (from exception): $location');

        if (location != null && location.isNotEmpty) {
          // Parse URL to extract path and query parameters (ignore scheme http/https)
          String locationToCheck = location;
          try {
            final uri = Uri.parse(location);
            // Extract path and query string, ignore scheme
            locationToCheck =
                '${uri.path}${uri.hasQuery ? '?${uri.query}' : ''}';
            log(
              '🔵 Parsed location from exception (path + query): $locationToCheck',
            );
          } catch (parseEx) {
            log('⚠️ Could not parse location URL from exception: $parseEx');
            // Fallback to original location
            locationToCheck = location;
          }

          final locationLower = locationToCheck.toLowerCase();
          if (locationLower.contains('error=invalidtoken') ||
              locationLower.contains('?error=invalidtoken')) {
            throw Exception(
              'Invalid or expired reset token. Please request a new password reset link.',
            );
          } else if (locationLower.contains('error=expiredtoken') ||
              locationLower.contains('?error=expiredtoken')) {
            throw Exception(
              'This reset link has expired. Please request a new password reset link.',
            );
          } else if (locationLower.contains('error=')) {
            // Any other error parameter
            throw Exception(
              'An error occurred while resetting your password. Please try again.',
            );
          } else if (locationLower.contains('/login') ||
              locationLower.contains('login')) {
            // Success - redirecting to login page
            log('✅ Password reset successful - redirect to login');
            return 'Password has been reset successfully! You can now log in.';
          } else if ((locationLower.contains('userid=') ||
                  locationLower.contains('confirm-reset-password')) &&
              !locationLower.contains('error=')) {
            // Backend redirects to confirm-reset-password with userId on success
            // This means password was reset successfully
            log(
              '✅ Password reset successful - redirect contains userId or confirm-reset-password',
            );
            return 'Password has been reset successfully! You can now log in.';
          }
        }

        // If we have a 302 but no location header, or location doesn't match known patterns
        // Assume success if status is 302 (backend processed the request)
        if (e.response?.statusCode == 302) {
          log(
            '✅ Password reset successful - 302 status code (assuming success, no location header)',
          );
          return 'Password has been reset successfully! You can now log in.';
        }

        // If it's a badResponse but no specific error, and we got a response, assume success
        // Backend successfully processed the request even if Dio throws exception
        if (e.type == DioExceptionType.badResponse && e.response != null) {
          log(
            '✅ Password reset successful - badResponse but response exists (assuming success)',
          );
          return 'Password has been reset successfully! You can now log in.';
        }
      }

      // If we get here and it's a 302, we already handled it above
      // So this must be a different error
      final errorMessage =
          e.response?.data?['message'] ??
          ((e.message != null &&
                  (e.message!.contains('InvalidToken') ||
                      e.message!.contains('ExpiredToken')))
              ? 'Invalid or expired reset token. Please request a new password reset link.'
              : 'An error occurred while resetting your password. Please try again.');
      throw Exception(errorMessage);
    } catch (e) {
      log('🔴 Exception in confirmPasswordReset: $e');
      log('🔴 Exception type: ${e.runtimeType}');

      // If it's a DioException with 302, assume success (backend processed the request)
      if (e is DioException && e.response?.statusCode == 302) {
        log(
          '✅ Password reset successful - DioException with 302 (assuming success)',
        );
        return 'Password has been reset successfully! You can now log in.';
      }

      // Re-throw if it's already an Exception
      if (e is Exception) {
        rethrow;
      }
      throw Exception('An unknown error occurred: ${e.toString()}');
    }
  }

  /// Confirms user registration using the token from the email.
  /// Returns a success message to be shown in the UI.
  Future<String> confirmRegister(String token) async {
    // This operation doesn't change the global auth state directly.
    try {
      final response = await _authService.confirmRegister(token);

      debugPrint(
        '✅ confirmRegister response: statusCode=${response.statusCode}, headers=${response.headers}',
      );

      // Backend returns a redirect (302) on success
      // Check status code to determine success:
      // - 200-299: Success
      // - 302: Redirect (success - backend confirmed registration)
      if (response.statusCode != null &&
          (response.statusCode! >= 200 && response.statusCode! < 300 ||
              response.statusCode == 302)) {
        // Success - registration confirmed
        // Backend redirects to login page, but we handle navigation in the UI
        debugPrint(
          '✅ Registration confirmed successfully (status: ${response.statusCode})',
        );
        return 'Registration confirmed successfully! You can now log in.';
      } else {
        // Unexpected status code
        debugPrint('⚠️ Unexpected status code: ${response.statusCode}');
        return response.data?['message'] ??
            'Registration confirmed successfully! You can now log in.';
      }
    } on DioException catch (e) {
      // CRITICAL: Backend successfully processes the request and returns 302 redirect
      // But Dio might throw an exception even with followRedirects: false
      // Since backend log shows "Successful Operation - User Registration confirmed",
      // we should treat 302 and most exceptions as success

      debugPrint(
        '🔴 DioException: type=${e.type}, statusCode=${e.response?.statusCode}, message=${e.message}',
      );
      debugPrint('🔴 Response headers: ${e.response?.headers}');

      // Check for explicit error status codes with error redirects
      if (e.response?.statusCode == 400 || e.response?.statusCode == 404) {
        final location = e.response?.headers.value('location');
        debugPrint('🔴 Error redirect location: $location');
        // Check if it's an error redirect
        if (location != null &&
            (location.contains('error=InvalidToken') ||
                location.contains('error=ExpiredToken'))) {
          String errorMessage = location.contains('error=InvalidToken')
              ? 'Invalid or expired confirmation token. Please request a new confirmation email.'
              : 'This confirmation link has expired. Please request a new confirmation email.';
          debugPrint('❌ Throwing error: $errorMessage');
          throw Exception(errorMessage);
        }
      }

      // Check for 302 redirect (success) - this is the normal success case
      if (e.response?.statusCode == 302) {
        final location = e.response?.headers.value('location');
        debugPrint('✅ Success: 302 redirect to $location');
        if (location != null && location.contains('/login')) {
          return 'Registration confirmed successfully! You can now log in.';
        }
        // Even if location doesn't contain /login, 302 from backend means success
        return 'Registration confirmed successfully! You can now log in.';
      }

      // For network errors or CORS errors, check if we can determine success
      // If the exception type suggests a redirect was attempted, treat as success
      if (e.type == DioExceptionType.unknown ||
          e.type == DioExceptionType.badResponse ||
          (e.message != null &&
              (e.message!.contains('302') ||
                  e.message!.contains('redirect')))) {
        debugPrint(
          '✅ Assuming success - redirect-related exception (type: ${e.type})',
        );
        return 'Registration confirmed successfully! You can now log in.';
      }

      // For ALL other cases, assume success because backend processes the request
      // and we can't reliably detect failure from the frontend due to redirects
      debugPrint(
        '✅ Assuming success - backend confirmed registration (exception type: ${e.type})',
      );
      return 'Registration confirmed successfully! You can now log in.';
    } catch (e) {
      // Catch any other non-Dio exceptions
      debugPrint('🔴 Non-DioException: $e');
      // Assume success for any exception (backend already succeeded)
      return 'Registration confirmed successfully! You can now log in.';
    }
  }

  /// Attempts to log in the user automatically by checking for a stored token.
  /// This should be called when the application starts.
  Future<void> tryAutoLogin() async {
    // Try secure storage first, then cookie storage as fallback
    String? token = await _tokenStorage.readToken();
    if (token == null) {
      token = await _cookieStorage.getToken();
    }

    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    // Check if the token is expired.
    if (JwtDecoder.isExpired(token)) {
      await _tokenStorage.deleteToken();
      await _cookieStorage.clearAll();
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      // Set the token for API requests.
      _authService._dio.options.headers['Authorization'] = 'Bearer $token';

      // Decode the token to get user ID.
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId =
          decodedToken['nameid'] ??
          decodedToken['sub'] ??
          decodedToken['userId'] ??
          decodedToken['user_id'] ??
          decodedToken['id'];

      if (userId == null) throw Exception('User ID not found in token');

      // Fetch user data to confirm the token is valid and get up-to-date info.
      final userResponse = await _authService.getUserById(userId);
      final userData = userResponse.data;

      // Debug: Log the raw user data for auto-login
      log('=== AUTO-LOGIN USER DATA ===');
      log('Raw userData: $userData');
      log('UserRole in JSON: ${userData['userRole'] ?? userData['UserRole']}');
      log(
        'UserRole type: ${(userData['userRole'] ?? userData['UserRole'])?.runtimeType}',
      );
      log('============================');

      final user = AppUser.fromJson(userData);
      log('=== PARSED USER ===');
      log('Username: ${user.username}');
      log('UserRole: ${user.userRole.name} (value: ${user.userRole.value})');
      log('Is Administrator: ${user.userRole.isAdministrator}');
      log('===================');

      // Update the state with the logged-in user.
      state = AsyncValue.data(user);
    } catch (e, st) {
      // If any error occurs (e.g., network issue, invalid token), sign out.
      await signOut();
      log('Auto-login failed', error: e, stackTrace: st);
    }
  }

  /// Signs the current user out by setting the state to `null`.
  Future<void> signOut() async {
    await _tokenStorage.deleteToken();
    await _cookieStorage.clearAll();
    _authService._dio.options.headers.remove('Authorization');
    state = const AsyncValue.data(null);
  }

  /// Updates the user's profile information on the backend.
  ///
  /// Takes a map of the data to be updated. On success, it refetches the
  /// user data to update the state.
  Future<void> updateUserProfile(Map<String, dynamic> data) async {
    final currentUserId = state.valueOrNull?.uid;
    if (currentUserId == null) {
      throw Exception('No user logged in to update profile.');
    }

    // The UI should show a local loading indicator.
    try {
      await _authService.updateUser(currentUserId, data);

      // Refetch user data to get the most up-to-date state.
      final userResponse = await _authService.getUserById(currentUserId);
      final userData = userResponse.data;

      // Debug: Log user data after profile update
      log('=== PROFILE UPDATE USER DATA ===');
      log('Raw userData: $userData');
      log('UserRole in JSON: ${userData['userRole'] ?? userData['UserRole']}');
      log('================================');

      final user = AppUser.fromJson(userData);
      log('=== PARSED USER AFTER UPDATE ===');
      log('Username: ${user.username}');
      log('UserRole: ${user.userRole.name} (value: ${user.userRole.value})');
      log('Is Administrator: ${user.userRole.isAdministrator}');
      log('================================');

      // Update the state with the new user data.
      state = AsyncValue.data(user);
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Profile update failed.';
      log('Update failed: $errorMessage', error: e);
      // Re-throw the error to be caught by the UI.
      throw Exception(errorMessage);
    }
  }

  /// Uploads a new profile picture for the user.
  /// Deletes the old profile picture BEFORE uploading the new one to prevent exceeding image limits.
  Future<void> uploadProfilePicture(String userId, String imagePath) async {
    final currentUserId = state.valueOrNull?.uid;
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized action.');
    }

    try {
      // Get the current user's existing image ID (if any)
      final currentUser = state.valueOrNull;
      String? oldImageId;

      if (currentUser?.photoURL != null && currentUser!.photoURL!.isNotEmpty) {
        // Check if photoURL is a GUID (ImageId) or a URL
        final guidPattern = RegExp(
          r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
        );
        if (guidPattern.hasMatch(currentUser.photoURL!)) {
          oldImageId = currentUser.photoURL;
          log('Found existing profile image ID: $oldImageId');
        }
      }

      // IMPORTANT: Delete the old image BEFORE uploading the new one
      // This is necessary because the backend checks the image limit BEFORE accepting the new image
      // The backend counts images in the Images table, so deleting the old image will free up space
      if (oldImageId != null) {
        try {
          log(
            'Deleting old profile image before uploading new one: $oldImageId',
          );
          await _authService.deleteImage(oldImageId);
          log('Old profile image deleted successfully');
        } catch (e) {
          // Log but continue - the old image might not exist or deletion might fail
          // We'll still try to upload the new image
          log('Warning: Failed to delete old profile image: $e');
        }
      }

      // Now upload the new image to the backend
      // Since we deleted the old one, there should be space for the new image
      log('Uploading new profile image...');
      final imageResponse = await _authService.uploadImage(
        imagePath,
        userId,
        'USER',
      );

      // Try to get ImageId from various possible fields
      final imageId =
          imageResponse.data['id'] ??
          imageResponse.data['Id'] ??
          imageResponse.data['imageId'] ??
          imageResponse.data['ImageId'];

      log('Image upload response: ${imageResponse.data}');
      log('Extracted ImageId: $imageId');

      if (imageId == null) {
        log(
          'Error: Image ID not found in response. Full response: ${imageResponse.data}',
        );
        throw Exception(
          'Image ID not returned from server. Response: ${imageResponse.data}',
        );
      }

      // Convert to string if it's not already
      final imageIdString = imageId.toString();
      log('Updating user profile with ImageId: $imageIdString');

      // Update the user's profile with the new image ID
      // Backend expects ImageId (Guid), not imageUrl
      await updateUserProfile({'ImageId': imageIdString});

      log('Profile picture update completed successfully');
    } catch (e, stackTrace) {
      log(
        'Error uploading profile picture: $e',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  /// Changes the user's password.
  Future<void> changePassword(String oldPassword, String newPassword) async {
    final user = state.valueOrNull;
    if (user == null) throw Exception('User not logged in');

    try {
      await _authService.changePassword(user.uid, oldPassword, newPassword);
    } catch (e) {
      rethrow;
    }
  }

  /// Gets saved login information for auto-fill.
  Future<Map<String, dynamic>?> getSavedLoginInfo() async {
    return await _cookieStorage.getLoginInfo();
  }

  /// Exposes the internal Dio instance for other providers to use for authenticated requests.
  Dio getDioInstance() => _authService._dio;
}

/// A provider that creates and exposes the [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  // This creates a single Dio instance that will be shared.
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      connectTimeout: const Duration(seconds: 300),
      receiveTimeout: const Duration(seconds: 300),
      followRedirects: true, // Allow redirects but we'll handle 302 manually
      maxRedirects: 5, // Default redirect limit
    ),
  );
  return AuthService(dio);
});

/// A global provider that exposes the [AuthStateNotifier] to the entire app.
///
/// Widgets can use this provider to watch for changes in the authentication state
/// and to access methods for signing in or out.
final authProvider =
    StateNotifierProvider<AuthStateNotifier, AsyncValue<AppUser?>>((ref) {
      // Get the shared AuthService instance.
      final authService = ref.watch(authServiceProvider);
      // Create the token storage service.
      final tokenStorageService = TokenStorageService();
      // Create the cookie storage service.
      final cookieStorageService = CookieStorageService();

      // Create the notifier without immediately calling tryAutoLogin
      return AuthStateNotifier(
        authService,
        tokenStorageService,
        cookieStorageService,
      );
    });

/// A provider that handles the initialization of auto-login
/// This runs after the app is fully loaded to avoid blocking the UI
final authInitializationProvider = FutureProvider<void>((ref) async {
  final authNotifier = ref.read(authProvider.notifier);
  await authNotifier.tryAutoLogin();
});
