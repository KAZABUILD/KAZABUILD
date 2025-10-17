import 'package:flutter/material.dart';
import 'package:frontend/screens/explore_build/explore_build_model.dart';
import 'package:frontend/screens/explore_build/build_detail_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class ExploreBuildsPage extends StatefulWidget {
  const ExploreBuildsPage({super.key});

  @override
  State<ExploreBuildsPage> createState() => _ExploreBuildsPageState();
}

class _ExploreBuildsPageState extends State<ExploreBuildsPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final crossAxisCount = (screenWidth / 350).floor().clamp(1, 4);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.1),
              theme.colorScheme.background,
              theme.colorScheme.secondary.withOpacity(0.1),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: CustomPaint(
                painter: WavePainter(
                  theme.colorScheme.primary.withOpacity(0.2),
                ),
                child: const SizedBox(height: 100),
              ),
            ),
            Column(
              children: [
                const CustomNavigationBar(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        _Header(),
                        const SizedBox(height: 24),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 20,
                                mainAxisSpacing: 20,
                                childAspectRatio: 0.75,
                              ),
                          itemCount: mockCommunityBuilds.length,
                          itemBuilder: (context, index) {
                            return _BuildCard(
                              communityBuild: mockCommunityBuilds[index],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class WavePainter extends CustomPainter {
  final Color color;

  WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 40);
    path.quadraticBezierTo(size.width * 0.25, 60, size.width * 0.5, 40);
    path.quadraticBezierTo(size.width * 0.75, 20, size.width, 40);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Community Builds (${mockCommunityBuilds.length})',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            Row(
              children: [
                _StyledButton(
                  icon: Icons.compare_arrows,
                  label: 'Compare',
                  onPressed: () {},
                  isOutlined: true,
                ),
                const SizedBox(width: 12),
                _StyledButton(
                  icon: Icons.add,
                  label: 'Post your build',
                  onPressed: () {},
                  isOutlined: false,
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search builds...',
                  prefixIcon: Icon(
                    Icons.search,
                    color: theme.colorScheme.primary,
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface.withOpacity(0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            _StyledButton(
              icon: Icons.sell_outlined,
              label: 'Tags',
              onPressed: () {},
              isOutlined: true,
            ),
            const SizedBox(width: 12),
            DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: 'Latest',
                items: const [
                  DropdownMenuItem(
                    value: 'Latest',
                    child: Text('Sort by: Latest'),
                  ),
                  DropdownMenuItem(
                    value: 'Popular',
                    child: Text('Sort by: Popular'),
                  ),
                  DropdownMenuItem(
                    value: 'Price',
                    child: Text('Sort by: Price'),
                  ),
                ],
                onChanged: (value) {},
                style: theme.textTheme.bodyMedium,
                dropdownColor: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StyledButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isOutlined;

  const _StyledButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.isOutlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return isOutlined
        ? OutlinedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: theme.colorScheme.primary),
            ),
          )
        : ElevatedButton.icon(
            onPressed: onPressed,
            icon: Icon(icon, size: 20),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              elevation: 2,
            ),
          );
  }
}

class _BuildCard extends StatelessWidget {
  final CommunityBuild communityBuild;

  const _BuildCard({required this.communityBuild});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 4,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BuildDetailPage(build: communityBuild),
            ),
          );
        },
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: Image.network(
                    communityBuild.imageUrl,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        height: 200,
                        color: theme.colorScheme.surface,
                        child: const Center(child: CircularProgressIndicator()),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 200,
                      color: theme.colorScheme.error.withOpacity(0.1),
                      child: const Center(child: Icon(Icons.error)),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          communityBuild.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            communityBuild.rating.toString(),
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                        ],
                      ),
                    ],
                  ),
                  Text(
                    '\$${communityBuild.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (var component in communityBuild.components.take(3))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        '• ${component.name}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.colorScheme.primary,
                    child: Text(
                      communityBuild.author.username.substring(0, 1),
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      communityBuild.author.username,
                      style: theme.textTheme.bodyMedium,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
