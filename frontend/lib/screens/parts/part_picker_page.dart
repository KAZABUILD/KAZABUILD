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
import 'package:frontend/core/constants/app_color.dart';
import 'package:frontend/models/component_provider.dart';
import 'package:frontend/models/component_models.dart';
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
  final List<PcComponent> currentBuild;
  const PartPickerPage({
    super.key,
    required this.componentType,
    required this.currentBuild,
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

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch the provider to get the async state of our component list.
    final asyncComponents = ref.watch(componentsProvider(widget.componentType));

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
                    child: _LeftPanel(
                      currentBuild: widget.currentBuild,
                      allProducts: asyncComponents.valueOrNull ?? [], // Pass current data or empty list
                      componentType: widget.componentType,
                    ),
                  ),
                  const SizedBox(width: 32),

                  /// The right panel displaying the list of filtered products.
                  Expanded(
                    // Use the provider's state to show loading/error/data UI.
                    child: asyncComponents.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, stack) => Center(child: Text('Error: $err')),
                      data: (products) => _ProductList(
                        componentType: widget.componentType,
                        searchController: _searchController,
                        products: products, // Directly use the data from the provider
                      ),
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

  const _LeftPanel({
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
        // TODO: Implement the actual compatibility filtering logic.
        CheckboxListTile(
          title: const Text(
            'Compatibility Filter',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          value: false, // TODO: Re-enable and implement compatibility logic.
          onChanged: (val) {},
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

  const _FilterPanel({
    required this.allProducts,
    required this.componentType,
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
          selectedItems: [], // Placeholder
          onChanged: (val, sel) {}, // Placeholder
        ),
        _buildPriceFilter(context),
      ],
    );
  }

  /// Dynamically builds the list of filter widgets based on the current [componentType].
  List<Widget> _buildComponentSpecificFilters(WidgetRef ref) {
    // TODO: Implement component-specific filters by updating the filter provider.

    // A switch statement determines which set of filters to show.
    switch (componentType) {
      case ComponentType.cpu:
        return [
          _buildFilterSection<String>(
            title: 'Series',
            items: _getUniqueValuesFor<String, CPUComponent>((p) => p.series),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<String>(
            title: 'Socket',
            items: _getUniqueValuesFor<String, CPUComponent>(
              (p) => p.socketType,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildBooleanFilter(
            title: 'Includes Cooler',
            value: null, // Placeholder
            onChanged: (val) {}, // Placeholder
          ),
        ];
      case ComponentType.motherboard:
        return [
          _buildFilterSection<String>(
            title: 'Socket',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.socketType,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<String>(
            title: 'Chipset',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.chipsetType,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<String>(
            title: 'Form Factor',
            items: _getUniqueValuesFor<String, MotherboardComponent>(
              (p) => p.formFactor,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
        ];
      case ComponentType.ram:
        return [
          _buildFilterSection<String>(
            title: 'Type',
            items: _getUniqueValuesFor<String, MemoryComponent>(
              (p) => p.ramType,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<int>(
            title: 'Modules',
            items: _getUniqueValuesFor<int, MemoryComponent>(
              (p) => p.moduleQuantity,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
            displayMapper: (val) => '$val module(s)',
          ),
          _buildBooleanFilter(
            title: 'RGB',
            value: null, // Placeholder
            onChanged: (val) {}, // Placeholder
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
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<String>(
            title: 'Efficiency',
            items: _getUniqueValuesFor<String, PowerSupplyComponent>(
              (p) => p.efficiencyRating!,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<String>(
            title: 'Modularity',
            items: _getUniqueValuesFor<String, PowerSupplyComponent>(
              (p) => p.modularityType,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
        ];
      case ComponentType.storage:
        return [
          _buildFilterSection<String>(
            title: 'Type',
            items: _getUniqueValuesFor<String, StorageComponent>(
              (p) => p.driveType,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
          _buildFilterSection<String>(
            title: 'Interface',
            items: _getUniqueValuesFor<String, StorageComponent>(
              (p) => p.interface,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
        ];
      case ComponentType.pcCase:
        return [
          _buildFilterSection<String>(
            title: 'Form Factor',
            items: _getUniqueValuesFor<String, CaseComponent>(
              (p) => p.formFactor,
            ),
            selectedItems: [], // Placeholder
            onChanged: (val, sel) {}, // Placeholder
          ),
        ];
      default:
        return [];
    }
  }

  /// Builds the price range slider filter.
  Widget _buildPriceFilter(BuildContext context) {
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
            values: const RangeValues(0, 1000), // Placeholder
            min: 0,
            max: 1000,
            divisions: 100,
            labels: RangeLabels(
              '\$0',
              '\$1000',
            ),
            onChanged: (values) {}, // Placeholder
          ),
        ),
        // Labels showing the current min and max values of the slider.
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$0',
              style: TextStyle(color: Colors.grey.shade400),
            ),
            Text(
              '\$1000+',
              style: TextStyle(color: Colors.grey.shade400),
            ),
          ],
        ),
      ],
    );
  }

  /// A generic function to build a section of checkbox filters.
  Widget _buildFilterSection<T>({
    required String title,
    required List<T> items,
    List<String>? displayItems,
    required List<T> selectedItems,
    required Function(T, bool) onChanged,
    String Function(T)? displayMapper,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    // Each filter section is a column containing a title and a list of checkboxes.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...List.generate(items.length, (index) {
          // Determine the text to display for the checkbox.
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
        /// The top bar with product count and search field.
        _TopBar(searchController: searchController, count: products.length),
        const SizedBox(height: 24),

        /// The header row for the product list table, which is also dynamic.
        _ProductListHeader(componentType: componentType),
        const SizedBox(height: 8),
        Expanded(
          child: products.isEmpty
              /// Display a message if no products match the filters.
              ? const Center(child: Text("No products match your criteria."))
              : ListView.builder(
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];

                    switch (product.type) {
                      /// Dynamically choose the correct row widget based on the product type.
                      case ComponentType.cpu:
                        return _CpuProductRow(
                            product: product as CPUComponent);
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
                      case ComponentType.cooler:
                        // TODO: Create a specific _CoolerProductRow widget for better details.
                        return _GenericProductRow(product: product);
                      case ComponentType.caseFan:
                        // TODO: Create a specific _CaseFanProductRow widget for better details.
                        return _GenericProductRow(product: product);
                      case ComponentType.monitor:
                        // TODO: Create a specific _MonitorProductRow widget for better details.
                        return _GenericProductRow(product: product);
                      case ComponentType.gpu:
                        // TODO: Create a specific _GpuProductRow widget for better details.
                        return _GenericProductRow(product: product);
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

/// The top bar of the product list, containing a title, search bar, and action buttons.
class _TopBar extends StatelessWidget {
  final TextEditingController searchController;
  final int count;
  const _TopBar({required this.searchController, required this.count});

  @override
  Widget build(BuildContext context) {
    // TODO: Make this layout responsive for mobile.
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
    List<String> headers;
    List<int> flexValues;

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
      default:
        headers = const ['Product', 'Details', 'Price'];
        flexValues = const [4, 4, 3];
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
abstract class _ProductRow extends StatelessWidget {
  final BaseComponent product;
  const _ProductRow({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    // The base structure for every product row is a Card with a Row inside.
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

  /// Abstract method to be implemented by subclasses to define the row's content.
  List<Widget> buildRow(BuildContext context);

  /// A reusable widget for the first cell in a row, typically showing the product image and name.
  /// It includes an error builder for the network image.
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

  /// A reusable widget for a simple text cell with a specified flex factor.
  Widget buildTextCell(String text, {int flex = 2}) {
    return Expanded(flex: flex, child: Text(text));
  }

  /// A reusable widget for the last cell, showing the price and an "Add" button.
  /// When the "Add" button is pressed, it pops the current page and returns the selected `product`.
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
              // Pop the navigator and pass the selected product back to the previous screen (`BuildNowPage`).
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

/// A concrete implementation of [_ProductRow] for displaying CPU details.
class _CpuProductRow extends _ProductRow {
  const _CpuProductRow({required CPUComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    // Cast the product to the specific type to access its properties.
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

/// A concrete implementation of [_ProductRow] for displaying Motherboard details.
class _MotherboardProductRow extends _ProductRow {
  const _MotherboardProductRow({required MotherboardComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    // Cast the product to the specific type.
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

/// A concrete implementation of [_ProductRow] for displaying RAM details.
class _RamProductRow extends _ProductRow {
  const _RamProductRow({required MemoryComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    // Cast the product to the specific type.
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

/// A concrete implementation of [_ProductRow] for displaying Storage details.
class _StorageProductRow extends _ProductRow {
  const _StorageProductRow({required StorageComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    // Cast the product to the specific type.
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

/// A concrete implementation of [_ProductRow] for displaying PSU details.
class _PsuProductRow extends _ProductRow {
  const _PsuProductRow({required PowerSupplyComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    // Cast the product to the specific type.
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

/// A concrete implementation of [_ProductRow] for displaying PC Case details.
class _CaseProductRow extends _ProductRow {
  const _CaseProductRow({required CaseComponent product})
    : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    // Cast the product to the specific type.
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

/// A generic fallback implementation of [_ProductRow] for component types without a specific row widget.
class _GenericProductRow extends _ProductRow {
  const _GenericProductRow({required BaseComponent product})
      : super(product: product);

  @override
  List<Widget> buildRow(BuildContext context) {
    return [
      buildNameCell(flex: 5),
      buildTextCell(product.manufacturer, flex: 4),
      buildPriceCell(context, flex: 3),
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
