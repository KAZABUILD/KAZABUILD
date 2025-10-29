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
import 'package:frontend/models/api_constants.dart';

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
    final bool isEmail = RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(usernameOrEmail);

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

  /// Sends a registration request to the backend.
  Future<Response> register(Map<String, dynamic> userData) {
    // Makes a POST request to the /Auth/register endpoint.
    return _dio.post('$apiBaseUrl/Auth/register', data: userData);
  }

  /// Sends a password reset request to the backend.
  Future<Response> resetPassword(String email) {
    // The backend expects a redirectUrl. We'll provide a path for the frontend
    // where the user can enter their new password.
    // We construct the full URL to ensure it works in any environment.
    const frontendBaseUrl = String.fromEnvironment('FRONTEND_BASE_URL', defaultValue: 'http://localhost:8080');
    const redirectPath = '/confirm-reset-password';
    final redirectUrl = '$frontendBaseUrl$redirectPath';
    return _dio.post('$apiBaseUrl/Auth/reset-password', data: {
      'email': email,
      'redirectUrl': redirectUrl,
    });
  }

  /// Sends a request to confirm the password reset with a new password.
  Future<Response> confirmResetPassword(String token, String newPassword) {
    // Makes a POST request to the /Auth/confirm-reset-password endpoint.
    return _dio.post('$apiBaseUrl/Auth/confirm-reset-password', data: {'token': token, 'newPassword': newPassword});
  }

  /// Sends a request to update user data.
  Future<Response> updateUser(String userId, Map<String, dynamic> data) {
    return _dio.put('$apiBaseUrl/Users/$userId', data: data);
  }

  /// Sends a request to upload an image.
  Future<Response> uploadImage(String imagePath, String targetId, String locationType) async {
    final fileName = imagePath.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(imagePath, filename: fileName),
      'targetId': targetId,
      'locationType': locationType,
      // 'Name' alanı backend'de zorunlu olabilir, default bir değer gönderiyoruz.
      'name': 'user_upload_$fileName',
    });

    // Makes a POST request to the /Images/add endpoint.
    return _dio.post('$apiBaseUrl/Images/add', data: formData);
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

  /// The user's chosen display name.
  final String username;

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

  /// Creates an instance of an application user.
  /// All fields are final to ensure the object is immutable.
  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL,
    this.bio,
    this.phoneNumber,
    this.themePreference = ThemeMode.dark,
    this.languagePreference = 'en',
    this.profileAccessibility = ProfileAccessibility.public,
    this.gender,
    this.birthDate,
    this.address,
  });

  /// Creates an `AppUser` instance from a JSON map.
  /// This is useful for parsing user data received from the backend API.
  factory AppUser.fromJson(Map<String, dynamic> json) {
    // Helper to parse ThemeMode from string, defaulting to dark.
    ThemeMode parseTheme(String? themeStr) {
      return ThemeMode.values.firstWhere(
        (e) => e.name.toUpperCase() == themeStr?.toUpperCase(),
        orElse: () => ThemeMode.dark,
      );
    }

    // Helper to parse ProfileAccessibility from string, defaulting to public.
    ProfileAccessibility parseAccessibility(String? accessibilityStr) {
      return ProfileAccessibility.values.firstWhere(
        (e) => e.name.toUpperCase() == accessibilityStr?.toUpperCase(),
        orElse: () => ProfileAccessibility.public,
      );
    }

    return AppUser(
      uid: json['id'],
      username: json['login'],
      email: json['email'],
      photoURL: json['imageUrl'],
    
      bio: json['description'],
      phoneNumber: json['phoneNumber'],
      gender: json['gender'],
      birthDate: json['birth'],
      themePreference: parseTheme(json['theme']),
      languagePreference: json['language']?.toLowerCase() ?? 'en',
      profileAccessibility: parseAccessibility(json['profileAccessibility']),
      address: json['address'] != null ? Address.fromJson(json['address']) : null,
    );
  }
}

