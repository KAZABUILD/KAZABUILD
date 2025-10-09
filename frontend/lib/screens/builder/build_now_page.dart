import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/builder/currency_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';

// data models
class Product {
  final String title;
  final double priceInPln;
  final String link;
  final int wattage;

  Product({
    required this.title,
    required this.priceInPln,
    required this.link,
    this.wattage = 0,
  });
}

class PcComponent {
  final String name;
  Product? selectedProduct;
  bool isCompatible;

  PcComponent({
    required this.name,
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
  // copying link
  final String buildLink = 'https://kazabuild.com/b/somerandom123';

  final List<PcComponent> _components = [
    PcComponent(name: 'CPU'),
    PcComponent(name: 'Motherboard'),
    PcComponent(name: 'CPU Cooler'),
    PcComponent(name: 'Ram'),
    PcComponent(name: 'Storage'),
    PcComponent(name: 'Graphics Card'),
    PcComponent(name: 'Power Supply'),
    PcComponent(name: 'Case'),
    PcComponent(name: 'Monitor'),
  ];

  // checking if its empty or not
  bool get _isBuildEmpty {
    return _components.every((component) => component.selectedProduct == null);
  }

  // total price total wat and compatibility
  double get _totalPriceInPln {
    return _components.fold(0.0, (sum, item) {
      return sum + (item.selectedProduct?.priceInPln ?? 0.0);
    });
  }

  int get _estimatedWattage {
    return _components.fold(0, (sum, item) {
      return sum + (item.selectedProduct?.wattage ?? 0);
    });
  }

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
    final convertedPrice = _totalPriceInPln * currencyData.exchangeRate;

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

                        _components[index].isCompatible = true;
                      });
                    },
                    onAdd: (index) {
                      // later this part going to open parts section but for i added test parts

                      setState(() {
                        final bool makeIncompatible = _components
                            .where((c) => c.selectedProduct != null)
                            .length
                            .isOdd;

                        _components[index].selectedProduct = Product(
                          title: 'Sample Product ${index + 1}',
                          priceInPln: 500.0 + (index * 100),
                          link: 'store.com/product',
                          wattage: 50,
                        );

                        _components[index].isCompatible = !makeIncompatible;
                      });
                      print('Add product for ${_components[index].name}');
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

// topbar widget
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.theme,
    required this.buildLink,
    required this.components,
    required this.totalPrice,
    required this.currencyData,
    required this.estimatedWattage,
  });

  final ThemeData theme;
  final String buildLink;
  final List<PcComponent> components;
  final double totalPrice;
  final CurrencyData currencyData;
  final int estimatedWattage;

  String _generateRedditMarkup() {
    final buffer = StringBuffer();
    buffer.writeln('**Component** | **Product** | **Price**');
    buffer.writeln(':----|:----|:----');
    for (final component in components) {
      if (component.selectedProduct != null) {
        final product = component.selectedProduct!;
        buffer.writeln(
          '**${component.name}** | [${product.title}](${product.link}) | ${product.priceInPln.toStringAsFixed(2)} zł',
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

// widgets of comp and price bar
class _CompatibilityAndPriceBar extends ConsumerWidget {
  const _CompatibilityAndPriceBar({
    required this.theme,
    required this.totalPrice,
    required this.currencyData,
    required this.statusMessage,
  });

  final ThemeData theme;
  final double totalPrice;
  final CurrencyData currencyData;
  final String statusMessage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool noIssues =
        statusMessage == 'No issues or incompatibilities found';
    final Color backgroundColor = noIssues
        ? const Color(0xFF0C4F2A)
        : theme.colorScheme.errorContainer;
    final Color iconColor = noIssues
        ? Colors.greenAccent
        : theme.colorScheme.error;
    final IconData iconData = noIssues
        ? Icons.check_circle
        : Icons.warning_amber;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 20),
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

// widgets of componentable
class _ComponentTable extends StatelessWidget {
  const _ComponentTable({
    required this.theme,
    required this.components,
    required this.onRemove,
    required this.onAdd,
  });

  final ThemeData theme;
  final List<PcComponent> components;
  final Function(int) onRemove;
  final Function(int) onAdd;

  @override
  Widget build(BuildContext context) {
    const headerStyle = TextStyle(
      fontWeight: FontWeight.bold,
      color: Colors.grey,
    );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(flex: 2, child: Text('Component', style: headerStyle)),
              Expanded(flex: 3, child: Text('Product', style: headerStyle)),
              Expanded(flex: 2, child: Text('Price', style: headerStyle)),
              Expanded(
                flex: 2,
                child: Text('Product link', style: headerStyle),
              ),
              SizedBox(
                width: 60,
                child: Text(
                  'Remove',
                  style: headerStyle,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          ...List.generate(components.length, (index) {
            final component = components[index];
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
                    flex: 3,
                    child: component.selectedProduct == null
                        ? _AddButton(onPressed: () => onAdd(index))
                        : Text(component.selectedProduct!.title),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      component.selectedProduct == null
                          ? '-'
                          : '${component.selectedProduct!.priceInPln.toStringAsFixed(2)} zł',
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: component.selectedProduct == null
                        ? const Text('-')
                        : InkWell(
                            onTap: () {},
                            child: const Text(
                              'allegro',
                              style: TextStyle(
                                color: Colors.orange,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                  ),
                  SizedBox(
                    width: 60,
                    child: component.selectedProduct == null
                        ? const SizedBox.shrink()
                        : IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              color: theme.colorScheme.error,
                            ),
                            onPressed: () => onRemove(index),
                            splashRadius: 20,
                            tooltip: 'Remove ${component.name}',
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

// widgets of addbutton
class _AddButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _AddButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: const Icon(Icons.add_circle),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}
