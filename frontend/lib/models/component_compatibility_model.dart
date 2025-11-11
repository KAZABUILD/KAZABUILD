/// This file defines the ComponentCompatibility data model for frontend.
library;

/// A ComponentCompatibility that defines compatibility between two components.
class ComponentCompatibility {
  final String id;
  final String componentId;
  final String compatibleComponentId;
  final DateTime? databaseEntryAt;
  final DateTime? lastEditedAt;
  final String? note;

  ComponentCompatibility({
    required this.id,
    required this.componentId,
    required this.compatibleComponentId,
    this.databaseEntryAt,
    this.lastEditedAt,
    this.note,
  });

  /// Creates a [ComponentCompatibility] from a JSON map.
  factory ComponentCompatibility.fromJson(Map<String, dynamic> json) {
    return ComponentCompatibility(
      id: (json['id'] ?? json['Id'] ?? '').toString(),
      componentId: (json['componentId'] ?? json['ComponentId'] ?? '').toString(),
      compatibleComponentId: (json['compatibleComponentId'] ?? json['CompatibleComponentId'] ?? '').toString(),
      databaseEntryAt: json['databaseEntryAt'] != null || json['DatabaseEntryAt'] != null
          ? DateTime.parse(json['databaseEntryAt'] ?? json['DatabaseEntryAt'])
          : null,
      lastEditedAt: json['lastEditedAt'] != null || json['LastEditedAt'] != null
          ? DateTime.parse(json['lastEditedAt'] ?? json['LastEditedAt'])
          : null,
      note: json['note'] ?? json['Note'],
    );
  }

  /// Converts this [ComponentCompatibility] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'componentId': componentId,
      'compatibleComponentId': compatibleComponentId,
      'databaseEntryAt': databaseEntryAt?.toIso8601String(),
      'lastEditedAt': lastEditedAt?.toIso8601String(),
      'note': note,
    };
  }
}

