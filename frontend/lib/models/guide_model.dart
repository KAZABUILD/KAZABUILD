library;

/// Represents a single guide or article stored on the backend.
class Guide {
  final String id;
  final String title;
  final String author;
  final String category;
  final double timeToReadMinutes;
  final String readTime;
  final DateTime publishedDate;
  final DateTime? databaseEntryAt;
  final DateTime? lastEditedAt;
  final String? note;
  final String text;
  final List<Map<String, String>> content;
  final String? imageUrl;

  Guide({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.timeToReadMinutes,
    required this.readTime,
    required this.publishedDate,
    required this.text,
    required this.content,
    this.databaseEntryAt,
    this.lastEditedAt,
    this.note,
    this.imageUrl,
  });

  Guide copyWith({
    String? title,
    String? author,
    String? category,
    double? timeToReadMinutes,
    DateTime? publishedDate,
    String? text,
    List<Map<String, String>>? content,
    DateTime? databaseEntryAt,
    DateTime? lastEditedAt,
    String? note,
    String? imageUrl,
  }) {
    final updatedTime = timeToReadMinutes ?? this.timeToReadMinutes;
    return Guide(
      id: id,
      title: title ?? this.title,
      author: author ?? this.author,
      category: category ?? this.category,
      timeToReadMinutes: updatedTime,
      readTime: _formatReadTime(updatedTime),
      publishedDate: publishedDate ?? this.publishedDate,
      text: text ?? this.text,
      content: content ?? this.content,
      databaseEntryAt: databaseEntryAt ?? this.databaseEntryAt,
      lastEditedAt: lastEditedAt ?? this.lastEditedAt,
      note: note ?? this.note,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  factory Guide.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String && value.isNotEmpty) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    double parseTime(dynamic value) {
      if (value is num) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0;
      return 0;
    }

    final id = json['id']?.toString() ?? json['Id']?.toString() ?? '';
    final title = (json['title'] ?? json['Title'] ?? '').toString();
    final author = (json['author'] ?? json['Author'] ?? '').toString();
    final category = (json['category'] ?? json['Category'] ?? '').toString();
    final note = json['note'] ?? json['Note'];
    final text = (json['text'] ?? json['Text'] ?? '').toString();
    final rawContent = _parseContentBlocks(text);
    final timeToRead = parseTime(json['timeToRead'] ?? json['TimeToRead']);

    final postedAt = parseDate(json['postedAt'] ?? json['PostedAt']);
    final databaseEntryAt = parseDate(
      json['databaseEntryAt'] ?? json['DatabaseEntryAt'],
    );
    final lastEditedAt = parseDate(
      json['lastEditedAt'] ?? json['LastEditedAt'],
    );
    final publishedDate = postedAt ?? databaseEntryAt ?? DateTime.now();

    return Guide(
      id: id,
      title: title,
      author: author,
      category: category,
      timeToReadMinutes: timeToRead,
      readTime: _formatReadTime(timeToRead),
      publishedDate: publishedDate,
      text: text,
      content: rawContent,
      databaseEntryAt: databaseEntryAt,
      lastEditedAt: lastEditedAt,
      note: note?.toString(),
      imageUrl: json['imageUrl']?.toString(),
    );
  }

  static String _formatReadTime(double minutes) {
    if (minutes <= 0) return 'Quick read';
    if (minutes < 1) return 'Under a minute';
    return '${minutes.round()} min read';
  }

  static List<Map<String, String>> _parseContentBlocks(String rawText) {
    final trimmed = rawText.trim();
    if (trimmed.isEmpty) {
      return [
        {'type': 'p', 'text': 'Content coming soon.'},
      ];
    }

    final List<Map<String, String>> blocks = [];
    final buffer = StringBuffer();

    void flushParagraph() {
      final paragraph = buffer.toString().trim();
      if (paragraph.isNotEmpty) {
        blocks.add({'type': 'p', 'text': paragraph});
      }
      buffer.clear();
    }

    for (final line in trimmed.split('\n')) {
      final cleanedLine = line.trim();
      if (cleanedLine.isEmpty) {
        flushParagraph();
        continue;
      }

      if (cleanedLine.startsWith('#')) {
        flushParagraph();
        final headerText = cleanedLine.replaceFirst(RegExp(r'^#+\s*'), '');
        if (headerText.isNotEmpty) {
          blocks.add({'type': 'h2', 'text': headerText});
        }
        continue;
      }

      buffer.writeln(cleanedLine);
    }

    flushParagraph();

    return blocks.isEmpty
        ? [
            {'type': 'p', 'text': trimmed},
          ]
        : blocks;
  }
}
