/// This file provides utilities for handling user images and avatars.
/// 
/// It includes fallback logic for when user images are not available
/// and provides consistent avatar generation across the app.
library;

import 'package:flutter/material.dart';
import 'package:frontend/models/api_constants.dart';

/// Utility class for handling user images and avatars.
class UserImageUtils {
  /// Converts photoURL (which might be a GUID ImageId from backend) to a proper image URL.
  /// Backend returns ImageId as GUID, which needs to be converted to a download URL.
  /// [cacheBust] if true, adds a timestamp query parameter to force cache refresh.
  static String? getUserImageUrl(String? photoURL, {bool cacheBust = false}) {
    if (photoURL == null || photoURL.isEmpty) {
      return null;
    }
    
    String url;
    
    // Check if it's an image ID (GUID format)
    final guidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (guidPattern.hasMatch(photoURL)) {
      url = '$apiBaseUrl/Images/download/$photoURL';
    } else if (!photoURL.startsWith('http://') && !photoURL.startsWith('https://')) {
      // Relative URL, prepend base URL
      url = '$apiBaseUrl$photoURL';
    } else {
      // Already a full URL
      url = photoURL;
    }
    
    // Add cache busting parameter if requested
    if (cacheBust) {
      final separator = url.contains('?') ? '&' : '?';
      url = '$url${separator}_t=${DateTime.now().millisecondsSinceEpoch}';
    }
    
    return url;
  }
  
  /// Default avatar colors for generating consistent avatars.
  static const List<Color> _avatarColors = [
    Color(0xFFE57373), // Red
    Color(0xFFF06292), // Pink
    Color(0xFFBA68C8), // Purple
    Color(0xFF9575CD), // Deep Purple
    Color(0xFF7986CB), // Indigo
    Color(0xFF64B5F6), // Blue
    Color(0xFF4FC3F7), // Light Blue
    Color(0xFF4DD0E1), // Cyan
    Color(0xFF4DB6AC), // Teal
    Color(0xFF81C784), // Green
    Color(0xFFAED581), // Light Green
    Color(0xFFFFD54F), // Yellow
    Color(0xFFFFB74D), // Orange
    Color(0xFFFF8A65), // Deep Orange
    Color(0xFFA1887F), // Brown
    Color(0xFF90A4AE), // Blue Grey
  ];

  /// Generates a consistent color for a user based on their ID or name.
  static Color getAvatarColor(String? userId, String? username) {
    final seed = (userId ?? username ?? 'default').hashCode;
    return _avatarColors[seed.abs() % _avatarColors.length];
  }

  /// Gets the first letter of a username for avatar display.
  static String getAvatarLetter(String? username) {
    if (username == null || username.isEmpty) return '?';
    return username[0].toUpperCase();
  }

  /// Creates a network image widget with fallback to a generated avatar.
  static Widget buildUserAvatar({
    String? imageUrl,
    String? username,
    String? userId,
    double radius = 20,
    Color? backgroundColor,
    Color? textColor,
  }) {
    final color = backgroundColor ?? getAvatarColor(userId, username);
    final letter = getAvatarLetter(username);
    final textColorFinal = textColor ?? Colors.white;

    final processedUrl = getUserImageUrl(imageUrl, cacheBust: true);
    if (processedUrl != null && processedUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: color,
        backgroundImage: NetworkImage(
          processedUrl,
          // Add headers to prevent caching issues
        ),
        onBackgroundImageError: (exception, stackTrace) {
          // If network image fails, it will fall back to the background color
          // and we can show the letter instead
        },
        child: null, // Will show the network image
      );
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: Text(
        letter,
        style: TextStyle(
          color: textColorFinal,
          fontSize: radius * 0.6,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// Creates a network image widget with error handling and fallback.
  static Widget buildUserImage({
    String? imageUrl,
    String? username,
    String? userId,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
    BorderRadius? borderRadius,
  }) {
    final color = getAvatarColor(userId, username);
    final letter = getAvatarLetter(username);

    final processedUrl = getUserImageUrl(imageUrl, cacheBust: true);
    if (processedUrl != null && processedUrl.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: Image.network(
          processedUrl,
          width: width,
          height: height,
          fit: fit,
          key: ValueKey(processedUrl), // Force rebuild when URL changes
          errorBuilder: (context, error, stackTrace) {
            // Fallback to generated avatar when network image fails
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color,
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  letter,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: (width != null ? width * 0.4 : 24),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.3),
                borderRadius: borderRadius ?? BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  strokeWidth: 2,
                ),
              ),
            );
          },
        ),
      );
    }

    // No image URL provided, show generated avatar
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(
          letter,
          style: TextStyle(
            color: Colors.white,
            fontSize: (width != null ? width * 0.4 : 24),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
