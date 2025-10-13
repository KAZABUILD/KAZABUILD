import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoURL;

  //new part of the profile and settings
  final String? bio;
  final String? country;
  final int followers;
  final String? phoneNumber;
  final bool isProfilePrivate;
  // i will add this feature in theme file as well
  final ThemeMode themePreference;
  final String languagePreference;
  final String? gender;
  final String? birthDate;
  final String? address;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    //new parts
    this.photoURL,
    this.bio,
    this.country,
    this.followers = 0,
    this.phoneNumber,
    this.isProfilePrivate = false,
    this.themePreference = ThemeMode.system,
    this.languagePreference = 'en',
    this.gender,
    this.birthDate,
    this.address,
  });
}

class AuthStateNotifier extends StateNotifier<AppUser?> {
  AuthStateNotifier() : super(null);

  void signInForTest() {
    state = const AppUser(
      uid: '1',
      username: 'artun',
      email: 'artun@gmail.com',
      photoURL: 'https://placehold.co/100x100/7c3aed/white?text=R',
      bio: "test bioooooo",
      country: "Poland",
      followers: 6767,
      phoneNumber: "+48 123123123",
      isProfilePrivate: false,
    );
  }

  void signOut() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});
