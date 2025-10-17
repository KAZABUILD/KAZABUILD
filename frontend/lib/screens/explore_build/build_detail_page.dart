import 'package:flutter/material.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/explore_build/explore_build_model.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:intl/intl.dart';

class BuildDetailPage extends StatefulWidget {
  final CommunityBuild build;
  const BuildDetailPage({super.key, required this.build});

  @override
  State<BuildDetailPage> createState() => _BuildDetailPageState();
}

class _BuildDetailPageState extends State<BuildDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 900),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ana Resim
                      ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.network(
                          widget.build.imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Kullanıcı ve Tarih Bilgisi
                      _buildMetaInfo(theme),
                      const SizedBox(height: 16),
                      // Başlık ve Puanlama
                      _buildTitleAndRating(theme),
                      const SizedBox(height: 24),
                      // Açıklama
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          widget.build.description,
                          style: theme.textTheme.bodyLarge,
                        ),
                      ),
                      const SizedBox(height: 32),
                      // Parça Listesi
                      Text(
                        'Specifications:',
                        style: theme.textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 16),
                      ...widget.build.components.map(
                        (component) => _ComponentTile(component: component),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaInfo(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          child: Text(widget.build.author.username.substring(0, 1)),
        ),
        const SizedBox(width: 8),
        Text(widget.build.author.username, style: theme.textTheme.bodyMedium),
        const SizedBox(width: 8),
        Text('•', style: theme.textTheme.bodySmall),
        const SizedBox(width: 8),
        Text(
          'Posted on: ${DateFormat.yMMMMd().format(widget.build.postedDate)}',
          style: theme.textTheme.bodySmall,
        ),
        const Spacer(),
        OutlinedButton(onPressed: () {}, child: const Text('Wishlist Build')),
        const SizedBox(width: 12),
        ElevatedButton(onPressed: () {}, child: const Text('Follow Builds')),
      ],
    );
  }

  Widget _buildTitleAndRating(ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          widget.build.title,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < widget.build.rating.floor()
                  ? Icons.star
                  : (index < widget.build.rating
                        ? Icons.star_half
                        : Icons.star_border),
              color: Colors.amber,
            );
          }),
        ),
      ],
    );
  }
}

// Parça listesindeki her bir eleman
class _ComponentTile extends StatelessWidget {
  final BaseComponent component;
  const _ComponentTile({required this.component});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(Icons.memory, size: 24), // İleride dinamik ikon eklenebilir
            const SizedBox(width: 16),
            Expanded(
              child: Text(component.name, style: theme.textTheme.titleMedium),
            ),
            Text(
              '\$${component.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 24),
            InkWell(
              onTap: () {},
              child: const Text(
                'allegro',
                style: TextStyle(
                  color: Colors.orange,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 24),
            ElevatedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add to build'),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: theme.colorScheme.onSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
