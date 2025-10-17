import 'package:frontend/screens/auth/auth_provider.dart';

// answer structure
class PostReply {
  final String id;
  final AppUser author;
  final String content;
  final DateTime createdAt;

  PostReply({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });
}

class PCComponent {
  final String type; // e.g., 'CPU', 'GPU'
  final String name; // e.g., 'AMD Ryzen 7 7800X3D'

  PCComponent({required this.type, required this.name});
}

class UserBuild {
  final String id;
  final String name; // e.g., "My Gaming Rig", "Workstation v2"
  final List<PCComponent> components;
  final double totalPrice;

  UserBuild({
    required this.id,
    required this.name,
    required this.components,
    required this.totalPrice,
  });
}

// post structure we will add additional things
class ForumPost {
  final String id;
  final String title;
  final AppUser author;
  final String category;
  final String content;
  final DateTime createdAt;
  final DateTime lastActivity;
  final int viewCount;
  final List<PostReply> replies;

  final String? acceptedReplyId;
  final List<String> tags;
  final String? attachedBuildId;

  ForumPost({
    required this.id,
    required this.title,
    required this.author,
    required this.category,
    required this.content,
    required this.createdAt,
    required this.lastActivity,
    this.viewCount = 0,
    this.replies = const [],

    this.acceptedReplyId,
    this.tags = const [],
    this.attachedBuildId,
  });
}

// tests
final _testUser1 = AppUser(
  uid: '1',
  email: 'test1@kaza.com',
  username: 'Artun',
);
final _testUser2 = AppUser(
  uid: '2',
  email: 'test2@kaza.com',
  username: 'Ziyad',
);
final List<UserBuild> mockUserBuilds = [
  UserBuild(
    id: 'build_001',
    name: 'My Overkill Gaming Rig',
    totalPrice: 2450.00,
    components: [
      PCComponent(type: 'CPU', name: 'Intel Core i9-13900K'),
      PCComponent(type: 'GPU', name: 'NVIDIA GeForce RTX 4090'),
      PCComponent(type: 'RAM', name: 'G.Skill Trident Z5 32GB DDR5'),
    ],
  ),
  UserBuild(
    id: 'build_002',
    name: 'Budget 1080p Machine',
    totalPrice: 820.50,
    components: [
      PCComponent(type: 'CPU', name: 'AMD Ryzen 5 5600X'),
      PCComponent(type: 'GPU', name: 'NVIDIA GeForce RTX 3060'),
      PCComponent(type: 'RAM', name: 'Corsair Vengeance LPX 16GB DDR4'),
    ],
  ),
];
final List<ForumPost> mockPosts = [
  ForumPost(
    id: 'post1',
    title: 'My PC won\'t turn on after installing a new GPU',
    author: _testUser1,
    category: 'Troubleshooting',
    content:
        'Hey everyone, I just installed a new RTX 4080 and now my PC shows no signs of life. The PSU is a 750W Gold. Any ideas what could be wrong?',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
    viewCount: 124,

    replies: [
      PostReply(
        id: 'reply1',
        author: _testUser2,
        content:
            'Did you make sure to plug in all the power connectors to the GPU? Some of them need more than one.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
      ),
      PostReply(
        id: 'reply2',
        author: _testUser1,
        content:
            'That was it! I missed one of the 8-pin connectors. Thanks a lot!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
    ],
  ),
  ForumPost(
    id: 'post2',
    title: 'Show off your RGB setup!',
    author: _testUser2,
    category: 'Show Off Your Build',
    content:
        'Just finished my new build with a ton of RGB. Let\'s see what you guys have created!',
    createdAt: DateTime.now().subtract(const Duration(days: 1)),
    lastActivity: DateTime.now().subtract(const Duration(hours: 3)),
    viewCount: 588,

    replies: [],
  ),
];

UserBuild? getBuildById(String id) {
  try {
    return mockUserBuilds.firstWhere((build) => build.id == id);
  } catch (e) {
    return null;
  }
}
