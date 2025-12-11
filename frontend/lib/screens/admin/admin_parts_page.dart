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
  final int _pageSize = 20; // Show 20 components per page
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: Column(
        children: [
          _buildHeader(isDark, isMobile),
          Expanded(
            child: _buildContent(isDark, isMobile),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
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
          isMobile
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Parts Management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Part'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isDark
                              ? AppColorsDark.buttonGreen
                              : AppColorsLight.buttonGreen,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
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
          SizedBox(height: isMobile ? 16 : 24),
          isMobile
              ? Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search parts...',
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
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _currentPage = 1;
                          _cachedQueryParams = null;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColorsDark.backgroundTertiary
                              : AppColorsLight.backgroundSecondary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
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
                              _cachedQueryParams = null;
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
                    ),
                  ],
                )
              : Row(
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
                            _cachedQueryParams = null;
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
                            _cachedQueryParams = null;
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
    final newParams = {
      'query': _searchController.text.isEmpty ? null : _searchController.text,
      'componentTypes': _selectedCategory == 'All' 
          ? null 
          : [_selectedCategory],
      'page': _currentPage,
      'pageLength': _pageSize,
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

  Widget _buildContent(bool isDark, bool isMobile) {
    final queryParams = _buildQueryParams();
    final componentsAsync = ref.watch(adminComponentsProvider(queryParams));

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(isMobile ? 8 : 24),
          child: componentsAsync.when(
            data: (components) => _buildStatsRow(isDark, components, isMobile),
            loading: () => _buildStatsRow(isDark, [], isMobile),
            error: (error, stack) => _buildStatsRow(isDark, [], isMobile),
          ),
        ),
        Expanded(
          child: Container(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColorsDark.backgroundSecondary
                    : AppColorsLight.backgroundTertiary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  if (!isMobile) _buildTableHeader(isDark),
                  Expanded(
                    child: componentsAsync.when(
                      data: (components) {
                        print('AdminPartsPage: Received ${components.length} components from backend');
                        
                        if (components.isEmpty) {
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
                        return Column(
                          children: [
                            Expanded(
                              child: ListView.separated(
                                itemCount: components.length,
                                separatorBuilder: (context, index) => const SizedBox(height: 0),
                                itemBuilder: (context, index) {
                                  final component = components[index];
                                  if (index < 5) {
                                    print('AdminPartsPage: Building row $index for component ${component.name ?? component.id}');
                                  }
                                  return _buildPartRow(component, isDark, isMobile);
                                },
                              ),
                            ),
                            _buildPagination(isDark, componentsAsync),
                          ],
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
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow(bool isDark, List<AdminComponent> allComponents, bool isMobile) {
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

    if (isMobile) {
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 2.2,
        ),
        itemCount: stats.length,
        itemBuilder: (context, index) {
          final stat = stats[index];
          return Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColorsDark.backgroundSecondary
                  : AppColorsLight.backgroundTertiary,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    stat['icon'] as IconData,
                    color: stat['color'] as Color,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        stat['value'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        stat['label'] as String,
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    }

    return Row(
      children: stats.asMap().entries.map((entry) {
        final index = entry.key;
        final stat = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index < stats.length - 1 ? 16 : 0),
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

  Widget _buildPartCard(AdminComponent component, bool isDark) {
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark
          ? AppColorsDark.backgroundSecondary
          : AppColorsLight.backgroundTertiary,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
                          fontSize: 16,
                          color: isDark
                              ? AppColorsDark.textWhite
                              : AppColorsLight.textBlack,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          getTypeDisplayName(component.componentType),
                          style: const TextStyle(
                            color: AppColorsDark.buttonBlue,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.business,
                  size: 16,
                  color: isDark
                      ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                      : AppColorsLight.textBlack.withValues(alpha: 0.6),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Manufacturer: ${component.manufacturer ?? 'Unknown'}',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (component.release != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                        : AppColorsLight.textBlack.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Release: ${_formatDate(component.release!)}',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            if (component.numberOfParts != null && component.numberOfParts! > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.inventory_2,
                    size: 16,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.6)
                        : AppColorsLight.textBlack.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Parts: ${component.numberOfParts}',
                    style: TextStyle(
                      color: isDark
                          ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                          : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.visibility, size: 20),
                  onPressed: () {
                    // Navigate to component detail page if exists
                  },
                  tooltip: 'View',
                ),
                IconButton(
                  icon: const Icon(Icons.edit, size: 20),
                  onPressed: () {
                    // Navigate to component edit page if exists
                  },
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 20),
                  onPressed: () {
                    _showDeleteConfirmation(context, component, isDark);
                  },
                  tooltip: 'Delete',
                  color: AppColorsDark.error,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPartRow(AdminComponent component, bool isDark, bool isMobile) {
    if (isMobile) {
      return _buildPartCard(component, isDark);
    }
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
                      // Navigate to parts page for the component type with component ID to view details
                      final componentType = component.componentType.toLowerCase();
                      context.go('/parts/$componentType?componentId=${component.id}');
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return componentsAsync.when(
      data: (components) {
        final currentPageComponents = components.length;
        final start = currentPageComponents > 0 ? ((_currentPage - 1) * _pageSize) + 1 : 0;
        final end = currentPageComponents > 0 ? start + currentPageComponents - 1 : 0;
        
        // If we got a full page, there might be more pages
        // If we got less than pageSize, we're on the last page
        final hasMore = currentPageComponents == _pageSize;
        
        return Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
          ),
          child: isMobile
              ? Column(
                  children: [
                    Text(
                      currentPageComponents > 0
                          ? 'Showing $start-$end components (Page $_currentPage${hasMore ? '+' : ''})'
                          : 'No components',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                            : AppColorsLight.textBlack.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                    _cachedQueryParams = null;
                                  });
                                }
                              : null,
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'Page $_currentPage',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark
                                  ? AppColorsDark.textWhite
                                  : AppColorsLight.textBlack,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: hasMore || currentPageComponents == _pageSize
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                    _cachedQueryParams = null;
                                  });
                                }
                              : null,
                        ),
                      ],
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        currentPageComponents > 0
                            ? 'Showing $start-$end components (Page $_currentPage${hasMore ? '+' : ''})'
                            : 'No components',
                        style: TextStyle(
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: _currentPage > 1
                              ? () {
                                  setState(() {
                                    _currentPage--;
                                    _cachedQueryParams = null;
                                  });
                                }
                              : null,
                        ),
                        Text(
                          'Page $_currentPage',
                          style: TextStyle(
                            color: isDark
                                ? AppColorsDark.textWhite
                                : AppColorsLight.textBlack,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: hasMore || currentPageComponents == _pageSize
                              ? () {
                                  setState(() {
                                    _currentPage++;
                                    _cachedQueryParams = null;
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
    final _nameController = TextEditingController(text: component.name ?? '');
    final _manufacturerController = TextEditingController(text: component.manufacturer ?? '');
    final _noteController = TextEditingController(text: component.note ?? '');
    bool _isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            'Edit Component',
            style: TextStyle(
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Component ID: ${component.id.substring(0, 8)}...',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Type: ${component.componentType}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColorsDark.backgroundTertiary
                        : AppColorsLight.backgroundSecondary,
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _manufacturerController,
                  decoration: InputDecoration(
                    labelText: 'Manufacturer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColorsDark.backgroundTertiary
                        : AppColorsLight.backgroundSecondary,
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? AppColorsDark.backgroundTertiary
                        : AppColorsLight.backgroundSecondary,
                  ),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          backgroundColor: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          actions: [
            TextButton(
              onPressed: _isSaving ? null : () {
                _nameController.dispose();
                _manufacturerController.dispose();
                _noteController.dispose();
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: _isSaving ? null : () async {
                setDialogState(() => _isSaving = true);
                try {
                  final updateData = <String, dynamic>{};
                  if (_nameController.text.trim().isNotEmpty) {
                    updateData['Name'] = _nameController.text.trim();
                  }
                  if (_manufacturerController.text.trim().isNotEmpty) {
                    updateData['Manufacturer'] = _manufacturerController.text.trim();
                  }
                  if (_noteController.text.trim().isNotEmpty) {
                    updateData['Note'] = _noteController.text.trim();
                  } else {
                    updateData['Note'] = null;
                  }

                  final adminService = ref.read(adminServiceProvider);
                  await adminService.updateComponent(
                    component.id, 
                    updateData,
                    componentType: component.componentType,
                  );
                  
                  if (mounted) {
                    // Invalidate the components provider to refresh the list
                    ref.invalidate(adminComponentsProvider(_cachedQueryParams ?? {}));
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Component updated successfully'),
                        backgroundColor: AppColorsDark.buttonGreen,
                      ),
                    );
                  }
                } catch (e) {
                  setDialogState(() => _isSaving = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(getUserFriendlyError(e)),
                        backgroundColor: AppColorsDark.error,
                      ),
                    );
                  }
                } finally {
                  _nameController.dispose();
                  _manufacturerController.dispose();
                  _noteController.dispose();
                }
              },
              child: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }


  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
