import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/builder/currency_provider.dart';
import 'package:frontend/screens/builder/part_picker_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';

class BuildNotifier extends StateNotifier<List<PcComponent>> {
  BuildNotifier() : super(_initialState);

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

  void removeComponent(ComponentType type) {
    final currentState = List<PcComponent>.from(state);
    final componentIndex = currentState.indexWhere((c) => c.type == type);

    if (componentIndex != -1) {
      currentState[componentIndex].selectedProduct = null;
      state = currentState;
    }
  }
}

final buildProvider = StateNotifierProvider<BuildNotifier, List<PcComponent>>((
  ref,
) {
  return BuildNotifier();
});

class PcComponent {
  final String name;
  final ComponentType type;
  BaseComponent? selectedProduct;
  bool isCompatible;

  PcComponent({
    required this.name,
    required this.type,
    this.selectedProduct,
    this.isCompatible = true,
  });
}

class BuildNowPage extends ConsumerStatefulWidget {
  const BuildNowPage({super.key});

  @override
  ConsumerState<BuildNowPage> createState() => _BuildNowPageState();
}

class _BuildNowPageState extends ConsumerState<BuildNowPage> {
  final String buildLink = 'https://kazabuild.com/b/somerandom123';

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

  bool get _isBuildEmpty {
    return _components.every((component) => component.selectedProduct == null);
  }

  double get _totalPrice {
    return _components.fold(
      0.0,
      (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
    );
  }

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

  //we will add the logic later
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

    final selectedCurrency = ref.watch(currencyProvider);
    final currencyData = currencyDetails[selectedCurrency]!;
    final convertedPrice = _totalPrice * currencyData.exchangeRate;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  _TopBar(
                    theme: theme,
                    buildLink: buildLink,
                    components: _components,
                    totalPrice: convertedPrice,
                    currencyData: currencyData,
                    estimatedWattage: _estimatedWattage,
                  ),
                  if (!_isBuildEmpty) ...[
                    const SizedBox(height: 16),
                    _CompatibilityAndPriceBar(
                      theme: theme,
                      totalPrice: convertedPrice,
                      currencyData: currencyData,
                      statusMessage: _compatibilityStatus,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ComponentTable(
                    theme: theme,
                    components: _components,
                    onRemove: (index) {
                      setState(() {
                        _components[index].selectedProduct = null;
                      });
                    },
                    onAdd: (index) async {
                      final selectedComponent =
                          await Navigator.push<BaseComponent>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartPickerPage(
                                componentType: _components[index].type,
                                currentBuild: _components,
                              ),
                            ),
                          );

                      if (selectedComponent != null && mounted) {
                        setState(() {
                          _components[index].selectedProduct =
                              selectedComponent;
                        });
                      }
                    },
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

class _TopBar extends StatelessWidget {
  final ThemeData theme;
  final String buildLink;
  final List<PcComponent> components;
  final double totalPrice;
  final CurrencyData currencyData;
  final int estimatedWattage;

  const _TopBar({
    required this.theme,
    required this.buildLink,
    required this.components,
    required this.totalPrice,
    required this.currencyData,
    required this.estimatedWattage,
  });

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
      child: Row(
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
          Expanded(child: Text(buildLink, overflow: TextOverflow.ellipsis)),
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

class _CompatibilityAndPriceBar extends ConsumerWidget {
  final ThemeData theme;
  final double totalPrice;
  final CurrencyData currencyData;
  final String statusMessage;

  const _CompatibilityAndPriceBar({
    required this.theme,
    required this.totalPrice,
    required this.currencyData,
    required this.statusMessage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool hasIssues = statusMessage.toLowerCase().contains('issues found');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: hasIssues
            ? theme.colorScheme.errorContainer
            : const Color(0xFF0C4F2A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            hasIssues ? Icons.warning_amber : Icons.check_circle,
            color: hasIssues ? theme.colorScheme.error : Colors.greenAccent,
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
                ref.read(currencyProvider.notifier).setCurrency(newCurrency);
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

class _ComponentTable extends StatelessWidget {
  final ThemeData theme;
  final List<PcComponent> components;
  final Function(int) onRemove;
  final Function(int) onAdd;

  const _ComponentTable({
    required this.theme,
    required this.components,
    required this.onRemove,
    required this.onAdd,
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
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
                    child: Padding(
                      padding: const EdgeInsets.only(right: 24.0),
                      child: Text(
                        product == null
                            ? '-'
                            : '\$${product.lowestPrice?.toStringAsFixed(2) ?? 'N/A'}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 120,
                    child: product == null
                        ? Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Part'),
                              onPressed: () => onAdd(index),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
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
