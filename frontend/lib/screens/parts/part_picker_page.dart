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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/component_compatibility_provider.dart'
    as compatibility;
import 'package:frontend/models/api_constants.dart';
import 'package:flutter/foundation.dart';
import 'package:frontend/screens/builder/build_now_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

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

  const PartPickerPage({
    super.key,
    required this.componentType,
    this.currentBuild,
    this.onComponentSelected,
    this.initialPage = 1,
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
  late int _currentPage;

  // Filter state
  final Set<String> _selectedManufacturers = {};
  RangeValues? _priceRange; // Will be initialized based on products

  // Component-specific filter states
  final Set<String> _selectedCpuSeries = {};
  final Set<String> _selectedCpuSockets = {};
  bool? _cpuIncludesCooler;

  final Set<String> _selectedMotherboardSockets = {};
  final Set<String> _selectedMotherboardChipsets = {};
  final Set<String> _selectedMotherboardFormFactors = {};

  final Set<String> _selectedRamTypes = {};
  final Set<int> _selectedRamModules = {};
  bool? _ramHasRgb;

  final Set<String> _selectedStorageTypes = {};
  final Set<String> _selectedStorageInterfaces = {};

  final Set<String> _selectedPsuWattages = {};
  final Set<String> _selectedPsuEfficiencies = {};
  final Set<String> _selectedPsuModularities = {};

  final Set<String> _selectedCaseFormFactors = {};

  // GPU filters
  final Set<String> _selectedGpuChipsets = {};
  RangeValues? _gpuVramRange; // Will be initialized based on products
  final Set<String> _selectedGpuMemoryTypes = {};
  final Set<String> _selectedGpuCoolingTypes = {};
  final Set<String> _selectedGpuFrameSyncs = {};

  // Cooler filters
  bool? _coolerIsWaterCooled;
  RangeValues? _coolerHeightRange;
  RangeValues? _coolerRadiatorSizeRange;
  RangeValues? _coolerFanSizeRange;

  // Case Fan filters
  RangeValues? _caseFanSizeRange;
  final Set<String> _selectedCaseFanLedTypes = {};
  final Set<String> _selectedCaseFanFlowDirections = {};
  final Set<String> _selectedCaseFanConnectorTypes = {};

  // Monitor filters
  RangeValues? _monitorScreenSizeRange;
  final Set<String> _selectedMonitorPanelTypes = {};
  RangeValues? _monitorRefreshRateRange;
  final Set<String> _selectedMonitorAdaptiveSyncTypes = {};
  final Set<String> _selectedMonitorAspectRatios = {};

  // Case filters (additional)
  RangeValues? _caseMaxGpuLengthRange;
  RangeValues? _caseMaxCoolerHeightRange;

  // Compatibility filter
  bool _enableCompatibilityFilter = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _currentPage = _sanitizePage(widget.initialPage);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentPage());
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PartPickerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.componentType != oldWidget.componentType ||
        widget.initialPage != oldWidget.initialPage) {
      final nextPage = _sanitizePage(widget.initialPage);
      _currentPage = nextPage;
      _loadCurrentPage(force: true, targetPage: nextPage);
    }
  }

  void _onSearchChanged() {
    setState(() {}); // Trigger rebuild to apply search filter
  }

  int _sanitizePage(int page) => page < 1 ? 1 : page;

  void _loadCurrentPage({bool force = false, int? targetPage}) {
    final notifier = ref.read(
      componentPagingProvider(widget.componentType).notifier,
    );
    final desiredPage = targetPage ?? _currentPage;
    if (force) {
      notifier.goToPage(desiredPage);
    } else {
      notifier.ensurePage(desiredPage);
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
    _loadCurrentPage(force: true, targetPage: sanitized);
    _updateUrl(sanitized);
  }

  void _updateUrl(int page) {
    if (!mounted) return;
    final typeName = widget.componentType.name;
    final location = '/parts/$typeName?page=$page';
    GoRouter.of(context).go(location);
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
  List<BaseComponent> _filterProducts(
    List<BaseComponent> products, {
    Set<String>? compatibleIds,
  }) {
    return products.where((product) {
      // Search filter
      final searchText = _searchController.text.toLowerCase();
      if (searchText.isNotEmpty) {
        if (!product.name.toLowerCase().contains(searchText) &&
            !product.manufacturer.toLowerCase().contains(searchText)) {
          return false;
        }
      }

      // Manufacturer filter
      if (_selectedManufacturers.isNotEmpty &&
          !_selectedManufacturers.contains(product.manufacturer)) {
        return false;
      }

      // Price filter
      if (_priceRange != null) {
        final price = product.lowestPrice ?? 0;
        if (price < _priceRange!.start || price > _priceRange!.end) {
          return false;
        }
      }

      // Component-specific filters
      switch (widget.componentType) {
        case ComponentType.cpu:
          if (product is CPUComponent) {
            if (_selectedCpuSeries.isNotEmpty &&
                !_selectedCpuSeries.contains(product.series)) {
              return false;
            }
            if (_selectedCpuSockets.isNotEmpty &&
                !_selectedCpuSockets.contains(product.socketType)) {
              return false;
            }
            if (_cpuIncludesCooler != null &&
                product.includesCooler != _cpuIncludesCooler) {
              return false;
            }
          }
          break;
        case ComponentType.motherboard:
          if (product is MotherboardComponent) {
            if (_selectedMotherboardSockets.isNotEmpty &&
                !_selectedMotherboardSockets.contains(product.socketType)) {
              return false;
            }
            if (_selectedMotherboardChipsets.isNotEmpty &&
                !_selectedMotherboardChipsets.contains(product.chipsetType)) {
              return false;
            }
            if (_selectedMotherboardFormFactors.isNotEmpty &&
                !_selectedMotherboardFormFactors.contains(product.formFactor)) {
              return false;
            }
          }
          break;
        case ComponentType.ram:
          if (product is MemoryComponent) {
            if (_selectedRamTypes.isNotEmpty &&
                !_selectedRamTypes.contains(product.ramType)) {
              return false;
            }
            if (_selectedRamModules.isNotEmpty &&
                !_selectedRamModules.contains(product.moduleQuantity)) {
              return false;
            }
            if (_ramHasRgb != null && product.haveRGB != _ramHasRgb) {
              return false;
            }
          }
          break;
        case ComponentType.storage:
          if (product is StorageComponent) {
            if (_selectedStorageTypes.isNotEmpty &&
                !_selectedStorageTypes.contains(product.driveType)) {
              return false;
            }
            if (_selectedStorageInterfaces.isNotEmpty &&
                !_selectedStorageInterfaces.contains(product.interface)) {
              return false;
            }
          }
          break;
        case ComponentType.psu:
          if (product is PowerSupplyComponent) {
            // Wattage filter
            if (_selectedPsuWattages.isNotEmpty) {
              bool matchesWattage = false;
              for (final range in _selectedPsuWattages) {
                final parts = range.split('-');
                if (parts.length == 2) {
                  final min = int.tryParse(parts[0]) ?? 0;
                  final max = int.tryParse(parts[1]) ?? 9999;
                  if (product.powerOutput >= min &&
                      product.powerOutput <= max) {
                    matchesWattage = true;
                    break;
                  }
                }
              }
              if (!matchesWattage) return false;
            }
            if (_selectedPsuEfficiencies.isNotEmpty &&
                product.efficiencyRating != null &&
                !_selectedPsuEfficiencies.contains(product.efficiencyRating)) {
              return false;
            }
            if (_selectedPsuModularities.isNotEmpty &&
                !_selectedPsuModularities.contains(product.modularityType)) {
              return false;
            }
          }
          break;
        case ComponentType.pcCase:
          if (product is CaseComponent) {
            if (_selectedCaseFormFactors.isNotEmpty &&
                !_selectedCaseFormFactors.contains(product.formFactor)) {
              return false;
            }
            // Max GPU length filter
            if (_caseMaxGpuLengthRange != null &&
                (product.maxVideoCardLength < _caseMaxGpuLengthRange!.start ||
                    product.maxVideoCardLength > _caseMaxGpuLengthRange!.end)) {
              return false;
            }
            // Max Cooler height filter
            if (_caseMaxCoolerHeightRange != null &&
                (product.maxCPUCoolerHeight <
                        _caseMaxCoolerHeightRange!.start ||
                    product.maxCPUCoolerHeight >
                        _caseMaxCoolerHeightRange!.end)) {
              return false;
            }
          }
          break;
        case ComponentType.gpu:
          if (product is GPUComponent) {
            if (_selectedGpuChipsets.isNotEmpty &&
                !_selectedGpuChipsets.contains(product.chipset)) {
              return false;
            }
            if (_gpuVramRange != null &&
                (product.videoMemoryAmount < _gpuVramRange!.start ||
                    product.videoMemoryAmount > _gpuVramRange!.end)) {
              return false;
            }
            if (_selectedGpuMemoryTypes.isNotEmpty &&
                !_selectedGpuMemoryTypes.contains(product.videoMemoryType)) {
              return false;
            }
            if (_selectedGpuCoolingTypes.isNotEmpty &&
                !_selectedGpuCoolingTypes.contains(product.coolingType)) {
              return false;
            }
            if (_selectedGpuFrameSyncs.isNotEmpty &&
                !_selectedGpuFrameSyncs.contains(product.frameSync)) {
              return false;
            }
          }
          break;
        case ComponentType.cooler:
          if (product is CoolerComponent) {
            if (_coolerIsWaterCooled != null &&
                product.isWaterCooled != _coolerIsWaterCooled) {
              return false;
            }
            if (_coolerHeightRange != null &&
                (product.height < _coolerHeightRange!.start ||
                    product.height > _coolerHeightRange!.end)) {
              return false;
            }
            if (_coolerRadiatorSizeRange != null &&
                product.radiatorSize != null &&
                (product.radiatorSize! < _coolerRadiatorSizeRange!.start ||
                    product.radiatorSize! > _coolerRadiatorSizeRange!.end)) {
              return false;
            }
            if (_coolerFanSizeRange != null &&
                product.fanSize != null &&
                (product.fanSize! < _coolerFanSizeRange!.start ||
                    product.fanSize! > _coolerFanSizeRange!.end)) {
              return false;
            }
          }
          break;
        case ComponentType.caseFan:
          if (product is CaseFanComponent) {
            if (_caseFanSizeRange != null &&
                (product.size < _caseFanSizeRange!.start ||
                    product.size > _caseFanSizeRange!.end)) {
              return false;
            }
            if (_selectedCaseFanLedTypes.isNotEmpty &&
                product.ledType != null &&
                !_selectedCaseFanLedTypes.contains(product.ledType)) {
              return false;
            }
            if (_selectedCaseFanFlowDirections.isNotEmpty &&
                !_selectedCaseFanFlowDirections.contains(
                  product.flowDirection,
                )) {
              return false;
            }
            if (_selectedCaseFanConnectorTypes.isNotEmpty &&
                product.connectorType != null &&
                !_selectedCaseFanConnectorTypes.contains(
                  product.connectorType,
                )) {
              return false;
            }
          }
          break;
        case ComponentType.monitor:
          if (product is MonitorComponent) {
            if (_monitorScreenSizeRange != null &&
                (product.screenSize < _monitorScreenSizeRange!.start ||
                    product.screenSize > _monitorScreenSizeRange!.end)) {
              return false;
            }
            if (_selectedMonitorPanelTypes.isNotEmpty &&
                !_selectedMonitorPanelTypes.contains(product.panelType)) {
              return false;
            }
            if (_monitorRefreshRateRange != null &&
                (product.maxRefreshRate < _monitorRefreshRateRange!.start ||
                    product.maxRefreshRate > _monitorRefreshRateRange!.end)) {
              return false;
            }
            if (_selectedMonitorAdaptiveSyncTypes.isNotEmpty &&
                !_selectedMonitorAdaptiveSyncTypes.contains(
                  product.adaptiveSyncType,
                )) {
              return false;
            }
            if (_selectedMonitorAspectRatios.isNotEmpty &&
                !_selectedMonitorAspectRatios.contains(product.aspectRatio)) {
              return false;
            }
          }
          break;
      }

      // Compatibility filter
      if (_enableCompatibilityFilter && compatibleIds != null) {
        // If compatibility filter is enabled, only show products that are compatible
        // with at least one component in the current build
        if (!compatibleIds.contains(product.id)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final pagingState = ref.watch(
      componentPagingProvider(widget.componentType),
    );
    final pagingNotifier = ref.read(
      componentPagingProvider(widget.componentType).notifier,
    );

    return Scaffold(
      // TODO: Implement a responsive layout that switches to a single-column view on mobile.
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // The main layout is a Column containing the navigation bar and the page body.
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
                  /// The left panel containing the build summary and all filter options.
                  SizedBox(
                    width: 280,
                    child: Builder(
                      builder: (context) {
                        if (pagingState.isInitialLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final products = pagingState.items;
                        if (pagingState.errorMessage != null &&
                            products.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        // Initialize price range if not set
                        if (products.isNotEmpty) {
                          final maxPrice = products
                              .map((p) => p.lowestPrice ?? 0)
                              .fold<double>(
                                0,
                                (max, price) => price > max ? price : max,
                              );
                          final double cappedMax = maxPrice > 0
                              ? maxPrice
                              : 10000.0;
                          if (_priceRange == null) {
                            _priceRange = RangeValues(0, cappedMax);
                          } else if (cappedMax > _priceRange!.end) {
                            _priceRange = RangeValues(
                              _priceRange!.start,
                              cappedMax,
                            );
                          }
                        }
                        // Initialize component-specific range filters
                        if (widget.componentType == ComponentType.gpu &&
                            products.isNotEmpty) {
                          final gpus = products
                              .whereType<GPUComponent>()
                              .toList();
                          if (gpus.isNotEmpty) {
                            final maxVram = gpus
                                .map((p) => p.videoMemoryAmount)
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedMax = maxVram > 0
                                ? maxVram
                                : 24.0;
                            if (_gpuVramRange == null) {
                              _gpuVramRange = RangeValues(0, cappedMax);
                            } else if (cappedMax > _gpuVramRange!.end) {
                              _gpuVramRange = RangeValues(
                                _gpuVramRange!.start,
                                cappedMax,
                              );
                            }
                          }
                        }
                        if (widget.componentType == ComponentType.cooler &&
                            products.isNotEmpty) {
                          final coolers = products
                              .whereType<CoolerComponent>()
                              .toList();
                          if (coolers.isNotEmpty) {
                            final maxHeight = coolers
                                .map((p) => p.height)
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedMax = maxHeight > 0
                                ? maxHeight
                                : 200.0;
                            if (_coolerHeightRange == null) {
                              _coolerHeightRange = RangeValues(0, cappedMax);
                            } else if (cappedMax > _coolerHeightRange!.end) {
                              _coolerHeightRange = RangeValues(
                                _coolerHeightRange!.start,
                                cappedMax,
                              );
                            }
                          }
                        }
                        if (widget.componentType == ComponentType.caseFan &&
                            products.isNotEmpty) {
                          final fans = products
                              .whereType<CaseFanComponent>()
                              .toList();
                          if (fans.isNotEmpty) {
                            final maxSize = fans
                                .map((p) => p.size)
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedMax = maxSize > 0
                                ? maxSize
                                : 200.0;
                            if (_caseFanSizeRange == null) {
                              _caseFanSizeRange = RangeValues(0, cappedMax);
                            } else if (cappedMax > _caseFanSizeRange!.end) {
                              _caseFanSizeRange = RangeValues(
                                _caseFanSizeRange!.start,
                                cappedMax,
                              );
                            }
                          }
                        }
                        if (widget.componentType == ComponentType.monitor &&
                            products.isNotEmpty) {
                          final monitors = products
                              .whereType<MonitorComponent>()
                              .toList();
                          if (monitors.isNotEmpty) {
                            final maxSize = monitors
                                .map((p) => p.screenSize)
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedSize = maxSize > 0
                                ? maxSize
                                : 50.0;
                            if (_monitorScreenSizeRange == null) {
                              _monitorScreenSizeRange = RangeValues(
                                0,
                                cappedSize,
                              );
                            } else if (cappedSize >
                                _monitorScreenSizeRange!.end) {
                              _monitorScreenSizeRange = RangeValues(
                                _monitorScreenSizeRange!.start,
                                cappedSize,
                              );
                            }

                            final maxRefresh = monitors
                                .map((p) => p.maxRefreshRate)
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedRefresh = maxRefresh > 0
                                ? maxRefresh
                                : 240.0;
                            if (_monitorRefreshRateRange == null) {
                              _monitorRefreshRateRange = RangeValues(
                                0,
                                cappedRefresh,
                              );
                            } else if (cappedRefresh >
                                _monitorRefreshRateRange!.end) {
                              _monitorRefreshRateRange = RangeValues(
                                _monitorRefreshRateRange!.start,
                                cappedRefresh,
                              );
                            }
                          }
                        }
                        if (widget.componentType == ComponentType.pcCase &&
                            products.isNotEmpty) {
                          final cases = products
                              .whereType<CaseComponent>()
                              .toList();
                          if (cases.isNotEmpty) {
                            final maxGpuLength = cases
                                .map((p) => p.maxVideoCardLength)
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedGpu = maxGpuLength > 0
                                ? maxGpuLength
                                : 500.0;
                            if (_caseMaxGpuLengthRange == null) {
                              _caseMaxGpuLengthRange = RangeValues(
                                0,
                                cappedGpu,
                              );
                            } else if (cappedGpu >
                                _caseMaxGpuLengthRange!.end) {
                              _caseMaxGpuLengthRange = RangeValues(
                                _caseMaxGpuLengthRange!.start,
                                cappedGpu,
                              );
                            }

                            final maxCoolerHeight = cases
                                .map((p) => p.maxCPUCoolerHeight.toDouble())
                                .fold<double>(
                                  0,
                                  (max, val) => val > max ? val : max,
                                );
                            final double cappedCooler = maxCoolerHeight > 0
                                ? maxCoolerHeight
                                : 200.0;
                            if (_caseMaxCoolerHeightRange == null) {
                              _caseMaxCoolerHeightRange = RangeValues(
                                0,
                                cappedCooler,
                              );
                            } else if (cappedCooler >
                                _caseMaxCoolerHeightRange!.end) {
                              _caseMaxCoolerHeightRange = RangeValues(
                                _caseMaxCoolerHeightRange!.start,
                                cappedCooler,
                              );
                            }
                          }
                        }
                        // Get current build from provider if not provided
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
                          // Filter state and callbacks
                          selectedManufacturers: _selectedManufacturers,
                          onManufacturerChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedManufacturers.add(val);
                              } else {
                                _selectedManufacturers.remove(val);
                              }
                            });
                          },
                          priceRange:
                              _priceRange ?? const RangeValues(0, 10000),
                          onPriceRangeChanged: (range) {
                            setState(() {
                              _priceRange = range;
                            });
                          },
                          // CPU filters
                          selectedCpuSeries: _selectedCpuSeries,
                          onCpuSeriesChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedCpuSeries.add(val);
                              } else {
                                _selectedCpuSeries.remove(val);
                              }
                            });
                          },
                          selectedCpuSockets: _selectedCpuSockets,
                          onCpuSocketChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedCpuSockets.add(val);
                              } else {
                                _selectedCpuSockets.remove(val);
                              }
                            });
                          },
                          cpuIncludesCooler: _cpuIncludesCooler,
                          onCpuIncludesCoolerChanged: (val) {
                            setState(() {
                              _cpuIncludesCooler = val;
                            });
                          },
                          // Motherboard filters
                          selectedMotherboardSockets:
                              _selectedMotherboardSockets,
                          onMotherboardSocketChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedMotherboardSockets.add(val);
                              } else {
                                _selectedMotherboardSockets.remove(val);
                              }
                            });
                          },
                          selectedMotherboardChipsets:
                              _selectedMotherboardChipsets,
                          onMotherboardChipsetChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedMotherboardChipsets.add(val);
                              } else {
                                _selectedMotherboardChipsets.remove(val);
                              }
                            });
                          },
                          selectedMotherboardFormFactors:
                              _selectedMotherboardFormFactors,
                          onMotherboardFormFactorChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedMotherboardFormFactors.add(val);
                              } else {
                                _selectedMotherboardFormFactors.remove(val);
                              }
                            });
                          },
                          // RAM filters
                          selectedRamTypes: _selectedRamTypes,
                          onRamTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedRamTypes.add(val);
                              } else {
                                _selectedRamTypes.remove(val);
                              }
                            });
                          },
                          selectedRamModules: _selectedRamModules,
                          onRamModuleChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedRamModules.add(val);
                              } else {
                                _selectedRamModules.remove(val);
                              }
                            });
                          },
                          ramHasRgb: _ramHasRgb,
                          onRamHasRgbChanged: (val) {
                            setState(() {
                              _ramHasRgb = val;
                            });
                          },
                          // Storage filters
                          selectedStorageTypes: _selectedStorageTypes,
                          onStorageTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedStorageTypes.add(val);
                              } else {
                                _selectedStorageTypes.remove(val);
                              }
                            });
                          },
                          selectedStorageInterfaces: _selectedStorageInterfaces,
                          onStorageInterfaceChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedStorageInterfaces.add(val);
                              } else {
                                _selectedStorageInterfaces.remove(val);
                              }
                            });
                          },
                          // PSU filters
                          selectedPsuWattages: _selectedPsuWattages,
                          onPsuWattageChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedPsuWattages.add(val);
                              } else {
                                _selectedPsuWattages.remove(val);
                              }
                            });
                          },
                          selectedPsuEfficiencies: _selectedPsuEfficiencies,
                          onPsuEfficiencyChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedPsuEfficiencies.add(val);
                              } else {
                                _selectedPsuEfficiencies.remove(val);
                              }
                            });
                          },
                          selectedPsuModularities: _selectedPsuModularities,
                          onPsuModularityChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedPsuModularities.add(val);
                              } else {
                                _selectedPsuModularities.remove(val);
                              }
                            });
                          },
                          // Case filters
                          selectedCaseFormFactors: _selectedCaseFormFactors,
                          onCaseFormFactorChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedCaseFormFactors.add(val);
                              } else {
                                _selectedCaseFormFactors.remove(val);
                              }
                            });
                          },
                          caseMaxGpuLengthRange: _caseMaxGpuLengthRange,
                          onCaseMaxGpuLengthRangeChanged: (range) {
                            setState(() {
                              _caseMaxGpuLengthRange = range;
                            });
                          },
                          caseMaxCoolerHeightRange: _caseMaxCoolerHeightRange,
                          onCaseMaxCoolerHeightRangeChanged: (range) {
                            setState(() {
                              _caseMaxCoolerHeightRange = range;
                            });
                          },
                          // GPU filters
                          selectedGpuChipsets: _selectedGpuChipsets,
                          onGpuChipsetChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedGpuChipsets.add(val);
                              } else {
                                _selectedGpuChipsets.remove(val);
                              }
                            });
                          },
                          gpuVramRange: _gpuVramRange,
                          onGpuVramRangeChanged: (range) {
                            setState(() {
                              _gpuVramRange = range;
                            });
                          },
                          selectedGpuMemoryTypes: _selectedGpuMemoryTypes,
                          onGpuMemoryTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedGpuMemoryTypes.add(val);
                              } else {
                                _selectedGpuMemoryTypes.remove(val);
                              }
                            });
                          },
                          selectedGpuCoolingTypes: _selectedGpuCoolingTypes,
                          onGpuCoolingTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedGpuCoolingTypes.add(val);
                              } else {
                                _selectedGpuCoolingTypes.remove(val);
                              }
                            });
                          },
                          selectedGpuFrameSyncs: _selectedGpuFrameSyncs,
                          onGpuFrameSyncChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedGpuFrameSyncs.add(val);
                              } else {
                                _selectedGpuFrameSyncs.remove(val);
                              }
                            });
                          },
                          // Cooler filters
                          coolerIsWaterCooled: _coolerIsWaterCooled,
                          onCoolerIsWaterCooledChanged: (val) {
                            setState(() {
                              _coolerIsWaterCooled = val;
                            });
                          },
                          coolerHeightRange: _coolerHeightRange,
                          onCoolerHeightRangeChanged: (range) {
                            setState(() {
                              _coolerHeightRange = range;
                            });
                          },
                          coolerRadiatorSizeRange: _coolerRadiatorSizeRange,
                          onCoolerRadiatorSizeRangeChanged: (range) {
                            setState(() {
                              _coolerRadiatorSizeRange = range;
                            });
                          },
                          coolerFanSizeRange: _coolerFanSizeRange,
                          onCoolerFanSizeRangeChanged: (range) {
                            setState(() {
                              _coolerFanSizeRange = range;
                            });
                          },
                          // Case Fan filters
                          caseFanSizeRange: _caseFanSizeRange,
                          onCaseFanSizeRangeChanged: (range) {
                            setState(() {
                              _caseFanSizeRange = range;
                            });
                          },
                          selectedCaseFanLedTypes: _selectedCaseFanLedTypes,
                          onCaseFanLedTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedCaseFanLedTypes.add(val);
                              } else {
                                _selectedCaseFanLedTypes.remove(val);
                              }
                            });
                          },
                          selectedCaseFanFlowDirections:
                              _selectedCaseFanFlowDirections,
                          onCaseFanFlowDirectionChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedCaseFanFlowDirections.add(val);
                              } else {
                                _selectedCaseFanFlowDirections.remove(val);
                              }
                            });
                          },
                          selectedCaseFanConnectorTypes:
                              _selectedCaseFanConnectorTypes,
                          onCaseFanConnectorTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedCaseFanConnectorTypes.add(val);
                              } else {
                                _selectedCaseFanConnectorTypes.remove(val);
                              }
                            });
                          },
                          // Monitor filters
                          monitorScreenSizeRange: _monitorScreenSizeRange,
                          onMonitorScreenSizeRangeChanged: (range) {
                            setState(() {
                              _monitorScreenSizeRange = range;
                            });
                          },
                          selectedMonitorPanelTypes: _selectedMonitorPanelTypes,
                          onMonitorPanelTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedMonitorPanelTypes.add(val);
                              } else {
                                _selectedMonitorPanelTypes.remove(val);
                              }
                            });
                          },
                          monitorRefreshRateRange: _monitorRefreshRateRange,
                          onMonitorRefreshRateRangeChanged: (range) {
                            setState(() {
                              _monitorRefreshRateRange = range;
                            });
                          },
                          selectedMonitorAdaptiveSyncTypes:
                              _selectedMonitorAdaptiveSyncTypes,
                          onMonitorAdaptiveSyncTypeChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedMonitorAdaptiveSyncTypes.add(val);
                              } else {
                                _selectedMonitorAdaptiveSyncTypes.remove(val);
                              }
                            });
                          },
                          selectedMonitorAspectRatios:
                              _selectedMonitorAspectRatios,
                          onMonitorAspectRatioChanged: (val, sel) {
                            setState(() {
                              if (sel) {
                                _selectedMonitorAspectRatios.add(val);
                              } else {
                                _selectedMonitorAspectRatios.remove(val);
                              }
                            });
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 32),

                  /// The right panel displaying the list of filtered products.
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (pagingState.isInitialLoading) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

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
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pagingState.errorMessage!,
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

                        // Get current build from provider if not provided
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

                        Widget buildList({Set<String>? compatibleIds}) {
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
                            hasMore: pagingState.hasMore,
                            isLoading:
                                pagingState.isLoading &&
                                !pagingState.isInitialLoading,
                            isRefreshing: pagingState.isRefreshing,
                            onRefresh: pagingNotifier.refresh,
                            onPageChanged: _navigateToPage,
                          );
                        }

                        if (compatibilityFuture != null) {
                          return FutureBuilder<Set<String>>(
                            future: compatibilityFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              final compatibleIds = snapshot.data ?? <String>{};
                              return buildList(compatibleIds: compatibleIds);
                            },
                          );
                        }

                        return buildList();
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

  // Filter state and callbacks
  final Set<String> selectedManufacturers;
  final Function(String, bool) onManufacturerChanged;
  final RangeValues priceRange;
  final Function(RangeValues) onPriceRangeChanged;

  // CPU filters
  final Set<String> selectedCpuSeries;
  final Function(String, bool) onCpuSeriesChanged;
  final Set<String> selectedCpuSockets;
  final Function(String, bool) onCpuSocketChanged;
  final bool? cpuIncludesCooler;
  final Function(bool?) onCpuIncludesCoolerChanged;

  // Motherboard filters
  final Set<String> selectedMotherboardSockets;
  final Function(String, bool) onMotherboardSocketChanged;
  final Set<String> selectedMotherboardChipsets;
  final Function(String, bool) onMotherboardChipsetChanged;
  final Set<String> selectedMotherboardFormFactors;
  final Function(String, bool) onMotherboardFormFactorChanged;

  // RAM filters
  final Set<String> selectedRamTypes;
  final Function(String, bool) onRamTypeChanged;
  final Set<int> selectedRamModules;
  final Function(int, bool) onRamModuleChanged;
  final bool? ramHasRgb;
  final Function(bool?) onRamHasRgbChanged;

  // Storage filters
  final Set<String> selectedStorageTypes;
  final Function(String, bool) onStorageTypeChanged;
  final Set<String> selectedStorageInterfaces;
  final Function(String, bool) onStorageInterfaceChanged;

  // PSU filters
  final Set<String> selectedPsuWattages;
  final Function(String, bool) onPsuWattageChanged;
  final Set<String> selectedPsuEfficiencies;
  final Function(String, bool) onPsuEfficiencyChanged;
  final Set<String> selectedPsuModularities;
  final Function(String, bool) onPsuModularityChanged;

  // Case filters
  final Set<String> selectedCaseFormFactors;
  final Function(String, bool) onCaseFormFactorChanged;
  final RangeValues? caseMaxGpuLengthRange;
  final Function(RangeValues) onCaseMaxGpuLengthRangeChanged;
  final RangeValues? caseMaxCoolerHeightRange;
  final Function(RangeValues) onCaseMaxCoolerHeightRangeChanged;

  // GPU filters
  final Set<String> selectedGpuChipsets;
  final Function(String, bool) onGpuChipsetChanged;
  final RangeValues? gpuVramRange;
  final Function(RangeValues) onGpuVramRangeChanged;
  final Set<String> selectedGpuMemoryTypes;
  final Function(String, bool) onGpuMemoryTypeChanged;
  final Set<String> selectedGpuCoolingTypes;
  final Function(String, bool) onGpuCoolingTypeChanged;
  final Set<String> selectedGpuFrameSyncs;
  final Function(String, bool) onGpuFrameSyncChanged;

  // Cooler filters
  final bool? coolerIsWaterCooled;
  final Function(bool?) onCoolerIsWaterCooledChanged;
  final RangeValues? coolerHeightRange;
  final Function(RangeValues) onCoolerHeightRangeChanged;
  final RangeValues? coolerRadiatorSizeRange;
  final Function(RangeValues) onCoolerRadiatorSizeRangeChanged;
  final RangeValues? coolerFanSizeRange;
  final Function(RangeValues) onCoolerFanSizeRangeChanged;

  // Case Fan filters
  final RangeValues? caseFanSizeRange;
  final Function(RangeValues) onCaseFanSizeRangeChanged;
  final Set<String> selectedCaseFanLedTypes;
  final Function(String, bool) onCaseFanLedTypeChanged;
  final Set<String> selectedCaseFanFlowDirections;
  final Function(String, bool) onCaseFanFlowDirectionChanged;
  final Set<String> selectedCaseFanConnectorTypes;
  final Function(String, bool) onCaseFanConnectorTypeChanged;

  // Monitor filters
  final RangeValues? monitorScreenSizeRange;
  final Function(RangeValues) onMonitorScreenSizeRangeChanged;
  final Set<String> selectedMonitorPanelTypes;
  final Function(String, bool) onMonitorPanelTypeChanged;
  final RangeValues? monitorRefreshRateRange;
  final Function(RangeValues) onMonitorRefreshRateRangeChanged;
  final Set<String> selectedMonitorAdaptiveSyncTypes;
  final Function(String, bool) onMonitorAdaptiveSyncTypeChanged;
  final Set<String> selectedMonitorAspectRatios;
  final Function(String, bool) onMonitorAspectRatioChanged;

  // Compatibility filter
  final bool enableCompatibilityFilter;
  final Function(bool) onCompatibilityFilterChanged;

  const _LeftPanel({
    required this.enableCompatibilityFilter,
    required this.onCompatibilityFilterChanged,
    required this.currentBuild,
    required this.allProducts,
    required this.componentType,
    required this.selectedManufacturers,
    required this.onManufacturerChanged,
    required this.priceRange,
    required this.onPriceRangeChanged,
    required this.selectedCpuSeries,
    required this.onCpuSeriesChanged,
    required this.selectedCpuSockets,
    required this.onCpuSocketChanged,
    required this.cpuIncludesCooler,
    required this.onCpuIncludesCoolerChanged,
    required this.selectedMotherboardSockets,
    required this.onMotherboardSocketChanged,
    required this.selectedMotherboardChipsets,
    required this.onMotherboardChipsetChanged,
    required this.selectedMotherboardFormFactors,
    required this.onMotherboardFormFactorChanged,
    required this.selectedRamTypes,
    required this.onRamTypeChanged,
    required this.selectedRamModules,
    required this.onRamModuleChanged,
    required this.ramHasRgb,
    required this.onRamHasRgbChanged,
    required this.selectedStorageTypes,
    required this.onStorageTypeChanged,
    required this.selectedStorageInterfaces,
    required this.onStorageInterfaceChanged,
    required this.selectedPsuWattages,
    required this.onPsuWattageChanged,
    required this.selectedPsuEfficiencies,
    required this.onPsuEfficiencyChanged,
    required this.selectedPsuModularities,
    required this.onPsuModularityChanged,
    required this.selectedCaseFormFactors,
    required this.onCaseFormFactorChanged,
    required this.caseMaxGpuLengthRange,
    required this.onCaseMaxGpuLengthRangeChanged,
    required this.caseMaxCoolerHeightRange,
    required this.onCaseMaxCoolerHeightRangeChanged,
    required this.selectedGpuChipsets,
    required this.onGpuChipsetChanged,
    required this.gpuVramRange,
    required this.onGpuVramRangeChanged,
    required this.selectedGpuMemoryTypes,
    required this.onGpuMemoryTypeChanged,
    required this.selectedGpuCoolingTypes,
    required this.onGpuCoolingTypeChanged,
    required this.selectedGpuFrameSyncs,
    required this.onGpuFrameSyncChanged,
    required this.coolerIsWaterCooled,
    required this.onCoolerIsWaterCooledChanged,
    required this.coolerHeightRange,
    required this.onCoolerHeightRangeChanged,
    required this.coolerRadiatorSizeRange,
    required this.onCoolerRadiatorSizeRangeChanged,
    required this.coolerFanSizeRange,
    required this.onCoolerFanSizeRangeChanged,
    required this.caseFanSizeRange,
    required this.onCaseFanSizeRangeChanged,
    required this.selectedCaseFanLedTypes,
    required this.onCaseFanLedTypeChanged,
    required this.selectedCaseFanFlowDirections,
    required this.onCaseFanFlowDirectionChanged,
    required this.selectedCaseFanConnectorTypes,
    required this.onCaseFanConnectorTypeChanged,
    required this.monitorScreenSizeRange,
    required this.onMonitorScreenSizeRangeChanged,
    required this.selectedMonitorPanelTypes,
    required this.onMonitorPanelTypeChanged,
    required this.monitorRefreshRateRange,
    required this.onMonitorRefreshRateRangeChanged,
    required this.selectedMonitorAdaptiveSyncTypes,
    required this.onMonitorAdaptiveSyncTypeChanged,
    required this.selectedMonitorAspectRatios,
    required this.onMonitorAspectRatioChanged,
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
          title: const Text(
            'Compatibility Filter',
            style: TextStyle(fontWeight: FontWeight.bold),
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _FilterPanel(
              allProducts: allProducts,
              componentType: componentType,
              selectedManufacturers: selectedManufacturers,
              onManufacturerChanged: onManufacturerChanged,
              priceRange: priceRange,
              onPriceRangeChanged: onPriceRangeChanged,
              selectedCpuSeries: selectedCpuSeries,
              onCpuSeriesChanged: onCpuSeriesChanged,
              selectedCpuSockets: selectedCpuSockets,
              onCpuSocketChanged: onCpuSocketChanged,
              cpuIncludesCooler: cpuIncludesCooler,
              onCpuIncludesCoolerChanged: onCpuIncludesCoolerChanged,
              selectedMotherboardSockets: selectedMotherboardSockets,
              onMotherboardSocketChanged: onMotherboardSocketChanged,
              selectedMotherboardChipsets: selectedMotherboardChipsets,
              onMotherboardChipsetChanged: onMotherboardChipsetChanged,
              selectedMotherboardFormFactors: selectedMotherboardFormFactors,
              onMotherboardFormFactorChanged: onMotherboardFormFactorChanged,
              selectedRamTypes: selectedRamTypes,
              onRamTypeChanged: onRamTypeChanged,
              selectedRamModules: selectedRamModules,
              onRamModuleChanged: onRamModuleChanged,
              ramHasRgb: ramHasRgb,
              onRamHasRgbChanged: onRamHasRgbChanged,
              selectedStorageTypes: selectedStorageTypes,
              onStorageTypeChanged: onStorageTypeChanged,
              selectedStorageInterfaces: selectedStorageInterfaces,
              onStorageInterfaceChanged: onStorageInterfaceChanged,
              selectedPsuWattages: selectedPsuWattages,
              onPsuWattageChanged: onPsuWattageChanged,
              selectedPsuEfficiencies: selectedPsuEfficiencies,
              onPsuEfficiencyChanged: onPsuEfficiencyChanged,
              selectedPsuModularities: selectedPsuModularities,
              onPsuModularityChanged: onPsuModularityChanged,
              selectedCaseFormFactors: selectedCaseFormFactors,
              onCaseFormFactorChanged: onCaseFormFactorChanged,
              caseMaxGpuLengthRange: caseMaxGpuLengthRange,
              onCaseMaxGpuLengthRangeChanged: onCaseMaxGpuLengthRangeChanged,
              caseMaxCoolerHeightRange: caseMaxCoolerHeightRange,
              onCaseMaxCoolerHeightRangeChanged:
                  onCaseMaxCoolerHeightRangeChanged,
              selectedGpuChipsets: selectedGpuChipsets,
              onGpuChipsetChanged: onGpuChipsetChanged,
              gpuVramRange: gpuVramRange,
              onGpuVramRangeChanged: onGpuVramRangeChanged,
              selectedGpuMemoryTypes: selectedGpuMemoryTypes,
              onGpuMemoryTypeChanged: onGpuMemoryTypeChanged,
              selectedGpuCoolingTypes: selectedGpuCoolingTypes,
              onGpuCoolingTypeChanged: onGpuCoolingTypeChanged,
              selectedGpuFrameSyncs: selectedGpuFrameSyncs,
              onGpuFrameSyncChanged: onGpuFrameSyncChanged,
              coolerIsWaterCooled: coolerIsWaterCooled,
              onCoolerIsWaterCooledChanged: onCoolerIsWaterCooledChanged,
              coolerHeightRange: coolerHeightRange,
              onCoolerHeightRangeChanged: onCoolerHeightRangeChanged,
              coolerRadiatorSizeRange: coolerRadiatorSizeRange,
              onCoolerRadiatorSizeRangeChanged:
                  onCoolerRadiatorSizeRangeChanged,
              coolerFanSizeRange: coolerFanSizeRange,
              onCoolerFanSizeRangeChanged: onCoolerFanSizeRangeChanged,
              caseFanSizeRange: caseFanSizeRange,
              onCaseFanSizeRangeChanged: onCaseFanSizeRangeChanged,
              selectedCaseFanLedTypes: selectedCaseFanLedTypes,
              onCaseFanLedTypeChanged: onCaseFanLedTypeChanged,
              selectedCaseFanFlowDirections: selectedCaseFanFlowDirections,
              onCaseFanFlowDirectionChanged: onCaseFanFlowDirectionChanged,
              selectedCaseFanConnectorTypes: selectedCaseFanConnectorTypes,
              onCaseFanConnectorTypeChanged: onCaseFanConnectorTypeChanged,
              monitorScreenSizeRange: monitorScreenSizeRange,
              onMonitorScreenSizeRangeChanged: onMonitorScreenSizeRangeChanged,
              selectedMonitorPanelTypes: selectedMonitorPanelTypes,
              onMonitorPanelTypeChanged: onMonitorPanelTypeChanged,
              monitorRefreshRateRange: monitorRefreshRateRange,
              onMonitorRefreshRateRangeChanged:
                  onMonitorRefreshRateRangeChanged,
              selectedMonitorAdaptiveSyncTypes:
                  selectedMonitorAdaptiveSyncTypes,
              onMonitorAdaptiveSyncTypeChanged:
                  onMonitorAdaptiveSyncTypeChanged,
              selectedMonitorAspectRatios: selectedMonitorAspectRatios,
              onMonitorAspectRatioChanged: onMonitorAspectRatioChanged,
            ),
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
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        // Each piece of information is displayed in a `_SummaryRow`.
        children: [
          _SummaryRow(label: 'Parts:', value: '$partCount/12'),
          const SizedBox(height: 8),
          _SummaryRow(
            label: 'Total Price:',
            value: '\$${totalPrice.toStringAsFixed(2)}',
            valueColor: AppColorsDark.textPurple,
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

/// The main filter panel widget that dynamically builds filter options based on the component type.
// TODO: Consider breaking this down into smaller, more manageable widgets if it becomes too complex.
class _FilterPanel extends ConsumerWidget {
  final List<BaseComponent> allProducts;
  final ComponentType componentType;

  // Filter state and callbacks
  final Set<String> selectedManufacturers;
  final Function(String, bool) onManufacturerChanged;
  final RangeValues priceRange;
  final Function(RangeValues) onPriceRangeChanged;

  // CPU filters
  final Set<String> selectedCpuSeries;
  final Function(String, bool) onCpuSeriesChanged;
  final Set<String> selectedCpuSockets;
  final Function(String, bool) onCpuSocketChanged;
  final bool? cpuIncludesCooler;
  final Function(bool?) onCpuIncludesCoolerChanged;

  // Motherboard filters
  final Set<String> selectedMotherboardSockets;
  final Function(String, bool) onMotherboardSocketChanged;
  final Set<String> selectedMotherboardChipsets;
  final Function(String, bool) onMotherboardChipsetChanged;
  final Set<String> selectedMotherboardFormFactors;
  final Function(String, bool) onMotherboardFormFactorChanged;

  // RAM filters
  final Set<String> selectedRamTypes;
  final Function(String, bool) onRamTypeChanged;
  final Set<int> selectedRamModules;
  final Function(int, bool) onRamModuleChanged;
  final bool? ramHasRgb;
  final Function(bool?) onRamHasRgbChanged;

  // Storage filters
  final Set<String> selectedStorageTypes;
  final Function(String, bool) onStorageTypeChanged;
  final Set<String> selectedStorageInterfaces;
  final Function(String, bool) onStorageInterfaceChanged;

  // PSU filters
  final Set<String> selectedPsuWattages;
  final Function(String, bool) onPsuWattageChanged;
  final Set<String> selectedPsuEfficiencies;
  final Function(String, bool) onPsuEfficiencyChanged;
  final Set<String> selectedPsuModularities;
  final Function(String, bool) onPsuModularityChanged;

  // Case filters
  final Set<String> selectedCaseFormFactors;
  final Function(String, bool) onCaseFormFactorChanged;
  final RangeValues? caseMaxGpuLengthRange;
  final Function(RangeValues) onCaseMaxGpuLengthRangeChanged;
  final RangeValues? caseMaxCoolerHeightRange;
  final Function(RangeValues) onCaseMaxCoolerHeightRangeChanged;

  // GPU filters
  final Set<String> selectedGpuChipsets;
  final Function(String, bool) onGpuChipsetChanged;
  final RangeValues? gpuVramRange;
  final Function(RangeValues) onGpuVramRangeChanged;
  final Set<String> selectedGpuMemoryTypes;
  final Function(String, bool) onGpuMemoryTypeChanged;
  final Set<String> selectedGpuCoolingTypes;
  final Function(String, bool) onGpuCoolingTypeChanged;
  final Set<String> selectedGpuFrameSyncs;
  final Function(String, bool) onGpuFrameSyncChanged;

  // Cooler filters
  final bool? coolerIsWaterCooled;
  final Function(bool?) onCoolerIsWaterCooledChanged;
  final RangeValues? coolerHeightRange;
  final Function(RangeValues) onCoolerHeightRangeChanged;
  final RangeValues? coolerRadiatorSizeRange;
  final Function(RangeValues) onCoolerRadiatorSizeRangeChanged;
  final RangeValues? coolerFanSizeRange;
  final Function(RangeValues) onCoolerFanSizeRangeChanged;

  // Case Fan filters
  final RangeValues? caseFanSizeRange;
  final Function(RangeValues) onCaseFanSizeRangeChanged;
  final Set<String> selectedCaseFanLedTypes;
  final Function(String, bool) onCaseFanLedTypeChanged;
  final Set<String> selectedCaseFanFlowDirections;
  final Function(String, bool) onCaseFanFlowDirectionChanged;
  final Set<String> selectedCaseFanConnectorTypes;
  final Function(String, bool) onCaseFanConnectorTypeChanged;

  // Monitor filters
  final RangeValues? monitorScreenSizeRange;
  final Function(RangeValues) onMonitorScreenSizeRangeChanged;
  final Set<String> selectedMonitorPanelTypes;
  final Function(String, bool) onMonitorPanelTypeChanged;
  final RangeValues? monitorRefreshRateRange;
  final Function(RangeValues) onMonitorRefreshRateRangeChanged;
  final Set<String> selectedMonitorAdaptiveSyncTypes;
  final Function(String, bool) onMonitorAdaptiveSyncTypeChanged;
  final Set<String> selectedMonitorAspectRatios;
  final Function(String, bool) onMonitorAspectRatioChanged;

  const _FilterPanel({
    required this.allProducts,
    required this.componentType,
    required this.selectedManufacturers,
    required this.onManufacturerChanged,
    required this.priceRange,
    required this.onPriceRangeChanged,
    required this.selectedCpuSeries,
    required this.onCpuSeriesChanged,
    required this.selectedCpuSockets,
    required this.onCpuSocketChanged,
    required this.cpuIncludesCooler,
    required this.onCpuIncludesCoolerChanged,
    required this.selectedMotherboardSockets,
    required this.onMotherboardSocketChanged,
    required this.selectedMotherboardChipsets,
    required this.onMotherboardChipsetChanged,
    required this.selectedMotherboardFormFactors,
    required this.onMotherboardFormFactorChanged,
    required this.selectedRamTypes,
    required this.onRamTypeChanged,
    required this.selectedRamModules,
    required this.onRamModuleChanged,
    required this.ramHasRgb,
    required this.onRamHasRgbChanged,
    required this.selectedStorageTypes,
    required this.onStorageTypeChanged,
    required this.selectedStorageInterfaces,
    required this.onStorageInterfaceChanged,
    required this.selectedPsuWattages,
    required this.onPsuWattageChanged,
    required this.selectedPsuEfficiencies,
    required this.onPsuEfficiencyChanged,
    required this.selectedPsuModularities,
    required this.onPsuModularityChanged,
    required this.selectedCaseFormFactors,
    required this.onCaseFormFactorChanged,
    required this.caseMaxGpuLengthRange,
    required this.onCaseMaxGpuLengthRangeChanged,
    required this.caseMaxCoolerHeightRange,
    required this.onCaseMaxCoolerHeightRangeChanged,
    required this.selectedGpuChipsets,
    required this.onGpuChipsetChanged,
    required this.gpuVramRange,
    required this.onGpuVramRangeChanged,
    required this.selectedGpuMemoryTypes,
    required this.onGpuMemoryTypeChanged,
    required this.selectedGpuCoolingTypes,
    required this.onGpuCoolingTypeChanged,
    required this.selectedGpuFrameSyncs,
    required this.onGpuFrameSyncChanged,
    required this.coolerIsWaterCooled,
    required this.onCoolerIsWaterCooledChanged,
    required this.coolerHeightRange,
    required this.onCoolerHeightRangeChanged,
    required this.coolerRadiatorSizeRange,
    required this.onCoolerRadiatorSizeRangeChanged,
    required this.coolerFanSizeRange,
    required this.onCoolerFanSizeRangeChanged,
    required this.caseFanSizeRange,
    required this.onCaseFanSizeRangeChanged,
    required this.selectedCaseFanLedTypes,
    required this.onCaseFanLedTypeChanged,
    required this.selectedCaseFanFlowDirections,
    required this.onCaseFanFlowDirectionChanged,
    required this.selectedCaseFanConnectorTypes,
    required this.onCaseFanConnectorTypeChanged,
    required this.monitorScreenSizeRange,
    required this.onMonitorScreenSizeRangeChanged,
    required this.selectedMonitorPanelTypes,
    required this.onMonitorPanelTypeChanged,
    required this.monitorRefreshRateRange,
    required this.onMonitorRefreshRateRangeChanged,
    required this.selectedMonitorAdaptiveSyncTypes,
    required this.onMonitorAdaptiveSyncTypeChanged,
    required this.selectedMonitorAspectRatios,
    required this.onMonitorAspectRatioChanged,
  });

  /// A generic function to extract unique, non-null values for a specific property
  /// from the list of all products. This is used to populate filter options.
  List<T> _getUniqueValuesFor<T, C extends BaseComponent>(
    T Function(C) mapper,
  ) {
    return allProducts
        .whereType<C>()
        .map(mapper)
        .where((item) => item != null)
        .toSet()
        .toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      // The list of filters is built dynamically.
      children: [
        ..._buildComponentSpecificFilters(ref),
        _buildFilterSection<String>(
          title: 'Manufacturer',
          items: _getUniqueValuesFor<String, BaseComponent>(
            (p) => p.manufacturer,
          ),
          selectedItems: selectedManufacturers.toList(),
          onChanged: onManufacturerChanged,
        ),
        _buildPriceFilter(context),
      ],
    );
  }

  /// Dynamically builds the list of filter widgets based on the current [componentType].
  List<Widget> _buildComponentSpecificFilters(WidgetRef ref) {
    // TODO: Implement component-specific filters by updating the filter provider.

    // A switch statement determines which set of filters to show.
    List<Widget> filters = const [];
    switch (componentType) {
      case ComponentType.cpu:
        filters = [
          _buildFilterSection<String>(
            title: 'Series',
            items: _getUniqueValuesFor<String, CPUComponent>((p) => p.series),
            selectedItems: selectedCpuSeries.toList(),
            onChanged: onCpuSeriesChanged,
          ),
          _buildFilterSection<String>(
            title: 'Socket',
            items: _getUniqueValuesFor<String, CPUComponent>(
              (p) => p.socketType,
            ),
            selectedItems: selectedCpuSockets.toList(),
            onChanged: onCpuSocketChanged,
          ),
          _buildBooleanFilter(
            title: 'Includes Cooler',
            value: cpuIncludesCooler,
            onChanged: onCpuIncludesCoolerChanged,
          ),
        ];
        break;
      case ComponentType.motherboard:
        filters = [
          _buildFilterSection<String>(
            title: 'Socket',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.socketType,
            ),
            selectedItems: selectedMotherboardSockets.toList(),
            onChanged: onMotherboardSocketChanged,
          ),
          _buildFilterSection<String>(
            title: 'Chipset',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.chipsetType,
            ),
            selectedItems: selectedMotherboardChipsets.toList(),
            onChanged: onMotherboardChipsetChanged,
          ),
          _buildFilterSection<String>(
            title: 'Form Factor',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.formFactor,
            ),
            selectedItems: selectedMotherboardFormFactors.toList(),
            onChanged: onMotherboardFormFactorChanged,
          ),
        ];
        break;
      case ComponentType.ram:
        filters = [
          _buildFilterSection<String>(
            title: 'Type',
            items: _getUniqueValuesFor<String, MemoryComponent>(
              (p) => p.ramType,
            ),
            selectedItems: selectedRamTypes.toList(),
            onChanged: onRamTypeChanged,
          ),
          _buildFilterSection<int>(
            title: 'Modules',
            items: _getUniqueValuesFor<int, MemoryComponent>(
              (p) => p.moduleQuantity,
            ),
            selectedItems: selectedRamModules.toList(),
            onChanged: onRamModuleChanged,
            displayMapper: (val) => '$val module(s)',
          ),
          _buildBooleanFilter(
            title: 'RGB',
            value: ramHasRgb,
            onChanged: onRamHasRgbChanged,
          ),
        ];
        break;
      case ComponentType.psu:
        filters = [
          _buildFilterSection<String>(
            title: 'Wattage',
            items: const ['0-550', '551-750', '751-1000', '1001-9999'],
            displayItems: const [
              'Up to 550W',
              '551W - 750W',
              '751W - 1000W',
              '1000W+',
            ],
            selectedItems: selectedPsuWattages.toList(),
            onChanged: onPsuWattageChanged,
          ),
          _buildFilterSection<String>(
            title: 'Efficiency',
            items: _getUniqueValuesFor<String, PowerSupplyComponent>(
              (p) => p.efficiencyRating!,
            ),
            selectedItems: selectedPsuEfficiencies.toList(),
            onChanged: onPsuEfficiencyChanged,
          ),
          _buildFilterSection<String>(
            title: 'Modularity',
            items: _getUniqueValuesFor<String, PowerSupplyComponent>(
              (p) => p.modularityType,
            ),
            selectedItems: selectedPsuModularities.toList(),
            onChanged: onPsuModularityChanged,
          ),
        ];
        break;
      case ComponentType.storage:
        filters = [
          _buildFilterSection<String>(
            title: 'Type',
            items: _getUniqueValuesFor<String, StorageComponent>(
              (p) => p.driveType,
            ),
            selectedItems: selectedStorageTypes.toList(),
            onChanged: onStorageTypeChanged,
          ),
          _buildFilterSection<String>(
            title: 'Interface',
            items: _getUniqueValuesFor<String, StorageComponent>(
              (p) => p.interface,
            ),
            selectedItems: selectedStorageInterfaces.toList(),
            onChanged: onStorageInterfaceChanged,
          ),
        ];
        break;
      case ComponentType.pcCase:
        filters = [
          _buildFilterSection<String>(
            title: 'Form Factor',
            items: _getUniqueValuesFor<String, CaseComponent>(
              (p) => p.formFactor,
            ),
            selectedItems: selectedCaseFormFactors.toList(),
            onChanged: onCaseFormFactorChanged,
          ),
          Builder(
            builder: (context) {
              final cases = allProducts.whereType<CaseComponent>().toList();
              if (cases.isEmpty) return const SizedBox.shrink();
              final maxGpuLength = cases
                  .map((p) => p.maxVideoCardLength)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Max GPU Length (mm)',
                range: caseMaxGpuLengthRange,
                onRangeChanged: onCaseMaxGpuLengthRangeChanged,
                min: 0,
                max: maxGpuLength > 0 ? maxGpuLength : 500,
                formatValue: (val) => '${val.toStringAsFixed(0)}mm',
              );
            },
          ),
          Builder(
            builder: (context) {
              final cases = allProducts.whereType<CaseComponent>().toList();
              if (cases.isEmpty) return const SizedBox.shrink();
              final maxCoolerHeight = cases
                  .map((p) => p.maxCPUCoolerHeight.toDouble())
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Max Cooler Height (mm)',
                range: caseMaxCoolerHeightRange,
                onRangeChanged: onCaseMaxCoolerHeightRangeChanged,
                min: 0,
                max: maxCoolerHeight > 0 ? maxCoolerHeight : 200,
                formatValue: (val) => '${val.toStringAsFixed(0)}mm',
              );
            },
          ),
        ];
        break;
      case ComponentType.gpu:
        filters = [
          _buildFilterSection<String>(
            title: 'Chipset',
            items: _getUniqueValuesFor<String, GPUComponent>((p) => p.chipset),
            selectedItems: selectedGpuChipsets.toList(),
            onChanged: onGpuChipsetChanged,
          ),
          Builder(
            builder: (context) {
              final gpus = allProducts.whereType<GPUComponent>().toList();
              if (gpus.isEmpty) return const SizedBox.shrink();
              final maxVram = gpus
                  .map((p) => p.videoMemoryAmount)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'VRAM (GB)',
                range: gpuVramRange,
                onRangeChanged: onGpuVramRangeChanged,
                min: 0,
                max: maxVram > 0 ? maxVram : 24,
                formatValue: (val) => '${val.toStringAsFixed(0)}GB',
              );
            },
          ),
          _buildFilterSection<String>(
            title: 'Memory Type',
            items: _getUniqueValuesFor<String, GPUComponent>(
              (p) => p.videoMemoryType,
            ),
            selectedItems: selectedGpuMemoryTypes.toList(),
            onChanged: onGpuMemoryTypeChanged,
          ),
          _buildFilterSection<String>(
            title: 'Cooling Type',
            items: _getUniqueValuesFor<String, GPUComponent>(
              (p) => p.coolingType,
            ),
            selectedItems: selectedGpuCoolingTypes.toList(),
            onChanged: onGpuCoolingTypeChanged,
          ),
          _buildFilterSection<String>(
            title: 'Frame Sync',
            items: _getUniqueValuesFor<String, GPUComponent>(
              (p) => p.frameSync,
            ),
            selectedItems: selectedGpuFrameSyncs.toList(),
            onChanged: onGpuFrameSyncChanged,
          ),
        ];
        break;
      case ComponentType.cooler:
        filters = [
          _buildBooleanFilter(
            title: 'Water Cooled',
            value: coolerIsWaterCooled,
            onChanged: onCoolerIsWaterCooledChanged,
          ),
          Builder(
            builder: (context) {
              final coolers = allProducts.whereType<CoolerComponent>().toList();
              if (coolers.isEmpty) return const SizedBox.shrink();
              final maxHeight = coolers
                  .map((p) => p.height)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Height (mm)',
                range: coolerHeightRange,
                onRangeChanged: onCoolerHeightRangeChanged,
                min: 0,
                max: maxHeight > 0 ? maxHeight : 200,
                formatValue: (val) => '${val.toStringAsFixed(0)}mm',
              );
            },
          ),
          Builder(
            builder: (context) {
              final coolers = allProducts
                  .whereType<CoolerComponent>()
                  .where((p) => p.radiatorSize != null)
                  .toList();
              if (coolers.isEmpty) return const SizedBox.shrink();
              final maxRadiator = coolers
                  .map((p) => p.radiatorSize!)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Radiator Size (mm)',
                range: coolerRadiatorSizeRange,
                onRangeChanged: onCoolerRadiatorSizeRangeChanged,
                min: 0,
                max: maxRadiator > 0 ? maxRadiator : 480,
                formatValue: (val) => '${val.toStringAsFixed(0)}mm',
              );
            },
          ),
          Builder(
            builder: (context) {
              final coolers = allProducts
                  .whereType<CoolerComponent>()
                  .where((p) => p.fanSize != null)
                  .toList();
              if (coolers.isEmpty) return const SizedBox.shrink();
              final maxFanSize = coolers
                  .map((p) => p.fanSize!)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Fan Size (mm)',
                range: coolerFanSizeRange,
                onRangeChanged: onCoolerFanSizeRangeChanged,
                min: 0,
                max: maxFanSize > 0 ? maxFanSize : 140,
                formatValue: (val) => '${val.toStringAsFixed(0)}mm',
              );
            },
          ),
        ];
        break;
      case ComponentType.caseFan:
        filters = [
          Builder(
            builder: (context) {
              final fans = allProducts.whereType<CaseFanComponent>().toList();
              if (fans.isEmpty) return const SizedBox.shrink();
              final maxSize = fans
                  .map((p) => p.size)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Size (mm)',
                range: caseFanSizeRange,
                onRangeChanged: onCaseFanSizeRangeChanged,
                min: 0,
                max: maxSize > 0 ? maxSize : 200,
                formatValue: (val) => '${val.toStringAsFixed(0)}mm',
              );
            },
          ),
          _buildFilterSection<String>(
            title: 'LED Type',
            items: _getUniqueValuesFor<String, CaseFanComponent>(
              (p) => p.ledType ?? '',
            ).where((v) => v.isNotEmpty).toList(),
            selectedItems: selectedCaseFanLedTypes.toList(),
            onChanged: onCaseFanLedTypeChanged,
          ),
          _buildFilterSection<String>(
            title: 'Flow Direction',
            items: _getUniqueValuesFor<String, CaseFanComponent>(
              (p) => p.flowDirection,
            ),
            selectedItems: selectedCaseFanFlowDirections.toList(),
            onChanged: onCaseFanFlowDirectionChanged,
          ),
          _buildFilterSection<String>(
            title: 'Connector Type',
            items: _getUniqueValuesFor<String, CaseFanComponent>(
              (p) => p.connectorType ?? '',
            ).where((v) => v.isNotEmpty).toList(),
            selectedItems: selectedCaseFanConnectorTypes.toList(),
            onChanged: onCaseFanConnectorTypeChanged,
          ),
        ];
        break;
      case ComponentType.monitor:
        filters = [
          Builder(
            builder: (context) {
              final monitors = allProducts
                  .whereType<MonitorComponent>()
                  .toList();
              if (monitors.isEmpty) return const SizedBox.shrink();
              final maxSize = monitors
                  .map((p) => p.screenSize)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Screen Size (inches)',
                range: monitorScreenSizeRange,
                onRangeChanged: onMonitorScreenSizeRangeChanged,
                min: 0,
                max: maxSize > 0 ? maxSize : 50,
                formatValue: (val) => '${val.toStringAsFixed(1)}"',
              );
            },
          ),
          _buildFilterSection<String>(
            title: 'Panel Type',
            items: _getUniqueValuesFor<String, MonitorComponent>(
              (p) => p.panelType,
            ),
            selectedItems: selectedMonitorPanelTypes.toList(),
            onChanged: onMonitorPanelTypeChanged,
          ),
          Builder(
            builder: (context) {
              final monitors = allProducts
                  .whereType<MonitorComponent>()
                  .toList();
              if (monitors.isEmpty) return const SizedBox.shrink();
              final maxRefresh = monitors
                  .map((p) => p.maxRefreshRate)
                  .fold<double>(0, (max, val) => val > max ? val : max);
              return _buildRangeFilter<double>(
                context: context,
                title: 'Refresh Rate (Hz)',
                range: monitorRefreshRateRange,
                onRangeChanged: onMonitorRefreshRateRangeChanged,
                min: 0,
                max: maxRefresh > 0 ? maxRefresh : 240,
                formatValue: (val) => '${val.toStringAsFixed(0)}Hz',
              );
            },
          ),
          _buildFilterSection<String>(
            title: 'Adaptive Sync',
            items: _getUniqueValuesFor<String, MonitorComponent>(
              (p) => p.adaptiveSyncType,
            ),
            selectedItems: selectedMonitorAdaptiveSyncTypes.toList(),
            onChanged: onMonitorAdaptiveSyncTypeChanged,
          ),
          _buildFilterSection<String>(
            title: 'Aspect Ratio',
            items: _getUniqueValuesFor<String, MonitorComponent>(
              (p) => p.aspectRatio,
            ),
            selectedItems: selectedMonitorAspectRatios.toList(),
            onChanged: onMonitorAspectRatioChanged,
          ),
        ];
        break;
    }
    return filters;
  }

  /// Builds the price range slider filter.
  Widget _buildPriceFilter(BuildContext context) {
    // Calculate max price from products
    final maxPrice = allProducts
        .map((p) => p.lowestPrice ?? 0)
        .fold<double>(0, (max, price) => price > max ? price : max);
    final actualMax = maxPrice > 0 ? maxPrice : 10000;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section title.
        Text(
          'Price Range',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColorsDark.textPurple,
            inactiveTrackColor: Colors.grey.shade800,
            thumbColor: AppColorsDark.textPurple,
            overlayColor: AppColorsDark.textPurple.withAlpha(32),
            valueIndicatorColor: AppColorsDark.buttonPurple,
          ),
          // The actual RangeSlider widget.
          child: RangeSlider(
            values: RangeValues(
              priceRange.start.clamp(0.0, actualMax).toDouble(),
              priceRange.end.clamp(0.0, actualMax).toDouble(),
            ),
            min: 0.0,
            max: actualMax.toDouble(),
            divisions: actualMax > 0 ? (actualMax / 50).round() : 100,
            labels: RangeLabels(
              '\$${priceRange.start.toStringAsFixed(0)}',
              '\$${priceRange.end.toStringAsFixed(0)}',
            ),
            onChanged: onPriceRangeChanged,
          ),
        ),
        // Labels showing the current min and max values of the slider.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('\$0', style: TextStyle(color: Colors.grey.shade400)),
            Text(
              '\$${actualMax.toStringAsFixed(0)}+',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  /// Builds a range slider filter for numeric values
  Widget _buildRangeFilter<T extends num>({
    required BuildContext context,
    required String title,
    required RangeValues? range,
    required Function(RangeValues) onRangeChanged,
    required T min,
    required T max,
    required String Function(T) formatValue,
  }) {
    if (max <= min) return const SizedBox.shrink();

    final actualRange = range ?? RangeValues(min.toDouble(), max.toDouble());

    // Helper to format double values
    String formatDouble(double val) {
      if (T == int) {
        return formatValue(val.round() as T);
      } else {
        return formatValue(val as T);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColorsDark.textPurple,
            inactiveTrackColor: Colors.grey.shade800,
            thumbColor: AppColorsDark.textPurple,
            overlayColor: AppColorsDark.textPurple.withAlpha(32),
            valueIndicatorColor: AppColorsDark.buttonPurple,
          ),
          child: RangeSlider(
            values: RangeValues(
              actualRange.start
                  .clamp(min.toDouble(), max.toDouble())
                  .toDouble(),
              actualRange.end.clamp(min.toDouble(), max.toDouble()).toDouble(),
            ),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: (max.toDouble() - min.toDouble() > 0)
                ? ((max.toDouble() - min.toDouble()) / 10).round().clamp(
                    10,
                    100,
                  )
                : 100,
            labels: RangeLabels(
              formatDouble(actualRange.start),
              formatDouble(actualRange.end),
            ),
            onChanged: onRangeChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              formatValue(min),
              style: TextStyle(color: Colors.grey.shade400),
            ),
            Text(
              formatValue(max),
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  /// A generic function to build a section of dropdown filters for accessibility.
  Widget _buildFilterSection<T>({
    required String title,
    required List<T> items,
    List<String>? displayItems,
    required List<T> selectedItems,
    required Function(T, bool) onChanged,
    String Function(T)? displayMapper,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();

    // Build a multi-select dropdown for better accessibility
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _MultiSelectDropdown<T>(
          items: items,
          displayItems: displayItems,
          selectedItems: selectedItems,
          onChanged: onChanged,
          displayMapper: displayMapper,
          title: title,
        ),
        const Divider(height: 32, color: Colors.transparent),
      ],
    );
  }

  /// Builds a filter with three choices: "Any", "Yes", and "No".
  Widget _buildBooleanFilter({
    required String title,
    required bool? value,
    required Function(bool?) onChanged,
  }) {
    // This filter uses custom `_BooleanChip` widgets for selection.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _BooleanChip(
                label: 'Any',
                isSelected: value == null,
                onSelected: () => onChanged(null),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BooleanChip(
                label: 'Yes',
                isSelected: value == true,
                onSelected: () => onChanged(true),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BooleanChip(
                label: 'No',
                isSelected: value == false,
                onSelected: () => onChanged(false),
              ),
            ),
          ],
        ),
        const Divider(height: 32, color: Colors.transparent),
      ],
    );
  }
}

