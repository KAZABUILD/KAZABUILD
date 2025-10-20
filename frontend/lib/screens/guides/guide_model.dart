class Guide {
  final String id;
  final String title;
  final String author;
  final String imageUrl;
  final String category;
  final String readTime;
  final DateTime publishedDate;
  final List<Map<String, String>> content;

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
