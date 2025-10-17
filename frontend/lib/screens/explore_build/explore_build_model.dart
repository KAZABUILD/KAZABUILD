import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/auth/auth_provider.dart';

// "Explore Builds" sayfasında gösterilecek bir sistemin veri modeli.
class CommunityBuild {
  final String id;
  final String title;
  final double rating;
  final String imageUrl;
  final AppUser author;
  final DateTime postedDate;
  final DateTime lastEditedDate;
  final String description;
  final List<BaseComponent> components; // Artık tam bileşen listesini tutuyor

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

  //summing all prices
  double get totalPrice {
    return components.fold(0.0, (sum, item) => sum + (item.lowestPrice ?? 0.0));
  }
}

// test datas
final _testUser = AppUser(
  uid: 'user1',
  email: 'test@test.com',
  username: 'KazaBuilder',
);

final List<CommunityBuild> mockCommunityBuilds = [
  CommunityBuild(
    id: 'build-1',
    title: 'The Arctic White Beast',
    rating: 4.5,
    imageUrl: 'https://picsum.photos/seed/white-pc/1200/800',
    author: _testUser,
    postedDate: DateTime(2025, 10, 10),
    lastEditedDate: DateTime(2025, 10, 10),
    description:
        'A clean, powerful, and cool build focused on aesthetics without sacrificing performance. Perfect for 1440p gaming and streaming.',
    components: [mockCPUs.first],
  ),
];
