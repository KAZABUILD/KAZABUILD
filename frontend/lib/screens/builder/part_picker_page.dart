import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/builder/build_now_page.dart';

class PartPickerPage extends StatefulWidget {
  final ComponentType componentType;
  final List<PcComponent> currentBuild;
  const PartPickerPage({
    super.key,
    required this.componentType,
    required this.currentBuild,
  });

  @override
  State<PartPickerPage> createState() => _PartPickerPageState();
}

class _PartPickerPageState extends State<PartPickerPage> {
  late List<BaseComponent> _allProducts;
  List<BaseComponent> _filteredProducts = [];

  final _searchController = TextEditingController();

  //
  RangeValues _currentRangeValues = const RangeValues(0, 1000);
  List<String> _selectedBrands = [];

  // CPU
  List<String> _selectedCpuSockets = [];
  List<String> _selectedCpuSeries = [];
  bool? _cpuIncludesCooler;
  // Motherboard
  List<String> _selectedMotherboardFormFactors = [];
  List<String> _selectedMotherboardSockets = [];
  List<String> _selectedMotherboardChipsets = [];
  // RAM
  List<String> _selectedRamTypes = [];
  List<int> _selectedRamModules = [];
  bool? _ramHasRgb;
  // Storage
  List<String> _selectedStorageTypes = [];
  List<String> _selectedStorageInterfaces = [];
  // PSU
  List<String> _selectedPsuEfficiency = [];
  List<String> _selectedPsuWattage = [];
  List<String> _selectedPsuModularity = [];
  // Case
  List<String> _selectedCaseFormFactors = [];

