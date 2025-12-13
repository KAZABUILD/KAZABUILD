/// Admin Featured Builds Page
///
/// Shows builds whose name contains "featured". This avoids extra backend
/// fields and lets admins manage featured builds by renaming them accordingly.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';
import 'admin_base_layout.dart';

class AdminFeaturedBuildsPage extends ConsumerStatefulWidget {
  const AdminFeaturedBuildsPage({super.key});

  @override
  ConsumerState<AdminFeaturedBuildsPage> createState() => _AdminFeaturedBuildsPageState();
}

class _AdminFeaturedBuildsPageState extends ConsumerState<AdminFeaturedBuildsPage> {
  // Stable query params to avoid refetch loops (Riverpod family uses identity)
  static const Map<String, dynamic> _featuredQueryParams = {
    'query': 'feature', // lenient match (name/description/displayName contains)
    'status': ['PUBLISHED'],
    'page': 1,
    'pageLength': 50,
    'orderBy': 'DatabaseEntryAt',
    'sortDirection': 'desc',
  };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Always query for builds whose name/description/displayName contains "feature"
    final buildsAsync = ref.watch(adminBuildsProvider(_featuredQueryParams));

    return AdminBaseLayout(
      currentRoute: '/admin/featured-builds',
      pageTitle: 'Featured Builds (name contains "featured")',
      child: buildsAsync.when(
        data: (builds) {
          if (builds.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: builds.length,
            itemBuilder: (context, index) {
              final build = builds[index];
              final subtitle = build.description ?? 'No description';
              return Card(
                color: isDark ? AppColorsDark.backgroundSecondary : AppColorsLight.backgroundTertiary,
                child: ListTile(
                  leading: CircleAvatar(child: Text('${index + 1}')),
                  title: Text(build.name ?? 'Unnamed Build'),
                  subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
                  trailing: Text(
                    build.status,
                    style: TextStyle(
                      color: isDark ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            'Failed to load featured builds: $err',
            style: TextStyle(
              color: isDark ? AppColorsDark.error : AppColorsLight.error,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 72),
          const SizedBox(height: 12),
          Text(
            'No builds with "featured" in the name',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? AppColorsDark.textWhite : AppColorsLight.textBlack,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
