import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

@immutable
class AppUser {
  final String uid;
  final String username;
  final String email;
  final String? photoURL;

  const AppUser({
    required this.uid,
    required this.username,
    required this.email,
    this.photoURL,
  });
}

class AuthStateNotifier extends StateNotifier<AppUser?> {
  AuthStateNotifier() : super(null);

  void signInForTest() {
    state = const AppUser(
      uid: '1',
      username: 'artun',
      email: 'artun@gmail.com',
    );
  }

  void signOut() {
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});
