/// This file defines the main PC builder interface, the "Build Now" page.
///
/// It allows users to view and manage a list of PC component slots. Users can
/// add components by navigating to the `PartPickerPage`, remove them, and see
/// a running total of the price and estimated wattage.
/// The state of the build is managed using Riverpod, with `BuildNotifier` holding
/// the list of selected components. The page is responsive, adapting its layout
/// for mobile and desktop screens.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/currency_provider.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

/// Manages the state of the PC build, which is a list of component slots.
///
/// This notifier handles adding, updating, and removing components from the current build.
/// It holds the central "source of truth" for the user's in-progress PC.
class BuildNotifier extends StateNotifier<List<PcComponent>> {
  /// Initializes the build with a default set of empty component slots.
  BuildNotifier() : super(_initialState);

  /// Defines the default template for a new PC build, listing all necessary component types.
  static final List<PcComponent> _initialState = [
    PcComponent(name: 'CPU', type: ComponentType.cpu),
    PcComponent(name: 'Motherboard', type: ComponentType.motherboard),
    PcComponent(name: 'CPU Cooler', type: ComponentType.cooler),
    PcComponent(name: 'Memory (RAM)', type: ComponentType.ram),
    PcComponent(name: 'Storage', type: ComponentType.storage),
    PcComponent(name: 'Video Card', type: ComponentType.gpu),
    PcComponent(name: 'Power Supply', type: ComponentType.psu),
    PcComponent(name: 'Case', type: ComponentType.pcCase),
    PcComponent(name: 'Monitor', type: ComponentType.monitor),
  ];

  /// Adds or updates a component in the build.
  ///
  /// It finds the correct component slot by its [ComponentType] and replaces
  /// the `selectedProduct` with the new one. This triggers a state update.
  void addComponent(BaseComponent newProduct) {
    final currentState = List<PcComponent>.from(state);
    final componentIndex = currentState.indexWhere(
      (c) => c.type == newProduct.type,
    );

    if (componentIndex != -1) {
      currentState[componentIndex].selectedProduct = newProduct;
      state = currentState;
    }
  }

  /// Removes a selected component from a slot, setting it back to null.
  ///
  /// Finds the component slot by its [ComponentType] and clears the `selectedProduct`.
  void removeComponent(ComponentType type) {
    final currentState = List<PcComponent>.from(state);
    final componentIndex = currentState.indexWhere((c) => c.type == type);

    if (componentIndex != -1) {
      currentState[componentIndex].selectedProduct = null;
      state = currentState;
    }
  }
}

/// The global Riverpod provider for accessing the [BuildNotifier].
///
/// Widgets can use this provider to watch the build state and call methods
/// to modify the build.
final buildProvider = StateNotifierProvider<BuildNotifier, List<PcComponent>>((
  ref,
) {
  return BuildNotifier();
});

/// Represents a single slot in the PC build list (e.g., CPU, GPU).
class PcComponent {
  /// The display name of the component slot (e.g., "CPU", "Motherboard").
  final String name;

  /// The type of the component, used for filtering and identification.
  final ComponentType type;

  /// The actual component selected by the user. It is nullable if no part is chosen.
  BaseComponent? selectedProduct;

  /// A flag to indicate if the selected component is compatible with the rest of the build.
  // TODO: Implement compatibility check logic to update this flag.
  bool isCompatible;

  PcComponent({
    required this.name,
    required this.type,
    this.selectedProduct,
    this.isCompatible = true,
  });
}

/// The main UI widget for the "Build Now" page.
class BuildNowPage extends ConsumerStatefulWidget {
  const BuildNowPage({super.key});

  @override
  ConsumerState<BuildNowPage> createState() => _BuildNowPageState();
}

