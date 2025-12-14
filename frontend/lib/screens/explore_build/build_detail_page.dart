/// This file defines the detail page for a community-submitted PC build.
///
/// It presents a comprehensive view of a single build, including its main image,
/// title, description, author details, and a detailed list of all the components
/// used. Each component is displayed with its name, price, and actions.
/// Users can interact with the build through actions like "Wishlist" or "Follow".
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/comments_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/widgets/authenticated_image.dart';
import 'package:frontend/utils/user_image_utils.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/screens/explore_build/similar_builds_section.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/screens/builder/build_now_page.dart'
    show buildProvider;
import 'package:image_picker/image_picker.dart';
import 'package:frontend/models/image_provider.dart';
import 'package:frontend/widgets/linkable_text.dart';
import 'dart:typed_data';

/// Provider to fetch user details based on their ID
/// Uses autoDispose to prevent caching - data will be refetched each time the page is opened.
final buildUserProvider = FutureProvider.autoDispose.family<AppUser?, String>((
  ref,
  userId,
) async {
  try {
    final authService = ref.read(authServiceProvider);
    final userResponse = await authService.getUserById(userId);

    if (userResponse.statusCode == 200 && userResponse.data != null) {
      try {
        final user = AppUser.fromJson(userResponse.data);
        return user;
      } catch (parseError) {
        debugPrint('Error parsing user $userId: $parseError');
        return null;
      }
    }
    return null;
  } on DioException catch (e) {
    debugPrint('Error fetching user $userId: ${e.response?.statusCode}');
    return null;
  } catch (e) {
    debugPrint('Unexpected error fetching user $userId: $e');
    return null;
  }
});

/// A page that displays the full details of a specific [CommunityBuild].
class BuildDetailPage extends ConsumerStatefulWidget {
  /// The ID of the build to display.
  final String buildId;
  const BuildDetailPage({super.key, required this.buildId});

  @override
  ConsumerState<BuildDetailPage> createState() => _BuildDetailPageState();
}