/// A multi-select dropdown widget for better accessibility.
class _MultiSelectDropdown<T> extends StatefulWidget {
  final List<T> items;
  final List<String>? displayItems;
  final List<T> selectedItems;
  final Function(T, bool) onChanged;
  final String Function(T)? displayMapper;
  final String title;

  const _MultiSelectDropdown({
    required this.items,
    this.displayItems,
    required this.selectedItems,
    required this.onChanged,
    this.displayMapper,
    required this.title,
  });

  @override
  State<_MultiSelectDropdown<T>> createState() =>
      _MultiSelectDropdownState<T>();
}

class _MultiSelectDropdownState<T> extends State<_MultiSelectDropdown<T>> {
  @override
  Widget build(BuildContext context) {
    final selectedCount = widget.selectedItems.length;
    final displayText = selectedCount == 0
        ? 'Select ${widget.title}'
        : selectedCount == widget.items.length
        ? 'All selected'
        : '$selectedCount selected';

    return MenuAnchor(
      menuChildren: widget.items.map((item) {
        final index = widget.items.indexOf(item);
        final displayItem =
            widget.displayMapper?.call(item) ??
            widget.displayItems?[index] ??
            item.toString();
        final isSelected = widget.selectedItems.contains(item);

        return MenuItemButton(
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (value) {
                  widget.onChanged(item, value ?? false);
                },
                activeColor: AppColorsDark.textPurple,
              ),
              Expanded(child: Text(displayItem)),
            ],
          ),
          onPressed: () {
            widget.onChanged(item, !isSelected);
          },
        );
      }).toList(),
      builder: (context, controller, child) {
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () {
              if (controller.isOpen) {
                controller.close();
              } else {
                controller.open();
              }
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              alignment: Alignment.centerLeft,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    displayText,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.left,
                  ),
                ),
                Icon(
                  controller.isOpen
                      ? Icons.arrow_drop_up
                      : Icons.arrow_drop_down,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A custom chip widget used for the boolean ("Any", "Yes", "No") filters.
class _BooleanChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  const _BooleanChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label),
      onPressed: onSelected,
      backgroundColor: isSelected
          ? AppColorsDark.textPurple
          : Colors.grey.shade800,
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
  final bool hasMore;
  final bool isLoading;
  final bool isRefreshing;
  final Future<void> Function() onRefresh;
  final void Function(int page) onPageChanged;

  const _ProductList({
    required this.componentType,
    required this.searchController,
    required this.products,
    required this.currentPage,
    required this.hasMore,
    required this.isLoading,
    required this.isRefreshing,
    required this.onRefresh,
    required this.onPageChanged,
    this.onComponentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(
          searchController: searchController,
          count: products.length,
          currentPage: currentPage,
        ),
        const SizedBox(height: 24),
        if (isRefreshing || isLoading)
          const LinearProgressIndicator(minHeight: 2),
        if (isRefreshing || isLoading) const SizedBox(height: 12),
        _ProductListHeader(componentType: componentType),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? RefreshIndicator.adaptive(
                  onRefresh: onRefresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(
                        height: 200,
                        child: Center(
                          child: Text("No products match your criteria."),
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
                  ),
                ),
        ),
        const SizedBox(height: 16),
        _PaginationControls(
          currentPage: currentPage,
          hasMore: hasMore,
          onPageChanged: onPageChanged,
        ),
      ],
    );
  }
}