/// The state for the [BuildNowPage].
class _BuildNowPageState extends ConsumerState<BuildNowPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A mock link for sharing the build.
  // TODO: This should be generated dynamically based on the build's state.
  final String buildLink = 'https://kazabuild.com/b/somerandom123';

  // TODO: This local `_components` list is currently a duplicate of the state in `buildProvider`.
  // For better state management, this should be removed and the UI should directly `ref.watch(buildProvider)`.
  final List<PcComponent> _components = [
    PcComponent(name: 'CPU', type: ComponentType.cpu),
    PcComponent(name: 'Motherboard', type: ComponentType.motherboard),
    PcComponent(name: 'CPU Cooler', type: ComponentType.cooler),
    PcComponent(name: 'Memory (RAM)', type: ComponentType.ram),
    PcComponent(name: 'Storage', type: ComponentType.storage),
    PcComponent(name: 'Video Card', type: ComponentType.gpu),
    PcComponent(name: 'Power Supply', type: ComponentType.psu),
    PcComponent(name: 'Case', type: ComponentType.pcCase),
    PcComponent(name: 'Monitor', type: ComponentType.monitor),
  ];

  /// A computed property to check if any components have been selected in the build.
  bool get _isBuildEmpty {
    return _components.every((component) => component.selectedProduct == null);
  }

  /// A computed property to calculate the total price of all selected components.
  double get _totalPrice {
    return _components.fold(
      0.0,
      (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
    );
  }

  /// A computed property to calculate the estimated power consumption in watts.
  /// This is based on the Thermal Design Power (TDP) of the CPU and GPU.
  // TODO: Make this calculation more comprehensive by including other components.
  int get _estimatedWattage {
    return _components.fold(0, (sum, item) {
      final product = item.selectedProduct;
      if (product is CPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      if (product is GPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      return sum;
    });
  }

  /// A computed property to determine the overall compatibility status of the build.
  // TODO: Implement a real compatibility check engine instead of this placeholder logic.
  String get _compatibilityStatus {
    final selectedComponents = _components
        .where((c) => c.selectedProduct != null)
        .toList();
    if (selectedComponents.isEmpty) {
      return 'No issues or incompatibilities found';
    }
    bool allCompatible = selectedComponents.every((c) => c.isCompatible);
    return allCompatible
        ? 'No issues or incompatibilities found'
        : 'Compatibility issues found!';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    /// Watches the selected currency and gets its details for price conversion.
    final selectedCurrency = ref.watch(currencyProvider);
    final currencyData = currencyDetails[selectedCurrency]!;
    final convertedPrice = _totalPrice * currencyData.exchangeRate;

    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),

              /// The main content column of the page.
              child: Column(
                children: [
                  _TopBar(
                    theme: theme,
                    buildLink: buildLink,
                    components: _components,
                    totalPrice: convertedPrice,
                    currencyData: currencyData,
                    estimatedWattage: _estimatedWattage,
                    isMobile: isMobile,
                  ),
                  // The compatibility and price bar is only shown if the build is not empty.
                  if (!_isBuildEmpty) ...[
                    const SizedBox(height: 16),
                    _CompatibilityAndPriceBar(
                      theme: theme,
                      totalPrice: convertedPrice,
                      currencyData: currencyData,
                      statusMessage: _compatibilityStatus,
                      isMobile: isMobile,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ComponentTable(
                    theme: theme,
                    components: _components,

                    /// Callback to remove a component from the build.
                    /// This updates the local state.
                    onRemove: (index) {
                      setState(() {
                        _components[index].selectedProduct = null;
                      });
                    },
                    onAdd: (index) async {
                      /// Navigates to the PartPickerPage to let the user select a component.
                      /// The result (the selected component) is returned via `Navigator.pop`.
                      final BaseComponent? selectedComponent =
                          await Navigator.push<BaseComponent>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartPickerPage(
                                componentType: _components[index].type,
                                currentBuild: _components,
                              ),
                            ),
                          );

                      /// If a component was selected and the widget is still mounted, update the state.
                      if (selectedComponent != null && mounted) {
                        setState(() {
                          _components[index].selectedProduct =
                              selectedComponent;
                        });
                      }
                    },
                    isMobile: isMobile,
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

/// The top bar of the builder page, containing the build link and action buttons.
class _TopBar extends StatelessWidget {
  final ThemeData theme;
  final String buildLink;
  final List<PcComponent> components;
  final double totalPrice;
  final CurrencyData currencyData;
  final int estimatedWattage;
  final bool isMobile; // Added isMobile

  const _TopBar({
    required this.theme,
    required this.buildLink,
    required this.components,
    required this.totalPrice,
    required this.currencyData,
    required this.estimatedWattage,
    required this.isMobile, // Added isMobile
  });

  /// Generates a Reddit-compatible markdown table of the current build.
  String _generateRedditMarkup() {
    final buffer = StringBuffer();
    buffer.writeln('**Component** | **Product** | **Price**');
    buffer.writeln(':----|:----|:----');
    for (final component in components) {
      if (component.selectedProduct != null) {
        final product = component.selectedProduct!;
        buffer.writeln(
          '**${component.name}** | ${product.name} | \$${product.lowestPrice?.toStringAsFixed(2) ?? '-'}',
        );
      }
    }
    buffer.writeln(
      '\n**Total Price:** ${totalPrice.toStringAsFixed(2)} ${currencyData.symbol}',
    );
    buffer.writeln('**Estimated Wattage:** ${estimatedWattage}W');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),

      /// Displays a different layout for mobile and desktop.
      child: isMobile
          /// Mobile layout for the top bar.
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.link, size: 20),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: buildLink));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Build link copied to clipboard!'),
                          ),
                        );
                      },
                      tooltip: 'Copy build link',
                    ),
                    Expanded(
                      child: Text(buildLink, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Text('Markup:'),
                    IconButton(
                      onPressed: () {
                        final markup = _generateRedditMarkup();
                        Clipboard.setData(ClipboardData(text: markup));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Reddit Markup copied to clipboard!'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.code),
                      tooltip: 'Copy Reddit Markup',
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.send, size: 18),
                      label: const Text('Post Build'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary,
                        foregroundColor: theme.colorScheme.onSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Build'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text('Estimated wattage: ${estimatedWattage}W'),
              ],
            )
          : Row(
              /// Desktop layout for the top bar.
              children: [
                IconButton(
                  icon: const Icon(Icons.link, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: buildLink));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Build link copied to clipboard!'),
                      ),
                    );
                  },
                  tooltip: 'Copy build link',
                ),
                Expanded(
                  child: Text(buildLink, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 16),
                const Text('Markup:'),
                IconButton(
                  onPressed: () {
                    final markup = _generateRedditMarkup();
                    Clipboard.setData(ClipboardData(text: markup));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reddit Markup copied to clipboard!'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.code),
                  tooltip: 'Copy Reddit Markup',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.send, size: 18),
                  label: const Text('Post Build'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Build'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const Spacer(),
                Text('Estimated wattage: ${estimatedWattage}W'),
              ],
            ),
    );
  }
}