class _BuildDetailPageState extends ConsumerState<BuildDetailPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buildAsyncValue = ref.watch(buildDetailProvider(widget.buildId));

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,

      /// The main layout is a column with the navigation bar at the top
      /// and the scrollable content below.
      body: Column(
        children: <Widget>[
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: buildAsyncValue.when(
              data: (build) => _buildContentView(context, ref, build),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(AppLocalizations.of(context)!.errorLoadingBuilds),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView(BuildContext context, WidgetRef ref, Build build) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 900;
    final contentPadding = EdgeInsets.symmetric(
      horizontal: isMobile ? 16 : 32,
      vertical: isMobile ? 16 : 32,
    );
    final maxContentWidth = isMobile ? double.infinity : 900.0;

    return SingleChildScrollView(
      padding: contentPadding,
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxContentWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildBuildImage(context, theme, build, isMobile: isMobile),
              const SizedBox(height: 24),
              _buildMetaInfo(context, ref, theme, build, isMobile: isMobile),
              const SizedBox(height: 16),
              _buildTitleAndRating(theme, build, isMobile: isMobile),
              const SizedBox(height: 24),
              if (build.description != null && build.description!.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    build.description!,
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              const SizedBox(height: 32),
              // Components section
              if (build.components.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.components,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _ComponentsSection(components: build.components),
                const SizedBox(height: 32),
              ],
              // Tags section
              if (build.tags.isNotEmpty) ...[
                Text(
                  AppLocalizations.of(context)!.tags,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _TagsSection(tags: build.tags),
                const SizedBox(height: 32),
              ],
              // Comments section
              Text(
                '${AppLocalizations.of(context)!.comments}:',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              _CommentsSection(buildId: build.id),
              const SizedBox(height: 32),
              // Similar builds section
              if (build.tags.isNotEmpty)
                SimilarBuildsSection(buildId: build.id, tags: build.tags),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the build image widget with proper URL construction and error handling
  Widget _buildBuildImage(
    BuildContext context,
    ThemeData theme,
    Build build, {
    required bool isMobile,
  }) {
    final imageUrl = _getImageUrl(build);
    final imageHeight = isMobile ? 260.0 : 400.0;

    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildPlaceholderImage(context, theme);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Image.network(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        height: imageHeight,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: double.infinity,
            height: imageHeight,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          // On error (including ImageCodeException), show placeholder
          return _buildPlaceholderImage(context, theme);
        },
      ),
    );
  }

  /// Gets the image URL for the build, handling GUIDs and different URL formats
  String? _getImageUrl(Build build) {
    if (build.imageUrl == null || build.imageUrl!.isEmpty) {
      return null;
    }

    final url = build.imageUrl!;

    // Check if it's a GUID (image ID)
    final guidPattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    if (guidPattern.hasMatch(url)) {
      // It's an image ID, construct download URL
      return '$apiBaseUrl/Images/download/$url';
    } else if (url.startsWith('http://') || url.startsWith('https://')) {
      // Already a full URL
      return url;
    } else if (url.startsWith('/')) {
      // Relative URL
      return '$apiBaseUrl$url';
    }

    return null;
  }

  /// Builds a placeholder image widget when no image is available or on error
  Widget _buildPlaceholderImage(BuildContext context, ThemeData theme) {
    return Container(
      width: double.infinity,
      height: 400,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Image.network(
        '$apiBaseUrl/defaults/kaza.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to empty container if default image fails
          return const SizedBox.shrink();
        },
      ),
    );
  }

  /// Builds the row containing metadata about the build, such as the author and post date.
  Widget _buildMetaInfo(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Build build, {
    required bool isMobile,
  }) {
    // If author is not included in build, fetch it using userId
    final authorAsync = build.author != null
        ? AsyncValue.data(build.author)
        : ref.watch(buildUserProvider(build.userId));
    final currentUser = ref.watch(authProvider).valueOrNull;
    final isOwner = currentUser != null && currentUser.uid == build.userId;
    final isStaff = currentUser?.userRole.isModeratorOrHigher ?? false;
    final canEdit = isOwner || isStaff;

    List<Widget> buildMetaItems({
      Widget? authorWidget,
      required String postedText,
      required bool canEditAction,
    }) {
      return [
        if (authorWidget != null) authorWidget,
        if (authorWidget != null) Text('•', style: theme.textTheme.bodySmall),
        Text(postedText, style: theme.textTheme.bodySmall),
        if (canEditAction)
          OutlinedButton.icon(
            onPressed: () {
              context.go('/build/${build.id}/edit');
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
          ),
        OutlinedButton(
          onPressed: () {},
          child: Text(AppLocalizations.of(context)!.wishlistBuild),
        ),
      ];
    }

    Widget wrapMeta(List<Widget> children) {
      return Wrap(
        spacing: 12,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.start,
        children: children,
      );
    }

    final postedText =
        '${AppLocalizations.of(context)!.postedOn}: ${build.databaseEntryAt != null ? DateFormat.yMMMMd().format(build.databaseEntryAt!) : DateFormat.yMMMMd().format(DateTime.now())}';

    return authorAsync.when(
      data: (author) {
        Widget? authorWidget;
        if (author != null) {
          authorWidget = InkWell(
            onTap: () {
              context.go('/profile/${author.uid}');
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AuthenticatedImage(
                    imageUrl: author.photoURL,
                    isCircle: true,
                    radius: 12,
                    username: author.username,
                    userId: author.uid,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    author.displayName.isNotEmpty
                        ? author.displayName
                        : author.username,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          );
        }

        return wrapMeta(
          buildMetaItems(
            authorWidget: authorWidget,
            postedText: postedText,
            canEditAction: canEdit,
          ),
        );
      },
      loading: () {
        final currentUser = ref.watch(authProvider).valueOrNull;
        final isOwner = currentUser != null && currentUser.uid == build.userId;
        final isStaff = currentUser?.userRole.isModeratorOrHigher ?? false;
        final canEditLoading = isOwner || isStaff;

        return wrapMeta(
          buildMetaItems(
            authorWidget: const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            postedText: postedText,
            canEditAction: canEditLoading,
          ),
        );
      },
      error: (error, stack) {
        final currentUser = ref.watch(authProvider).valueOrNull;
        final isOwner = currentUser != null && currentUser.uid == build.userId;
        final isStaff = currentUser?.userRole.isModeratorOrHigher ?? false;
        final canEditError = isOwner || isStaff;

        return wrapMeta(
          buildMetaItems(
            authorWidget: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text('Unknown User', style: theme.textTheme.bodyMedium),
              ],
            ),
            postedText: postedText,
            canEditAction: canEditError,
          ),
        );
      },
    );
  }

  /// Builds the row containing the build's title and its star rating.
  Widget _buildTitleAndRating(
    ThemeData theme,
    Build build, {
    required bool isMobile,
  }) {
    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            build.name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _RatingBar(build: build),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Text(
            build.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 12),
        _RatingBar(build: build),
      ],
    );
  }
}

/// Widget that displays the list of tags for a build
class _TagsSection extends StatelessWidget {
  final List<String> tags;

  const _TagsSection({required this.tags});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map((tag) {
        return InkWell(
          onTap: () {
            // Navigate to explore builds page with this tag selected
            context.go('/explore?tag=${Uri.encodeComponent(tag)}');
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.label, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  tag,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Widget that displays the list of components in a build
class _ComponentsSection extends ConsumerWidget {
  final List<BaseComponent> components;

  const _ComponentsSection({required this.components});

  String _getComponentTypeName(BuildContext context, ComponentType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case ComponentType.cpu:
        return l10n.cpu;
      case ComponentType.gpu:
        return l10n.gpu;
      case ComponentType.motherboard:
        return l10n.motherboard;
      case ComponentType.ram:
        return l10n.memoryRam;
      case ComponentType.storage:
        return l10n.storage;
      case ComponentType.psu:
        return l10n.powerSupply;
      case ComponentType.cooler:
        return l10n.cooler;
      case ComponentType.caseFan:
        return l10n.caseFan;
      case ComponentType.pcCase:
        return l10n.pcCase;
      case ComponentType.monitor:
        return l10n.monitor;
    }
  }

  IconData _getComponentTypeIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.memory;
      case ComponentType.gpu:
        return Icons.videocam;
      case ComponentType.motherboard:
        return Icons.dashboard;
      case ComponentType.ram:
        return Icons.view_module;
      case ComponentType.storage:
        return Icons.storage;
      case ComponentType.psu:
        return Icons.power;
      case ComponentType.cooler:
        return Icons.ac_unit;
      case ComponentType.caseFan:
        return Icons.air;
      case ComponentType.pcCase:
        return Icons.computer;
      case ComponentType.monitor:
        return Icons.monitor;
    }
  }

  void _showComponentDetails(BuildContext context, BaseComponent component) {
    final theme = Theme.of(context);
    final lowestPrice = component.lowestPrice;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.info_outline, color: theme.colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                component.name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic info
              _buildInfoRow(
                context,
                theme,
                AppLocalizations.of(context)!.manufacturer,
                component.manufacturer,
              ),
              _buildInfoRow(
                context,
                theme,
                AppLocalizations.of(context)!.type,
                _getComponentTypeName(context, component.type),
              ),
              if (lowestPrice != null)
                _buildInfoRow(
                  context,
                  theme,
                  AppLocalizations.of(context)!.price,
                  '\$${lowestPrice.toStringAsFixed(2)}',
                  isHighlighted: true,
                ),
              if (component.prices.isNotEmpty)
                _buildInfoRow(
                  context,
                  theme,
                  AppLocalizations.of(context)!.vendors,
                  AppLocalizations.of(
                    context,
                  )!.fromVendors(component.prices.length),
                ),
              if (component.release != null)
                _buildInfoRow(
                  context,
                  theme,
                  AppLocalizations.of(context)!.releaseDate,
                  DateFormat.yMMMMd().format(component.release!),
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),

              // Component-specific details
              ..._buildComponentSpecificDetails(context, theme, component),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.close),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildComponentSpecificDetails(
    BuildContext context,
    ThemeData theme,
    BaseComponent component,
  ) {
    switch (component.type) {
      case ComponentType.cpu:
        if (component is CPUComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.cpu} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, theme, 'Series', component.series),
            _buildInfoRow(context, theme, 'Socket', component.socketType),
            _buildInfoRow(
              context,
              theme,
              'Microarchitecture',
              component.microarchitecture,
            ),
            _buildInfoRow(context, theme, 'Core Family', component.coreFamily),
            _buildInfoRow(
              context,
              theme,
              'Total Cores',
              '${component.coreTotal}',
            ),
            if (component.performanceAmount != null)
              _buildInfoRow(
                context,
                theme,
                'P-Cores',
                '${component.performanceAmount}',
              ),
            if (component.efficiencyAmount != null)
              _buildInfoRow(
                context,
                theme,
                'E-Cores',
                '${component.efficiencyAmount}',
              ),
            _buildInfoRow(
              context,
              theme,
              'Threads',
              '${component.threadsAmount}',
            ),
            if (component.basePerformanceSpeed != null)
              _buildInfoRow(
                context,
                theme,
                'Base Clock (P-Core)',
                '${component.basePerformanceSpeed} GHz',
              ),
            if (component.boostPerformanceSpeed != null)
              _buildInfoRow(
                context,
                theme,
                'Boost Clock (P-Core)',
                '${component.boostPerformanceSpeed} GHz',
              ),
            if (component.baseEfficiencySpeed != null)
              _buildInfoRow(
                context,
                theme,
                'Base Clock (E-Core)',
                '${component.baseEfficiencySpeed} GHz',
              ),
            if (component.boostEfficiencySpeed != null)
              _buildInfoRow(
                context,
                theme,
                'Boost Clock (E-Core)',
                '${component.boostEfficiencySpeed} GHz',
              ),
            if (component.l1 != null)
              _buildInfoRow(context, theme, 'L1 Cache', '${component.l1} MB'),
            if (component.l2 != null)
              _buildInfoRow(context, theme, 'L2 Cache', '${component.l2} MB'),
            if (component.l3 != null)
              _buildInfoRow(context, theme, 'L3 Cache', '${component.l3} MB'),
            if (component.l4 != null)
              _buildInfoRow(context, theme, 'L4 Cache', '${component.l4} MB'),
            _buildInfoRow(
              context,
              theme,
              'TDP',
              '${component.thermalDesignPower}W',
            ),
            _buildInfoRow(context, theme, 'Lithography', component.lithography),
            _buildInfoRow(context, theme, 'Memory Type', component.memoryType),
            _buildInfoRow(context, theme, 'Packaging', component.packagingType),
            _buildInfoRow(
              context,
              theme,
              'Includes Cooler',
              component.includesCooler
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'SMT Support',
              component.supportsSimultaneousMultithreading
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'ECC Support',
              component.supportsECC
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            if (component.graphics.isNotEmpty && component.graphics != 'N/A')
              _buildInfoRow(
                context,
                theme,
                'Integrated Graphics',
                component.graphics,
              ),
          ];
        }
        break;
      case ComponentType.gpu:
        if (component is GPUComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.gpu} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, theme, 'Chipset', component.chipset),
            _buildInfoRow(
              context,
              theme,
              'VRAM',
              '${component.videoMemoryAmount.toStringAsFixed(0)} GB',
            ),
            _buildInfoRow(
              context,
              theme,
              'Memory Type',
              component.videoMemoryType,
            ),
            _buildInfoRow(
              context,
              theme,
              'Base Clock',
              '${component.coreBaseClockSpeed.toStringAsFixed(0)} MHz',
            ),
            _buildInfoRow(
              context,
              theme,
              'Boost Clock',
              '${component.coreBoostClockSpeed.toStringAsFixed(0)} MHz',
            ),
            _buildInfoRow(
              context,
              theme,
              'Core Count',
              '${component.coreCount}',
            ),
            _buildInfoRow(
              context,
              theme,
              'Memory Clock',
              '${component.effectiveMemoryClockSpeed.toStringAsFixed(0)} MHz',
            ),
            _buildInfoRow(
              context,
              theme,
              'Memory Bus Width',
              '${component.memoryBusWidth} bit',
            ),
            _buildInfoRow(
              context,
              theme,
              'TDP',
              '${component.thermalDesignPower}W',
            ),
            _buildInfoRow(
              context,
              theme,
              'Length',
              '${component.length.toStringAsFixed(0)} mm',
            ),
            _buildInfoRow(
              context,
              theme,
              'Slot Width',
              '${component.caseExpansionSlotWidth} slots',
            ),
            _buildInfoRow(
              context,
              theme,
              'Total Slots',
              '${component.totalSlotAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              'Cooling Type',
              component.coolingType,
            ),
            _buildInfoRow(context, theme, 'Frame Sync', component.frameSync),
          ];
        }
        break;
      case ComponentType.motherboard:
        if (component is MotherboardComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.motherboard} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, theme, 'Socket', component.socketType),
            _buildInfoRow(context, theme, 'Chipset', component.chipsetType),
            _buildInfoRow(context, theme, 'Form Factor', component.formFactor),
            _buildInfoRow(context, theme, 'RAM Type', component.ramType),
            _buildInfoRow(
              context,
              theme,
              'RAM Slots',
              '${component.ramSlotsAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              'Max RAM',
              '${component.maxRAMAmount} GB',
            ),
            _buildInfoRow(
              context,
              theme,
              'SATA 6 Gb/s',
              '${component.sata6GBsAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              'SATA 3 Gb/s',
              '${component.sata3GBsAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              'U.2 Ports',
              '${component.u2PortAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              'Wi-Fi',
              component.wirelessNetworkingStandard,
            ),
            if (component.cpuFanHeaderAmount != null)
              _buildInfoRow(
                context,
                theme,
                'CPU Fan Headers',
                '${component.cpuFanHeaderAmount}',
              ),
            if (component.caseFanHeaderAmount != null)
              _buildInfoRow(
                context,
                theme,
                'Case Fan Headers',
                '${component.caseFanHeaderAmount}',
              ),
            if (component.pumpHeaderAmount != null)
              _buildInfoRow(
                context,
                theme,
                'Pump Headers',
                '${component.pumpHeaderAmount}',
              ),
            if (component.argb5vHeaderAmount != null)
              _buildInfoRow(
                context,
                theme,
                'ARGB 5V Headers',
                '${component.argb5vHeaderAmount}',
              ),
            if (component.rgb12vHeaderAmount != null)
              _buildInfoRow(
                context,
                theme,
                'RGB 12V Headers',
                '${component.rgb12vHeaderAmount}',
              ),
            _buildInfoRow(
              context,
              theme,
              'Audio Chipset',
              component.audioChipset,
            ),
            _buildInfoRow(
              context,
              theme,
              'Max Audio Channels',
              '${component.maxAudioChannels}',
            ),
            _buildInfoRow(
              context,
              theme,
              'ECC Support',
              component.hasECCSupport
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'RAID Support',
              component.hasRAIDSupport
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'BIOS Flashback',
              component.hasFlashback
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'Clear CMOS',
              component.hasCMOS
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
          ];
        }
        break;
      case ComponentType.ram:
        if (component is MemoryComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.memoryRam} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, theme, 'Type', component.ramType),
            _buildInfoRow(context, theme, 'Form Factor', component.formFactor),
            _buildInfoRow(
              context,
              theme,
              'Capacity',
              '${component.capacity.toStringAsFixed(0)} GB',
            ),
            _buildInfoRow(
              context,
              theme,
              'Speed',
              '${component.speed.toStringAsFixed(0)} MHz',
            ),
            _buildInfoRow(
              context,
              theme,
              'CAS Latency',
              '${component.casLatency}',
            ),
            if (component.timings != null)
              _buildInfoRow(context, theme, 'Timings', component.timings!),
            _buildInfoRow(
              context,
              theme,
              'Modules',
              '${component.moduleQuantity}',
            ),
            _buildInfoRow(
              context,
              theme,
              'Module Capacity',
              '${component.moduleCapacity.toStringAsFixed(0)} GB',
            ),
            _buildInfoRow(context, theme, 'ECC', component.ecc),
            _buildInfoRow(
              context,
              theme,
              'Registered',
              component.registeredType,
            ),
            _buildInfoRow(
              context,
              theme,
              'Heat Spreader',
              component.haveHeatSpreader
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'RGB',
              component.haveRGB
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            _buildInfoRow(
              context,
              theme,
              'Height',
              '${component.height.toStringAsFixed(0)} mm',
            ),
            _buildInfoRow(context, theme, 'Voltage', '${component.voltage}V'),
          ];
        }
        break;
      case ComponentType.storage:
        if (component is StorageComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.storage} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, theme, 'Series', component.series),
            _buildInfoRow(context, theme, 'Type', component.driveType),
            _buildInfoRow(context, theme, 'Form Factor', component.formFactor),
            _buildInfoRow(
              context,
              theme,
              'Capacity',
              '${component.capacity.toStringAsFixed(0)} GB',
            ),
            _buildInfoRow(context, theme, 'Interface', component.interface),
            _buildInfoRow(
              context,
              theme,
              'NVMe',
              component.hasNVMe
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
          ];
        }
        break;
      case ComponentType.psu:
        if (component is PowerSupplyComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.powerSupply} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              theme,
              'Wattage',
              '${component.powerOutput.toStringAsFixed(0)}W',
            ),
            _buildInfoRow(context, theme, 'Form Factor', component.formFactor),
            if (component.efficiencyRating != null)
              _buildInfoRow(
                context,
                theme,
                'Efficiency',
                component.efficiencyRating!,
              ),
            _buildInfoRow(
              context,
              theme,
              'Modularity',
              component.modularityType,
            ),
            _buildInfoRow(
              context,
              theme,
              'Length',
              '${component.length.toStringAsFixed(0)} mm',
            ),
            _buildInfoRow(
              context,
              theme,
              'Fanless',
              component.isFanless
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
          ];
        }
        break;
      case ComponentType.cooler:
        if (component is CoolerComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.cooler} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              theme,
              'Type',
              component.isWaterCooled ? 'Water Cooled' : 'Air Cooled',
            ),
            _buildInfoRow(
              context,
              theme,
              'Height',
              '${component.height.toStringAsFixed(0)} mm',
            ),
            if (component.radiatorSize != null)
              _buildInfoRow(
                context,
                theme,
                'Radiator Size',
                '${component.radiatorSize!.toStringAsFixed(0)} mm',
              ),
            if (component.fanSize != null)
              _buildInfoRow(
                context,
                theme,
                'Fan Size',
                '${component.fanSize!.toStringAsFixed(0)} mm',
              ),
            _buildInfoRow(
              context,
              theme,
              'Fan Quantity',
              '${component.fanQuantity}',
            ),
            if (component.minFanRotationSpeed != null)
              _buildInfoRow(
                context,
                theme,
                'Min Fan Speed',
                '${component.minFanRotationSpeed!.toStringAsFixed(0)} RPM',
              ),
            if (component.maxFanRotationSpeed != null)
              _buildInfoRow(
                context,
                theme,
                'Max Fan Speed',
                '${component.maxFanRotationSpeed!.toStringAsFixed(0)} RPM',
              ),
            if (component.minNoiseLevel != null)
              _buildInfoRow(
                context,
                theme,
                'Min Noise',
                '${component.minNoiseLevel!.toStringAsFixed(1)} dBA',
              ),
            if (component.maxNoiseLevel != null)
              _buildInfoRow(
                context,
                theme,
                'Max Noise',
                '${component.maxNoiseLevel!.toStringAsFixed(1)} dBA',
              ),
            _buildInfoRow(
              context,
              theme,
              'Fanless Operation',
              component.canOperateFanless
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
          ];
        }
        break;
      case ComponentType.caseFan:
        if (component is CaseFanComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.caseFan} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              theme,
              'Size',
              '${component.size.toStringAsFixed(0)} mm',
            ),
            _buildInfoRow(context, theme, 'Quantity', '${component.quantity}'),
            _buildInfoRow(
              context,
              theme,
              'Min Airflow',
              '${component.minAirflow.toStringAsFixed(0)} CFM',
            ),
            if (component.maxAirflow != null)
              _buildInfoRow(
                context,
                theme,
                'Max Airflow',
                '${component.maxAirflow!.toStringAsFixed(0)} CFM',
              ),
            _buildInfoRow(
              context,
              theme,
              'Min Noise',
              '${component.minNoiseLevel.toStringAsFixed(1)} dBA',
            ),
            if (component.maxNoiseLevel != null)
              _buildInfoRow(
                context,
                theme,
                'Max Noise',
                '${component.maxNoiseLevel!.toStringAsFixed(1)} dBA',
              ),
            _buildInfoRow(
              context,
              theme,
              'PWM',
              component.pulseWidthModulation
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            if (component.ledType != null)
              _buildInfoRow(context, theme, 'LED Type', component.ledType!),
            if (component.connectorType != null)
              _buildInfoRow(
                context,
                theme,
                'Connector',
                component.connectorType!,
              ),
            _buildInfoRow(
              context,
              theme,
              'Controller',
              component.controllerType,
            ),
            _buildInfoRow(
              context,
              theme,
              'Static Pressure',
              '${component.staticPressureAmount.toStringAsFixed(2)} mmH2O',
            ),
            _buildInfoRow(
              context,
              theme,
              'Flow Direction',
              component.flowDirection,
            ),
          ];
        }
        break;
      case ComponentType.pcCase:
        if (component is CaseComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.pcCase} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(context, theme, 'Form Factor', component.formFactor),
            _buildInfoRow(
              context,
              theme,
              'Power Supply Shrouded',
              component.powerSupplyShrouded
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            if (component.powerSupplyAmount != null)
              _buildInfoRow(
                context,
                theme,
                'Included PSU',
                '${component.powerSupplyAmount!.toStringAsFixed(0)}W',
              ),
            _buildInfoRow(
              context,
              theme,
              'Transparent Side Panel',
              component.hasTransparentSidePanel
                  ? AppLocalizations.of(context)!.yes
                  : AppLocalizations.of(context)!.no,
            ),
            if (component.sidePanelType != null)
              _buildInfoRow(
                context,
                theme,
                'Side Panel Type',
                component.sidePanelType!,
              ),
            _buildInfoRow(
              context,
              theme,
              'Max GPU Length',
              '${component.maxVideoCardLength.toStringAsFixed(0)} mm',
            ),
            _buildInfoRow(
              context,
              theme,
              'Max CPU Cooler Height',
              '${component.maxCPUCoolerHeight} mm',
            ),
            _buildInfoRow(
              context,
              theme,
              '3.5" Bays',
              '${component.internal35BayAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              '2.5" Bays',
              '${component.internal25BayAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              '5.25" Bays',
              '${component.external525BayAmount}',
            ),
            _buildInfoRow(
              context,
              theme,
              '3.5" External Bays',
              '${component.external35BayAmount}',
            ),
          ];
        }
        break;
      case ComponentType.monitor:
        if (component is MonitorComponent) {
          return [
            Text(
              '${AppLocalizations.of(context)!.monitor} ${AppLocalizations.of(context)!.components}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              theme,
              'Screen Size',
              '${component.screenSize.toStringAsFixed(1)}"',
            ),
            _buildInfoRow(
              context,
              theme,
              'Resolution',
              '${component.horizontalResolution}x${component.verticalResolution}',
            ),
            _buildInfoRow(
              context,
              theme,
              'Refresh Rate',
              '${component.maxRefreshRate.toStringAsFixed(0)} Hz',
            ),
            _buildInfoRow(context, theme, 'Panel Type', component.panelType),
            _buildInfoRow(
              context,
              theme,
              'Response Time',
              '${component.responseTime.toStringAsFixed(1)} ms',
            ),
            _buildInfoRow(
              context,
              theme,
              'Viewing Angle',
              component.viewingAngle,
            ),
            _buildInfoRow(
              context,
              theme,
              'Aspect Ratio',
              component.aspectRatio,
            ),
            if (component.maxBrightness != null)
              _buildInfoRow(
                context,
                theme,
                'Max Brightness',
                '${component.maxBrightness!.toStringAsFixed(0)} nits',
              ),
            if (component.highDynamicRangeType != null)
              _buildInfoRow(
                context,
                theme,
                'HDR',
                component.highDynamicRangeType!,
              ),
            _buildInfoRow(
              context,
              theme,
              'Adaptive Sync',
              component.adaptiveSyncType,
            ),
          ];
        }
        break;
    }
    return [];
  }

  Widget _buildInfoRow(
    BuildContext context,
    ThemeData theme,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    // Helper method to get localized label
    String getLocalizedLabel(String label) {
      final l10n = AppLocalizations.of(context)!;
      // Map English labels to localization keys
      switch (label) {
        case 'Series':
          return l10n.series;
        case 'Socket':
          return l10n.socket;
        case 'Chipset':
          return l10n.chipset;
        case 'Form Factor':
          return l10n.formFactor;
        case 'Memory Type':
          return l10n.memoryType;
        case 'RAM Type':
          return l10n.ramType;
        case 'Capacity':
          return l10n.capacity;
        case 'Speed':
          return l10n.speed;
        case 'TDP':
          return l10n.tdp;
        case 'Length':
          return l10n.length;
        case 'Height':
          return l10n.height;
        case 'Base Clock':
          return l10n.baseClock;
        case 'Boost Clock':
          return l10n.boostClock;
        case 'Core Count':
          return l10n.coreCount;
        case 'Threads':
          return l10n.threads;
        case 'VRAM':
          return l10n.vram;
        case 'Microarchitecture':
          return l10n.microarchitecture;
        case 'Core Family':
          return l10n.coreFamily;
        case 'Total Cores':
          return l10n.totalCores;
        case 'P-Cores':
          return l10n.pCores;
        case 'E-Cores':
          return l10n.eCores;
        case 'L1 Cache':
          return l10n.l1Cache;
        case 'L2 Cache':
          return l10n.l2Cache;
        case 'L3 Cache':
          return l10n.l3Cache;
        case 'L4 Cache':
          return l10n.l4Cache;
        case 'Lithography':
          return l10n.lithography;
        case 'Packaging':
          return l10n.packaging;
        case 'Includes Cooler':
          return l10n.includesCooler;
        case 'SMT Support':
          return l10n.smtSupport;
        case 'ECC Support':
          return l10n.eccSupport;
        case 'Integrated Graphics':
          return l10n.integratedGraphics;
        case 'Memory Clock':
          return l10n.memoryClock;
        case 'Memory Bus Width':
          return l10n.memoryBusWidth;
        case 'Slot Width':
          return l10n.slotWidth;
        case 'Total Slots':
          return l10n.totalSlots;
        case 'Cooling Type':
          return l10n.coolingType;
        case 'Frame Sync':
          return l10n.frameSync;
        case 'RAM Slots':
          return l10n.ramSlots;
        case 'Max RAM':
          return l10n.maxRam;
        case 'CPU Fan Headers':
          return l10n.cpuFanHeaders;
        case 'Case Fan Headers':
          return l10n.caseFanHeaders;
        case 'Pump Headers':
          return l10n.pumpHeaders;
        case 'ARGB 5V Headers':
          return l10n.argb5vHeaders;
        case 'RGB 12V Headers':
          return l10n.rgb12vHeaders;
        case 'Audio Chipset':
          return l10n.audioChipset;
        case 'Max Audio Channels':
          return l10n.maxAudioChannels;
        case 'RAID Support':
          return l10n.raidSupport;
        case 'BIOS Flashback':
          return l10n.biosFlashback;
        case 'Clear CMOS':
          return l10n.clearCmos;
        case 'CAS Latency':
          return l10n.casLatency;
        case 'Timings':
          return l10n.timings;
        case 'Modules':
          return l10n.modules;
        case 'Module Capacity':
          return l10n.moduleCapacity;
        case 'ECC':
          return l10n.ecc;
        case 'Registered':
          return l10n.registered;
        case 'Heat Spreader':
          return l10n.heatSpreader;
        case 'RGB':
          return l10n.rgb;
        case 'Voltage':
          return l10n.voltage;
        case 'Interface':
          return l10n.interface;
        case 'NVMe':
          return l10n.nvme;
        case 'Wattage':
          return l10n.wattage;
        case 'Efficiency':
          return l10n.efficiency;
        case 'Modularity':
          return l10n.modularity;
        case 'Fanless':
          return l10n.fanless;
        case 'Radiator Size':
          return l10n.radiatorSize;
        case 'Fan Size':
          return l10n.fanSize;
        case 'Fan Quantity':
          return l10n.fanQuantity;
        case 'Min Fan Speed':
          return l10n.minFanSpeed;
        case 'Max Fan Speed':
          return l10n.maxFanSpeed;
        case 'Min Noise':
          return l10n.minNoise;
        case 'Max Noise':
          return l10n.maxNoise;
        case 'Fanless Operation':
          return l10n.fanlessOperation;
        case 'Size':
          return l10n.size;
        case 'Quantity':
          return l10n.quantity;
        case 'Min Airflow':
          return l10n.minAirflow;
        case 'Max Airflow':
          return l10n.maxAirflow;
        case 'PWM':
          return l10n.pwm;
        case 'LED Type':
          return l10n.ledType;
        case 'Connector':
          return l10n.connector;
        case 'Controller':
          return l10n.controller;
        case 'Static Pressure':
          return l10n.staticPressure;
        case 'Flow Direction':
          return l10n.flowDirection;
        case 'Power Supply Shrouded':
          return l10n.powerSupplyShrouded;
        case 'Included PSU':
          return l10n.includedPsu;
        case 'Transparent Side Panel':
          return l10n.transparentSidePanel;
        case 'Side Panel Type':
          return l10n.sidePanelType;
        case 'Max GPU Length':
          return l10n.maxGpuLength;
        case 'Max CPU Cooler Height':
          return l10n.maxCpuCoolerHeight;
        case 'Screen Size':
          return l10n.screenSize;
        case 'Resolution':
          return l10n.resolution;
        case 'Refresh Rate':
          return l10n.refreshRate;
        case 'Panel Type':
          return l10n.panelType;
        case 'Response Time':
          return l10n.responseTime;
        case 'Viewing Angle':
          return l10n.viewingAngle;
        case 'Aspect Ratio':
          return l10n.aspectRatio;
        case 'Max Brightness':
          return l10n.maxBrightness;
        case 'HDR':
          return l10n.hdr;
        case 'Adaptive Sync':
          return l10n.adaptiveSync;
        case 'SATA 6 Gb/s':
          return l10n.sata6Gbs;
        case 'SATA 3 Gb/s':
          return l10n.sata3Gbs;
        case 'U.2 Ports':
          return l10n.u2Ports;
        case 'Wi-Fi':
          return l10n.wifi;
        case '3.5" Bays':
          return l10n.internal35BayAmount;
        case '2.5" Bays':
          return l10n.internal25BayAmount;
        case '5.25" Bays':
          return l10n.external525BayAmount;
        case '3.5" External Bays':
          return l10n.external35BayAmount;
        case 'Water Cooled':
          return l10n.waterCooled;
        case 'Air Cooled':
          return l10n.airCooled;
        case 'Type':
          return l10n.type;
        case 'Price':
          return l10n.price;
        case 'Release Date':
          return l10n.releaseDate;
        case 'Manufacturer':
          return l10n.manufacturer;
        case 'Vendors':
          return l10n.vendors;
        case 'Base Clock (P-Core)':
          return '${l10n.baseClock} (${l10n.pCores})';
        case 'Boost Clock (P-Core)':
          return '${l10n.boostClock} (${l10n.pCores})';
        case 'Base Clock (E-Core)':
          return '${l10n.baseClock} (${l10n.eCores})';
        case 'Boost Clock (E-Core)':
          return '${l10n.boostClock} (${l10n.eCores})';
        default:
          return label; // Return original if not found
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '${getLocalizedLabel(label)}:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted ? theme.colorScheme.primary : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: components.isEmpty
                  ? null
                  : () async {
                      final componentService = ref.read(
                        componentServiceProvider,
                      );
                      await ref
                          .read(buildProvider.notifier)
                          .loadComponentsFromBuildWithPrices(
                            components,
                            componentService,
                          );
                      context.go('/build-now');
                    },
              icon: const Icon(Icons.dashboard_customize_outlined, size: 18),
              label: Text(l10n.openInBuilder),
            ),
          ),
          const SizedBox(height: 12),
          if (components.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text(
                  l10n.noComponentsListed,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ),
            )
          else
            ...components.whereType<BaseComponent>().map((component) {
              final lowestPrice = component.lowestPrice;

              return InkWell(
                onTap: () => _showComponentDetails(context, component),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          _getComponentTypeIcon(component.type),
                          size: 24,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.primary.withValues(
                                      alpha: 0.15,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _getComponentTypeName(
                                      context,
                                      component.type,
                                    ),
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              component.name,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              component.manufacturer,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (lowestPrice != null && component.prices.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '\$${lowestPrice.toStringAsFixed(2)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              Text(
                                AppLocalizations.of(
                                  context,
                                )!.fromVendors(component.prices.length),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}

class _CommentsSection extends ConsumerStatefulWidget {
  final String buildId;
  const _CommentsSection({required this.buildId});

  @override
  ConsumerState<_CommentsSection> createState() => _CommentsSectionState();
}

class _RatingBar extends ConsumerStatefulWidget {
  final Build build;
  const _RatingBar({required this.build});

  @override
  ConsumerState<_RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends ConsumerState<_RatingBar> {
  late double _average;
  late int _count;
  double? _userRating;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _average = widget.build.averageRating;
    _count = widget.build.ratingsCount;
    // Only set userRating if it's a valid rating (not null and > 0)
    _userRating =
        (widget.build.userRating != null && widget.build.userRating! > 0)
        ? widget.build.userRating
        : null;
  }

  @override
  void didUpdateWidget(_RatingBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update state when build data changes (e.g., after refetch)
    if (oldWidget.build.averageRating != widget.build.averageRating ||
        oldWidget.build.ratingsCount != widget.build.ratingsCount ||
        oldWidget.build.userRating != widget.build.userRating) {
      setState(() {
        _average = widget.build.averageRating;
        _count = widget.build.ratingsCount;
        // Only set userRating if it's a valid rating (not null and > 0)
        _userRating =
            (widget.build.userRating != null && widget.build.userRating! > 0)
            ? widget.build.userRating
            : null;
      });
    }
  }

  Future<void> _submit(double rating) async {
    final currentUser = ref.read(authProvider).valueOrNull;
    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.pleaseSignInToRate),
          ),
        );
      }
      return;
    }

    if (_submitting) return;

    // Check if user is clicking the same rating (undo)
    final isUndo = _userRating != null && _userRating == rating;
    final ratingToSubmit = isUndo ? 0.0 : rating;

    // Store previous values in case we need to revert
    final previousAverage = _average;
    final previousCount = _count;
    final previousUserRating = _userRating;

    setState(() {
      _submitting = true;
      // Optimistic update
      if (isUndo) {
        // Remove rating: subtract user's rating from average
        if (_count > 1) {
          final total = (_average * _count) - _userRating!;
          _average = total / (_count - 1);
          _count = _count - 1;
        } else {
          // Last rating removed
          _average = 0.0;
          _count = 0;
        }
        _userRating = null;
      } else {
        final hadPrevious = _userRating != null;
        if (!hadPrevious) {
          // New rating
          _average = _count == 0
              ? rating
              : ((_average * _count) + rating) / (_count + 1);
          _count = _count + 1;
        } else {
          // Update existing rating
          final total = (_average * _count) - _userRating! + rating;
          _average = _count == 0 ? rating : (total / _count);
        }
        _userRating = rating;
      }
    });

    try {
      final user = ref.read(authProvider).valueOrNull;
      if (user == null) {
        // Revert optimistic update if user check fails
        if (mounted) {
          setState(() {
            _average = previousAverage;
            _count = previousCount;
            _userRating = previousUserRating;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)!.pleaseSignInToRateBuilds,
              ),
            ),
          );
        }
        return;
      }
      final service = ref.read(buildServiceProvider);
      final result = await service.rateBuild(
        widget.build.id,
        ratingToSubmit,
        user.uid,
      );

      // Check if backend returned rating statistics
      final newAvg =
          result['averageRating'] ??
          result['ratingAverage'] ??
          result['rating'];
      final newCount =
          result['ratingsCount'] ?? result['ratingCount'] ?? result['votes'];

      if (mounted && newAvg != null && newCount != null) {
        setState(() {
          // Backend returns 0-100; normalize to 0-5
          final avgDouble = (newAvg as num).toDouble();
          _average = avgDouble > 5.0 ? (avgDouble / 20.0) : avgDouble;
          _count = (newCount as num).toInt();
        });
      } else {
        // Backend didn't return stats, but request succeeded
        // Keep the optimistic update - don't refresh to avoid disrupting UI
        // The rating will be updated when the page is refreshed or navigated to again
      }
    } catch (e) {
      // On error, revert optimistic update
      if (mounted) {
        setState(() {
          _average = previousAverage;
          _count = previousCount;
          _userRating = previousUserRating;
        });
        // Check if it's the "already exists" error - treat as success
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('already exists') ||
            errorMsg.contains('interaction already')) {
          // Rating was already saved, keep optimistic update
          // Don't refresh to avoid disrupting UI
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(getUserFriendlyError(e))));
        }
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Stars only show user's rating, not the average
    // Only show filled stars if userRating exists and is greater than 0
    // If userRating is null or 0, all stars should be empty (border only)
    final hasUserRating = _userRating != null && _userRating! > 0;
    final userRatingValue = hasUserRating ? _userRating : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            // Only fill stars if user has a valid rating AND it's >= this star index
            final isFilled =
                hasUserRating && userRatingValue! >= starIndex - 0.5;
            final isCurrentRating =
                hasUserRating && _userRating == starIndex.toDouble();
            return IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: Colors.amber,
              ),
              onPressed: _submitting
                  ? null
                  : () => _submit(starIndex.toDouble()),
              tooltip: isCurrentRating
                  ? AppLocalizations.of(context)!.removeRating
                  : '${AppLocalizations.of(context)!.rate} $starIndex',
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          '${_average.toStringAsFixed(1)} ($_count)',
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _CommentsSectionState extends ConsumerState<_CommentsSection> {
  final TextEditingController _controller = TextEditingController();
  bool _posting = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  String? _replyingToCommentId; // Track which comment we're replying to

  void _copyToClipboard(String text) {
    if (text.trim().isEmpty || text == '[Image]') return;
    Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  void _copyImageUrlToClipboard(String url) {
    if (url.trim().isEmpty) return;
    Clipboard.setData(ClipboardData(text: url));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Image link copied to clipboard')),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          if (_selectedImages.length > 5) {
            _selectedImages.removeRange(5, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Maximum 5 images allowed. Only first 5 will be uploaded.',
                ),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to pick images: ${getUserFriendlyError(e)}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitComment() async {
    final text = _controller.text.trim();
    // Allow posting with just images (no text required)
    if (text.isEmpty && _selectedImages.isEmpty) return;
    if (_posting) return;

    setState(() => _posting = true);
    try {
      final user = ref.read(authProvider).valueOrNull;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.pleaseSignInToCommentShort,
            ),
          ),
        );
        setState(() => _posting = false);
        return;
      }
      final authorName = user.username;
      // Use text or placeholder if only images
      final commentText = text.isEmpty ? '[Image]' : text;
      final comment = await ref
          .read(buildCommentsProvider(widget.buildId).notifier)
          .add(
            authorName,
            commentText,
            user.uid,
            parentCommentId: _replyingToCommentId,
          );

      if (_selectedImages.isNotEmpty && comment.id.isNotEmpty) {
        await _uploadImages(comment.id).catchError((e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Comment posted but images failed: ${getUserFriendlyError(e)}',
                ),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        });
        // Invalidate comment images provider to refresh images immediately
        // Wait a bit for backend to process the images
        await Future.delayed(const Duration(milliseconds: 500));
        ref.invalidate(commentImagesProvider(comment.id));
      }

      _controller.clear();
      setState(() {
        _selectedImages.clear();
        _replyingToCommentId = null;
      });
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post comment: ${getUserFriendlyError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _posting = false);
      }
    }
  }

  Future<void> _uploadImages(String commentId) async {
    final dio = ref.read(authProvider.notifier).getDioInstance();
    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      try {
        final fileBytes = await image.readAsBytes();
        var fileName = image.name;
        if (fileName.isEmpty || !fileName.contains('.')) {
          fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        }
        final formData = FormData.fromMap({
          'File': MultipartFile.fromBytes(fileBytes, filename: fileName),
          'TargetId': commentId,
          'LocationType': 'COMMENT',
          'Name': 'build_comment_${DateTime.now().millisecondsSinceEpoch}_$i',
        });
        await dio.post('$apiBaseUrl/Images/add', data: formData);
      } catch (e) {
        debugPrint('Failed to upload image ${i + 1}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final commentsAsync = ref.watch(buildCommentsProvider(widget.buildId));
    final userAsync = ref.watch(authProvider);
    final isLoggedIn = userAsync.valueOrNull != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Comment input box at the top
        if (!isLoggedIn)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.lock_outline, color: theme.colorScheme.outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppLocalizations.of(context)!.signInToComment,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // Show a message directing user to sign in
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(context)!.pleaseSignInToComment,
                        ),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.signIn),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    userAsync.when(
                      data: (user) => AuthenticatedImage(
                        imageUrl: user?.photoURL,
                        isCircle: true,
                        radius: 16,
                        username: user?.username,
                        userId: user?.uid,
                      ),
                      loading: () => UserImageUtils.buildUserAvatar(
                        username: userAsync.valueOrNull?.username,
                        userId: userAsync.valueOrNull?.uid,
                        radius: 16,
                      ),
                      error: (_, __) => UserImageUtils.buildUserAvatar(
                        username: userAsync.valueOrNull?.username,
                        userId: userAsync.valueOrNull?.uid,
                        radius: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        minLines: 1,
                        maxLines: 4,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                        decoration: InputDecoration(
                          hintText: AppLocalizations.of(context)!.writeComment,
                          helperText:
                              'Share your thoughts about this build. You can also attach up to 5 images. Press Enter to submit.',
                          helperMaxLines: 2,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_selectedImages.length < 5)
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate),
                        onPressed: _pickImages,
                        tooltip: 'Add images',
                      ),
                    const SizedBox(width: 4),
                    ElevatedButton(
                      onPressed: _posting ? null : _submitComment,
                      child: _posting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(AppLocalizations.of(context)!.post),
                    ),
                  ],
                ),
                if (_selectedImages.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        final image = _selectedImages[index];
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder<Uint8List>(
                                  future: image.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: theme.colorScheme.surfaceVariant,
                                        child: const Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError ||
                                        !snapshot.hasData) {
                                      return Container(
                                        width: 80,
                                        height: 80,
                                        color: theme.colorScheme.surfaceVariant,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 80,
                                      height: 80,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
        const SizedBox(height: 16),
        // Comments list below the input box
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
          ),
          child: commentsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text(
                AppLocalizations.of(context)!.failedToLoadComments,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            data: (comments) {
              if (comments.isEmpty) {
                return Center(
                  child: Text(
                    AppLocalizations.of(context)!.noCommentsYet,
                    style: theme.textTheme.bodyMedium,
                  ),
                );
              }

              // Create username to user ID mapping for @mention resolution
              final Map<String, String> usernameToUserIdMap = {};
              for (final comment in comments) {
                if (comment.userId != null && comment.authorName.isNotEmpty) {
                  usernameToUserIdMap[comment.authorName] = comment.userId!;
                }
              }

              // Organize comments into a tree structure
              final Map<String, List<BuildComment>> commentTree = {};
              final List<BuildComment> topLevelComments = [];

              for (final comment in comments) {
                if (comment.parentCommentId != null &&
                    comment.parentCommentId!.isNotEmpty) {
                  // This is a reply to another comment
                  commentTree
                      .putIfAbsent(comment.parentCommentId!, () => [])
                      .add(comment);
                } else {
                  // This is a top-level comment
                  topLevelComments.add(comment);
                }
              }

              // Build flat list with nested structure
              final List<BuildComment> organizedComments = [];
              void addCommentWithReplies(BuildComment comment, int depth) {
                organizedComments.add(comment);
                final replies = commentTree[comment.id] ?? [];
                for (final reply in replies) {
                  addCommentWithReplies(reply, depth + 1);
                }
              }

              for (final topLevel in topLevelComments) {
                addCommentWithReplies(topLevel, 0);
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: organizedComments.length,
                separatorBuilder: (_, __) => const Divider(height: 24),
                itemBuilder: (context, index) {
                  final c = organizedComments[index];
                  final isReply =
                      c.parentCommentId != null &&
                      c.parentCommentId!.isNotEmpty;
                  return Padding(
                    padding: EdgeInsets.only(left: isReply ? 32.0 : 0.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (c.userId != null)
                          ref
                              .watch(buildUserProvider(c.userId!))
                              .when(
                                data: (user) => InkWell(
                                  onTap: () {
                                    context.go('/profile/${c.userId}');
                                  },
                                  borderRadius: BorderRadius.circular(20),
                                  child: Padding(
                                    padding: const EdgeInsets.all(4),
                                    child: AuthenticatedImage(
                                      imageUrl: user?.photoURL,
                                      isCircle: true,
                                      radius: 16,
                                      username: c.authorName,
                                      userId: c.userId,
                                    ),
                                  ),
                                ),
                                loading: () => UserImageUtils.buildUserAvatar(
                                  username: c.authorName,
                                  userId: c.userId,
                                  radius: 16,
                                ),
                                error: (_, __) =>
                                    UserImageUtils.buildUserAvatar(
                                      username: c.authorName,
                                      userId: c.userId,
                                      radius: 16,
                                    ),
                              )
                        else
                          UserImageUtils.buildUserAvatar(
                            username: c.authorName,
                            radius: 16,
                          ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                children: <Widget>[
                                  if (c.userId != null)
                                    InkWell(
                                      onTap: () {
                                        context.go('/profile/${c.userId}');
                                      },
                                      child: Text(
                                        c.authorName,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.primary,
                                            ),
                                      ),
                                    )
                                  else
                                    Text(
                                      c.authorName,
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    DateFormat.yMMMd().add_jm().format(
                                      c.createdAt,
                                    ),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              // Only show text if it's not the placeholder
                              if (c.text != '[Image]')
                                LinkableText(
                                  text: c.text,
                                  style: theme.textTheme.bodyMedium,
                                  usernameToUserIdMap: usernameToUserIdMap,
                                ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(
                                      minWidth: 28,
                                      minHeight: 28,
                                    ),
                                    iconSize: 16,
                                    tooltip: 'Copy',
                                    onPressed:
                                        c.text.trim().isEmpty ||
                                            c.text == '[Image]'
                                        ? null
                                        : () => _copyToClipboard(c.text),
                                    icon: Icon(
                                      Icons.copy,
                                      size: 16,
                                      color: theme.colorScheme.onSurface
                                          .withValues(alpha: 0.7),
                                    ),
                                  ),
                                  if (isLoggedIn)
                                    TextButton.icon(
                                      onPressed: () {
                                        setState(() {
                                          _replyingToCommentId =
                                              _replyingToCommentId == c.id
                                              ? null
                                              : c.id;
                                          if (_replyingToCommentId == c.id) {
                                            _controller.text =
                                                '@${c.authorName} ';
                                            _controller.selection =
                                                TextSelection.fromPosition(
                                                  TextPosition(
                                                    offset:
                                                        _controller.text.length,
                                                  ),
                                                );
                                          } else {
                                            _controller.clear();
                                          }
                                        });
                                      },
                                      icon: Icon(
                                        _replyingToCommentId == c.id
                                            ? Icons.close
                                            : Icons.reply,
                                        size: 16,
                                      ),
                                      label: Text(
                                        _replyingToCommentId == c.id
                                            ? 'Cancel'
                                            : 'Reply',
                                      ),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                ],
                              ),
                              // Display images attached to the comment
                              ref
                                  .watch(commentImagesProvider(c.id))
                                  .when(
                                    data: (imageUrls) {
                                      if (imageUrls.isEmpty)
                                        return const SizedBox.shrink();
                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 8),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: imageUrls.map((imageUrl) {
                                              return GestureDetector(
                                                onTap: () {
                                                  // Show fullscreen image viewer
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) => Dialog(
                                                      backgroundColor:
                                                          Colors.transparent,
                                                      insetPadding:
                                                          const EdgeInsets.all(
                                                            20,
                                                          ),
                                                      child: Stack(
                                                        children: [
                                                          Center(
                                                            child: InteractiveViewer(
                                                              minScale: 0.5,
                                                              maxScale: 4.0,
                                                              child: Image.network(
                                                                imageUrl,
                                                                fit: BoxFit
                                                                    .contain,
                                                                errorBuilder:
                                                                    (
                                                                      context,
                                                                      error,
                                                                      stackTrace,
                                                                    ) {
                                                                      return Container(
                                                                        width:
                                                                            300,
                                                                        height:
                                                                            300,
                                                                        color: theme
                                                                            .colorScheme
                                                                            .surfaceVariant,
                                                                        child: const Icon(
                                                                          Icons
                                                                              .broken_image,
                                                                          size:
                                                                              64,
                                                                        ),
                                                                      );
                                                                    },
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            right: 10,
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons.close,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              onPressed: () =>
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop(),
                                                              style: IconButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .black54,
                                                              ),
                                                            ),
                                                          ),
                                                          Positioned(
                                                            top: 10,
                                                            left: 10,
                                                            child: IconButton(
                                                              icon: const Icon(
                                                                Icons.copy,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                              tooltip:
                                                                  'Copy image link',
                                                              onPressed: () =>
                                                                  _copyImageUrlToClipboard(
                                                                    imageUrl,
                                                                  ),
                                                              style: IconButton.styleFrom(
                                                                backgroundColor:
                                                                    Colors
                                                                        .black54,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: Stack(
                                                  children: [
                                                    ClipRRect(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      child: Image.network(
                                                        imageUrl,
                                                        width: 150,
                                                        height: 150,
                                                        fit: BoxFit.cover,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Container(
                                                                width: 150,
                                                                height: 150,
                                                                color: theme
                                                                    .colorScheme
                                                                    .surfaceVariant,
                                                                child: const Icon(
                                                                  Icons
                                                                      .broken_image,
                                                                ),
                                                              );
                                                            },
                                                      ),
                                                    ),
                                                    Positioned(
                                                      top: 6,
                                                      right: 6,
                                                      child: Material(
                                                        color: Colors.black54,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              16,
                                                            ),
                                                        child: InkWell(
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                16,
                                                              ),
                                                          onTap: () =>
                                                              _copyImageUrlToClipboard(
                                                                imageUrl,
                                                              ),
                                                          child: const Padding(
                                                            padding:
                                                                EdgeInsets.all(
                                                                  4.0,
                                                                ),
                                                            child: Icon(
                                                              Icons.copy,
                                                              size: 14,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );
                                            }).toList(),
                                          ),
                                        ],
                                      );
                                    },
                                    loading: () => const SizedBox.shrink(),
                                    error: (e, s) => const SizedBox.shrink(),
                                  ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
