/// This file provides a cookie-like storage service using SharedPreferences.
/// 
/// It stores user login information in a persistent way that survives app restarts
/// and provides a fallback when FlutterSecureStorage fails on web.
library;

import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// A service for storing user login information in a cookie-like manner.
/// Uses SharedPreferences for persistent storage across app sessions.
class CookieStorageService {
  static const String _loginKey = 'user_login';
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';
  static const String _buildStateKey = 'build_state';

  /// Saves user login information including email/username for auto-fill.
  Future<void> saveLoginInfo({
    required String email,
    String? username,
    bool rememberMe = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      final loginData = {
        'email': email,
        'username': username,
        'rememberMe': rememberMe,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      };
      
      await prefs.setString(_loginKey, jsonEncode(loginData));
    } else {
      // Clear saved login if user doesn't want to be remembered
      await prefs.remove(_loginKey);
    }
  }

  /// Retrieves saved login information.
  Future<Map<String, dynamic>?> getLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final loginData = prefs.getString(_loginKey);
    
    if (loginData != null) {
      try {
        final data = jsonDecode(loginData) as Map<String, dynamic>;
        
        // Check if the data is not too old (30 days)
        final timestamp = data['timestamp'] as int?;
        if (timestamp != null) {
          final savedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
          final now = DateTime.now();
          final daysDifference = now.difference(savedDate).inDays;
          
          if (daysDifference > 30) {
            // Data is too old, remove it
            await prefs.remove(_loginKey);
            return null;
          }
        }
        
        return data;
      } catch (e) {
        // Invalid JSON, remove it
        await prefs.remove(_loginKey);
        return null;
      }
    }
    
    return null;
  }

  /// Saves authentication token as a fallback.
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Retrieves authentication token.
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Saves user data for offline access.
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, jsonEncode(userData));
  }

  /// Retrieves saved user data.
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userData = prefs.getString(_userDataKey);
    
    if (userData != null) {
      try {
        return jsonDecode(userData) as Map<String, dynamic>;
      } catch (e) {
        // Invalid JSON, remove it
        await prefs.remove(_userDataKey);
        return null;
      }
    }
    
    return null;
  }

  /// Clears all stored data (logout).
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_buildStateKey);
  }

  /// Clears only login info but keeps token (for "remember me" toggle).
  Future<void> clearLoginInfo() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
  }

  /// Saves the current build state (selected components) to cookies.
  /// This allows users to resume their build after closing the app.
  Future<void> saveBuildState(List<Map<String, dynamic>> buildComponents) async {
    final prefs = await SharedPreferences.getInstance();
    final buildState = {
      'components': buildComponents,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString(_buildStateKey, jsonEncode(buildState));
  }

  /// Retrieves the saved build state from cookies.
  /// Returns null if no saved state exists or if the data is too old (30 days).
  Future<List<Map<String, dynamic>>?> getBuildState() async {
    final prefs = await SharedPreferences.getInstance();
    final buildStateData = prefs.getString(_buildStateKey);
    
    if (buildStateData == null) {
      return null;
    }
    
    try {
      final data = jsonDecode(buildStateData) as Map<String, dynamic>;
      
      // Check if the data is not too old (30 days)
      final timestamp = data['timestamp'] as int?;
      if (timestamp != null) {
        final savedDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
        final now = DateTime.now();
        final daysDifference = now.difference(savedDate).inDays;
        
        if (daysDifference > 30) {
          // Data is too old, remove it
          await prefs.remove(_buildStateKey);
          return null;
        }
      }
      
      final components = data['components'] as List<dynamic>?;
      if (components != null) {
        return components
            .whereType<Map<String, dynamic>>()
            .toList();
      }
      
      return null;
    } catch (e) {
      // Invalid JSON, remove it
      await prefs.remove(_buildStateKey);
      return null;
    }
  }

  /// Clears the saved build state.
  Future<void> clearBuildState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_buildStateKey);
  }
}
