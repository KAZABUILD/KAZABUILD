/// Admin Parts Management Page
/// 
/// Provides component/part management interface with categorization and actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';
import '../../utils/error_utils.dart';

class AdminPartsPage extends ConsumerStatefulWidget {
  const AdminPartsPage({super.key});

  @override
  ConsumerState<AdminPartsPage> createState() => _AdminPartsPageState();
}

class _AdminPartsPageState extends ConsumerState<AdminPartsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'CPU', 'GPU', 'MEMORY', 'MOTHERBOARD', 'STORAGE', 'POWER_SUPPLY', 'CASE', 'COOLER', 'CASE_FAN', 'MONITOR'];
  int _currentPage = 1;
  final int _pageSize = 12;
  String? _orderBy;
  String _sortDirection = 'desc';
  
  // Cache query params to prevent Map recreation on every build
  Map<String, dynamic>? _cachedQueryParams;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark),
          Expanded(
            child: _buildContent(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Parts Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.add),
                label: const Text('Add Part'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? AppColorsDark.buttonGreen
                      : AppColorsLight.buttonGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search parts by name, brand, or model...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: isDark
                        ? AppColorsDark.backgroundTertiary
                        : AppColorsLight.backgroundSecondary,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _currentPage = 1;
                      _cachedQueryParams = null; // Invalidate cache
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColorsDark.backgroundTertiary
                      : AppColorsLight.backgroundSecondary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value!;
                      _currentPage = 1;
                      _cachedQueryParams = null; // Invalidate cache
                    });
                  },
                  underline: Container(),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _buildQueryParams() {
    // Don't send pagination params to backend - get all components and paginate on client side
    final newParams = {
      'query': _searchController.text.isEmpty ? null : _searchController.text,
      'componentTypes': _selectedCategory == 'All' 
          ? null 
          : [_selectedCategory],
      'page': null, // Don't paginate on backend
      'pageLength': null, // Get all components
      'orderBy': _orderBy ?? 'DatabaseEntryAt',
      'sortDirection': _sortDirection,
    };
    
    // Check if params actually changed to prevent unnecessary rebuilds
    if (_cachedQueryParams != null) {
      bool changed = false;
      for (var key in newParams.keys) {
        if (_cachedQueryParams![key] != newParams[key]) {
          changed = true;
          break;
        }
      }
      // Compare lists if componentTypes changed
      if (!changed && newParams['componentTypes'] != null && _cachedQueryParams!['componentTypes'] != null) {
        final newTypes = newParams['componentTypes'] as List<String>?;
        final oldTypes = _cachedQueryParams!['componentTypes'] as List<String>?;
        if (newTypes?.length != oldTypes?.length ||
            (newTypes != null && oldTypes != null && 
             !newTypes.every((t) => oldTypes.contains(t)))) {
          changed = true;
        }
      }
      if (!changed) {
        return _cachedQueryParams!;
      }
    }
    
    _cachedQueryParams = newParams;
    return _cachedQueryParams!;
  }

  Widget _buildContent(bool isDark) {
    final queryParams = _buildQueryParams();
    final componentsAsync = ref.watch(adminComponentsProvider(queryParams));

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          componentsAsync.when(
            data: (components) => _buildStatsRow(isDark, components),
            loading: () => _buildStatsRow(isDark, []),
            error: (error, stack) => _buildStatsRow(isDark, []),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.backgroundSecondary
                    : AppColorsLight.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildTableHeader(isDark),
                  Expanded(
                    child: componentsAsync.when(
                      data: (allComponents) {
                        print('AdminPartsPage: Received ${allComponents.length} total components');
                        
                        // Client-side pagination
                        final startIndex = (_currentPage - 1) * _pageSize;
                        final endIndex = startIndex + _pageSize;
                        final components = allComponents.length > startIndex
                            ? allComponents.sublist(
                                startIndex,
                                endIndex > allComponents.length ? allComponents.length : endIndex,
                              )
                            : <AdminComponent>[];
                        
                        print('AdminPartsPage: Showing ${components.length} components (page $_currentPage, ${allComponents.length} total)');
                        
                        if (allComponents.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.memory_outlined,
                                  size: 64,
                                  color: isDark
                                      ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                                      : AppColorsLight.textBlack.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No components found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: isDark
                                        ? AppColorsDark.textWhite
                                        : AppColorsLight.textBlack,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        print('AdminPartsPage: Rendering ${components.length} components in ListView');
                        return ListView.separated(
                          itemCount: components.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 0),
                          itemBuilder: (context, index) {
                            final component = components[index];
                            if (index < 5) {
                              print('AdminPartsPage: Building row $index for component ${component.name ?? component.id}');
                            }
                            return _buildPartRow(component, isDark);
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (error, stack) => Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: AppColorsDark.error),
                            const SizedBox(height: 16),
                            Text(
                              'Unable to load components. Please try again.',
                              style: TextStyle(
                                color: isDark
                                    ? AppColorsDark.textWhite
                                    : AppColorsLight.textBlack,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(adminComponentsProvider(queryParams)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  _buildPagination(isDark, componentsAsync),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark, List<AdminComponent> allComponents) {
    // Calculate stats from all components (not just current page)
    final totalComponents = allComponents.length;
    final uniqueTypes = allComponents.map((c) => c.componentType).toSet().length;
    final withRelease = allComponents.where((c) => c.release != null).length;
    final totalPages = (totalComponents / _pageSize).ceil();
    
    // Show total stats
    final stats = [
      {'label': 'Total Components', 'value': totalComponents.toString(), 'icon': Icons.memory, 'color': AppColorsDark.buttonBlue},
      {'label': 'Types', 'value': uniqueTypes.toString(), 'icon': Icons.category, 'color': AppColorsDark.buttonPurple},
      {'label': 'With Release Date', 'value': withRelease.toString(), 'icon': Icons.calendar_today, 'color': AppColorsDark.buttonGreen},
      {'label': 'Page $_currentPage / $totalPages', 'value': '', 'icon': Icons.pages, 'color': AppColorsDark.warning},
    ];

    return Row(
      children: stats.map((stat) {
        return Expanded(
          child: Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundSecondary
                  : AppColorsLight.backgroundTertiary,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                      ),
                      Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
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
    );
  }

  Widget _buildTableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell('Part Name', isDark)),
          Expanded(flex: 2, child: _buildHeaderCell('Manufacturer', isDark)),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Type', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Release', isDark),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: _buildHeaderCell('Actions', isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, bool isDark) {
    return Text(
      text,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: isDark
            ? AppColorsDark.textWhite
            : AppColorsLight.textBlack,
      ),
    );
  }

  Widget _buildPartRow(AdminComponent component, bool isDark) {
    // Map component type to display name
    String getTypeDisplayName(String type) {
      final typeMap = {
        'CASE_FAN': 'Case Fan',
        'GPU': 'GPU',
        'CPU': 'CPU',
        'MEMORY': 'Memory',
        'MOTHERBOARD': 'Motherboard',
        'STORAGE': 'Storage',
        'MONITOR': 'Monitor',
        'COOLER': 'Cooler',
        'POWER_SUPPLY': 'PSU',
        'CASE': 'Case',
      };
      return typeMap[type.toUpperCase()] ?? type;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColorsDark.buttonPurple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.memory),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        component.name ?? 'Unnamed Component',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (component.numberOfParts != null && component.numberOfParts! > 0)
                        Text(
                          '${component.numberOfParts} parts',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                                : AppColorsLight.textBlack.withValues(alpha: 0.6),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              component.manufacturer ?? 'Unknown',
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                constraints: const BoxConstraints(
                  maxWidth: 120,
                  minWidth: 80,
                ),
                child: Text(
                  getTypeDisplayName(component.componentType),
                  style: TextStyle(
                    color: AppColorsDark.buttonBlue,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                component.release != null ? _formatDate(component.release!) : 'N/A',
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, size: 18),
                    onPressed: () {
                      // Navigate to parts page for the component type to view details
                      final componentType = component.componentType.toLowerCase();
                      context.go('/parts/$componentType');
                    },
                    tooltip: 'View',
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18),
                    onPressed: () {
                      // Show edit dialog for component
                      _showEditComponentDialog(context, component, isDark);
                    },
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18),
                    onPressed: () {
                      _showDeleteConfirmation(context, component, isDark);
                    },
                    tooltip: 'Delete',
                    color: AppColorsDark.error,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPagination(bool isDark, AsyncValue<List<AdminComponent>> componentsAsync) {
    return componentsAsync.when(
      data: (allComponents) {
        final totalComponents = allComponents.length;
        final totalPages = totalComponents > 0 ? (totalComponents / _pageSize).ceil() : 1;
        
        // Client-side pagination için hesaplama
        final startIndex = (_currentPage - 1) * _pageSize;
        final endIndex = startIndex + _pageSize;
        final currentPageItems = allComponents.length > startIndex
            ? allComponents.sublist(
                startIndex,
                endIndex > allComponents.length ? allComponents.length : endIndex,
              )
            : <AdminComponent>[];
        
        final start = totalComponents > 0 && currentPageItems.isNotEmpty 
            ? startIndex + 1 
            : 0;
        final end = totalComponents > 0 && currentPageItems.isNotEmpty
            ? startIndex + currentPageItems.length
            : 0;
        
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                totalComponents > 0
                    ? 'Showing $start-$end of $totalComponents components (Page $_currentPage / $totalPages)'
                    : 'No components',
                style: TextStyle(
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                      : AppColorsLight.textBlack.withValues(alpha: 0.7),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _currentPage > 1
                        ? () {
                            setState(() {
                              _currentPage--;
                              _cachedQueryParams = null; // Invalidate cache
                            });
                          }
                        : null,
                  ),
                  Text(
                    'Page $_currentPage / $totalPages',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    // Client-side pagination: currentPage < totalPages kontrolü yeterli
                    onPressed: _currentPage < totalPages
                        ? () {
                            setState(() {
                              _currentPage++;
                              _cachedQueryParams = null; // Invalidate cache
                            });
                          }
                        : null,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
    );
  }

  void _showDeleteConfirmation(BuildContext context, AdminComponent component, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Component'),
        content: Text('Are you sure you want to delete "${component.name ?? "Unnamed Component"}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final adminService = ref.read(adminServiceProvider);
                await adminService.deleteComponent(component.id);
                
                if (mounted) {
                  // Invalidate the components provider to refresh the list
                  ref.invalidate(adminComponentsProvider(_cachedQueryParams ?? {}));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Component deleted successfully'),
                      backgroundColor: AppColorsDark.buttonGreen,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(getUserFriendlyError(e)),
                      backgroundColor: AppColorsDark.error,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColorsDark.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditComponentDialog(BuildContext context, AdminComponent component, bool isDark) {
    // For now, show a message that component editing is not yet implemented
    // In the future, this could open a dialog to edit component properties
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Component editing is not yet available. Use the parts page to view component details.'),
        backgroundColor: AppColorsDark.buttonBlue,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