/// A bar that displays the compatibility status and the total price of the build.
class _CompatibilityAndPriceBar extends ConsumerWidget {
  final ThemeData theme;
  final double totalPrice;
  final CurrencyData currencyData;
  final String statusMessage;
  final bool isMobile; // Added isMobile

  const _CompatibilityAndPriceBar({
    required this.theme,
    required this.totalPrice,
    required this.currencyData,
    required this.statusMessage,
    required this.isMobile, // Added isMobile
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasIssues = statusMessage.toLowerCase().contains('issues found');

    // The background color changes based on the compatibility status.
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasIssues
            ? theme.colorScheme.errorContainer
            : const Color(0xFF0C4F2A),
        borderRadius: BorderRadius.circular(8),
      ),

      /// Displays a different layout for mobile and desktop.
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      hasIssues ? Icons.warning_amber : Icons.check_circle,
                      color: hasIssues
                          ? theme.colorScheme.error
                          : Colors.greenAccent,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        statusMessage,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  // Price and currency row for mobile.
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Total Price: ',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withOpacity(0.8),
                      ),
                    ),

                    /// Dropdown to allow the user to change the currency.
                    DropdownButton<Currency>(
                      value: ref.watch(currencyProvider),
                      onChanged: (Currency? newCurrency) {
                        if (newCurrency != null) {
                          ref
                              .read(currencyProvider.notifier)
                              .setCurrency(newCurrency);
                        }
                      },
                      icon: const Icon(
                        Icons.arrow_drop_down,
                        color: Colors.white,
                      ),
                      underline: const SizedBox(),
                      items: Currency.values.map((Currency currency) {
                        return DropdownMenuItem<Currency>(
                          value: currency,
                          child: Text(
                            currencyDetails[currency]!.symbol,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    Text(
                      totalPrice.toStringAsFixed(2),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            )
          : Row(
              /// Desktop layout for the compatibility and price bar.
              children: [
                Icon(
                  hasIssues ? Icons.warning_amber : Icons.check_circle,
                  color: hasIssues
                      ? theme.colorScheme.error
                      : Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                Text(
                  'Total Price: ',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                DropdownButton<Currency>(
                  value: ref.watch(currencyProvider),
                  onChanged: (Currency? newCurrency) {
                    if (newCurrency != null) {
                      ref
                          .read(currencyProvider.notifier)
                          .setCurrency(newCurrency);
                    }
                  },
                  icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
                  underline: const SizedBox(),
                  items: Currency.values.map((Currency currency) {
                    return DropdownMenuItem<Currency>(
                      value: currency,
                      child: Text(
                        currencyDetails[currency]!.symbol,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList(),
                ),
                Text(
                  totalPrice.toStringAsFixed(2),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
    );
  }
}

/// The main table widget that lists all component slots in the build.
class _ComponentTable extends StatelessWidget {
  final ThemeData theme;
  final List<PcComponent> components;
  final Function(int) onRemove;
  final Function(int) onAdd;
  final bool isMobile; // Added isMobile

  const _ComponentTable({
    required this.theme,
    required this.components,
    required this.onRemove,
    required this.onAdd,
    required this.isMobile, // Added isMobile
  });

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),

      /// Renders a list of cards on mobile and a table on desktop.
      child: isMobile
          /// Mobile layout: A vertical list of cards for each component.
          ? Column(
              children: List.generate(components.length, (index) {
                final component = components[index];
                final product = component.selectedProduct;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
                  elevation: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          component.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          product == null ? 'No part selected.' : product.name,
                          style: product == null
                              ? TextStyle(
                                  color: Colors.grey.shade400,
                                  fontStyle: FontStyle.italic,
                                )
                              : theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            product == null
                                ? '-'
                                : '\$${product.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        product == null
                            ? Center(
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.add, size: 16),
                                  label: const Text('Add Part'),
                                  onPressed: () => onAdd(index),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor:
                                        theme.colorScheme.onPrimary,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      color: theme.colorScheme.secondary,
                                      size: 20,
                                    ),
                                    onPressed: () => onAdd(index),
                                    tooltip: 'Change ${component.name}',
                                    splashRadius: 20,
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    onPressed: () => onRemove(index),
                                    tooltip: 'Remove ${component.name}',
                                    splashRadius: 20,
                                  ),
                                ],
                              ),
                      ],
                    ),
                  ),
                );
              }),
            )
          /// Desktop layout: A structured table with headers.
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),

                  /// Table header row.
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 2,
                        child: Text('Component', style: headerStyle),
                      ),
                      const Expanded(
                        flex: 4,
                        child: Text('Selection', style: headerStyle),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text(
                            'Price',
                            style: headerStyle,
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 120,
                        child: Text(
                          'Actions',
                          style: headerStyle,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),

                /// Generates a row for each component slot.
                ...List.generate(components.length, (index) {
                  final component = components[index];
                  final product = component.selectedProduct;
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 8.0,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            component.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          flex: 4,

                          /// Displays the selected product's name or a placeholder.
                          child: product == null
                              ? Text(
                                  'No part selected.',
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontStyle: FontStyle.italic,
                                  ),
                                )
                              : Text(
                                  product.name,
                                  style: const TextStyle(fontSize: 14),
                                ),
                        ),
                        Expanded(
                          flex: 2,

                          /// Displays the price of the selected product.
                          child: Padding(
                            padding: const EdgeInsets.only(right: 24.0),
                            child: Text(
                              product == null
                                  ? '-'
                                  : '\$${product.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 120,

                          /// Shows an "Add Part" button or "Edit/Delete" icons.
                          child: product == null
                              ? Center(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.add, size: 16),
                                    label: const Text('Add Part'),
                                    onPressed: () => onAdd(index),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor:
                                          theme.colorScheme.primary,
                                      foregroundColor:
                                          theme.colorScheme.onPrimary,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        Icons.edit_outlined,
                                        color: theme.colorScheme.secondary,
                                        size: 20,
                                      ),
                                      onPressed: () => onAdd(index),
                                      tooltip: 'Change ${component.name}',
                                      splashRadius: 20,
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: theme.colorScheme.error,
                                        size: 20,
                                      ),
                                      onPressed: () => onRemove(index),
                                      tooltip: 'Remove ${component.name}',
                                      splashRadius: 20,
                                    ),
                                  ],
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