class _ProductListWithCompatibility extends ConsumerWidget {
  final List<BaseComponent> products;
  final ComponentType componentType;
  final Function(BaseComponent)? onComponentSelected;

  const _ProductListWithCompatibility({
    required this.products,
    required this.componentType,
    this.onComponentSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];

        final onComponentSelected = this.onComponentSelected;
        Widget row = _GenericProductRow(
          product: product,
          onComponentSelected: onComponentSelected,
        );
        switch (product.type) {
          case ComponentType.cpu:
            row = _CpuProductRow(
              product: product as CPUComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.motherboard:
            row = _MotherboardProductRow(
              product: product as MotherboardComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.ram:
            row = _RamProductRow(
              product: product as MemoryComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.storage:
            row = _StorageProductRow(
              product: product as StorageComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.psu:
            row = _PsuProductRow(
              product: product as PowerSupplyComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.pcCase:
            row = _CaseProductRow(
              product: product as CaseComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.gpu:
            row = _GpuProductRow(
              product: product as GPUComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.cooler:
            row = _CoolerProductRow(
              product: product as CoolerComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.caseFan:
            row = _CaseFanProductRow(
              product: product as CaseFanComponent,
              onComponentSelected: onComponentSelected,
            );
            break;
          case ComponentType.monitor:
            row = _MonitorProductRow(
              product: product as MonitorComponent,
              onComponentSelected: onComponentSelected,
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
          'Page $currentPage',
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: canGoBack ? () => onPageChanged(currentPage - 1) : null,
          icon: const Icon(Icons.chevron_left),
          label: const Text('Previous'),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: canGoForward ? () => onPageChanged(currentPage + 1) : null,
          icon: const Icon(Icons.chevron_right),
          label: const Text('Next'),
        ),
      ],
    );
  }
}

/// The top bar of the product list, containing a title, search bar, and action buttons.
class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final int count;
  final int currentPage;
  const _TopBar({
    required this.searchController,
    required this.count,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context) {
    // TODO: Make this layout responsive for mobile.
    return Row(
      children: [
        Text(
          'Compatible Products ($count) • Page $currentPage',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        SizedBox(
          width: 250,
          child: TextField(
            // The search input field.
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search processors...',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              filled: true,
              fillColor: AppColorsDark.backgroundTertiary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // A button to navigate to a comparison page (not yet implemented).
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.compare_arrows),
          label: const Text('Compare'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: BorderSide(color: Colors.grey.shade700),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        // A button to add all filtered items to the build (not yet implemented).
        ElevatedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.add, size: 20),
          label: const Text('Add From Filter'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorsDark.buttonPurple,
            foregroundColor: Colors.white,
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
  const _ProductRow({required this.product, this.onComponentSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The base structure for every product row is a Card with a Row inside.
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: InkWell(
        onTap: () => _showSpecsDialog(context, product),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: buildRow(context, ref),
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
  Widget buildPriceCell(BuildContext context, WidgetRef ref, {int flex = 3}) {
    return Expanded(
      flex: flex,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '\$${product.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
            style: const TextStyle(
              color: AppColorsDark.buttonGreen,
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
              backgroundColor: AppColorsDark.buttonGreen,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Add'),
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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
      buildPriceCell(context, ref, flex: 3),
    ];
  }
}

/// A concrete implementation of [_ProductRow] for displaying Motherboard details.
class _MotherboardProductRow extends _ProductRow {
  const _MotherboardProductRow({
    required MotherboardComponent product,
    Function(BaseComponent)? onComponentSelected,
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
  }) : super(product: product, onComponentSelected: onComponentSelected);

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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
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
        MapEntry('Price', '\$${component.lowestPrice!.toStringAsFixed(2)}'),
      if (component.averageRating != null)
        MapEntry(
          'Rating',
          '${component.averageRating!.toStringAsFixed(1)}/5.0',
        ),
    ];

    return _buildSpecSection('General Information', specs, theme);
  }
}
