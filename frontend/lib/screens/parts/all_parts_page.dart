/// This file defines the UI for displaying all PC parts grouped by component type.
library;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// The main page for viewing all PC parts grouped by type.
class AllPartsPage extends ConsumerStatefulWidget {
  const AllPartsPage({super.key});

  @override
  ConsumerState<AllPartsPage> createState() => _AllPartsPageState();
}

class _AllPartsPageState extends ConsumerState<AllPartsPage> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final asyncComponents = ref.watch(allComponentsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    theme.scaffoldBackgroundColor,
                    theme.colorScheme.surface.withOpacity(0.3),
                  ],
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1400),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      const _HeaderSection(),
                      const SizedBox(height: 32),
                      // Category Menu
                      asyncComponents.when(
                        data: (components) {
                          // Count components by type for display
                          final countsByType = <ComponentType, int>{};
                          for (final component in components) {
                            countsByType[component.type] = (countsByType[component.type] ?? 0) + 1;
                          }
                          
                          return _CategoryMenuGrid(countsByType: countsByType);
                        },
                        loading: () => const Center(
                          child: Padding(
                            padding: EdgeInsets.all(48.0),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        error: (error, stack) => _ErrorState(error: error.toString()),
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
}

/// Header section with title
class _HeaderSection extends StatelessWidget {
  const _HeaderSection();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.category,
              size: 40,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Text(
              'PC Parts Categories',
              style: theme.textTheme.headlineLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Choose a category to browse available PC components',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

/// Error state
class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(64.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Error loading parts',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// A grid widget that displays all component categories as clickable cards.
class _CategoryMenuGrid extends StatelessWidget {
  final Map<ComponentType, int> countsByType;

  const _CategoryMenuGrid({required this.countsByType});

  String _getTypeDisplayName(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return 'CPU';
      case ComponentType.gpu:
        return 'GPU';
      case ComponentType.motherboard:
        return 'Motherboard';
      case ComponentType.ram:
        return 'Memory (RAM)';
      case ComponentType.storage:
        return 'Storage';
      case ComponentType.psu:
        return 'Power Supply';
      case ComponentType.cooler:
        return 'Cooler';
      case ComponentType.caseFan:
        return 'Case Fan';
      case ComponentType.pcCase:
        return 'Case';
      case ComponentType.monitor:
        return 'Monitor';
    }
  }

  IconData _getTypeIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.speed;
      case ComponentType.gpu:
        return Icons.videogame_asset;
      case ComponentType.motherboard:
        return Icons.developer_board;
      case ComponentType.ram:
        return Icons.memory;
      case ComponentType.storage:
        return Icons.save;
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

  Color _getTypeColor(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Colors.blue;
      case ComponentType.gpu:
        return Colors.purple;
      case ComponentType.motherboard:
        return Colors.green;
      case ComponentType.ram:
        return Colors.orange;
      case ComponentType.storage:
        return Colors.teal;
      case ComponentType.psu:
        return Colors.red;
      case ComponentType.cooler:
        return Colors.cyan;
      case ComponentType.caseFan:
        return Colors.indigo;
      case ComponentType.pcCase:
        return Colors.grey;
      case ComponentType.monitor:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final allTypes = ComponentType.values;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200
            ? 4
            : constraints.maxWidth > 800
                ? 3
                : constraints.maxWidth > 600
                    ? 2
                    : 2;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            childAspectRatio: 1.1,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
          ),
          itemCount: allTypes.length,
          itemBuilder: (context, index) {
            final type = allTypes[index];
            final count = countsByType[type] ?? 0;
            final typeColor = _getTypeColor(type);
            
            return _CategoryCard(
              componentType: type,
              displayName: _getTypeDisplayName(type),
              icon: _getTypeIcon(type),
              color: typeColor,
              itemCount: count,
            );
          },
        );
      },
    );
  }
}

