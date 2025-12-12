/// This file defines the UI for the part picker screen, a core feature of the PC builder.
///

/// It allows users to browse, search, and filter a list of PC components
/// of a specific type (e.g., CPU, GPU). The page is structured with a filter panel
/// on the left and a product list on the right for desktop views.
///
/// Key features include:
/// - Dynamic filter generation based on the `ComponentType`.
/// - Real-time filtering based on search text, price range, and component-specific attributes.
/// - A summary of the user's current build.
/// - A responsive layout that should be adapted for mobile screens.
/// - When a user selects a part, it is returned to the `BuildNowPage`.

library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/filter_models.dart';
import 'package:frontend/models/filter_provider.dart';
import 'package:frontend/models/component_compatibility_provider.dart'
    as compatibility;
import 'package:frontend/models/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:frontend/utils/error_utils.dart';

part 'Parts_filter.dart';

/// The main page for selecting a specific type of PC component.
///
/// This page is navigated to from the `BuildNowPage` when a user wants to
/// add or change a part in their build.
class PartPickerPage extends ConsumerStatefulWidget {
  /// The type of component to display and filter (e.g., CPU, Motherboard).
  final ComponentType componentType;

  /// The user's current build, used for compatibility checks and summary display.
  /// If null, will be fetched from buildProvider.
  final List<PcComponent>? currentBuild;

  /// Optional callback when a component is selected.
  /// If provided, component will be returned via callback instead of adding to buildProvider.
  final Function(BaseComponent)? onComponentSelected;
  final int initialPage;
  
  /// Optional component ID to show details for when page loads.
  /// If provided, the component details dialog will be shown automatically.
  final String? componentId;

  const PartPickerPage({
    super.key,
    required this.componentType,
    this.currentBuild,
    this.onComponentSelected,
    this.initialPage = 1,
    this.componentId,
  });

  @override
  ConsumerState<PartPickerPage> createState() => _PartPickerPageState();
}

/// The state for the [PartPickerPage], now using Riverpod for data fetching.
///
/// Manages the list of all products, the filtered list of products,
/// and the state of all applied filters.
class _PartPickerPageState extends ConsumerState<PartPickerPage> {
  /// A key to manage the [Scaffold], particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Controller for the text-based search input.
  final _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _searchDebounce;
  late int _currentPage;
  static const int _maxComparisonItems = 4;
  final Map<String, BaseComponent> _comparisonComponents = {};

  // Filter state
  // Note: Most filter state is now managed by activeFiltersProvider.
  // We keep these local variables for backward compatibility during refactor
  // or if they are used by non-dynamic widgets, but eventually they should be removed.
  
  // Unused fields removed to clean up warnings
  // The state is now fully managed by the activeFiltersProvider and DynamicFilterPanel