  @override
  void initState() {
    super.initState();
    _allProducts = _getMockDataForType(widget.componentType);
    _applyFilters();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  void _applyFilters() {
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        // common filters
        final searchLower = _searchController.text.toLowerCase();
        if (_searchController.text.isNotEmpty &&
            !product.name.toLowerCase().contains(searchLower))
          return false;
        final price = product.lowestPrice ?? 0.0;
        if (price < _currentRangeValues.start ||
            price > _currentRangeValues.end)
          return false;
        if (_selectedBrands.isNotEmpty &&
            !_selectedBrands.contains(product.manufacturer))
          return false;

        switch (product.type) {
          case ComponentType.cpu:
            final p = product as CPUComponent;
            if (_selectedCpuSockets.isNotEmpty &&
                !_selectedCpuSockets.contains(p.socketType))
              return false;
            if (_selectedCpuSeries.isNotEmpty &&
                !_selectedCpuSeries.contains(p.series))
              return false;
            if (_cpuIncludesCooler != null &&
                p.includesCooler != _cpuIncludesCooler)
              return false;
            break;
          case ComponentType.motherboard:
            final p = product as MotherboardComponent;
            if (_selectedMotherboardFormFactors.isNotEmpty &&
                !_selectedMotherboardFormFactors.contains(p.formFactor))
              return false;
            if (_selectedMotherboardSockets.isNotEmpty &&
                !_selectedMotherboardSockets.contains(p.socketType))
              return false;
            if (_selectedMotherboardChipsets.isNotEmpty &&
                !_selectedMotherboardChipsets.contains(p.chipsetType))
              return false;
            break;
          case ComponentType.ram:
            final p = product as MemoryComponent;
            if (_selectedRamTypes.isNotEmpty &&
                !_selectedRamTypes.contains(p.ramType))
              return false;
            if (_selectedRamModules.isNotEmpty &&
                !_selectedRamModules.contains(p.moduleQuantity))
              return false;
            if (_ramHasRgb != null && p.haveRGB != _ramHasRgb) return false;
            break;
          case ComponentType.storage:
            final p = product as StorageComponent;
            if (_selectedStorageTypes.isNotEmpty &&
                !_selectedStorageTypes.contains(p.driveType))
              return false;
            if (_selectedStorageInterfaces.isNotEmpty &&
                !_selectedStorageInterfaces.contains(p.interface))
              return false;
            break;
          case ComponentType.psu:
            final p = product as PowerSupplyComponent;
            if (_selectedPsuEfficiency.isNotEmpty &&
                p.efficiencyRating != null &&
                !_selectedPsuEfficiency.contains(p.efficiencyRating!))
              return false;
            if (_selectedPsuModularity.isNotEmpty &&
                !_selectedPsuModularity.contains(p.modularityType))
              return false;
            if (_selectedPsuWattage.isNotEmpty) {
              bool wattageMatch = _selectedPsuWattage.any((range) {
                final parts = range.split('-');
                final min = int.parse(parts[0]);
                final max = int.parse(parts[1]);
                return p.powerOutput >= min && p.powerOutput <= max;
              });
              if (!wattageMatch) return false;
            }
            break;
          case ComponentType.pcCase:
            final p = product as CaseComponent;
            if (_selectedCaseFormFactors.isNotEmpty &&
                !_selectedCaseFormFactors.contains(p.formFactor))
              return false;
            break;
          default:
            break;
        }
        return true;
      }).toList();
    });
  }

  List<BaseComponent> _getMockDataForType(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return mockCPUs;
      case ComponentType.pcCase:
        return mockCases;
      case ComponentType.motherboard:
        return mockMotherboards;
      case ComponentType.ram:
        return mockRAMs;
      case ComponentType.psu:
        return mockPSUs;
      case ComponentType.storage:
        return mockStorages;
      default:
        return [];
    }
  }

  void _updateFilterList<T>(List<T> selectedList, T value, bool isSelected) {
    setState(() {
      if (isSelected) {
        if (!selectedList.contains(value)) selectedList.add(value);
      } else {
        selectedList.remove(value);
      }
      _applyFilters();
    });
  }

  void _updateFilterBool(Function(bool?) setter, bool? value) {
    setState(() {
      setter(value);
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: _LeftPanel(
                currentBuild: widget.currentBuild,
                allProducts: _allProducts,
                componentType: widget.componentType,
                currentRangeValues: _currentRangeValues,
                onPriceChanged: (values) => setState(() {
                  _currentRangeValues = values;
                  _applyFilters();
                }),
                selectedBrands: _selectedBrands,
                onBrandChanged: (val, sel) =>
                    _updateFilterList(_selectedBrands, val, sel),
                selectedCpuSockets: _selectedCpuSockets,
                onCpuSocketChanged: (val, sel) =>
                    _updateFilterList(_selectedCpuSockets, val, sel),
                selectedCpuSeries: _selectedCpuSeries,
                onCpuSeriesChanged: (val, sel) =>
                    _updateFilterList(_selectedCpuSeries, val, sel),
                cpuIncludesCooler: _cpuIncludesCooler,
                onCpuIncludesCoolerChanged: (val) =>
                    _updateFilterBool((v) => _cpuIncludesCooler = v, val),
                selectedMotherboardFormFactors: _selectedMotherboardFormFactors,
                onMotherboardFormFactorChanged: (val, sel) => _updateFilterList(
                  _selectedMotherboardFormFactors,
                  val,
                  sel,
                ),
                selectedMotherboardSockets: _selectedMotherboardSockets,
                onMotherboardSocketChanged: (val, sel) =>
                    _updateFilterList(_selectedMotherboardSockets, val, sel),
                selectedMotherboardChipsets: _selectedMotherboardChipsets,
                onMotherboardChipsetChanged: (val, sel) =>
                    _updateFilterList(_selectedMotherboardChipsets, val, sel),
                selectedRamTypes: _selectedRamTypes,
                onRamTypeChanged: (val, sel) =>
                    _updateFilterList(_selectedRamTypes, val, sel),
                selectedRamModules: _selectedRamModules,
                onRamModulesChanged: (val, sel) =>
                    _updateFilterList(_selectedRamModules, val, sel),
                ramHasRgb: _ramHasRgb,
                onRamHasRgbChanged: (val) =>
                    _updateFilterBool((v) => _ramHasRgb = v, val),
                selectedStorageTypes: _selectedStorageTypes,
                onStorageTypeChanged: (val, sel) =>
                    _updateFilterList(_selectedStorageTypes, val, sel),
                selectedStorageInterfaces: _selectedStorageInterfaces,
                onStorageInterfaceChanged: (val, sel) =>
                    _updateFilterList(_selectedStorageInterfaces, val, sel),
                selectedPsuEfficiency: _selectedPsuEfficiency,
                onPsuEfficiencyChanged: (val, sel) =>
                    _updateFilterList(_selectedPsuEfficiency, val, sel),
                selectedPsuWattage: _selectedPsuWattage,
                onPsuWattageChanged: (val, sel) =>
                    _updateFilterList(_selectedPsuWattage, val, sel),
                selectedPsuModularity: _selectedPsuModularity,
                onPsuModularityChanged: (val, sel) =>
                    _updateFilterList(_selectedPsuModularity, val, sel),
                selectedCaseFormFactors: _selectedCaseFormFactors,
                onCaseFormFactorChanged: (val, sel) =>
                    _updateFilterList(_selectedCaseFormFactors, val, sel),
              ),
            ),
            const SizedBox(width: 32),
            Expanded(
              child: _ProductList(
                componentType: widget.componentType,
                searchController: _searchController,
                products: _filteredProducts,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// left panel and bottom widgets
class _LeftPanel extends StatelessWidget {
  final List<PcComponent> currentBuild;
  final List<BaseComponent> allProducts;
  final ComponentType componentType;
  final RangeValues currentRangeValues;
  final Function(RangeValues) onPriceChanged;
  final List<String> selectedBrands;
  final Function(String, bool) onBrandChanged;
  final List<String> selectedCpuSockets;
  final Function(String, bool) onCpuSocketChanged;
  final List<String> selectedCpuSeries;
  final Function(String, bool) onCpuSeriesChanged;
  final bool? cpuIncludesCooler;
  final Function(bool?) onCpuIncludesCoolerChanged;
  final List<String> selectedMotherboardFormFactors;
  final Function(String, bool) onMotherboardFormFactorChanged;
  final List<String> selectedMotherboardSockets;
  final Function(String, bool) onMotherboardSocketChanged;
  final List<String> selectedMotherboardChipsets;
  final Function(String, bool) onMotherboardChipsetChanged;
  final List<String> selectedRamTypes;
  final Function(String, bool) onRamTypeChanged;
  final List<int> selectedRamModules;
  final Function(int, bool) onRamModulesChanged;
  final bool? ramHasRgb;
  final Function(bool?) onRamHasRgbChanged;
  final List<String> selectedStorageTypes;
  final Function(String, bool) onStorageTypeChanged;
  final List<String> selectedStorageInterfaces;
  final Function(String, bool) onStorageInterfaceChanged;
  final List<String> selectedPsuEfficiency;
  final Function(String, bool) onPsuEfficiencyChanged;
  final List<String> selectedPsuWattage;
  final Function(String, bool) onPsuWattageChanged;
  final List<String> selectedPsuModularity;
  final Function(String, bool) onPsuModularityChanged;
  final List<String> selectedCaseFormFactors;
  final Function(String, bool) onCaseFormFactorChanged;

  const _LeftPanel({
    required this.currentBuild,
    required this.allProducts,
    required this.componentType,
    required this.currentRangeValues,
    required this.onPriceChanged,
    required this.selectedBrands,
    required this.onBrandChanged,
    required this.selectedCpuSockets,
    required this.onCpuSocketChanged,
    required this.selectedCpuSeries,
    required this.onCpuSeriesChanged,
    required this.cpuIncludesCooler,
    required this.onCpuIncludesCoolerChanged,
    required this.selectedMotherboardFormFactors,
    required this.onMotherboardFormFactorChanged,
    required this.selectedMotherboardSockets,
    required this.onMotherboardSocketChanged,
    required this.selectedMotherboardChipsets,
    required this.onMotherboardChipsetChanged,
    required this.selectedRamTypes,
    required this.onRamTypeChanged,
    required this.selectedRamModules,
    required this.onRamModulesChanged,
    required this.ramHasRgb,
    required this.onRamHasRgbChanged,
    required this.selectedStorageTypes,
    required this.onStorageTypeChanged,
    required this.selectedStorageInterfaces,
    required this.onStorageInterfaceChanged,
    required this.selectedPsuEfficiency,
    required this.onPsuEfficiencyChanged,
    required this.selectedPsuWattage,
    required this.onPsuWattageChanged,
    required this.selectedPsuModularity,
    required this.onPsuModularityChanged,
    required this.selectedCaseFormFactors,
    required this.onCaseFormFactorChanged,
  });

  int get _selectedPartCount =>
      currentBuild.where((c) => c.selectedProduct != null).length;
  double get _totalPrice => currentBuild.fold(
    0.0,
    (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
  );
  int get _estimatedWattage => currentBuild.fold(0, (sum, item) {
    final p = item.selectedProduct;
    if (p is CPUComponent) return sum + p.thermalDesignPower.toInt();
    if (p is GPUComponent) return sum + p.thermalDesignPower.toInt();
    return sum;
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CheckboxListTile(
          title: const Text(
            'Compatibility Filter',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: true,
          onChanged: (val) {},
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
          activeColor: AppColorsDark.textPurple,
        ),
        const SizedBox(height: 16),
        _BuildSummary(
          partCount: _selectedPartCount,
          totalPrice: _totalPrice,
          estimatedWattage: _estimatedWattage,
        ),
        const SizedBox(height: 24),
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
              currentRangeValues: currentRangeValues,
              onPriceChanged: onPriceChanged,
              selectedBrands: selectedBrands,
              onBrandChanged: onBrandChanged,
              selectedCpuSockets: selectedCpuSockets,
              onCpuSocketChanged: onCpuSocketChanged,
              selectedCpuSeries: selectedCpuSeries,
              onCpuSeriesChanged: onCpuSeriesChanged,
              cpuIncludesCooler: cpuIncludesCooler,
              onCpuIncludesCoolerChanged: onCpuIncludesCoolerChanged,
              selectedMotherboardFormFactors: selectedMotherboardFormFactors,
              onMotherboardFormFactorChanged: onMotherboardFormFactorChanged,
              selectedMotherboardSockets: selectedMotherboardSockets,
              onMotherboardSocketChanged: onMotherboardSocketChanged,
              selectedMotherboardChipsets: selectedMotherboardChipsets,
              onMotherboardChipsetChanged: onMotherboardChipsetChanged,
              selectedRamTypes: selectedRamTypes,
              onRamTypeChanged: onRamTypeChanged,
              selectedRamModules: selectedRamModules,
              onRamModulesChanged: onRamModulesChanged,
              ramHasRgb: ramHasRgb,
              onRamHasRgbChanged: onRamHasRgbChanged,
              selectedStorageTypes: selectedStorageTypes,
              onStorageTypeChanged: onStorageTypeChanged,
              selectedStorageInterfaces: selectedStorageInterfaces,
              onStorageInterfaceChanged: onStorageInterfaceChanged,
              selectedPsuEfficiency: selectedPsuEfficiency,
              onPsuEfficiencyChanged: onPsuEfficiencyChanged,
              selectedPsuWattage: selectedPsuWattage,
              onPsuWattageChanged: onPsuWattageChanged,
              selectedPsuModularity: selectedPsuModularity,
              onPsuModularityChanged: onPsuModularityChanged,
              selectedCaseFormFactors: selectedCaseFormFactors,
              onCaseFormFactorChanged: onCaseFormFactorChanged,
            ),
          ),
        ),
      ],
    );
  }
}

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
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

class _FilterPanel extends StatelessWidget {
  final List<BaseComponent> allProducts;
  final ComponentType componentType;
  final RangeValues currentRangeValues;
  final Function(RangeValues) onPriceChanged;
  final List<String> selectedBrands;
  final Function(String, bool) onBrandChanged;
  final List<String> selectedCpuSockets;
  final Function(String, bool) onCpuSocketChanged;
  final List<String> selectedCpuSeries;
  final Function(String, bool) onCpuSeriesChanged;
  final bool? cpuIncludesCooler;
  final Function(bool?) onCpuIncludesCoolerChanged;
  final List<String> selectedMotherboardFormFactors;
  final Function(String, bool) onMotherboardFormFactorChanged;
  final List<String> selectedMotherboardSockets;
  final Function(String, bool) onMotherboardSocketChanged;
  final List<String> selectedMotherboardChipsets;
  final Function(String, bool) onMotherboardChipsetChanged;
  final List<String> selectedRamTypes;
  final Function(String, bool) onRamTypeChanged;
  final List<int> selectedRamModules;
  final Function(int, bool) onRamModulesChanged;
  final bool? ramHasRgb;
  final Function(bool?) onRamHasRgbChanged;
  final List<String> selectedStorageTypes;
  final Function(String, bool) onStorageTypeChanged;
  final List<String> selectedStorageInterfaces;
  final Function(String, bool) onStorageInterfaceChanged;
  final List<String> selectedPsuEfficiency;
  final Function(String, bool) onPsuEfficiencyChanged;
  final List<String> selectedPsuWattage;
  final Function(String, bool) onPsuWattageChanged;
  final List<String> selectedPsuModularity;
  final Function(String, bool) onPsuModularityChanged;
  final List<String> selectedCaseFormFactors;
  final Function(String, bool) onCaseFormFactorChanged;

  const _FilterPanel({
    required this.allProducts,
    required this.componentType,
    required this.currentRangeValues,
    required this.onPriceChanged,
    required this.selectedBrands,
    required this.onBrandChanged,
    required this.selectedCpuSockets,
    required this.onCpuSocketChanged,
    required this.selectedCpuSeries,
    required this.onCpuSeriesChanged,
    required this.cpuIncludesCooler,
    required this.onCpuIncludesCoolerChanged,
    required this.selectedMotherboardFormFactors,
    required this.onMotherboardFormFactorChanged,
    required this.selectedMotherboardSockets,
    required this.onMotherboardSocketChanged,
    required this.selectedMotherboardChipsets,
    required this.onMotherboardChipsetChanged,
    required this.selectedRamTypes,
    required this.onRamTypeChanged,
    required this.selectedRamModules,
    required this.onRamModulesChanged,
    required this.ramHasRgb,
    required this.onRamHasRgbChanged,
    required this.selectedStorageTypes,
    required this.onStorageTypeChanged,
    required this.selectedStorageInterfaces,
    required this.onStorageInterfaceChanged,
    required this.selectedPsuEfficiency,
    required this.onPsuEfficiencyChanged,
    required this.selectedPsuWattage,
    required this.onPsuWattageChanged,
    required this.selectedPsuModularity,
    required this.onPsuModularityChanged,
    required this.selectedCaseFormFactors,
    required this.onCaseFormFactorChanged,
  });

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
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ..._buildComponentSpecificFilters(),
        _buildFilterSection<String>(
          title: 'Manufacturer',
          items: _getUniqueValuesFor<String, BaseComponent>(
            (p) => p.manufacturer,
          ),
          selectedItems: selectedBrands,
          onChanged: onBrandChanged,
        ),
        _buildPriceFilter(context),
      ],
    );
  }

  List<Widget> _buildComponentSpecificFilters() {
    switch (componentType) {
      case ComponentType.cpu:
        return [
          _buildFilterSection<String>(
            title: 'Series',
            items: _getUniqueValuesFor<String, CPUComponent>((p) => p.series),
            selectedItems: selectedCpuSeries,
            onChanged: onCpuSeriesChanged,
          ),
          _buildFilterSection<String>(
            title: 'Socket',
            items: _getUniqueValuesFor<String, CPUComponent>(
              (p) => p.socketType,
            ),
            selectedItems: selectedCpuSockets,
            onChanged: onCpuSocketChanged,
          ),
          _buildBooleanFilter(
            title: 'Includes Cooler',
            value: cpuIncludesCooler,
            onChanged: onCpuIncludesCoolerChanged,
          ),
        ];
      case ComponentType.motherboard:
        return [
          _buildFilterSection<String>(
            title: 'Socket',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.socketType,
            ),
            selectedItems: selectedMotherboardSockets,
            onChanged: onMotherboardSocketChanged,
          ),
          _buildFilterSection<String>(
            title: 'Chipset',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.chipsetType,
            ),
            selectedItems: selectedMotherboardChipsets,
            onChanged: onMotherboardChipsetChanged,
          ),
          _buildFilterSection<String>(
            title: 'Form Factor',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.formFactor,
            ),
            selectedItems: selectedMotherboardFormFactors,
            onChanged: onMotherboardFormFactorChanged,
          ),
        ];
      case ComponentType.ram:
        return [
          _buildFilterSection<String>(
            title: 'Type',
            items: _getUniqueValuesFor<String, MemoryComponent>(
              (p) => p.ramType,
            ),
            selectedItems: selectedRamTypes,
            onChanged: onRamTypeChanged,
          ),
          _buildFilterSection<int>(
            title: 'Modules',
            items: _getUniqueValuesFor<int, MemoryComponent>(
              (p) => p.moduleQuantity,
            ),
            selectedItems: selectedRamModules,
            onChanged: onRamModulesChanged,
            displayMapper: (val) => '$val module(s)',
          ),
          _buildBooleanFilter(
            title: 'RGB',
            value: ramHasRgb,
            onChanged: onRamHasRgbChanged,
          ),
        ];
      case ComponentType.psu:
        return [
          _buildFilterSection<String>(
            title: 'Wattage',
            items: const ['0-550', '551-750', '751-1000', '1001-9999'],
            displayItems: const [
              'Up to 550W',
              '551W - 750W',
              '751W - 1000W',
              '1000W+',
            ],
            selectedItems: selectedPsuWattage,
            onChanged: onPsuWattageChanged,
          ),
          _buildFilterSection<String>(
            title: 'Efficiency',
            items: _getUniqueValuesFor<String, PowerSupplyComponent>(
              (p) => p.efficiencyRating!,
            ),
            selectedItems: selectedPsuEfficiency,
            onChanged: onPsuEfficiencyChanged,
          ),
          _buildFilterSection<String>(
            title: 'Modularity',
            items: _getUniqueValuesFor<String, PowerSupplyComponent>(
              (p) => p.modularityType,
            ),
            selectedItems: selectedPsuModularity,
            onChanged: onPsuModularityChanged,
          ),
        ];
      case ComponentType.storage:
        return [
          _buildFilterSection<String>(
            title: 'Type',
            items: _getUniqueValuesFor<String, StorageComponent>(
              (p) => p.driveType,
            ),
            selectedItems: selectedStorageTypes,
            onChanged: onStorageTypeChanged,
          ),
          _buildFilterSection<String>(
            title: 'Interface',
            items: _getUniqueValuesFor<String, StorageComponent>(
              (p) => p.interface,
            ),
            selectedItems: selectedStorageInterfaces,
            onChanged: onStorageInterfaceChanged,
          ),
        ];
      case ComponentType.pcCase:
        return [
          _buildFilterSection<String>(
            title: 'Form Factor',
            items: _getUniqueValuesFor<String, CaseComponent>(
              (p) => p.formFactor,
            ),
            selectedItems: selectedCaseFormFactors,
            onChanged: onCaseFormFactorChanged,
          ),
        ];
      default:
        return [];
    }
  }

  Widget _buildPriceFilter(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          child: RangeSlider(
            values: currentRangeValues,
            min: 0,
            max: 1000,
            divisions: 100,
            labels: RangeLabels(
              '\$${currentRangeValues.start.round()}',
              '\$${currentRangeValues.end.round()}',
            ),
            onChanged: onPriceChanged,
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${currentRangeValues.start.round()}',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            Text(
              '\$${currentRangeValues.end.round()}+',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterSection<T>({
    required String title,
    required List<T> items,
    List<String>? displayItems,
    required List<T> selectedItems,
    required Function(T, bool) onChanged,
    String Function(T)? displayMapper,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(items.length, (index) {
          final item = items[index];
          final displayItem =
              displayMapper?.call(item) ??
              displayItems?[index] ??
              item.toString();
          return CheckboxListTile(
            title: Text(displayItem),
            value: selectedItems.contains(item),
            onChanged: (isSelected) => onChanged(item, isSelected ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
            activeColor: AppColorsDark.textPurple,
          );
        }),
        const Divider(height: 32, color: Colors.transparent),
      ],
    );
  }

  Widget _buildBooleanFilter({
    required String title,
    required bool? value,
    required Function(bool?) onChanged,
  }) {
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

//right panel and bottom widgets
class _ProductList extends StatelessWidget {
  final ComponentType componentType;
  final TextEditingController searchController;
  final List<BaseComponent> products;
  const _ProductList({
    required this.componentType,
    required this.searchController,
    required this.products,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _TopBar(searchController: searchController, count: products.length),
        const SizedBox(height: 24),
        _ProductListHeader(componentType: componentType),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text("No products match your criteria."))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    switch (product.type) {
                      case ComponentType.cpu:
                        return _CpuProductRow(product: product as CPUComponent);
                      case ComponentType.motherboard:
                        return _MotherboardProductRow(
                          product: product as MotherboardComponent,
                        );
                      case ComponentType.ram:
                        return _RamProductRow(
                          product: product as MemoryComponent,
                        );
                      case ComponentType.storage:
                        return _StorageProductRow(
                          product: product as StorageComponent,
                        );
                      case ComponentType.psu:
                        return _PsuProductRow(
                          product: product as PowerSupplyComponent,
                        );
                      case ComponentType.pcCase:
                        return _CaseProductRow(
                          product: product as CaseComponent,
                        );
                      default:
                        return Card(
                          child: ListTile(
                            title: Text(
                              "Unsupported product type: ${product.name}",
                            ),
                          ),
                        );
                    }
                  },
                ),
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final int count;
  const _TopBar({required this.searchController, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Compatible Products ($count)',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        SizedBox(
          width: 250,
          child: TextField(
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

class _ProductListHeader extends StatelessWidget {
  final ComponentType componentType;
  const _ProductListHeader({required this.componentType});

  @override
  Widget build(BuildContext context) {
    List<String> headers;
    List<int> flexValues;

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
      default:
        headers = const ['Product', 'Details', 'Price'];
        flexValues = const [4, 4, 3];
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
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

abstract class _ProductRow extends StatelessWidget {
  final BaseComponent product;
  const _ProductRow({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: buildRow(context),
        ),
      ),
    );
  }

  List<Widget> buildRow(BuildContext context);

  Widget buildNameCell({int flex = 5}) {
    return Expanded(
      flex: flex,
      child: Row(
        children: [
          Image.network(
            product.imageUrl,
            width: 40,
            height: 40,
            errorBuilder: (c, o, s) =>
                Icon(Icons.broken_image, size: 40, color: Colors.grey.shade700),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildTextCell(String text, {int flex = 2}) {
    return Expanded(flex: flex, child: Text(text));
  }

  Widget buildPriceCell(BuildContext context, {int flex = 3}) {
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
              Navigator.pop(context, product);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${product.name} added to your build!',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor: AppColorsDark.success,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.all(16),
                ),
              );
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

class _CpuProductRow extends _ProductRow {
  const _CpuProductRow({required CPUComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    final p = product as CPUComponent;
    return [
      buildNameCell(flex: 4),
      buildTextCell(p.coreTotal.toString(), flex: 1),
      buildTextCell(
        '${p.basePerformanceSpeed}/${p.boostPerformanceSpeed} GHz',
        flex: 2,
      ),
      buildTextCell(p.microarchitecture, flex: 2),
      buildTextCell('${p.thermalDesignPower.toInt()}W', flex: 1),
      buildTextCell(p.graphics, flex: 2),
      Expanded(flex: 2, child: _RatingStars(rating: p.averageRating ?? 0)),
      buildPriceCell(context, flex: 3),
    ];
  }
}

class _MotherboardProductRow extends _ProductRow {
  const _MotherboardProductRow({required MotherboardComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    final p = product as MotherboardComponent;
    return [
      buildNameCell(flex: 5),
      buildTextCell(p.formFactor, flex: 3),
      buildTextCell(p.socketType, flex: 2),
      buildTextCell('${p.ramSlotsAmount}', flex: 2),
      buildPriceCell(context, flex: 3),
    ];
  }
}

class _RamProductRow extends _ProductRow {
  const _RamProductRow({required MemoryComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    final p = product as MemoryComponent;
    return [
      buildNameCell(flex: 5),
      buildTextCell('${p.speed.toInt()} MHz', flex: 2),
      buildTextCell(p.ramType, flex: 2),
      buildTextCell(
        '${p.moduleQuantity}x${p.moduleCapacity.toInt() / 1000}GB',
        flex: 2,
      ),
      buildPriceCell(context, flex: 3),
    ];
  }
}

class _StorageProductRow extends _ProductRow {
  const _StorageProductRow({required StorageComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    final p = product as StorageComponent;
    return [
      buildNameCell(flex: 5),
      buildTextCell('${p.capacity.toInt()} GB', flex: 2),
      buildTextCell(p.driveType, flex: 2),
      buildTextCell(p.interface, flex: 3),
      buildPriceCell(context, flex: 3),
    ];
  }
}

class _PsuProductRow extends _ProductRow {
  const _PsuProductRow({required PowerSupplyComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    final p = product as PowerSupplyComponent;
    return [
      buildNameCell(flex: 5),
      buildTextCell('${p.powerOutput.toInt()}W', flex: 2),
      buildTextCell(p.efficiencyRating ?? 'N/A', flex: 3),
      buildTextCell(p.modularityType, flex: 3),
      buildPriceCell(context, flex: 3),
    ];
  }
}

class _CaseProductRow extends _ProductRow {
  const _CaseProductRow({required CaseComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    final p = product as CaseComponent;
    return [
      buildNameCell(flex: 5),
      buildTextCell(p.formFactor, flex: 3),
      buildTextCell('${p.maxVideoCardLength.toInt()}mm', flex: 2),
      buildTextCell('${p.maxCPUCoolerHeight.toInt()}mm', flex: 2),
      buildPriceCell(context, flex: 3),
    ];
  }
}

class _RatingStars extends StatelessWidget {
  final double rating;
  const _RatingStars({required this.rating});

  @override
  Widget build(BuildContext context) {
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
