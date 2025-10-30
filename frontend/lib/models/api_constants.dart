library;

const String apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'https://localhost:7249');

/// Google OAuth 2.0 Web Client ID
/// Set via: --dart-define=GOOGLE_WEB_CLIENT_ID=your-client-id.apps.googleusercontent.com
const String googleWebClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID', defaultValue: '');