  // Track if we've shown the component details dialog for the current componentId
  String? _shownComponentId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _currentPage = _sanitizePage(widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Clear previous filters on load to ensure clean state
      final notifier = ref.read(activeFiltersProvider(widget.componentType).notifier);
      notifier.clearAll();
      // Set default compatibility filter to true
      notifier.setFilter('Compatibility', true);
      _loadCurrentPage();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PartPickerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.componentType != oldWidget.componentType ||
        widget.initialPage != oldWidget.initialPage) {
      final nextPage = _sanitizePage(widget.initialPage);
      _currentPage = nextPage;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Clear filters when component type changes
        if (widget.componentType != oldWidget.componentType) {
          final notifier = ref.read(activeFiltersProvider(widget.componentType).notifier);
          notifier.clearAll();
          // Keep compatibility filter enabled by default on type change
          notifier.setFilter('Compatibility', true);
        }
        _loadCurrentPage(force: true, targetPage: nextPage);
      });
    }
    // If componentId changed, reset shown flag so new component details can be shown
    if (widget.componentId != oldWidget.componentId) {
      _shownComponentId = null;
    }
  }

  void _onSearchChanged() {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      setState(() {
        _currentPage = 1;
      });
      _loadCurrentPage(force: true, targetPage: 1);
      _updateUrl(1);
    });
  }

  int _sanitizePage(int page) => page < 1 ? 1 : page;

  Map<String, dynamic> _buildFilters() {
    final activeFilters =
        Map<String, dynamic>.from(ref.read(activeFiltersProvider(widget.componentType)));
    
    // Remove client-side only filters
    activeFilters.remove('Compatibility');

    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      activeFilters['Query'] = query;
    }
    return activeFilters;
  }

  void _loadCurrentPage({bool force = false, int? targetPage}) {
    final notifier = ref.read(
      componentPagingProvider(widget.componentType).notifier,
    );
    final desiredPage = targetPage ?? _currentPage;
    final filters = _buildFilters();
    
    if (force) {
      notifier.goToPage(desiredPage, filters: filters);
    } else {
      notifier.ensurePage(desiredPage, filters: filters);
    }
  }

  void _navigateToPage(int page) {
    final sanitized = _sanitizePage(page);
    if (sanitized == _currentPage && mounted) {
      _updateUrl(sanitized);
      _loadCurrentPage();
      return;
    }
    setState(() {
      _currentPage = sanitized;
    });
    // Scroll to top after the page update is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _scrollController.hasClients) {
        _scrollController.jumpTo(0);
      }
    });
    _loadCurrentPage(force: true, targetPage: sanitized);
    _updateUrl(sanitized);
  }

  void _toggleComparisonSelection(BaseComponent component, bool shouldSelect) {
    if (!mounted) return;
    setState(() {
      if (shouldSelect) {
        if (_comparisonComponents.length >= _maxComparisonItems &&
            !_comparisonComponents.containsKey(component.id)) {
          final l10n = AppLocalizations.of(context)!;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.maxComparisonLimit(_maxComparisonItems),
              ),
            ),
          );
          return;
        }
        _comparisonComponents[component.id] = component;
      } else {
        _comparisonComponents.remove(component.id);
      }
    });
  }

  void _clearComparisonSelection() {
    if (!mounted) return;
    setState(() {
      _comparisonComponents.clear();
    });
  }

  void _showComparisonDialog() {
    if (_comparisonComponents.length < 2 || !mounted) return;
    final components = _comparisonComponents.values.toList();
    final specsList =
        components.map(_buildComparisonMetrics).toList(growable: false);
    final Set<String> allKeys = {
      'Name',
      'Manufacturer',
      'Price',
      'Type',
      ...specsList.expand((specs) => specs.keys)
    };

    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(24),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 600),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Text(
                          AppLocalizations.of(context)!.componentComparison,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 0),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(16),
                      child: DataTable(
                        headingRowColor: MaterialStateProperty.resolveWith(
                          (states) => Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.3),
                        ),
                        columns: [
                          DataColumn(label: Text(AppLocalizations.of(context)!.spec)),
                          ...components.map(
                            (component) => DataColumn(
                              label: SizedBox(
                                width: 180,
                                child: Text(
                                  component.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ),
                            ),
                          ),
                        ],
                        rows: allKeys.map((key) {
                          return DataRow(
                            cells: [
                              DataCell(Text(key)),
                              ...List.generate(components.length, (index) {
                                String value;
                                switch (key) {
                                  case 'Name':
                                    value = components[index].name;
                                    break;
                                  case 'Manufacturer':
                                    value = components[index].manufacturer;
                                    break;
                                  case 'Price':
                                    final price = components[index].lowestPrice;
                                    value = price != null
                                        ? 'zł${price.toStringAsFixed(2)}'
                                        : 'N/A';
                                    break;
                                  case 'Type':
                                    value = components[index]
                                        .type
                                        .name
                                        .toUpperCase();
                                    break;
                                  default:
                                    value = specsList[index][key] ?? '-';
                                }
                                return DataCell(
                                  SizedBox(
                                    width: 180,
                                    child: Text(
                                      value,
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                );
                              }),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _clearComparisonSelection,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: Text(AppLocalizations.of(context)!.clearSelection),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Map<String, String> _buildComparisonMetrics(BaseComponent component) {
    final specs = <String, String>{};
    switch (component.type) {
      case ComponentType.cpu:
        final cpu = component as CPUComponent;
        specs['Cores/Threads'] = '${cpu.coreTotal} / ${cpu.threadsAmount}';
        specs['Base/Boost'] =
            '${cpu.basePerformanceSpeed ?? '-'} / ${cpu.boostPerformanceSpeed ?? '-'} GHz';
        specs['Socket'] = cpu.socketType;
        specs['TDP'] = '${cpu.thermalDesignPower.toStringAsFixed(0)}W';
        break;
      case ComponentType.gpu:
        final gpu = component as GPUComponent;
        specs['Chipset'] = gpu.chipset;
        specs['VRAM'] = '${gpu.videoMemoryAmount.toStringAsFixed(0)} GB';
        specs['Base/Boost'] =
            '${gpu.coreBaseClockSpeed.toStringAsFixed(0)}/${gpu.coreBoostClockSpeed.toStringAsFixed(0)} MHz';
        specs['Length'] = '${gpu.length.toStringAsFixed(0)} mm';
        break;
      case ComponentType.motherboard:
        final mb = component as MotherboardComponent;
        specs['Socket'] = mb.socketType;
        specs['Form Factor'] = mb.formFactor;
        specs['RAM Slots'] = mb.ramSlotsAmount.toString();
        specs['Chipset'] = mb.chipsetType;
        break;
      case ComponentType.ram:
        final ram = component as MemoryComponent;
        specs['Speed'] = '${ram.speed.toStringAsFixed(0)} MHz';
        specs['Type'] = ram.ramType;
        specs['Modules'] =
            '${ram.moduleQuantity}x${ram.moduleCapacity.toStringAsFixed(0)}GB';
        break;
      case ComponentType.storage:
        final storage = component as StorageComponent;
        specs['Capacity'] = '${storage.capacity.toStringAsFixed(0)} GB';
        specs['Type'] = storage.driveType;
        specs['Interface'] = storage.interface;
        break;
      case ComponentType.psu:
        final psu = component as PowerSupplyComponent;
        specs['Wattage'] = '${psu.powerOutput.toStringAsFixed(0)}W';
        specs['Efficiency'] = psu.efficiencyRating ?? 'N/A';
        specs['Modularity'] = psu.modularityType;
        break;
      case ComponentType.pcCase:
        final pcCase = component as CaseComponent;
        specs['Form Factor'] = pcCase.formFactor;
        specs['Max GPU'] = '${pcCase.maxVideoCardLength.toStringAsFixed(0)} mm';
        specs['Max Cooler'] = '${pcCase.maxCPUCoolerHeight} mm';
        break;
      case ComponentType.cooler:
        final cooler = component as CoolerComponent;
        specs['Type'] = cooler.isWaterCooled ? 'Water' : 'Air';
        specs['Height'] = '${cooler.height.toStringAsFixed(0)} mm';
        specs['Fan Qty'] = cooler.fanQuantity.toString();
        break;
      case ComponentType.caseFan:
        final fan = component as CaseFanComponent;
        specs['Size'] = '${fan.size.toStringAsFixed(0)} mm';
        specs['Airflow'] = fan.maxAirflow != null
            ? '${fan.minAirflow.toStringAsFixed(0)}-${fan.maxAirflow!.toStringAsFixed(0)} CFM'
            : '${fan.minAirflow.toStringAsFixed(0)} CFM';
        specs['Noise'] = fan.maxNoiseLevel != null
            ? '${fan.minNoiseLevel.toStringAsFixed(1)}-${fan.maxNoiseLevel!.toStringAsFixed(1)} dBA'
            : '${fan.minNoiseLevel.toStringAsFixed(1)} dBA';
        break;
      case ComponentType.monitor:
        final monitor = component as MonitorComponent;
        specs['Size'] = '${monitor.screenSize.toStringAsFixed(1)}"';
        specs['Resolution'] =
            '${monitor.horizontalResolution}x${monitor.verticalResolution}';
        specs['Refresh Rate'] =
            '${monitor.maxRefreshRate.toStringAsFixed(0)} Hz';
        break;
    }
    return specs;
  }

  void _updateUrl(int page) {
    if (!mounted) return;
    final typeName = widget.componentType.name;
    final location = '/parts/$typeName?page=$page';
    GoRouter.of(context).go(location);
  }

  /// Shows a dialog with all specifications for the component
  void _showSpecsDialog(BuildContext context, BaseComponent component) {
    showDialog(
      context: context,
      builder: (context) => _ComponentSpecsDialog(component: component),
    );
  }

  /// Fetches compatible component IDs for given component IDs
  Future<Set<String>> _getCompatibleComponentIds(
    List<String> componentIds,
    WidgetRef ref,
  ) async {
    final Set<String> compatibleIds = {};
    final service = ref.read(
      compatibility.componentCompatibilityServiceProvider,
    );

    try {
      for (final componentId in componentIds) {
        final compatible = await service.getCompatibleComponentIds(componentId);
        compatibleIds.addAll(compatible);
        // Also add the component itself as compatible
        compatibleIds.add(componentId);
      }
    } catch (e) {
      debugPrint('Error fetching compatible components: $e');
    }

    return compatibleIds;
  }

  /// Filters products based on all active filters
  // Note: This client-side filtering is now largely redundant as the server handles it,
  // but we keep search and basic checks here for immediate feedback if needed.
  List<BaseComponent> _filterProducts(
    List<BaseComponent> products, {
    Set<String>? compatibleIds,
  }) {
    final activeFilters = ref.watch(activeFiltersProvider(widget.componentType));
    final compatibilityValue = activeFilters['Compatibility'];

    return products.where((product) {
      // Note: All filters except compatibility are handled server-side.
      // Compatibility filter
      if (compatibleIds != null) {
        if (compatibilityValue == true) {
          // If compatibility filter is Yes, only show products that are compatible
          if (!compatibleIds.contains(product.id)) {
            return false;
          }
        } else if (compatibilityValue == false) {
          // If compatibility filter is No, only show products that are NOT compatible
          if (compatibleIds.contains(product.id)) {
            return false;
          }
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Listen to filter changes and reload the page
    ref.listen<Map<String, dynamic>>(
      activeFiltersProvider(widget.componentType),
      (previous, next) {
        // Only reload if filters actually changed
        if (previous != next) {
          _loadCurrentPage(force: true, targetPage: 1);
        }
      },
    );

    final pagingState = ref.watch(
      componentPagingProvider(widget.componentType),
    );
    final pagingNotifier = ref.read(
      componentPagingProvider(widget.componentType).notifier,
    );

    final isLargeScreen = MediaQuery.of(context).size.width >= 1300;

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      endDrawer: !isLargeScreen
          ? Drawer(
              width: 300,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              child: SafeArea(
                child: Builder(
                  builder: (context) {
                    final products = pagingState.items;
                    final List<PcComponent> currentBuild =
                        widget.currentBuild ?? ref.watch(buildProvider);
                    return _LeftPanel(
                      enableCompatibilityFilter: _enableCompatibilityFilter,
                      onCompatibilityFilterChanged: (val) {
                        setState(() {
                          _enableCompatibilityFilter = val;
                        });
                      },
                      currentBuild: currentBuild,
                      allProducts: products,
                      componentType: widget.componentType,
                    );
                  },
                ),
              ),
            )
          : null,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 32.0,
                vertical: 24.0,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (isLargeScreen)
                    SizedBox(
                      width: 280,
                      child: Builder(
                        builder: (context) {
                          final products = pagingState.items;
                          if (pagingState.errorMessage != null &&
                              products.isEmpty) {
                            return const SizedBox.shrink();
                          }

                          if (widget.componentId != null &&
                              widget.componentId != _shownComponentId &&
                              !pagingState.isInitialLoading &&
                              !pagingState.isLoading) {
                            final componentIdToShow = widget.componentId!;
                            _shownComponentId = componentIdToShow;

                            WidgetsBinding.instance
                                .addPostFrameCallback((_) async {
                              if (!mounted ||
                                  componentIdToShow != widget.componentId) {
                                return;
                              }

                              BaseComponent? componentToShow;
                              try {
                                componentToShow = products.firstWhere(
                                  (p) => p.id == componentIdToShow,
                                );
                              } catch (e) {
                                try {
                                  final componentService =
                                      ref.read(componentServiceProvider);
                                  componentToShow =
                                      await componentService.getComponentById(
                                    componentIdToShow,
                                  );
                                } catch (fetchError) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Component not found'),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                  _shownComponentId = null;
                                  return;
                                }
                              }

                              if (mounted) {
                                _showSpecsDialog(context, componentToShow);
                              }
                            });
                          }

                          final List<PcComponent> currentBuild =
                              widget.currentBuild ?? ref.watch(buildProvider);

                          return _LeftPanel(
                            enableCompatibilityFilter:
                                _enableCompatibilityFilter,
                            onCompatibilityFilterChanged: (val) {
                              setState(() {
                                _enableCompatibilityFilter = val;
                              });
                            },
                            currentBuild: currentBuild,
                            allProducts: products,
                            componentType: widget.componentType,
                          );
                        },
                      ),
                    ),
                  if (isLargeScreen) const SizedBox(width: 32),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (pagingState.errorMessage != null &&
                            pagingState.items.isEmpty) {
                          return Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 48,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Failed to load components',
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  getUserFriendlyError(pagingState.errorMessage),
                                  style: Theme.of(context).textTheme.bodyMedium,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                FilledButton(
                                  onPressed: () => pagingNotifier.refresh(),
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }

                        final List<PcComponent> currentBuild =
                            widget.currentBuild ?? ref.watch(buildProvider);

                        Future<Set<String>>? compatibilityFuture;
                        if (_enableCompatibilityFilter &&
                            currentBuild.isNotEmpty) {
                          final buildComponentIds = currentBuild
                              .where((item) => item.selectedProduct != null)
                              .map((item) => item.selectedProduct!.id)
                              .toList();
                          if (buildComponentIds.isNotEmpty) {
                            compatibilityFuture = _getCompatibleComponentIds(
                              buildComponentIds,
                              ref,
                            );
                          }
                        }

                        Widget buildList({
                          Set<String>? compatibleIds,
                          Map<String, double>? priceMap,
                        }) {
                          final filteredProducts = _filterProducts(
                            pagingState.items,
                            compatibleIds: compatibleIds,
                          );

                          return _ProductList(
                            componentType: widget.componentType,
                            searchController: _searchController,
                            products: filteredProducts,
                            onComponentSelected: widget.onComponentSelected,
                            currentPage: _currentPage,
                            count: pagingState.totalCount,
                            hasMore: pagingState.hasMore,
                            isLoading: pagingState.isLoading ||
                                pagingState.isInitialLoading,
                            isRefreshing: pagingState.isRefreshing,
                            onRefresh: pagingNotifier.refresh,
                            onPageChanged: _navigateToPage,
                            comparisonSelection: _comparisonComponents,
                            maxComparisonItems: _maxComparisonItems,
                            onCompareToggle: _toggleComparisonSelection,
                            onCompare: _showComparisonDialog,
                            onClearComparison: _clearComparisonSelection,
                            scrollController: _scrollController,
                            showCompare: isLargeScreen,
                            priceMap: priceMap,
                            onOpenFilters: !isLargeScreen
                                ? () {
                                    _scaffoldKey.currentState?.openEndDrawer();
                                  }
                                : null,
                          );
                        }

                        if (compatibilityFuture != null) {
                          return FutureBuilder<List<Object?>>(
                            future: Future.wait<Object?>([
                              compatibilityFuture,
                            ]),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final compatibleIds =
                                  snapshot.data?[0] as Set<String>?;
                              return buildList(
                                compatibleIds: compatibleIds,
                                priceMap: const {},
                              );
                            },
                          );
                        }

                        return buildList(priceMap: const {});
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The left-side panel of the Part Picker page, containing the build summary and all filters.
class _LeftPanel extends ConsumerWidget {
  // --- Properties for passing data and callbacks ---
  final List<PcComponent> currentBuild;
  final List<BaseComponent> allProducts;
  final ComponentType componentType;

  // Compatibility filter
  final bool enableCompatibilityFilter;
  final Function(bool) onCompatibilityFilterChanged;

  const _LeftPanel({
    required this.enableCompatibilityFilter,
    required this.onCompatibilityFilterChanged,
    required this.currentBuild,
    required this.allProducts,
    required this.componentType,
  });

  /// A computed property that calculates the number of parts currently selected in the build.
  int get _selectedPartCount =>
      currentBuild.where((c) => c.selectedProduct != null).length;

  /// A computed property that calculates the total price of the current build.
  double get _totalPrice => currentBuild.fold(
        0.0,
        (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
      );

  /// A computed property that calculates the estimated wattage of the current build based on CPU and GPU TDP.
  // TODO: Make this calculation more comprehensive by including other components.
  int get _estimatedWattage => currentBuild.fold(0, (sum, item) {
        final p = item.selectedProduct;
        if (p is CPUComponent) return sum + p.thermalDesignPower.toInt();
        if (p is GPUComponent) return sum + p.thermalDesignPower.toInt();
        return sum;
      });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        /// A checkbox to toggle the compatibility filter.
        CheckboxListTile(
          title: Text(
            AppLocalizations.of(context)!.compatibilityFilter,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          value: enableCompatibilityFilter,
          onChanged: (val) {
            onCompatibilityFilterChanged(val ?? false);
          },
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColorsDark.textPurple,
        ),
        const SizedBox(height: 16),

        /// Displays a summary of the user's current build.
        _BuildSummary(
          partCount: _selectedPartCount,
          totalPrice: _totalPrice,
          estimatedWattage: _estimatedWattage,
        ),
        const SizedBox(height: 24),

        /// The main filter panel, which is scrollable and contains all filter widgets.
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF13131F),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: DynamicFilterPanel(componentType: componentType),
          ),
        ),
      ],
    );
  }
}


/// A widget that displays a summary of the current build (part count, price, wattage).
class _BuildSummary extends StatelessWidget {
  final int partCount;
  final double totalPrice;
  final int estimatedWattage;
  const _BuildSummary({
    required this.partCount,
    required this.totalPrice,
    required this.estimatedWattage,
  });

  @override
  Widget build(BuildContext context) {
    // A styled container for the summary information.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF13131F),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        // Each piece of information is displayed in a `_SummaryRow`.
        children: [
          _SummaryRow(label: 'Parts:', value: '$partCount/12'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Total Price:',
            value: 'zł${totalPrice.toStringAsFixed(2)}',
            valueColor: const Color(0xFF00E5FF),
          ),
          const SizedBox(height: 8),
          _SummaryRow(label: 'Est. Wattage:', value: '${estimatedWattage}W'),
        ],
      ),
    );
  }
}

/// A helper widget to display a single row in the build summary.
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(color: Colors.grey.shade400)),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

/// The right-side panel that displays the list of products.
class _ProductList extends ConsumerWidget {
  final ComponentType componentType;
  final TextEditingController searchController;
  final List<BaseComponent> products;
  final Function(BaseComponent)? onComponentSelected;
  final int currentPage;
  final int count;
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final void Function(int page) onPageChanged;
  final Map<String, BaseComponent> comparisonSelection;
  final int maxComparisonItems;
  final void Function(BaseComponent component, bool shouldSelect)
      onCompareToggle;
  final VoidCallback onCompare;
  final VoidCallback onClearComparison;
  final ScrollController scrollController;
  final bool showCompare;
  final VoidCallback? onOpenFilters;
  final Map<String, double>? priceMap;

  const _ProductList({
    required this.componentType,
    required this.searchController,
    required this.products,
    required this.currentPage,
    required this.count,
    required this.hasMore,
    required this.isLoading,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onPageChanged,
    required this.comparisonSelection,
    required this.maxComparisonItems,
    required this.onCompareToggle,
    required this.onCompare,
    required this.onClearComparison,
    required this.scrollController,
    this.onComponentSelected,
    this.showCompare = true,
    this.onOpenFilters,
    this.priceMap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(
          searchController: searchController,
          count: count,
          currentPage: currentPage,
          selectedComparisonCount: comparisonSelection.length,
          maxComparisonItems: maxComparisonItems,
          onCompare: onCompare,
          onClearComparison: onClearComparison,
          onClearFilters: () {
            ref.read(activeFiltersProvider(componentType).notifier).clearAll();
          },
          showCompare: showCompare,
          onOpenFilters: onOpenFilters,
        ),
        _DataSourceWatermark(isMobile: !showCompare),
        const SizedBox(height: 24),
        if (isRefreshing || isLoading)
          const LinearProgressIndicator(minHeight: 2),
        if (isRefreshing || isLoading) const SizedBox(height: 12),
        if (showCompare) _ProductListHeader(componentType: componentType),
        if (showCompare) const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? RefreshIndicator.adaptive(
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: isLoading
                              ? const SizedBox.shrink()
                              : const Text("No products match your criteria."),
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator.adaptive(
                  onRefresh: onRefresh,
                  child: _ProductListWithCompatibility(
                    products: products,
                    componentType: componentType,
                    onComponentSelected: onComponentSelected,
                    comparisonSelection: comparisonSelection,
                    maxComparisonItems: maxComparisonItems,
                    onCompareToggle: onCompareToggle,
                    scrollController: scrollController,
                    currentPage: currentPage,
                    hasMore: hasMore,
                    onPageChanged: onPageChanged,
                    showCompare: showCompare,
                    priceOverrides: priceMap,
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProductListWithCompatibility extends ConsumerWidget {
  final List<BaseComponent> products;
  final ComponentType componentType;
  final Function(BaseComponent)? onComponentSelected;
  final Map<String, BaseComponent> comparisonSelection;
  final int maxComparisonItems;
  final void Function(BaseComponent component, bool shouldSelect)
      onCompareToggle;
  final ScrollController scrollController;
  final int currentPage;
  final bool hasMore;
  final void Function(int page) onPageChanged;
  final bool showCompare;
  final Map<String, double>? priceOverrides;

  const _ProductListWithCompatibility({
    required this.products,
    required this.componentType,
    required this.comparisonSelection,
    required this.maxComparisonItems,
    required this.onCompareToggle,
    required this.scrollController,
    required this.currentPage,
    required this.hasMore,
    required this.onPageChanged,
    this.onComponentSelected,
    this.showCompare = true,
    this.priceOverrides,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      controller: scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: products.length + 1,
      itemBuilder: (context, index) {
        if (index == products.length) {
          return Padding(
            padding: const EdgeInsets.only(top: 16.0, bottom: 32.0),
            child: _PaginationControls(
              currentPage: currentPage,
              hasMore: hasMore,
              onPageChanged: onPageChanged,
            ),
          );
        }

        final product = products[index];
        final overridePrice = priceOverrides?[product.id];
        final onComponentSelected = this.onComponentSelected;

        if (!showCompare) {
          return _MobileProductCard(
            product: product,
            onComponentSelected: onComponentSelected,
          );
        }

        Widget row = _GenericProductRow(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: comparisonSelection.containsKey(product.id),
          onCompareToggle: (selected) => onCompareToggle(product, selected),
          priceOverride: overridePrice,
        );
        switch (product.type) {
          case ComponentType.cpu:
            row = _CpuProductRow(
              product: product as CPUComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.motherboard:
            row = _MotherboardProductRow(
              product: product as MotherboardComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.ram:
            row = _RamProductRow(
              product: product as MemoryComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.storage:
            row = _StorageProductRow(
              product: product as StorageComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.psu:
            row = _PsuProductRow(
              product: product as PowerSupplyComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.pcCase:
            row = _CaseProductRow(
              product: product as CaseComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.gpu:
            row = _GpuProductRow(
              product: product as GPUComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.cooler:
            row = _CoolerProductRow(
              product: product as CoolerComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.caseFan:
            row = _CaseFanProductRow(
              product: product as CaseFanComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
          case ComponentType.monitor:
            row = _MonitorProductRow(
              product: product as MonitorComponent,
              onComponentSelected: onComponentSelected,
              isSelectedForCompare: comparisonSelection.containsKey(product.id),
              onCompareToggle: (selected) =>
                  onCompareToggle(product, selected),
              priceOverride: overridePrice,
            );
            break;
        }
        return row;
      },
    );
  }
}

class _PaginationControls extends StatelessWidget {
  final int currentPage;
  final bool hasMore;
  final void Function(int page) onPageChanged;

  const _PaginationControls({
    required this.currentPage,
    required this.hasMore,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canGoBack = currentPage > 1;
    final canGoForward = hasMore;

    return Row(
      children: [
        Text(
          '${AppLocalizations.of(context)!.page} $currentPage',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          label: Text(AppLocalizations.of(context)!.previous),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: canGoForward ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          label: Text(AppLocalizations.of(context)!.next),
        ),
      ],
    );
  }
}

/// A small watermark indicating the data source for the parts list.
class _DataSourceWatermark extends StatelessWidget {
  final bool isMobile;
  const _DataSourceWatermark({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Colors.grey.shade500,
        );

    return Padding(
      padding: EdgeInsets.only(top: isMobile ? 12 : 8),
      child: Row(
        mainAxisAlignment:
            isMobile ? MainAxisAlignment.start : MainAxisAlignment.end,
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade500),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Component data is sourced from buildcores open db '
              '(e.g., component schema at '
              'https://github.com/buildcores/buildcores-open-db/).',
              style: textStyle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// The top bar of the product list, containing a title, search bar, and action buttons.
class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final int count;
  final int currentPage;
  final int selectedComparisonCount;
  final int maxComparisonItems;
  final VoidCallback onCompare;
  final VoidCallback onClearComparison;
  final VoidCallback onClearFilters;
  final bool showCompare;
  final VoidCallback? onOpenFilters;

  const _TopBar({
    required this.searchController,
    required this.count,
    required this.currentPage,
    required this.selectedComparisonCount,
    required this.maxComparisonItems,
    required this.onCompare,
    required this.onClearComparison,
    required this.onClearFilters,
    this.showCompare = true,
    this.onOpenFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (!showCompare) {
      // Mobile Layout
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.compatibleProductsCount(count),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              FilledButton.icon(
                onPressed: onOpenFilters,
                icon: const Icon(Icons.filter_list),
                label: Text(AppLocalizations.of(context)!.filters),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF2A2A35),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchProcessors,
              hintStyle: TextStyle(color: Colors.grey.shade600),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade600),
              filled: true,
              fillColor: const Color(0xFF13131F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            style: const TextStyle(color: Colors.white),
          ),
        ],
      );
    }

    // Desktop Layout
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            AppLocalizations.of(context)!.compatibleProductsCountPage(count, currentPage),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 250,
          child: TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.searchProcessors,
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              filled: true,
              fillColor: const Color(0xFF13131F),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: selectedComparisonCount >= 2 ? onCompare : null,
          icon: const Icon(Icons.compare_arrows),
          label: Text(
            AppLocalizations.of(context)!.compareCount(selectedComparisonCount, maxComparisonItems),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        if (selectedComparisonCount > 0) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onClearComparison,
            child: Text(AppLocalizations.of(context)!.clear),
          ),
        ],
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: onClearFilters,
          icon: const Icon(Icons.filter_alt_off, size: 20),
          label: Text(AppLocalizations.of(context)!.clearFilters),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }
}

/// The header for the product list, which changes its columns based on the component type.
class _ProductListHeader extends StatelessWidget {
  final ComponentType componentType;
  const _ProductListHeader({required this.componentType});

  @override
  Widget build(BuildContext context) {
    List<String> headers = const ['Product', 'Details', 'Price'];
    List<int> flexValues = const [4, 4, 3];

    // The headers and their corresponding flex values change based on the component type.
    switch (componentType) {
      case ComponentType.cpu:
        headers = const [
          'Product',
          'Cores',
          'Base/Boost',
          'MicroArch',
          'TDP',
          'Graphics',
          'Rating',
          'Price',
        ];
        flexValues = const [4, 1, 2, 2, 1, 2, 2, 3];
        break;
      case ComponentType.motherboard:
        headers = ['Product', 'Form Factor', 'Socket', 'RAM Slots', 'Price'];
        flexValues = [5, 3, 2, 2, 3];
        break;
      case ComponentType.ram:
        headers = ['Product', 'Speed', 'Type', 'Modules', 'Price'];
        flexValues = [5, 2, 2, 2, 3];
        break;
      case ComponentType.storage:
        headers = ['Product', 'Capacity', 'Type', 'Interface', 'Price'];
        flexValues = [5, 2, 2, 3, 3];
        break;
      case ComponentType.psu:
        headers = ['Product', 'Wattage', 'Efficiency', 'Modularity', 'Price'];
        flexValues = [5, 2, 3, 3, 3];
        break;
      case ComponentType.pcCase:
        headers = ['Product', 'Form Factor', 'Max GPU', 'Max Cooler', 'Price'];
        flexValues = [5, 3, 2, 2, 3];
        break;
      case ComponentType.gpu:
        headers = [
          'Product',
          'Chipset',
          'VRAM',
          'Memory Type',
          'Base/Boost',
          'TDP',
          'Length',
          'Price',
        ];
        flexValues = [4, 2, 1, 2, 2, 1, 1, 3];
        break;
      case ComponentType.cooler:
        headers = [
          'Product',
          'Type',
          'Height',
          'Radiator',
          'Fan Size',
          'Fan Qty',
          'Price',
        ];
        flexValues = [4, 2, 1, 1, 1, 1, 3];
        break;
      case ComponentType.caseFan:
        headers = [
          'Product',
          'Size',
          'Airflow',
          'Noise',
          'PWM',
          'LED',
          'Price',
        ];
        flexValues = [4, 1, 2, 1, 1, 1, 3];
        break;
      case ComponentType.monitor:
        headers = [
          'Product',
          'Size',
          'Resolution',
          'Refresh',
          'Panel',
          'Sync',
          'Price',
        ];
        flexValues = [4, 1, 2, 1, 2, 2, 3];
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        // Generate the header cells from the lists defined above.
        children: List.generate(headers.length, (index) {
          return Expanded(
            flex: flexValues[index],
            child: Text(
              headers[index],
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          );
        }),
      ),
    );
  }
}

/// An abstract base class for all product row widgets to reduce code duplication.
abstract class _ProductRow extends ConsumerWidget {
  final BaseComponent product;
  final Function(BaseComponent)? onComponentSelected;
  final bool isSelectedForCompare;
  final void Function(bool)? onCompareToggle;
  final bool showCompare;
  final double? priceOverride;

  const _ProductRow({
    required this.product,
    this.onComponentSelected,
    this.isSelectedForCompare = false,
    this.onCompareToggle,
    this.showCompare = true,
    this.priceOverride,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The base structure for every product row is a Card with a Row inside.
    return Card(
      color: const Color(0xFF13131F),
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      child: InkWell(
        onTap: () => _showSpecsDialog(context, product),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showCompare) ...[
                Checkbox(
                  value: isSelectedForCompare,
                  onChanged: onCompareToggle == null
                      ? null
                      : (value) => onCompareToggle!(value ?? false),
                ),
                const SizedBox(width: 8),
              ],
              ...buildRow(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a dialog with all specifications for the component
  void _showSpecsDialog(BuildContext context, BaseComponent component) {
    showDialog(
      context: context,
      builder: (context) => _ComponentSpecsDialog(component: component),
    );
  }

  /// Abstract method to be implemented by subclasses to define the row's content.
  List<Widget> buildRow(BuildContext context, WidgetRef ref);

  /// A reusable widget for the first cell in a row, typically showing the product image and name.
  /// It includes an error builder for the network image and compatibility badge.
  Widget buildNameCell(BuildContext context, WidgetRef ref, {int flex = 5}) {
    // For now, just use product.imageUrl to avoid infinite loops
    // Image uploads will be handled by backend updating component.imageUrl
    final rawImageUrl = product.imageUrl.trim();
    String? imageUrl;

    if (rawImageUrl.isNotEmpty) {
      // Check if it's a GUID (image ID) or a URL
      final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (guidPattern.hasMatch(rawImageUrl)) {
        imageUrl = '$apiBaseUrl/Images/download/$rawImageUrl';
      } else if (rawImageUrl.startsWith('http://') ||
          rawImageUrl.startsWith('https://')) {
        imageUrl = rawImageUrl;
      } else if (rawImageUrl.startsWith('/')) {
        imageUrl = '$apiBaseUrl$rawImageUrl';
      } else {
        imageUrl = '$apiBaseUrl/$rawImageUrl';
      }
    }

    return Expanded(
      flex: flex,
      child: Row(
        children: [
          if (imageUrl != null && imageUrl.isNotEmpty)
            Image.network(
              imageUrl,
              width: 40,
              height: 40,
              errorBuilder: (c, o, s) => Icon(
                Icons.broken_image,
                size: 40,
                color: Colors.grey.shade700,
              ),
            )
          else
            Icon(Icons.broken_image, size: 40, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                _buildCompatibilityBadge(context, ref),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the compatibility badge if component is compatible with current build
  /// Temporarily disabled due to API rate limiting and validation issues
  Widget _buildCompatibilityBadge(BuildContext context, WidgetRef ref) {
    // Temporarily disabled to prevent 400/429 errors
    // TODO: Fix backend API validation or implement proper batch endpoint
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
    // // Use compatibility map if available, otherwise don't show badge
    // final isCompatible = compatibilityMap?[product.id] ?? false;
    //
    // if (!isCompatible) return const SizedBox.shrink();
    //
    // return Container(
    //   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    //   decoration: BoxDecoration(
    //     color: Colors.green.withValues(alpha: 0.9),
    //     borderRadius: BorderRadius.circular(8),
    //   ),
    //   child: Row(
    //     mainAxisSize: MainAxisSize.min,
    //     children: [
    //       const Icon(
    //         Icons.check_circle,
    //         size: 12,
    //         color: Colors.white,
    //       ),
    //       const SizedBox(width: 4),
    //       Text(
    //         'Compatible',
    //         style: const TextStyle(
    //           color: Colors.white,
    //           fontSize: 10,
    //           fontWeight: FontWeight.bold,
    //         ),
    //       ),
    //     ],
    //   ),
    // );
  }

  /// A reusable widget for a simple text cell with a specified flex factor.
  Widget buildTextCell(String text, {int flex = 2}) {
    return Expanded(flex: flex, child: Text(text));
  }

  /// A reusable widget for the last cell, showing the price and an "Add" button.
  /// When the "Add" button is pressed, it pops the current page and returns the selected `product`.
  Widget buildPriceCell(
    BuildContext context,
    WidgetRef ref, {
    int flex = 3,
    double? priceOverride,
  }) {
    final displayPrice = priceOverride ?? product.lowestPrice;
    final priceText = displayPrice != null
        ? 'zł${displayPrice.toStringAsFixed(2)}'
        : 'N/A -';
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            priceText,
            style: const TextStyle(
              color: Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 24),
          ElevatedButton.icon(
            onPressed: () {
              // If callback is provided (e.g., from edit page), use it instead of buildProvider
              if (onComponentSelected != null) {
                onComponentSelected!(product);
                Navigator.pop(context);
              } else {
                // Default behavior: Add component to buildProvider and navigate to build-now
                ref.read(buildProvider.notifier).addComponent(product);
                // Navigate to build-now page
                context.go('/build-now');
                // Also pop if we came from a navigation stack
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00E676),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

/// A concrete implementation of [_ProductRow] for displaying CPU details.
class _CpuProductRow extends _ProductRow {
  const _CpuProductRow({
    required CPUComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    // Cast the product to the specific type to access its properties.
    final p = product as CPUComponent;
    return [
      buildNameCell(context, ref, flex: 4),
      buildTextCell(p.coreTotal.toString(), flex: 1),
      buildTextCell(
        '${p.basePerformanceSpeed}/${p.boostPerformanceSpeed} GHz',
        flex: 2,
      ),
      buildTextCell(p.microarchitecture, flex: 2),
      buildTextCell('${p.thermalDesignPower.toInt()}W', flex: 1),
      buildTextCell(p.graphics, flex: 2),
      Expanded(flex: 2, child: _RatingStars(rating: p.averageRating ?? 0)),
      buildPriceCell(context, ref, flex: 3, priceOverride: priceOverride),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying Motherboard details.
class _MotherboardProductRow extends _ProductRow {
  const _MotherboardProductRow({
    required MotherboardComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    // Cast the product to the specific type.
    final p = product as MotherboardComponent;
    return [
      buildNameCell(context, ref, flex: 5),
      buildTextCell(p.formFactor, flex: 3),
      buildTextCell(p.socketType, flex: 2),
      buildTextCell('${p.ramSlotsAmount}', flex: 2),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying RAM details.
class _RamProductRow extends _ProductRow {
  const _RamProductRow({
    required MemoryComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    // Cast the product to the specific type.
    final p = product as MemoryComponent;
    return [
      buildNameCell(context, ref, flex: 5),
      buildTextCell('${p.speed.toInt()} MHz', flex: 2),
      buildTextCell(p.ramType, flex: 2),
      buildTextCell(
        '${p.moduleQuantity}x${p.moduleCapacity.toInt() / 1000}GB',
        flex: 2,
      ),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying Storage details.
class _StorageProductRow extends _ProductRow {
  const _StorageProductRow({
    required StorageComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    // Cast the product to the specific type.
    final p = product as StorageComponent;
    return [
      buildNameCell(context, ref, flex: 5),
      buildTextCell('${p.capacity.toInt()} GB', flex: 2),
      buildTextCell(p.driveType, flex: 2),
      buildTextCell(p.interface, flex: 3),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying PSU details.
class _PsuProductRow extends _ProductRow {
  const _PsuProductRow({
    required PowerSupplyComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    // Cast the product to the specific type.
    final p = product as PowerSupplyComponent;
    return [
      buildNameCell(context, ref, flex: 5),
      buildTextCell('${p.powerOutput.toInt()}W', flex: 2),
      buildTextCell(p.efficiencyRating ?? 'N/A', flex: 3),
      buildTextCell(p.modularityType, flex: 3),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying PC Case details.
class _CaseProductRow extends _ProductRow {
  const _CaseProductRow({
    required CaseComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    // Cast the product to the specific type.
    final p = product as CaseComponent;
    return [
      buildNameCell(context, ref, flex: 5),
      buildTextCell(p.formFactor, flex: 3),
      buildTextCell('${p.maxVideoCardLength.toInt()}mm', flex: 2),
      buildTextCell('${p.maxCPUCoolerHeight.toInt()}mm', flex: 2),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying GPU details.
class _GpuProductRow extends _ProductRow {
  const _GpuProductRow({
    required GPUComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    final p = product as GPUComponent;
    return [
      buildNameCell(context, ref, flex: 4),
      buildTextCell(p.chipset, flex: 2),
      buildTextCell('${p.videoMemoryAmount.toStringAsFixed(0)}GB', flex: 1),
      buildTextCell(p.videoMemoryType, flex: 2),
      buildTextCell(
        '${p.coreBaseClockSpeed.toStringAsFixed(0)}/${p.coreBoostClockSpeed.toStringAsFixed(0)} MHz',
        flex: 2,
      ),
      buildTextCell('${p.thermalDesignPower.toInt()}W', flex: 1),
      buildTextCell('${p.length.toStringAsFixed(0)}mm', flex: 1),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying Cooler details.
class _CoolerProductRow extends _ProductRow {
  const _CoolerProductRow({
    required CoolerComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    final p = product as CoolerComponent;
    return [
      buildNameCell(context, ref, flex: 4),
      buildTextCell(p.isWaterCooled ? 'Water' : 'Air', flex: 2),
      buildTextCell('${p.height.toStringAsFixed(0)}mm', flex: 1),
      buildTextCell(
        p.radiatorSize != null
            ? '${p.radiatorSize!.toStringAsFixed(0)}mm'
            : 'N/A',
        flex: 1,
      ),
      buildTextCell(
        p.fanSize != null ? '${p.fanSize!.toStringAsFixed(0)}mm' : 'N/A',
        flex: 1,
      ),
      buildTextCell('${p.fanQuantity}', flex: 1),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying Case Fan details.
class _CaseFanProductRow extends _ProductRow {
  const _CaseFanProductRow({
    required CaseFanComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    final p = product as CaseFanComponent;
    return [
      buildNameCell(context, ref, flex: 4),
      buildTextCell('${p.size.toStringAsFixed(0)}mm', flex: 1),
      buildTextCell(
        p.maxAirflow != null
            ? '${p.minAirflow.toStringAsFixed(0)}-${p.maxAirflow!.toStringAsFixed(0)} CFM'
            : '${p.minAirflow.toStringAsFixed(0)} CFM',
        flex: 2,
      ),
      buildTextCell(
        p.maxNoiseLevel != null
            ? '${p.minNoiseLevel.toStringAsFixed(1)}-${p.maxNoiseLevel!.toStringAsFixed(1)} dBA'
            : '${p.minNoiseLevel.toStringAsFixed(1)} dBA',
        flex: 1,
      ),
      buildTextCell(p.pulseWidthModulation ? 'Yes' : 'No', flex: 1),
      buildTextCell(p.ledType ?? 'None', flex: 1),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying Monitor details.
class _MonitorProductRow extends _ProductRow {
  const _MonitorProductRow({
    required MonitorComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    final p = product as MonitorComponent;
    return [
      buildNameCell(context, ref, flex: 4),
      buildTextCell('${p.screenSize.toStringAsFixed(1)}"', flex: 1),
      buildTextCell(
        '${p.horizontalResolution}x${p.verticalResolution}',
        flex: 2,
      ),
      buildTextCell('${p.maxRefreshRate.toStringAsFixed(0)}Hz', flex: 1),
      buildTextCell(p.panelType, flex: 2),
      buildTextCell(p.adaptiveSyncType, flex: 2),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A generic fallback implementation of [_ProductRow] for component types without a specific row widget.
class _GenericProductRow extends _ProductRow {
  const _GenericProductRow({
    required BaseComponent product,
    Function(BaseComponent)? onComponentSelected,
    bool isSelectedForCompare = false,
    void Function(bool)? onCompareToggle,
    bool showCompare = true,
    double? priceOverride,
  }) : super(
          product: product,
          onComponentSelected: onComponentSelected,
          isSelectedForCompare: isSelectedForCompare,
          onCompareToggle: onCompareToggle,
          showCompare: showCompare,
          priceOverride: priceOverride,
        );

  @override
  List<Widget> buildRow(BuildContext context, WidgetRef ref) {
    return [
      buildNameCell(context, ref, flex: 5),
      buildTextCell(product.manufacturer, flex: 4),
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A widget to display a product's rating using star icons.
class _RatingStars extends StatelessWidget {
  final double rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
    // Generates 5 stars, filling them based on the rating value.
    return Row(
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(Icons.star, color: Colors.amber, size: 16);
        } else if (index == rating.floor() &&
            (rating - rating.floor()) >= 0.5) {
          return const Icon(Icons.star_half, color: Colors.amber, size: 16);
        } else {
          return const Icon(Icons.star_border, color: Colors.amber, size: 16);
        }
      }),
    );
  }
}

/// A dialog widget that displays all specifications for a component
class _ComponentSpecsDialog extends ConsumerWidget {
  final BaseComponent component;
  const _ComponentSpecsDialog({required this.component});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // For now, just use component.imageUrl to avoid infinite loops
    // Image uploads will be handled by backend updating component.imageUrl
    final rawImageUrl = component.imageUrl.trim();
    String? imageUrl;

    if (rawImageUrl.isNotEmpty) {
      // Check if it's a GUID (image ID) or a URL
      final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (guidPattern.hasMatch(rawImageUrl)) {
        imageUrl = '$apiBaseUrl/Images/download/$rawImageUrl';
      } else if (rawImageUrl.startsWith('http://') ||
          rawImageUrl.startsWith('https://')) {
        imageUrl = rawImageUrl;
      } else if (rawImageUrl.startsWith('/')) {
        imageUrl = '$apiBaseUrl$rawImageUrl';
      } else {
        imageUrl = '$apiBaseUrl/$rawImageUrl';
      }
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  if (imageUrl != null && imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      width: 60,
                      height: 60,
                      errorBuilder: (c, o, s) => Icon(
                        Icons.broken_image,
                        size: 60,
                        color: Colors.grey.shade700,
                      ),
                    )
                  else
                    Icon(
                      Icons.broken_image,
                      size: 60,
                      color: Colors.grey.shade700,
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          component.manufacturer,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _buildSpecsContent(context, theme),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecsContent(BuildContext context, ThemeData theme) {
    Widget specs = _buildGenericSpecs(component, theme);
    switch (component.type) {
      case ComponentType.cpu:
        specs = _buildCpuSpecs(component as CPUComponent, theme);
        break;
      case ComponentType.gpu:
        specs = _buildGpuSpecs(component as GPUComponent, theme);
        break;
      case ComponentType.motherboard:
        specs = _buildMotherboardSpecs(
          component as MotherboardComponent,
          theme,
        );
        break;
      case ComponentType.ram:
        specs = _buildRamSpecs(component as MemoryComponent, theme);
        break;
      case ComponentType.storage:
        specs = _buildStorageSpecs(component as StorageComponent, theme);
        break;
      case ComponentType.psu:
        specs = _buildPsuSpecs(component as PowerSupplyComponent, theme);
        break;
      case ComponentType.pcCase:
        specs = _buildCaseSpecs(component as CaseComponent, theme);
        break;
      case ComponentType.cooler:
        specs = _buildCoolerSpecs(component as CoolerComponent, theme);
        break;
      case ComponentType.caseFan:
        specs = _buildCaseFanSpecs(component as CaseFanComponent, theme);
        break;
      case ComponentType.monitor:
        specs = _buildMonitorSpecs(component as MonitorComponent, theme);
        break;
    }
    return specs;
  }

  Widget _buildSpecSection(
    String title,
    List<MapEntry<String, String>> specs,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        ...specs.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 180,
                  child: Text(
                    entry.key,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    entry.value,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildCpuSpecs(CPUComponent cpu, ThemeData theme) {
    final generalSpecs = <MapEntry<String, String>>[];
    final performanceSpecs = <MapEntry<String, String>>[];

    generalSpecs.addAll([
      MapEntry('Series', cpu.series),
      MapEntry('Microarchitecture', cpu.microarchitecture),
      MapEntry('Core Family', cpu.coreFamily),
      MapEntry('Socket Type', cpu.socketType),
      MapEntry('Total Cores', cpu.coreTotal.toString()),
      if (cpu.performanceAmount != null)
        MapEntry('Performance Cores', cpu.performanceAmount.toString()),
      if (cpu.efficiencyAmount != null)
        MapEntry('Efficiency Cores', cpu.efficiencyAmount.toString()),
      MapEntry('Total Threads', cpu.threadsAmount.toString()),
      MapEntry('Includes Cooler', cpu.includesCooler ? 'Yes' : 'No'),
      MapEntry('Lithography', cpu.lithography),
      MapEntry(
        'SMT Support',
        cpu.supportsSimultaneousMultithreading ? 'Yes' : 'No',
      ),
      MapEntry('Memory Type', cpu.memoryType),
      MapEntry('Packaging', cpu.packagingType),
      MapEntry('ECC Support', cpu.supportsECC ? 'Yes' : 'No'),
      MapEntry('TDP', '${cpu.thermalDesignPower.toStringAsFixed(0)}W'),
      MapEntry('Integrated Graphics', cpu.graphics),
    ]);

    performanceSpecs.addAll([
      if (cpu.basePerformanceSpeed != null)
        MapEntry('Base Clock (P-cores)', '${cpu.basePerformanceSpeed} GHz'),
      if (cpu.boostPerformanceSpeed != null)
        MapEntry('Boost Clock (P-cores)', '${cpu.boostPerformanceSpeed} GHz'),
      if (cpu.baseEfficiencySpeed != null)
        MapEntry('Base Clock (E-cores)', '${cpu.baseEfficiencySpeed} GHz'),
      if (cpu.boostEfficiencySpeed != null)
        MapEntry('Boost Clock (E-cores)', '${cpu.boostEfficiencySpeed} GHz'),
      if (cpu.l1 != null) MapEntry('L1 Cache', '${cpu.l1} MB'),
      if (cpu.l2 != null) MapEntry('L2 Cache', '${cpu.l2} MB'),
      if (cpu.l3 != null) MapEntry('L3 Cache', '${cpu.l3} MB'),
      if (cpu.l4 != null) MapEntry('L4 Cache', '${cpu.l4} MB'),
      if (cpu.release != null)
        MapEntry('Release Date', cpu.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return Column(
      children: [
        _buildSpecSection('General Information', generalSpecs, theme),
        if (performanceSpecs.isNotEmpty)
          _buildSpecSection('Performance', performanceSpecs, theme),
      ],
    );
  }

  Widget _buildGpuSpecs(GPUComponent gpu, ThemeData theme) {
    final specs = <MapEntry<String, String>>[];

    specs.addAll([
      MapEntry('Chipset', gpu.chipset),
      MapEntry('VRAM', '${gpu.videoMemoryAmount.toStringAsFixed(0)} GB'),
      MapEntry('Memory Type', gpu.videoMemoryType),
      MapEntry(
        'Base Clock',
        '${gpu.coreBaseClockSpeed.toStringAsFixed(0)} MHz',
      ),
      MapEntry(
        'Boost Clock',
        '${gpu.coreBoostClockSpeed.toStringAsFixed(0)} MHz',
      ),
      MapEntry('Core Count', gpu.coreCount.toString()),
      MapEntry(
        'Memory Clock',
        '${gpu.effectiveMemoryClockSpeed.toStringAsFixed(0)} MHz',
      ),
      MapEntry('Memory Bus Width', '${gpu.memoryBusWidth} bits'),
      MapEntry('Frame Sync', gpu.frameSync),
      MapEntry('Length', '${gpu.length.toStringAsFixed(0)} mm'),
      MapEntry('TDP', '${gpu.thermalDesignPower.toStringAsFixed(0)}W'),
      MapEntry('Slot Width', '${gpu.caseExpansionSlotWidth} slots'),
      MapEntry('Total Slots', gpu.totalSlotAmount.toString()),
      MapEntry('Cooling Type', gpu.coolingType),
      if (gpu.release != null)
        MapEntry('Release Date', gpu.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return _buildSpecSection('GPU Specifications', specs, theme);
  }

  Widget _buildMotherboardSpecs(MotherboardComponent mb, ThemeData theme) {
    final generalSpecs = <MapEntry<String, String>>[];
    final connectivitySpecs = <MapEntry<String, String>>[];
    final headersSpecs = <MapEntry<String, String>>[];

    generalSpecs.addAll([
      MapEntry('Socket Type', mb.socketType),
      MapEntry('Form Factor', mb.formFactor),
      MapEntry('Chipset', mb.chipsetType),
      MapEntry('RAM Type', mb.ramType),
      MapEntry('RAM Slots', mb.ramSlotsAmount.toString()),
      MapEntry('Max RAM', '${mb.maxRAMAmount} GB'),
      MapEntry('Audio Chipset', mb.audioChipset),
      MapEntry('Max Audio Channels', mb.maxAudioChannels.toString()),
    ]);

    connectivitySpecs.addAll([
      MapEntry('SATA 6 Gb/s Ports', mb.sata6GBsAmount.toString()),
      MapEntry('SATA 3 Gb/s Ports', mb.sata3GBsAmount.toString()),
      MapEntry('U.2 Ports', mb.u2PortAmount.toString()),
      MapEntry('Wireless Standard', mb.wirelessNetworkingStandard),
      if (mb.mainPowerType != null)
        MapEntry('Main Power Connector', mb.mainPowerType!),
    ]);

    headersSpecs.addAll([
      if (mb.cpuFanHeaderAmount != null)
        MapEntry('CPU Fan Headers', mb.cpuFanHeaderAmount.toString()),
      if (mb.caseFanHeaderAmount != null)
        MapEntry('Case Fan Headers', mb.caseFanHeaderAmount.toString()),
      if (mb.pumpHeaderAmount != null)
        MapEntry('Pump Headers', mb.pumpHeaderAmount.toString()),
      if (mb.cpuOptionalFanHeaderAmount != null)
        MapEntry(
          'Optional CPU Fan Headers',
          mb.cpuOptionalFanHeaderAmount.toString(),
        ),
      if (mb.argb5vHeaderAmount != null)
        MapEntry('ARGB 5V Headers', mb.argb5vHeaderAmount.toString()),
      if (mb.rgb12vHeaderAmount != null)
        MapEntry('RGB 12V Headers', mb.rgb12vHeaderAmount.toString()),
      if (mb.temperatureSensorHeaderAmount != null)
        MapEntry(
          'Temperature Sensor Headers',
          mb.temperatureSensorHeaderAmount.toString(),
        ),
      if (mb.thunderboltHeaderAmount != null)
        MapEntry('Thunderbolt Headers', mb.thunderboltHeaderAmount.toString()),
      if (mb.comPortHeaderAmount != null)
        MapEntry('COM Port Headers', mb.comPortHeaderAmount.toString()),
      MapEntry('Power Button Header', mb.hasPowerButtonHeader ? 'Yes' : 'No'),
      MapEntry('Reset Button Header', mb.hasResetButtonHeader ? 'Yes' : 'No'),
      MapEntry('Power LED Header', mb.hasPowerLEDHeader ? 'Yes' : 'No'),
      MapEntry('HDD LED Header', mb.hasHDDLEDHeader ? 'Yes' : 'No'),
    ]);

    final featuresSpecs = <MapEntry<String, String>>[
      MapEntry('ECC Support', mb.hasECCSupport ? 'Yes' : 'No'),
      MapEntry('RAID Support', mb.hasRAIDSupport ? 'Yes' : 'No'),
      MapEntry('BIOS Flashback', mb.hasFlashback ? 'Yes' : 'No'),
      MapEntry('Clear CMOS', mb.hasCMOS ? 'Yes' : 'No'),
      if (mb.release != null)
        MapEntry('Release Date', mb.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ];

    return Column(
      children: [
        _buildSpecSection('General', generalSpecs, theme),
        _buildSpecSection('Connectivity', connectivitySpecs, theme),
        _buildSpecSection('Headers & Connectors', headersSpecs, theme),
        _buildSpecSection('Features', featuresSpecs, theme),
      ],
    );
  }

  Widget _buildRamSpecs(MemoryComponent ram, ThemeData theme) {
    final specs = <MapEntry<String, String>>[];

    specs.addAll([
      MapEntry('Speed', '${ram.speed.toStringAsFixed(0)} MHz'),
      MapEntry('Type', ram.ramType),
      MapEntry('Form Factor', ram.formFactor),
      MapEntry('Total Capacity', '${ram.capacity.toStringAsFixed(0)} GB'),
      MapEntry('CAS Latency', ram.casLatency.toStringAsFixed(0)),
      if (ram.timings != null) MapEntry('Timings', ram.timings!),
      MapEntry('Module Quantity', ram.moduleQuantity.toString()),
      MapEntry(
        'Module Capacity',
        '${ram.moduleCapacity.toStringAsFixed(0)} GB',
      ),
      MapEntry('ECC', ram.ecc.toString()),
      MapEntry('Registered Type', ram.registeredType),
      MapEntry('Heat Spreader', ram.haveHeatSpreader ? 'Yes' : 'No'),
      MapEntry('RGB', ram.haveRGB ? 'Yes' : 'No'),
      MapEntry('Height', '${ram.height.toStringAsFixed(0)} mm'),
      MapEntry('Voltage', '${ram.voltage.toStringAsFixed(2)}V'),
      if (ram.release != null)
        MapEntry('Release Date', ram.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return _buildSpecSection('Memory Specifications', specs, theme);
  }

  Widget _buildStorageSpecs(StorageComponent storage, ThemeData theme) {
    final specs = <MapEntry<String, String>>[];

    specs.addAll([
      MapEntry('Series', storage.series),
      MapEntry('Capacity', '${storage.capacity.toStringAsFixed(0)} GB'),
      MapEntry('Type', storage.driveType),
      MapEntry('Form Factor', storage.formFactor),
      MapEntry('Interface', storage.interface),
      MapEntry('NVMe', storage.hasNVMe ? 'Yes' : 'No'),
      if (storage.release != null)
        MapEntry('Release Date', storage.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return _buildSpecSection('Storage Specifications', specs, theme);
  }

  Widget _buildPsuSpecs(PowerSupplyComponent psu, ThemeData theme) {
    final specs = <MapEntry<String, String>>[];

    specs.addAll([
      MapEntry('Power Output', '${psu.powerOutput.toStringAsFixed(0)}W'),
      MapEntry('Form Factor', psu.formFactor),
      if (psu.efficiencyRating != null)
        MapEntry('Efficiency Rating', psu.efficiencyRating!),
      MapEntry('Modularity', psu.modularityType),
      MapEntry('Length', '${psu.length.toStringAsFixed(0)} mm'),
      MapEntry('Fanless Mode', psu.isFanless ? 'Yes' : 'No'),
      if (psu.release != null)
        MapEntry('Release Date', psu.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return _buildSpecSection('Power Supply Specifications', specs, theme);
  }

  Widget _buildCaseSpecs(CaseComponent case_, ThemeData theme) {
    final generalSpecs = <MapEntry<String, String>>[];
    final dimensionsSpecs = <MapEntry<String, String>>[];
    final compatibilitySpecs = <MapEntry<String, String>>[];

    generalSpecs.addAll([
      MapEntry('Form Factor', case_.formFactor),
      MapEntry(
        'Power Supply Shrouded',
        case_.powerSupplyShrouded ? 'Yes' : 'No',
      ),
      if (case_.powerSupplyAmount != null)
        MapEntry(
          'Included PSU',
          '${case_.powerSupplyAmount!.toStringAsFixed(0)}W',
        ),
      MapEntry(
        'Transparent Side Panel',
        case_.hasTransparentSidePanel ? 'Yes' : 'No',
      ),
      if (case_.sidePanelType != null)
        MapEntry('Side Panel Type', case_.sidePanelType!),
      MapEntry(
        'Rear Connecting MB Support',
        case_.supportsRearConnectingMotherboard ? 'Yes' : 'No',
      ),
    ]);

    dimensionsSpecs.addAll([
      MapEntry('Width', '${case_.width.toStringAsFixed(0)} mm'),
      MapEntry('Height', '${case_.height.toStringAsFixed(0)} mm'),
      MapEntry('Depth', '${case_.depth.toStringAsFixed(0)} mm'),
      MapEntry('Volume', '${case_.volume.toStringAsFixed(1)} L'),
      MapEntry('Weight', '${case_.weight.toStringAsFixed(2)} kg'),
    ]);

    compatibilitySpecs.addAll([
      MapEntry(
        'Max GPU Length',
        '${case_.maxVideoCardLength.toStringAsFixed(0)} mm',
      ),
      MapEntry('Max Cooler Height', '${case_.maxCPUCoolerHeight} mm'),
      MapEntry('Internal 3.5" Bays', case_.internal35BayAmount.toString()),
      MapEntry('Internal 2.5" Bays', case_.internal25BayAmount.toString()),
      MapEntry('External 3.5" Bays', case_.external35BayAmount.toString()),
      MapEntry('External 5.25" Bays', case_.external525BayAmount.toString()),
      MapEntry('Expansion Slots', case_.expansionSlotAmount.toString()),
      if (case_.release != null)
        MapEntry('Release Date', case_.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return Column(
      children: [
        _buildSpecSection('General', generalSpecs, theme),
        _buildSpecSection('Dimensions', dimensionsSpecs, theme),
        _buildSpecSection('Compatibility', compatibilitySpecs, theme),
      ],
    );
  }

  Widget _buildCoolerSpecs(CoolerComponent cooler, ThemeData theme) {
    final specs = <MapEntry<String, String>>[];

    specs.addAll([
      MapEntry('Type', cooler.isWaterCooled ? 'Water Cooled' : 'Air Cooled'),
      MapEntry('Height', '${cooler.height.toStringAsFixed(0)} mm'),
      if (cooler.radiatorSize != null)
        MapEntry(
          'Radiator Size',
          '${cooler.radiatorSize!.toStringAsFixed(0)} mm',
        ),
      if (cooler.fanSize != null)
        MapEntry('Fan Size', '${cooler.fanSize!.toStringAsFixed(0)} mm'),
      MapEntry('Fan Quantity', cooler.fanQuantity.toString()),
      if (cooler.minFanRotationSpeed != null)
        MapEntry(
          'Min Fan Speed',
          '${cooler.minFanRotationSpeed!.toStringAsFixed(0)} RPM',
        ),
      if (cooler.maxFanRotationSpeed != null)
        MapEntry(
          'Max Fan Speed',
          '${cooler.maxFanRotationSpeed!.toStringAsFixed(0)} RPM',
        ),
      if (cooler.minNoiseLevel != null)
        MapEntry(
          'Min Noise',
          '${cooler.minNoiseLevel!.toStringAsFixed(1)} dBA',
        ),
      if (cooler.maxNoiseLevel != null)
        MapEntry(
          'Max Noise',
          '${cooler.maxNoiseLevel!.toStringAsFixed(1)} dBA',
        ),
      MapEntry('Fanless Operation', cooler.canOperateFanless ? 'Yes' : 'No'),
      if (cooler.release != null)
        MapEntry('Release Date', cooler.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return _buildSpecSection('Cooler Specifications', specs, theme);
  }

  Widget _buildCaseFanSpecs(CaseFanComponent fan, ThemeData theme) {
    final specs = <MapEntry<String, String>>[];

    specs.addAll([
      MapEntry('Size', '${fan.size.toStringAsFixed(0)} mm'),
      MapEntry('Quantity', fan.quantity.toString()),
      MapEntry('Min Airflow', '${fan.minAirflow.toStringAsFixed(0)} CFM'),
      if (fan.maxAirflow != null)
        MapEntry('Max Airflow', '${fan.maxAirflow!.toStringAsFixed(0)} CFM'),
      MapEntry('Min Noise', '${fan.minNoiseLevel.toStringAsFixed(1)} dBA'),
      if (fan.maxNoiseLevel != null)
        MapEntry('Max Noise', '${fan.maxNoiseLevel!.toStringAsFixed(1)} dBA'),
      MapEntry('PWM', fan.pulseWidthModulation ? 'Yes' : 'No'),
      MapEntry('LED Type', fan.ledType ?? 'None'),
      MapEntry('Connector Type', fan.connectorType ?? 'N/A'),
      MapEntry('Controller Type', fan.controllerType),
      MapEntry(
        'Static Pressure',
        '${fan.staticPressureAmount.toStringAsFixed(2)} mmH2O',
      ),
      MapEntry('Flow Direction', fan.flowDirection),
      if (fan.release != null)
        MapEntry('Release Date', fan.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return _buildSpecSection('Case Fan Specifications', specs, theme);
  }

  Widget _buildMonitorSpecs(MonitorComponent monitor, ThemeData theme) {
    final displaySpecs = <MapEntry<String, String>>[];
    final performanceSpecs = <MapEntry<String, String>>[];

    displaySpecs.addAll([
      MapEntry('Screen Size', '${monitor.screenSize.toStringAsFixed(1)}"'),
      MapEntry(
        'Resolution',
        '${monitor.horizontalResolution}x${monitor.verticalResolution}',
      ),
      MapEntry('Aspect Ratio', monitor.aspectRatio),
      MapEntry('Panel Type', monitor.panelType),
      MapEntry('Viewing Angle', monitor.viewingAngle),
      if (monitor.maxBrightness != null)
        MapEntry(
          'Max Brightness',
          '${monitor.maxBrightness!.toStringAsFixed(0)} nits',
        ),
      if (monitor.highDynamicRangeType != null)
        MapEntry('HDR', monitor.highDynamicRangeType!),
    ]);

    performanceSpecs.addAll([
      MapEntry(
        'Refresh Rate',
        '${monitor.maxRefreshRate.toStringAsFixed(0)} Hz',
      ),
      MapEntry(
        'Response Time',
        '${monitor.responseTime.toStringAsFixed(1)} ms',
      ),
      MapEntry('Adaptive Sync', monitor.adaptiveSyncType),
      if (monitor.release != null)
        MapEntry('Release Date', monitor.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ]);

    return Column(
      children: [
        _buildSpecSection('Display', displaySpecs, theme),
        _buildSpecSection('Performance', performanceSpecs, theme),
      ],
    );
  }

  Widget _buildGenericSpecs(BaseComponent component, ThemeData theme) {
    final specs = <MapEntry<String, String>>[
      MapEntry('Manufacturer', component.manufacturer),
      if (component.release != null)
        MapEntry('Release Date', component.release!.toString().split(' ')[0]),
      if (component.lowestPrice != null)
        MapEntry('Price', 'zł${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ];

    return _buildSpecSection('General Information', specs, theme);
  }
}

// Helper for display name
String _getComponentTypeDisplay(ComponentType type) {
  switch (type) {
    case ComponentType.cpu: return 'Desktop Processor';
    case ComponentType.gpu: return 'Graphics Card';
    case ComponentType.motherboard: return 'Motherboard';
    case ComponentType.ram: return 'Memory';
    case ComponentType.storage: return 'Storage';
    case ComponentType.psu: return 'Power Supply';
    case ComponentType.pcCase: return 'Case';
    case ComponentType.cooler: return 'CPU Cooler';
    case ComponentType.caseFan: return 'Case Fan';
    case ComponentType.monitor: return 'Monitor';
  }
}

Map<String, String> buildComparisonMetrics(BaseComponent component) {
  final specs = <String, String>{};
  switch (component.type) {
    case ComponentType.cpu:
      final cpu = component as CPUComponent;
      specs['Cores'] = '${cpu.coreTotal}';
      specs['Base/Boost'] =
          '${cpu.basePerformanceSpeed ?? '-'} / ${cpu.boostPerformanceSpeed ?? '-'} GHz';
      specs['Arch'] = cpu.microarchitecture;
      specs['TDP'] = '${cpu.thermalDesignPower.toStringAsFixed(0)}W';
      specs['Graphics'] = cpu.graphics;
      break;
    case ComponentType.gpu:
      final gpu = component as GPUComponent;
      specs['Chipset'] = gpu.chipset;
      specs['VRAM'] = '${gpu.videoMemoryAmount.toStringAsFixed(0)} GB';
      specs['Base/Boost'] =
          '${gpu.coreBaseClockSpeed.toStringAsFixed(0)}/${gpu.coreBoostClockSpeed.toStringAsFixed(0)} MHz';
      specs['Length'] = '${gpu.length.toStringAsFixed(0)} mm';
      break;
    case ComponentType.motherboard:
      final mb = component as MotherboardComponent;
      specs['Socket'] = mb.socketType;
      specs['Form Factor'] = mb.formFactor;
      specs['RAM Slots'] = mb.ramSlotsAmount.toString();
      specs['Chipset'] = mb.chipsetType;
      break;
    case ComponentType.ram:
      final ram = component as MemoryComponent;
      specs['Speed'] = '${ram.speed.toStringAsFixed(0)} MHz';
      specs['Type'] = ram.ramType;
      specs['Modules'] =
          '${ram.moduleQuantity}x${ram.moduleCapacity.toStringAsFixed(0)}GB';
      break;
    case ComponentType.storage:
      final storage = component as StorageComponent;
      specs['Capacity'] = '${storage.capacity.toStringAsFixed(0)} GB';
      specs['Type'] = storage.driveType;
      specs['Interface'] = storage.interface;
      break;
    case ComponentType.psu:
      final psu = component as PowerSupplyComponent;
      specs['Wattage'] = '${psu.powerOutput.toStringAsFixed(0)}W';
      specs['Efficiency'] = psu.efficiencyRating ?? 'N/A';
      specs['Modularity'] = psu.modularityType;
      break;
    case ComponentType.pcCase:
      final pcCase = component as CaseComponent;
      specs['Form Factor'] = pcCase.formFactor;
      specs['Max GPU'] = '${pcCase.maxVideoCardLength.toStringAsFixed(0)} mm';
      specs['Max Cooler'] = '${pcCase.maxCPUCoolerHeight} mm';
      break;
    case ComponentType.cooler:
      final cooler = component as CoolerComponent;
      specs['Type'] = cooler.isWaterCooled ? 'Water' : 'Air';
      specs['Height'] = '${cooler.height.toStringAsFixed(0)} mm';
      specs['Fan Qty'] = cooler.fanQuantity.toString();
      break;
    case ComponentType.caseFan:
      final fan = component as CaseFanComponent;
      specs['Size'] = '${fan.size.toStringAsFixed(0)} mm';
      specs['Airflow'] = fan.maxAirflow != null
          ? '${fan.minAirflow.toStringAsFixed(0)}-${fan.maxAirflow!.toStringAsFixed(0)} CFM'
          : '${fan.minAirflow.toStringAsFixed(0)} CFM';
      specs['Noise'] = fan.maxNoiseLevel != null
          ? '${fan.minNoiseLevel.toStringAsFixed(1)}-${fan.maxNoiseLevel!.toStringAsFixed(1)} dBA'
          : '${fan.minNoiseLevel.toStringAsFixed(1)} dBA';
      break;
    case ComponentType.monitor:
      final monitor = component as MonitorComponent;
      specs['Size'] = '${monitor.screenSize.toStringAsFixed(1)}"';
      specs['Resolution'] =
          '${monitor.horizontalResolution}x${monitor.verticalResolution}';
      specs['Refresh Rate'] =
          '${monitor.maxRefreshRate.toStringAsFixed(0)} Hz';
      break;
  }
  return specs;
}

class _MobileProductCard extends ConsumerWidget {
  final BaseComponent product;
  final Function(BaseComponent)? onComponentSelected;

  const _MobileProductCard({
    required this.product,
    this.onComponentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specs = buildComparisonMetrics(product);
    final typeLabel = _getComponentTypeDisplay(product.type);

    // Image logic
    final rawImageUrl = product.imageUrl.trim();
    String? imageUrl;
    if (rawImageUrl.isNotEmpty) {
      final guidPattern = RegExp(
        r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
      );
      if (guidPattern.hasMatch(rawImageUrl)) {
        imageUrl = '$apiBaseUrl/Images/download/$rawImageUrl';
      } else if (rawImageUrl.startsWith('http://') ||
          rawImageUrl.startsWith('https://')) {
        imageUrl = rawImageUrl;
      } else if (rawImageUrl.startsWith('/')) {
        imageUrl = '$apiBaseUrl$rawImageUrl';
      } else {
        imageUrl = '$apiBaseUrl/$rawImageUrl';
      }
    }

    return Card(
      color: const Color(0xFF13131F), // Dark card background like reference
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.white.withOpacity(0.05)),
      ),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
            showDialog(
            context: context,
            builder: (context) => _ComponentSpecsDialog(component: product),
            );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Container
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white10),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: imageUrl != null
                        ? Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (c, o, s) => const Icon(
                                Icons.broken_image,
                                color: Colors.grey),
                          )
                        : const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                  const SizedBox(width: 16),
                  // Title and Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          typeLabel,
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Specs Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: _buildSpecsGrid(specs, product),
            ),
            
            const SizedBox(height: 16),
            const Divider(height: 1, color: Colors.white10),
            
            // Price and Action
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                  'zł${product.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00E5FF), // Cyan color from reference
                    ),
                  ),
                  SizedBox(
                    height: 36,
                    child: ElevatedButton.icon(
                      onPressed: () {
                           if (onComponentSelected != null) {
                onComponentSelected!(product);
                Navigator.pop(context);
              } else {
                ref.read(buildProvider.notifier).addComponent(product);
                context.go('/build-now');
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                }
              }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00E676), // Green color
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                      ),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSpecsGrid(Map<String, String> specs, BaseComponent product) {
    final items = specs.entries.toList();
    final displayItems = items.take(5).toList();
    
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ...displayItems.map((e) => _buildSpecItem(e.key, e.value)),
             _buildRatingItem(product.averageRating ?? 0),
          ],
        );
      },
    );
  }
  
  Widget _buildSpecItem(String label, String value) {
      return SizedBox(
          width: 90, 
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
          ),
      );
  }

   Widget _buildRatingItem(double rating) {
      return SizedBox(
          width: 90,
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                  Text('Rating', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                  const SizedBox(height: 2),
                  _RatingStars(rating: rating),
              ],
          ),
      );
  }
}
