/// Admin Parts Management Page
/// 
/// Provides component/part management interface with categorization and actions.
library;

import 'package:flutter/material.dart';
import '../../core/constants/app_color.dart';

class AdminPartsPage extends StatefulWidget {
  const AdminPartsPage({super.key});

  @override
  State<AdminPartsPage> createState() => _AdminPartsPageState();
}

class _AdminPartsPageState extends State<AdminPartsPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'CPU', 'GPU', 'RAM', 'Motherboard', 'Storage', 'PSU', 'Case'];

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
            color: Colors.black.withOpacity(0.05),
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
                  onChanged: (value) => setState(() {}),
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

  Widget _buildContent(bool isDark) {
    final parts = List.generate(
      15,
      (index) => {
        'id': 'part_${index + 1}',
        'name': 'Component ${index + 1}',
        'brand': ['Intel', 'AMD', 'NVIDIA', 'Corsair', 'Samsung'][index % 5],
        'category': _categories[(index % (_categories.length - 1)) + 1],
        'price': (index * 50 + 100).toDouble(),
        'stock': (index * 10) % 100,
        'rating': (4.0 + (index % 2) * 0.5),
      },
    );

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatsRow(isDark),
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
                    child: ListView.builder(
                      itemCount: parts.length,
                      itemBuilder: (context, index) {
                        return _buildPartRow(parts[index], isDark);
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

  Widget _buildStatsRow(bool isDark) {
    final stats = [
      {'label': 'Total Parts', 'value': '2,890', 'icon': Icons.memory, 'color': AppColorsDark.buttonBlue},
      {'label': 'In Stock', 'value': '2,456', 'icon': Icons.inventory, 'color': AppColorsDark.buttonGreen},
      {'label': 'Out of Stock', 'value': '234', 'icon': Icons.inventory_2, 'color': AppColorsDark.error},
      {'label': 'Categories', 'value': '8', 'icon': Icons.category, 'color': AppColorsDark.buttonPurple},
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
                    ? Colors.white.withOpacity(0.1)
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withOpacity(0.2),
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
                              ? AppColorsDark.textWhite.withOpacity(0.7)
                              : AppColorsLight.textBlack.withOpacity(0.7),
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
                ? Colors.white.withOpacity(0.1)
                : Colors.black.withOpacity(0.1),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: _buildHeaderCell('Part Name', isDark)),
          Expanded(flex: 2, child: _buildHeaderCell('Brand', isDark)),
          Expanded(flex: 1, child: _buildHeaderCell('Category', isDark)),
          Expanded(flex: 1, child: _buildHeaderCell('Price', isDark)),
          Expanded(flex: 1, child: _buildHeaderCell('Stock', isDark)),
          Expanded(flex: 1, child: _buildHeaderCell('Rating', isDark)),
          Expanded(flex: 1, child: _buildHeaderCell('Actions', isDark)),
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

  Widget _buildPartRow(Map<String, dynamic> part, bool isDark) {
    final stockColor = part['stock'] > 10
        ? AppColorsDark.buttonGreen
        : part['stock'] > 0
            ? AppColorsDark.warning
            : AppColorsDark.error;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.05),
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
                    color: AppColorsDark.buttonPurple.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.memory),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    part['name'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? AppColorsDark.textWhite
                          : AppColorsLight.textBlack,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              part['brand'],
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColorsDark.buttonBlue.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                part['category'],
                style: TextStyle(
                  color: AppColorsDark.buttonBlue,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              '\$${part['price'].toStringAsFixed(2)}',
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite
                    : AppColorsLight.textBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: stockColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                part['stock'].toString(),
                style: TextStyle(
                  color: stockColor,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, size: 16, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  part['rating'].toStringAsFixed(1),
                  style: TextStyle(
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: () {},
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete, size: 18),
                  onPressed: () {},
                  tooltip: 'Delete',
                  color: AppColorsDark.error,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