/// A card widget representing a single component category.
class _CategoryCard extends StatefulWidget {
  final ComponentType componentType;
  final String displayName;
  final IconData icon;
  final Color color;
  final int itemCount;

  const _CategoryCard({
    required this.componentType,
    required this.displayName,
    required this.icon,
    required this.color,
    required this.itemCount,
  });

  @override
  State<_CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<_CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.05 : 1.0),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: _isHovered
                  ? widget.color.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              context.go('/parts/${widget.componentType.name}');
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.color.withOpacity(0.1),
                    widget.color.withOpacity(0.05),
                    theme.colorScheme.surface,
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Icon
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: widget.color.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: 48,
                        color: widget.color,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Category name
                    Text(
                      widget.displayName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    // Item count
                    Text(
                      '${widget.itemCount} ${widget.itemCount == 1 ? 'item' : 'items'}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Arrow indicator
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: widget.color.withOpacity(0.7),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Component card widget
class _ComponentCard extends ConsumerStatefulWidget {
  final BaseComponent component;
  final Color typeColor;
  final ComponentType componentType;

  const _ComponentCard({
    required this.component,
    required this.typeColor,
    required this.componentType,
  });

  @override
  ConsumerState<_ComponentCard> createState() => _ComponentCardState();
}

class _ComponentCardState extends ConsumerState<_ComponentCard> {
  bool _isHovered = false;

  /// Normalizes image URL - handles relative URLs, GUIDs, and absolute URLs
  String _normalizeImageUrl(String imageUrl) {
    final trimmed = imageUrl.trim();
    
    // Empty URL
    if (trimmed.isEmpty) return '';
    
    // Already an absolute URL
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    
    // Relative URL starting with /
    if (trimmed.startsWith('/')) {
      return '$apiBaseUrl$trimmed';
    }
    
    // Check if it's a GUID (image ID) - GUIDs are 36 characters with hyphens
    final guidPattern = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    if (guidPattern.hasMatch(trimmed)) {
      return '$apiBaseUrl/Images/download/$trimmed';
    }
    
    // Otherwise, try as relative URL from API base
    return '$apiBaseUrl/$trimmed';
  }

  /// Builds the component image with proper error handling and validation
  Widget _buildComponentImage() {
    final theme = Theme.of(context);
    final rawImageUrl = widget.component.imageUrl.trim();
    
    // Validate image URL
    if (rawImageUrl.isEmpty) {
      return Icon(
        Icons.image_not_supported,
        size: 48,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      );
    }

    // Normalize the image URL
    final imageUrl = _normalizeImageUrl(rawImageUrl);
    
    if (imageUrl.isEmpty) {
      return Icon(
        Icons.image_not_supported,
        size: 48,
        color: theme.colorScheme.onSurface.withOpacity(0.3),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Image.network(
        imageUrl,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) {
          return child;
        }
        return Center(
          child: CircularProgressIndicator(
            value: loadingProgress.expectedTotalBytes != null
                ? loadingProgress.cumulativeBytesLoaded /
                    loadingProgress.expectedTotalBytes!
                : null,
            color: widget.typeColor,
            strokeWidth: 2,
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        if (kDebugMode) {
          print('Error loading image for ${widget.component.name}: $error');
          print('Original Image URL: ${widget.component.imageUrl}');
          print('Normalized Image URL: $imageUrl');
          print('Error details: $stackTrace');
        }
        return Icon(
          Icons.broken_image,
          size: 48,
          color: theme.colorScheme.onSurface.withOpacity(0.3),
        );
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) {
          return child;
        }
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: child,
        );
      },
      // Add headers to help with CORS if needed
      headers: const {
        'Accept': 'image/*',
      },
      ),
    );
  }

  /// Shows component details in a dialog
  void _showComponentDetails(BuildContext context, WidgetRef ref, BaseComponent component) {
    final theme = Theme.of(context);
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
              _buildInfoRow(theme, 'Manufacturer', component.manufacturer),
              _buildInfoRow(theme, 'Type', component.type.name.toUpperCase()),
              if (component.lowestPrice != null)
                _buildInfoRow(
                  theme,
                  'Price',
                  '\$${component.lowestPrice!.toStringAsFixed(2)}',
                  isHighlighted: true,
                ),
              if (component.release != null)
                _buildInfoRow(
                  theme,
                  'Release Date',
                  component.release!.toString().split(' ')[0],
                ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 16),
              
              // Component-specific details
              ..._buildComponentSpecificDetails(theme, component),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              // Add to build and navigate to build now page
              ref.read(buildProvider.notifier).addComponent(component);
              context.go('/build-now');
            },
            icon: const Icon(Icons.add),
            label: const Text('Add to Build'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(ThemeData theme, String label, String value, {bool isHighlighted = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade400,
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

  List<Widget> _buildComponentSpecificDetails(ThemeData theme, BaseComponent component) {
    switch (component.type) {
      case ComponentType.cpu:
        if (component is CPUComponent) {
          return [
            Text(
              'CPU Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Series', component.series),
            _buildInfoRow(theme, 'Socket', component.socketType),
            _buildInfoRow(theme, 'Microarchitecture', component.microarchitecture),
            _buildInfoRow(theme, 'Core Family', component.coreFamily),
            _buildInfoRow(theme, 'Total Cores', '${component.coreTotal}'),
            if (component.performanceAmount != null)
              _buildInfoRow(theme, 'P-Cores', '${component.performanceAmount}'),
            if (component.efficiencyAmount != null)
              _buildInfoRow(theme, 'E-Cores', '${component.efficiencyAmount}'),
            _buildInfoRow(theme, 'Threads', '${component.threadsAmount}'),
            if (component.basePerformanceSpeed != null)
              _buildInfoRow(theme, 'Base Clock (P-Core)', '${component.basePerformanceSpeed} GHz'),
            if (component.boostPerformanceSpeed != null)
              _buildInfoRow(theme, 'Boost Clock (P-Core)', '${component.boostPerformanceSpeed} GHz'),
            if (component.baseEfficiencySpeed != null)
              _buildInfoRow(theme, 'Base Clock (E-Core)', '${component.baseEfficiencySpeed} GHz'),
            if (component.boostEfficiencySpeed != null)
              _buildInfoRow(theme, 'Boost Clock (E-Core)', '${component.boostEfficiencySpeed} GHz'),
            if (component.l1 != null) _buildInfoRow(theme, 'L1 Cache', '${component.l1} MB'),
            if (component.l2 != null) _buildInfoRow(theme, 'L2 Cache', '${component.l2} MB'),
            if (component.l3 != null) _buildInfoRow(theme, 'L3 Cache', '${component.l3} MB'),
            if (component.l4 != null) _buildInfoRow(theme, 'L4 Cache', '${component.l4} MB'),
            _buildInfoRow(theme, 'TDP', '${component.thermalDesignPower}W'),
            _buildInfoRow(theme, 'Lithography', component.lithography),
            _buildInfoRow(theme, 'Memory Type', component.memoryType),
            _buildInfoRow(theme, 'Packaging', component.packagingType),
            _buildInfoRow(theme, 'Includes Cooler', component.includesCooler ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'SMT Support', component.supportsSimultaneousMultithreading ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'ECC Support', component.supportsECC ? 'Yes' : 'No'),
            if (component.graphics.isNotEmpty && component.graphics != 'N/A')
              _buildInfoRow(theme, 'Integrated Graphics', component.graphics),
          ];
        }
        break;
      case ComponentType.gpu:
        if (component is GPUComponent) {
          return [
            Text(
              'GPU Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Chipset', component.chipset),
            _buildInfoRow(theme, 'VRAM', '${component.videoMemoryAmount.toStringAsFixed(0)} GB'),
            _buildInfoRow(theme, 'Memory Type', component.videoMemoryType),
            _buildInfoRow(theme, 'Base Clock', '${component.coreBaseClockSpeed.toStringAsFixed(0)} MHz'),
            _buildInfoRow(theme, 'Boost Clock', '${component.coreBoostClockSpeed.toStringAsFixed(0)} MHz'),
            _buildInfoRow(theme, 'Core Count', '${component.coreCount}'),
            _buildInfoRow(theme, 'Memory Clock', '${component.effectiveMemoryClockSpeed.toStringAsFixed(0)} MHz'),
            _buildInfoRow(theme, 'Memory Bus Width', '${component.memoryBusWidth} bit'),
            _buildInfoRow(theme, 'TDP', '${component.thermalDesignPower}W'),
            _buildInfoRow(theme, 'Length', '${component.length.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Slot Width', '${component.caseExpansionSlotWidth} slots'),
            _buildInfoRow(theme, 'Total Slots', '${component.totalSlotAmount}'),
            _buildInfoRow(theme, 'Cooling Type', component.coolingType),
            _buildInfoRow(theme, 'Frame Sync', component.frameSync),
          ];
        }
        break;
      case ComponentType.motherboard:
        if (component is MotherboardComponent) {
          return [
            Text(
              'Motherboard Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Socket', component.socketType),
            _buildInfoRow(theme, 'Chipset', component.chipsetType),
            _buildInfoRow(theme, 'Form Factor', component.formFactor),
            _buildInfoRow(theme, 'RAM Type', component.ramType),
            _buildInfoRow(theme, 'RAM Slots', '${component.ramSlotsAmount}'),
            _buildInfoRow(theme, 'Max RAM', '${component.maxRAMAmount} GB'),
            _buildInfoRow(theme, 'SATA 6 Gb/s', '${component.sata6GBsAmount}'),
            _buildInfoRow(theme, 'SATA 3 Gb/s', '${component.sata3GBsAmount}'),
            _buildInfoRow(theme, 'U.2 Ports', '${component.u2PortAmount}'),
            _buildInfoRow(theme, 'Wi-Fi', component.wirelessNetworkingStandard),
            if (component.cpuFanHeaderAmount != null)
              _buildInfoRow(theme, 'CPU Fan Headers', '${component.cpuFanHeaderAmount}'),
            if (component.caseFanHeaderAmount != null)
              _buildInfoRow(theme, 'Case Fan Headers', '${component.caseFanHeaderAmount}'),
            if (component.pumpHeaderAmount != null)
              _buildInfoRow(theme, 'Pump Headers', '${component.pumpHeaderAmount}'),
            if (component.argb5vHeaderAmount != null)
              _buildInfoRow(theme, 'ARGB 5V Headers', '${component.argb5vHeaderAmount}'),
            if (component.rgb12vHeaderAmount != null)
              _buildInfoRow(theme, 'RGB 12V Headers', '${component.rgb12vHeaderAmount}'),
            _buildInfoRow(theme, 'Audio Chipset', component.audioChipset),
            _buildInfoRow(theme, 'Max Audio Channels', '${component.maxAudioChannels}'),
            _buildInfoRow(theme, 'ECC Support', component.hasECCSupport ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'RAID Support', component.hasRAIDSupport ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'BIOS Flashback', component.hasFlashback ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'Clear CMOS', component.hasCMOS ? 'Yes' : 'No'),
          ];
        }
        break;
      case ComponentType.ram:
        if (component is MemoryComponent) {
          return [
            Text(
              'RAM Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Type', component.ramType),
            _buildInfoRow(theme, 'Form Factor', component.formFactor),
            _buildInfoRow(theme, 'Capacity', '${component.capacity.toStringAsFixed(0)} GB'),
            _buildInfoRow(theme, 'Speed', '${component.speed.toStringAsFixed(0)} MHz'),
            _buildInfoRow(theme, 'CAS Latency', '${component.casLatency}'),
            if (component.timings != null)
              _buildInfoRow(theme, 'Timings', component.timings!),
            _buildInfoRow(theme, 'Modules', '${component.moduleQuantity}'),
            _buildInfoRow(theme, 'Module Capacity', '${component.moduleCapacity.toStringAsFixed(0)} GB'),
            _buildInfoRow(theme, 'ECC', component.ecc),
            _buildInfoRow(theme, 'Registered', component.registeredType),
            _buildInfoRow(theme, 'Heat Spreader', component.haveHeatSpreader ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'RGB', component.haveRGB ? 'Yes' : 'No'),
            _buildInfoRow(theme, 'Height', '${component.height.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Voltage', '${component.voltage}V'),
          ];
        }
        break;
      case ComponentType.storage:
        if (component is StorageComponent) {
          return [
            Text(
              'Storage Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Series', component.series),
            _buildInfoRow(theme, 'Type', component.driveType),
            _buildInfoRow(theme, 'Form Factor', component.formFactor),
            _buildInfoRow(theme, 'Capacity', '${component.capacity.toStringAsFixed(0)} GB'),
            _buildInfoRow(theme, 'Interface', component.interface),
            _buildInfoRow(theme, 'NVMe', component.hasNVMe ? 'Yes' : 'No'),
          ];
        }
        break;
      case ComponentType.psu:
        if (component is PowerSupplyComponent) {
          return [
            Text(
              'Power Supply Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Wattage', '${component.powerOutput.toStringAsFixed(0)}W'),
            _buildInfoRow(theme, 'Form Factor', component.formFactor),
            if (component.efficiencyRating != null)
              _buildInfoRow(theme, 'Efficiency', component.efficiencyRating!),
            _buildInfoRow(theme, 'Modularity', component.modularityType),
            _buildInfoRow(theme, 'Length', '${component.length.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Fanless', component.isFanless ? 'Yes' : 'No'),
          ];
        }
        break;
      case ComponentType.cooler:
        if (component is CoolerComponent) {
          return [
            Text(
              'Cooler Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Type', component.isWaterCooled ? 'Water Cooled' : 'Air Cooled'),
            _buildInfoRow(theme, 'Height', '${component.height.toStringAsFixed(0)} mm'),
            if (component.radiatorSize != null)
              _buildInfoRow(theme, 'Radiator Size', '${component.radiatorSize!.toStringAsFixed(0)} mm'),
            if (component.fanSize != null)
              _buildInfoRow(theme, 'Fan Size', '${component.fanSize!.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Fan Quantity', '${component.fanQuantity}'),
            if (component.minFanRotationSpeed != null)
              _buildInfoRow(theme, 'Min Fan Speed', '${component.minFanRotationSpeed!.toStringAsFixed(0)} RPM'),
            if (component.maxFanRotationSpeed != null)
              _buildInfoRow(theme, 'Max Fan Speed', '${component.maxFanRotationSpeed!.toStringAsFixed(0)} RPM'),
            if (component.minNoiseLevel != null)
              _buildInfoRow(theme, 'Min Noise', '${component.minNoiseLevel!.toStringAsFixed(1)} dBA'),
            if (component.maxNoiseLevel != null)
              _buildInfoRow(theme, 'Max Noise', '${component.maxNoiseLevel!.toStringAsFixed(1)} dBA'),
            _buildInfoRow(theme, 'Fanless Operation', component.canOperateFanless ? 'Yes' : 'No'),
          ];
        }
        break;
      case ComponentType.caseFan:
        if (component is CaseFanComponent) {
          return [
            Text(
              'Case Fan Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Size', '${component.size.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Quantity', '${component.quantity}'),
            _buildInfoRow(theme, 'Min Airflow', '${component.minAirflow.toStringAsFixed(0)} CFM'),
            if (component.maxAirflow != null)
              _buildInfoRow(theme, 'Max Airflow', '${component.maxAirflow!.toStringAsFixed(0)} CFM'),
            _buildInfoRow(theme, 'Min Noise', '${component.minNoiseLevel.toStringAsFixed(1)} dBA'),
            if (component.maxNoiseLevel != null)
              _buildInfoRow(theme, 'Max Noise', '${component.maxNoiseLevel!.toStringAsFixed(1)} dBA'),
            _buildInfoRow(theme, 'PWM', component.pulseWidthModulation ? 'Yes' : 'No'),
            if (component.ledType != null)
              _buildInfoRow(theme, 'LED Type', component.ledType!),
            if (component.connectorType != null)
              _buildInfoRow(theme, 'Connector', component.connectorType!),
            _buildInfoRow(theme, 'Controller', component.controllerType),
            _buildInfoRow(theme, 'Static Pressure', '${component.staticPressureAmount.toStringAsFixed(2)} mmH2O'),
            _buildInfoRow(theme, 'Flow Direction', component.flowDirection),
          ];
        }
        break;
      case ComponentType.pcCase:
        if (component is CaseComponent) {
          return [
            Text(
              'Case Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Form Factor', component.formFactor),
            _buildInfoRow(theme, 'Max GPU Length', '${component.maxVideoCardLength.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Max Cooler Height', '${component.maxCPUCoolerHeight} mm'),
            _buildInfoRow(theme, 'PSU Shrouded', component.powerSupplyShrouded ? 'Yes' : 'No'),
            if (component.powerSupplyAmount != null)
              _buildInfoRow(theme, 'PSU Included', '${component.powerSupplyAmount!.toStringAsFixed(0)}W'),
            _buildInfoRow(theme, 'Transparent Side Panel', component.hasTransparentSidePanel ? 'Yes' : 'No'),
            if (component.sidePanelType != null)
              _buildInfoRow(theme, 'Side Panel Type', component.sidePanelType!),
            _buildInfoRow(theme, '3.5" Internal Bays', '${component.internal35BayAmount}'),
            _buildInfoRow(theme, '2.5" Internal Bays', '${component.internal25BayAmount}'),
            _buildInfoRow(theme, '3.5" External Bays', '${component.external35BayAmount}'),
            _buildInfoRow(theme, '5.25" External Bays', '${component.external525BayAmount}'),
            _buildInfoRow(theme, 'Expansion Slots', '${component.expansionSlotAmount}'),
            _buildInfoRow(theme, 'Width', '${component.width.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Height', '${component.height.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Depth', '${component.depth.toStringAsFixed(0)} mm'),
            _buildInfoRow(theme, 'Volume', '${component.volume.toStringAsFixed(1)} L'),
            _buildInfoRow(theme, 'Weight', '${component.weight.toStringAsFixed(1)} kg'),
            _buildInfoRow(theme, 'Rear Connector Support', component.supportsRearConnectingMotherboard ? 'Yes' : 'No'),
          ];
        }
        break;
      case ComponentType.monitor:
        if (component is MonitorComponent) {
          return [
            Text(
              'Monitor Specifications',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(theme, 'Screen Size', '${component.screenSize.toStringAsFixed(1)}"'),
            _buildInfoRow(theme, 'Resolution', '${component.horizontalResolution}x${component.verticalResolution}'),
            _buildInfoRow(theme, 'Refresh Rate', '${component.maxRefreshRate.toStringAsFixed(0)} Hz'),
            _buildInfoRow(theme, 'Panel Type', component.panelType),
            _buildInfoRow(theme, 'Response Time', '${component.responseTime.toStringAsFixed(1)} ms'),
            _buildInfoRow(theme, 'Viewing Angle', component.viewingAngle),
            _buildInfoRow(theme, 'Aspect Ratio', component.aspectRatio),
            if (component.maxBrightness != null)
              _buildInfoRow(theme, 'Max Brightness', '${component.maxBrightness!.toStringAsFixed(0)} nits'),
            if (component.highDynamicRangeType != null)
              _buildInfoRow(theme, 'HDR', component.highDynamicRangeType!),
            _buildInfoRow(theme, 'Adaptive Sync', component.adaptiveSyncType),
          ];
        }
        break;
    }
    return [];
  }

  /// Builds the compatibility badge if component is compatible with current build
  /// Disabled to prevent excessive API calls - can be re-enabled with batch optimization
  Widget _buildCompatibilityBadge() {
    // Temporarily disabled to prevent rate limiting issues
    // Each component card was making separate API calls causing 429 errors
    // TODO: Implement batch compatibility check for all visible components
    return const SizedBox.shrink();
    
    // Original implementation (disabled):
    // final build = ref.watch(buildProvider);
    // final selectedIds = build
    //     .where((pc) => pc.selectedProduct != null)
    //     .map((pc) => pc.selectedProduct!.id)
    //     .toList();
    //
    // // Don't show badge if no components are selected
    // if (selectedIds.isEmpty) return const SizedBox.shrink();
    //
    // // Check compatibility
    // final compatibilityAsync = ref.watch(
    //   componentCompatibilityCheckProvider(
    //     (componentId: widget.component.id, selectedIds: selectedIds),
    //   ),
    // );
    //
    // return compatibilityAsync.when(
    //   data: (isCompatible) {
    //     if (!isCompatible) return const SizedBox.shrink();
    //
    //     return Container(
    //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    //       decoration: BoxDecoration(
    //         color: Colors.green.withOpacity(0.9),
    //         borderRadius: BorderRadius.circular(12),
    //         boxShadow: [
    //           BoxShadow(
    //             color: Colors.black.withOpacity(0.2),
    //             blurRadius: 4,
    //             offset: const Offset(0, 2),
    //           ),
    //         ],
    //       ),
    //       child: Row(
    //         mainAxisSize: MainAxisSize.min,
    //         children: [
    //           const Icon(
    //             Icons.check_circle,
    //             size: 14,
    //             color: Colors.white,
    //           ),
    //           const SizedBox(width: 4),
    //           Text(
    //             'Compatible',
    //             style: const TextStyle(
    //               color: Colors.white,
    //               fontSize: 11,
    //               fontWeight: FontWeight.bold,
    //             ),
    //           ),
    //         ],
    //       ),
    //     );
    //   },
    //   loading: () => Container(
    //     padding: const EdgeInsets.all(6),
    //     decoration: BoxDecoration(
    //       color: Colors.grey.withOpacity(0.7),
    //       borderRadius: BorderRadius.circular(12),
    //     ),
    //     child: const SizedBox(
    //       width: 12,
    //       height: 12,
    //       child: CircularProgressIndicator(
    //         strokeWidth: 2,
    //         valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
    //       ),
    //     ),
    //   ),
    //   error: (_, __) => const SizedBox.shrink(),
    // );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lowestPrice = widget.component.lowestPrice;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        transform: Matrix4.identity()..scale(_isHovered ? 1.02 : 1.0),
        child: Card(
          elevation: _isHovered ? 8 : 2,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: _isHovered
                  ? widget.typeColor.withOpacity(0.5)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: InkWell(
            onTap: () {
              // Show component details dialog
              _showComponentDetails(context, ref, widget.component);
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image section
                Expanded(
                  flex: 3,
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          widget.typeColor.withOpacity(0.1),
                          theme.colorScheme.surfaceVariant.withOpacity(0.1),
                        ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: _buildComponentImage(),
                        ),
                        if (_isHovered)
                          Container(
                            color: widget.typeColor.withOpacity(0.1),
                          ),
                        // Compatibility badge
                        Positioned(
                          top: 8,
                          right: 8,
                          child: _buildCompatibilityBadge(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Content section
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.component.manufacturer,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: widget.typeColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.component.name,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        if (lowestPrice != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: widget.typeColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '\$${lowestPrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: widget.typeColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          Text(
                            'Price N/A',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
