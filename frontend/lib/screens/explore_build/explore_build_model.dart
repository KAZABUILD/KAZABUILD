/// This file defines the data model for a community-submitted PC build.
///
/// The [CommunityBuild] class encapsulates all the information related to a
/// single PC build shared by a user, including its components, author,
/// description, and pricing information.

import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/auth/auth_provider.dart';

class CommunityBuild {
  final String id;
  final String title;
  final double rating;
  final String imageUrl;
  final AppUser author;
  final DateTime postedDate;
  final DateTime lastEditedDate;
  final String description;
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

  /// A computed property that calculates the total price of the build.
  ///
  /// It iterates through all the [components] and sums up their `lowestPrice`.
  /// If a component has no price, it is treated as 0.
  double get totalPrice {
    return components.fold(0.0, (sum, item) => sum + (item.lowestPrice ?? 0.0));
  }
}
