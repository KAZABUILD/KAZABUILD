/// This file defines the data model for a single guide or article.
///
/// The [Guide] class encapsulates all the information related to a piece of
/// written content, such as a tutorial or a "how-to" article, that is
/// displayed on the "Guides" page of the application.
library;

/// Represents a single guide or article within the application.
class Guide {
  /// The unique identifier for the guide.
  final String id;

  /// The title of the guide.
  final String title;

  /// The name of the person or entity who wrote the guide.
  final String author;

  /// The URL for the guide's main header or thumbnail image.
  final String imageUrl;

  /// The category the guide belongs to (e.g., "Beginner", "Performance Tuning").
  final String category;

  /// An estimated reading time for the guide (e.g., "5 min read").
  final String readTime;

  /// The date when the guide was originally published.
  final DateTime publishedDate;

  /// The structured content of the guide, represented as a list of blocks.
  // TODO: Refactor this to use a more structured class system (e.g., an abstract
  // `ContentBlock` with subclasses like `HeaderBlock`, `ParagraphBlock`, `ImageBlock`)
  // instead of a generic `List<Map<String, String>>` for better type safety and extensibility.
  final List<Map<String, String>> content;

  /// Creates an instance of a guide.
  Guide({
    required this.id,
    required this.title,
    required this.author,
    required this.imageUrl,
    required this.category,
    required this.readTime,
    required this.publishedDate,
    required this.content,
  });
}
