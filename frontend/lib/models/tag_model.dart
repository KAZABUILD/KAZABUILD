/// This file defines the Tag data model for frontend.
library;

/// A Tag that can be applied to a build to categorize it.
class Tag {
  final String id;
  final String name;
  final String description;
  final DateTime? databaseEntryAt;
  final DateTime? lastEditedAt;
  final String? note;

  Tag({
    required this.id,
    required this.name,
    required this.description,
    this.databaseEntryAt,
    this.lastEditedAt,
    this.note,
  });

  /// Creates a [Tag] from a JSON map.
  factory Tag.fromJson(Map<String, dynamic> json) {
    // Backend may not return Id for non-admin users, use empty string as fallback
    final idValue = json['id'] ?? json['Id'];
    final id = idValue != null ? idValue.toString() : '';
    
    return Tag(
      id: id,
      name: json['name'] ?? json['Name'] ?? '',
      description: json['description'] ?? json['Description'] ?? '',
      databaseEntryAt: json['databaseEntryAt'] != null || json['DatabaseEntryAt'] != null
          ? DateTime.parse(json['databaseEntryAt'] ?? json['DatabaseEntryAt'])
          : null,
      lastEditedAt: json['lastEditedAt'] != null || json['LastEditedAt'] != null
          ? DateTime.parse(json['lastEditedAt'] ?? json['LastEditedAt'])
          : null,
      note: json['note'] ?? json['Note'],
    );
  }

  /// Converts this [Tag] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'databaseEntryAt': databaseEntryAt?.toIso8601String(),
      'lastEditedAt': lastEditedAt?.toIso8601String(),
      'note': note,
    };
  }
}

