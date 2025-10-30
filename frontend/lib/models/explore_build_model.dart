/// This file defines the data model for a community-submitted PC build.
///
/// The [Build] class encapsulates all the information related to a
/// single PC build shared by a user. This model is used throughout the app,
/// particularly on the "Explore Builds" page and the "Build Detail" page,
/// to represent a complete, user-created computer setup.
library;

import 'package:frontend/models/auth_provider.dart';

/// Represents a PC build created by a user, mirroring the backend's Build entity.
class Build {
  /// The unique identifier for this specific build.
  final String id;

  /// The ID of the user who created the build.
  final String userId;

  /// The user-provided title for the build.
  final String name;

  /// A detailed description or story about the build, written by the author.
  final String? description;

  /// The current status of the build (e.g., DRAFT, PUBLISHED).
  final String status;

  /// A placeholder for the build's main image URL.
  /// TODO: This needs to be added to the backend response.
  final String? imageUrl;

  /// The user who created the build. This might be null if not included in the API response.
  final AppUser? author;

  /// The timestamp when this entry was created in the database.
  final DateTime? databaseEntryAt;

  /// The timestamp of the last modification to this entry.
  final DateTime? lastEditedAt;

  /// Average star rating for this build (0.0 - 5.0)
  final double averageRating;

  /// Number of ratings submitted for this build
  final int ratingsCount;

  /// The current logged-in user's rating for this build, if any
  final double? userRating;

  Build({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    required this.status,
    this.imageUrl,
    this.author,
    this.databaseEntryAt,
    this.lastEditedAt,
    this.averageRating = 0.0,
    this.ratingsCount = 0,
    this.userRating,
  });

  /// Creates a `Build` instance from a JSON map.
  factory Build.fromJson(Map<String, dynamic> json) {
    double parseRatingToFive(dynamic value) {
      if (value == null) return 0.0;
      double v;
      if (value is num) {
        v = value.toDouble();
      } else if (value is String) {
        v = double.tryParse(value) ?? 0.0;
      } else {
        v = 0.0;
      }
      // Backend may return 0-100; normalize to 0-5 if needed
      return v > 5.0 ? (v / 20.0) : v;
    }

    int parseCount(dynamic value) {
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return Build(
      id: json['id'] ?? json['Id'],
      userId: json['userId'] ?? json['UserId'],
      name: json['name'] ?? json['Name'],
      description: json['description'] ?? json['Description'],
      status: json['status'] ?? json['Status'],
      author: (json['user'] ?? json['User']) != null ? AppUser.fromJson(json['user'] ?? json['User']) : null,
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      databaseEntryAt: (json['databaseEntryAt'] ?? json['DatabaseEntryAt']) != null
          ? DateTime.parse(json['databaseEntryAt'] ?? json['DatabaseEntryAt'])
          : null,
      lastEditedAt: (json['lastEditedAt'] ?? json['LastEditedAt']) != null
          ? DateTime.parse(json['lastEditedAt'] ?? json['LastEditedAt'])
          : null,
      averageRating: parseRatingToFive(json['averageRating'] ?? json['AverageRating'] ?? json['ratingAverage'] ?? json['rating'] ?? 0),
      ratingsCount: parseCount(json['ratingsCount'] ?? json['RatingsCount'] ?? json['ratingCount'] ?? json['votes'] ?? 0),
      userRating: (json['userRating'] ?? json['UserRating'] ?? json['myRating']) == null
          ? null
          : parseRatingToFive(json['userRating'] ?? json['UserRating'] ?? json['myRating']),
    );
  }
}
