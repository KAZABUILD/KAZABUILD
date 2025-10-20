/// This file defines the user authentication state management for the application.
/// It includes:
/// - [AppUser]: A model class representing the authenticated user's data.
/// - [AuthStateNotifier]: A Riverpod `StateNotifier` to manage the user's
///   authentication state (logged in or logged out).
/// - [authProvider]: A global `StateNotifierProvider` to access the
///   authentication state from anywhere in the app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A model representing a user in the application.
/// This class holds all the information related to a user's profile,
/// preferences, and personal details.
@immutable
class AppUser {
  final String uid;

  final String username;

  final String email;

  final String? photoURL;

  final String? bio;

  final String? country;

  final int followers;

  final String? phoneNumber;

  final bool isProfilePrivate;

  final ThemeMode themePreference;

  final String languagePreference;

  final String? gender;

  final String? birthDate;

  final String? address;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL,
    this.bio,
    this.country,
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

/// This notifier holds the current [AppUser] object if a user is logged in,
/// or `null` if the user is logged out.
class AuthStateNotifier extends StateNotifier<AppUser?> {
  /// Initializes the notifier with a `null` state, indicating no user is logged in.
  AuthStateNotifier() : super(null);

  // TODO: Implement a signIn method that takes user credentials or a token,
  // authenticates with a backend service, and sets the state to a new AppUser.
  //
  // void signIn(String email, String password) async {
  //   // ... authentication logic
  //   state = AppUser(...);
  // }

  /// Signs the current user out by setting the state to `null`.
  void signOut() {
    state = null;
  }
}

/// A global provider that exposes the [AuthStateNotifier] to the entire app.

/// Widgets can use this provider to watch for changes in the authentication state
/// and to access methods for signing in or out.
final authProvider = StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});
