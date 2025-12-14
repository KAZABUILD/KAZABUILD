library;

import 'dart:io';
import 'package:flutter/foundation.dart';

/// Gets the appropriate API base URL based on the platform
/// 
/// - If API_BASE_URL is provided via --dart-define, it uses that value
/// - For Android emulator, automatically uses 10.0.2.2 (host machine IP)
/// - For web and other platforms, uses localhost
String get apiBaseUrl {
  // Check if URL is provided via environment variable
  const envUrl = String.fromEnvironment('API_BASE_URL');
  if (envUrl.isNotEmpty) {
    return envUrl;
  }
  
  // Auto-detect for Android emulator
  if (!kIsWeb && Platform.isAndroid) {
    // Android emulator uses 10.0.2.2 to access host machine
    // Using HTTP port 5100 (backend's HTTP port from launchSettings.json)
    return 'http://10.0.2.2:5100';
  }
  
  // Default for web and other platforms
  return 'https://localhost:7249';
}

/// Google OAuth 2.0 Web Client ID
/// Set via: --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id.apps.googleusercontent.com
/// Or use the default value below for development
const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '221004750220-te9fs4ltevcvevc62pmdbj81km96htb5.apps.googleusercontent.com');