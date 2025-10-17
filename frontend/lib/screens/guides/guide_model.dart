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

// testing part
final List<Guide> mockGuides = [
  Guide(
    id: '1',
    title: 'Choosing the Right CPU for Gaming in 2025',
    author: 'Artun Tonguc',
    imageUrl: 'https://picsum.photos/seed/cpu-guide/600/400',
    category: 'BEGINNER',
    readTime: '8 min read',
    publishedDate: DateTime(2025, 10, 1),
    content: [
      {
        'type': 'p',
        'text':
            'Selecting the heart of your gaming rig, the CPU, is a critical decision. In 2025, the market is dominated by two major players: Intel and AMD, each offering a compelling lineup of processors...',
      },
      {'type': 'h2', 'text': 'Understanding Cores and Clock Speeds'},
      {
        'type': 'p',
        'text':
            'Core count and clock speed are the two most advertised metrics, but they don\'t tell the whole story. A higher core count is beneficial for multitasking and modern games that can utilize them, while higher clock speeds generally translate to better performance in single-threaded applications.',
      },
    ],
  ),
  Guide(
    id: '2',
    title: 'A Beginner\'s Guide to Cable Management',
    author: 'Adrian Kopaniecki',
    imageUrl: 'https://picsum.photos/seed/cables-guide/600/400',
    category: 'AESTHETICS',
    readTime: '12 min read',
    publishedDate: DateTime(2025, 9, 25),
    content: [
      {
        'type': 'p',
        'text':
            'Clean cable management not only makes your PC look amazing but also improves airflow, leading to better cooling performance. It might seem daunting at first, but with a few simple tools and techniques, anyone can achieve a professional-looking build.',
      },
    ],
  ),
  Guide(
    id: '3',
    title: 'Understanding RAM: Speed vs. Timings',
    author: 'Ziyad Abayazid',
    imageUrl: 'https://picsum.photos/seed/ram-guide/600/400',
    category: 'ADVANCED',
    readTime: '15 min read',
    publishedDate: DateTime(2025, 9, 18),
    content: [
      {
        'type': 'p',
        'text':
            'When it comes to RAM, most people focus solely on capacity and speed (MHz). However, CAS latency and timings play an equally crucial role in your system\'s overall performance, especially in gaming and content creation workloads.',
      },
    ],
  ),
];
