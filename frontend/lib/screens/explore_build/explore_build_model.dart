/// This file defines the data model for a community-submitted PC build.
///
/// The [CommunityBuild] class encapsulates all the information related to a
/// single PC build shared by a user. This model is used throughout the app,
/// particularly on the "Explore Builds" page and the "Build Detail" page,
/// to represent a complete, user-created computer setup.

import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/auth/auth_provider.dart';

/// Represents a complete PC build created and shared by a user in the community.
class CommunityBuild {
  /// The unique identifier for this specific build.
  final String id;

  /// The user-provided title for the build.
  final String title;

  /// The average community rating for the build, typically on a scale of 1-5.
  final double rating;

  /// The URL for the main showcase image of the build.
  final String imageUrl;

  /// The [AppUser] who created and posted this build.
  final AppUser author;

  /// The date and time when the build was originally posted.
  final DateTime postedDate;

  /// The date and time of the last modification to the build's details.
  final DateTime lastEditedDate;

  /// A detailed description or story about the build, written by the author.
  final String description;

  /// A list of all the [BaseComponent] objects that make up this build.
  final List<BaseComponent> components;

  CommunityBuild({
    required this.id,
    required this.title,
    required this.rating,
    required this.imageUrl,
    required this.author,
    required this.postedDate,
    required this.lastEditedDate,
    required this.description,
    required this.components,
  });

  /// A computed property that calculates the total price of the build in real-time.
  ///
  /// It iterates through all the [components] and sums up their `lowestPrice`.
  /// If a component does not have a price, it is treated as 0 for the calculation.
  double get totalPrice {
    return components.fold(0.0, (sum, item) => sum + (item.lowestPrice ?? 0.0));
  }
}
