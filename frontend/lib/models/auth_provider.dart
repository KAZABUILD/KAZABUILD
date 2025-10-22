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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  /// The user's country of residence.
  final String? country;

  /// The number of followers the user has.
  final int followers;

  /// The user's phone number.
  final String? phoneNumber;

  /// A flag indicating whether the user's profile is visible to the public.
  final bool isProfilePrivate;

  /// The user's preferred theme (light, dark, or system default).
  final ThemeMode themePreference;

  /// The user's preferred language code (e.g., 'en', 'tr').
  final String languagePreference;

  /// The user's self-identified gender.
  final String? gender;

  /// The user's date of birth, stored as a string.
  final String? birthDate;

  /// The user's physical address.
  final String? address;

  /// Creates an instance of an application user.
  /// All fields are final to ensure the object is immutable.
  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL,
    this.bio,
    this.country,
    // Defaults to 0 if not provided.
    this.followers = 0,
    this.phoneNumber,
    this.isProfilePrivate = false,
    this.themePreference = ThemeMode.dark,
    this.languagePreference = 'en',
    this.gender,
    this.birthDate,
    this.address,
  });
}

/// Manages the authentication state of the application.
///
/// This notifier holds the current [AppUser] object if a user is logged in,
/// or `null` if the user is logged out.
class AuthStateNotifier extends StateNotifier<AppUser?> {
  /// Initializes the notifier with a `null` state, indicating no user is logged in.
  AuthStateNotifier() : super(null);

  /// Signs in a user.
  ///
  /// This method should be implemented to handle the authentication logic.
  /// It would typically involve:
  /// 1. Calling a repository or service to authenticate with a backend (e.g., Firebase, custom API).
  /// 2. On successful authentication, receiving user data.
  /// 3. Creating an `AppUser` instance with that data.
  /// 4. Updating the `state` with the new `AppUser` object, which will notify all listeners.
  void signIn(String email, String password) async {
    // TODO: Implement actual authentication logic here.
    // Example: final user = await authRepository.signIn(email, password);
    // state = user;
  }

  /// Signs the current user out by setting the state to `null`.
  void signOut() {
    state = null;
  }
}

/// A global provider that exposes the [AuthStateNotifier] to the entire app.
///
/// Widgets can use this provider to watch for changes in the authentication state
/// and to access methods for signing in or out.
final authProvider = StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});
