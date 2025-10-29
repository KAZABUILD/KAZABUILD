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
  });

  /// Creates a `Build` instance from a JSON map.
  factory Build.fromJson(Map<String, dynamic> json) {
    return Build(
      id: json['id'],
      userId: json['userId'],
      name: json['name'],
      description: json['description'],
      status: json['status'],
      author: json['user'] != null ? AppUser.fromJson(json['user']) : null,
      imageUrl: json['imageUrl'], // Assuming backend now sends 'imageUrl'
      databaseEntryAt: json['databaseEntryAt'] != null
          ? DateTime.parse(json['databaseEntryAt'])
          : null,
      lastEditedAt: json['lastEditedAt'] != null
          ? DateTime.parse(json['lastEditedAt'])
          : null,
    );
  }
}