/// Manages the authentication state of the application.
///
/// This notifier holds the current [AppUser] object if a user is logged in,
/// or `null` if the user is logged out.
class AuthStateNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  final AuthService _authService;
  final TokenStorageService _tokenStorage;

  /// Initializes the notifier with a `null` state, indicating no user is logged in.
  AuthStateNotifier(this._authService, this._tokenStorage) : super(const AsyncValue.data(null));

  /// Signs in a user.
  ///
  /// This method handles the authentication logic by:
  /// This method handles the authentication logic by:
  /// 1. Calling a repository or service to authenticate with a backend (e.g., Firebase, custom API).
  /// 2. On successful authentication, receiving user data.
  /// 3. Creating an `AppUser` instance with that data.
  /// 4. Updating the `state` with the new `AppUser` object, which will notify all listeners.
  void signIn(String usernameOrEmail, String password) async {
    // TODO: Implement actual authentication logic here.
    // Example: final user = await authRepository.signIn(email, password);
    state = const AsyncValue.loading();
    try {
      final response = await _authService.signIn(usernameOrEmail, password);
      final token = response.data['token'];

      // Store the token securely and set it in Dio headers for subsequent requests.
      await _tokenStorage.saveToken(token);
      _authService._dio.options.headers['Authorization'] = 'Bearer $token';

      // Decode the JWT to get the user ID.
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['nameid']; 

      if (userId == null) {
        throw Exception('User ID not found in token');
      }

      // Fetch the full user profile using the user ID.
      final userResponse = await _authService.getUserById(userId);
      final userData = userResponse.data;

      state = AsyncValue.data(AppUser.fromJson(userData));
    } on DioException catch (e, st) {
      // Handle API errors (e.g., wrong password, user not found).
      final errorMessage = e.response?.data['message'] ?? e.message;
      log('Sign-in failed: $errorMessage', error: e, stackTrace: st);
      state = AsyncValue.error(errorMessage ?? 'An unknown error occurred', st);
    }
  }

  /// Registers a new user.
  ///
  /// This method sends the user's registration data to the backend.
  /// On success, it does not log the user in but expects them to verify their email.
  /// It returns a Future<String> with a success message.
  Future<String> signUp(Map<String, dynamic> userData) async {
    state = const AsyncValue.loading();
    try {
      
      if (!userData.containsKey('password') || userData['password'] == null || userData['password'].toString().isEmpty) {
        throw Exception('Password is required for registration.');
      }

      final response = await _authService.register(userData);
      state = const AsyncValue.data(null); // Reset state, no user is logged in yet.
      return response.data['message'] ?? 'Registration successful! Please check your email to verify your account.';
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'An unknown registration error occurred.';
      state = AsyncValue.error(errorMessage, e.stackTrace ?? StackTrace.current);
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
      return response.data['message'] ?? 'Password reset link sent! Please check your email.';
    } on DioException catch (e) {
      // Re-throw a user-friendly error message for the UI to catch and display.
      final errorMessage = e.response?.data['message'] ?? 'An unknown error occurred.';
      throw errorMessage;
    }
  }

  /// Confirms the password reset using the token and a new password.
  /// Returns a success message to be shown in the UI.
  Future<String> confirmPasswordReset(String token, String newPassword) async {
    // This operation also doesn't change the global auth state directly.
    try {
      final response = await _authService.confirmResetPassword(token, newPassword);
      // The backend redirects on success, but dio will get a 200 OK with the response data.
      // We'll use a static message as the backend doesn't return a JSON body on this one.
      return response.data['message'] ?? 'Password has been reset successfully! You can now log in.';
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'An unknown error occurred. The token might be invalid or expired.';
      throw errorMessage;
    }
  }

  /// Attempts to log in the user automatically by checking for a stored token.
  /// This should be called when the application starts.
  Future<void> tryAutoLogin() async {
    final token = await _tokenStorage.readToken();
    if (token == null) {
      state = const AsyncValue.data(null);
      return;
    }

    // Check if the token is expired.
    if (JwtDecoder.isExpired(token)) {
      await _tokenStorage.deleteToken();
      state = const AsyncValue.data(null);
      return;
    }

    state = const AsyncValue.loading();
    try {
      // Set the token for API requests.
      _authService._dio.options.headers['Authorization'] = 'Bearer $token';

      // Decode the token to get user ID.
      Map<String, dynamic> decodedToken = JwtDecoder.decode(token);
      final userId = decodedToken['nameid'];

      if (userId == null) throw Exception('User ID not found in token');

      // Fetch user data to confirm the token is valid and get up-to-date info.
      final userResponse = await _authService.getUserById(userId);
      final userData = userResponse.data;

      // Update the state with the logged-in user.
      state = AsyncValue.data(AppUser.fromJson(userData));
    } catch (e, st) {
      // If any error occurs (e.g., network issue, invalid token), sign out.
      await signOut();
      log('Auto-login failed', error: e, stackTrace: st);
    }
  }

  /// Signs the current user out by setting the state to `null`.
  Future<void> signOut() async {
    await _tokenStorage.deleteToken();
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

    // We don't set the whole state to loading, as this is a partial update.
    // The UI should show a local loading indicator.
    try {
      await _authService.updateUser(currentUserId, data);

      // Refetch user data to get the most up-to-date state.
      final userResponse = await _authService.getUserById(currentUserId);
      final userData = userResponse.data;

      // Update the state with the new user data.
      state = AsyncValue.data(AppUser.fromJson(userData));
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Profile update failed.';
      log('Update failed: $errorMessage', error: e);
      // Re-throw the error to be caught by the UI.
      throw Exception(errorMessage);
    }
  }

  /// Uploads a new profile picture for the user.
  Future<void> uploadProfilePicture(String userId, String imagePath) async {
    final currentUserId = state.valueOrNull?.uid;
    if (currentUserId == null || currentUserId != userId) {
      throw Exception('Unauthorized action.');
    }

    try {
      
      final imageResponse = await _authService.uploadImage(imagePath, userId, 'USER');
      final imageId = imageResponse.data['id'];

      
      final imageUrl = '$apiBaseUrl/Images/download/$imageId';
      await updateUserProfile({'imageUrl': imageUrl});
    } catch (e) {
      rethrow;
    }
  }

  /// Exposes the internal Dio instance for other providers to use for authenticated requests.
  Dio getDioInstance() => _authService._dio;
}

/// A provider that creates and exposes the [AuthService] instance.
final authServiceProvider = Provider<AuthService>((ref) {
  // This creates a single Dio instance that will be shared.
  final dio = Dio();
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

  // Create the notifier and immediately try to auto-login.
  return AuthStateNotifier(authService, tokenStorageService)
    ..tryAutoLogin();
});
