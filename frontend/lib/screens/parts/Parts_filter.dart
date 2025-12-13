part of 'part_picker_page.dart';

/// The main filter panel widget that dynamically builds filter options
/// based on the component type.
class DynamicFilterPanel extends ConsumerWidget {
  final ComponentType componentType;

  const DynamicFilterPanel({super.key, required this.componentType});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtersAsync = ref.watch(availableFiltersProvider(componentType));
    final activeFilters = ref.watch(activeFiltersProvider(componentType));
    final notifier = ref.read(activeFiltersProvider(componentType).notifier);

    return filtersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(
        child: Text(
          'Error loading filters',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ),
      data: (filters) {
        // Ensure Price filter is always available and pinned to the top.
        final priceFilter = FilterDefinition(
          key: 'Price',
          label: AppLocalizations.of(context)!.price,
          type: FilterInputType.range,
          min: 0,
          max: 10000,
          unit: 'zł',
          formatValue: (val) => (val as num).toStringAsFixed(0),
        );

        // Avoid duplicating the backend-provided price filter if it ever appears.
        final remainingFilters =
            filters.where((f) => f.key != priceFilter.key).toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: _DynamicRangeFilter(
                filter: priceFilter,
                value: activeFilters[priceFilter.key] as RangeValues?,
                onChanged: (value) =>
                    notifier.setFilter(priceFilter.key, value),
              ),
            ),
            // Iterate through filter definitions and render corresponding widgets
            ...remainingFilters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: _buildFilterWidget(
                  context,
                  filter,
                  activeFilters[filter.key],
                  (value) => notifier.setFilter(filter.key, value),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildFilterWidget(
    BuildContext context,
    FilterDefinition filter,
    dynamic currentValue,
    Function(dynamic) onChanged,
  ) {
    switch (filter.type) {
      case FilterInputType.text:
        return _DynamicTextFilter(
          filter: filter,
          value: currentValue as String?,
          onChanged: onChanged,
        );
      case FilterInputType.select:
        return _DynamicSelectFilter(
          filter: filter,
          value: currentValue,
          onChanged: onChanged,
        );
      case FilterInputType.range:
        return _DynamicRangeFilter(
          filter: filter,
          value: currentValue as RangeValues?,
          onChanged: onChanged,
        );
      case FilterInputType.boolean:
        return _DynamicBooleanFilter(
          filter: filter,
          value: currentValue as bool?,
          onChanged: onChanged,
          context: context,
        );
    }
  }
}

class _DynamicTextFilter extends StatelessWidget {
  final FilterDefinition filter;
  final String? value;
  final ValueChanged<String?> onChanged;

  const _DynamicTextFilter({
    required this.filter,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter ${filter.label}...',
            hintStyle: TextStyle(color: Colors.grey.shade600),
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
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          controller: TextEditingController(text: value),
          onChanged: (val) => onChanged(val.isEmpty ? null : val),
        ),
      ],
    );
  }
}

class _DynamicSelectFilter extends StatefulWidget {
  final FilterDefinition filter;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _DynamicSelectFilter({
    required this.filter,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_DynamicSelectFilter> createState() => _DynamicSelectFilterState();
}

class _DynamicSelectFilterState extends State<_DynamicSelectFilter> {
  late TextEditingController _searchController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Determine if we're in multi-select mode (value is List) or single-select
    final selectedValues =
        widget.value is List ? List<String>.from(widget.value as List) : <String>[];

    // If no options, show disabled text
    if (widget.filter.options == null || widget.filter.options!.isEmpty) {
      return ListTile(
        title: Text(
          widget.filter.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'No options available',
          style: TextStyle(color: Colors.grey),
        ),
        dense: true,
        contentPadding: EdgeInsets.zero,
      );
    }

    // Filter options based on search query
    final filteredOptions = widget.filter.options!.where((option) {
      return option.toString().toLowerCase().contains(_searchQuery);
    }).toList();

    return ExpansionTile(
      title: Text(
        widget.filter.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: selectedValues.isNotEmpty
          ? Text(
              '${selectedValues.length} selected',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
            )
          : null,
      tilePadding: EdgeInsets.zero,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 250),
          decoration: BoxDecoration(
            color: const Color(0xFF13131F),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search ${widget.filter.label}...',
                    hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                    prefixIcon: Icon(Icons.search, size: 18, color: Colors.grey.shade600),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                    isDense: true,
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: filteredOptions.length,
                  itemBuilder: (context, index) {
                    final option = filteredOptions[index].toString();
                    final isSelected = selectedValues.contains(option);
                    return CheckboxListTile(
                      title: Text(
                        option,
                        style: const TextStyle(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      value: isSelected,
                      dense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                      onChanged: (bool? selected) {
                        final newValues = List<String>.from(selectedValues);
                        if (selected == true) {
                          newValues.add(option);
                        } else {
                          newValues.remove(option);
                        }
                        widget.onChanged(newValues.isEmpty ? null : newValues);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DynamicRangeFilter extends StatefulWidget {
  final FilterDefinition filter;
  final RangeValues? value;
  final ValueChanged<RangeValues?> onChanged;

  const _DynamicRangeFilter({
    required this.filter,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_DynamicRangeFilter> createState() => _DynamicRangeFilterState();
}

class _DynamicRangeFilterState extends State<_DynamicRangeFilter> {
  late RangeValues _currentRange;

  @override
  void initState() {
    super.initState();
    _currentRange = widget.value ??
        RangeValues(
          widget.filter.min ?? 0,
          widget.filter.max ?? 100,
        );
  }

  @override
  void didUpdateWidget(covariant _DynamicRangeFilter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      _currentRange = widget.value ??
          RangeValues(
            widget.filter.min ?? 0,
            widget.filter.max ?? 100,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final min = widget.filter.min ?? 0;
    final max = widget.filter.max ?? 100;
    final unit = widget.filter.unit ?? '';
    final formatValue = widget.filter.formatValue ?? (val) => (val as num).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                widget.filter.label,
                style: const TextStyle(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                '${formatValue(_currentRange.start)} - ${formatValue(_currentRange.end)} $unit',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
              ),
            ),
          ],
        ),
        RangeSlider(
          values: _currentRange,
          min: min,
          max: max,
          divisions: (max - min > 0) ? 100 : 1, // Increased divisions for smoother sliding on large ranges
          labels: RangeLabels(
            '${formatValue(_currentRange.start)} $unit',
            '${formatValue(_currentRange.end)} $unit',
          ),
          onChanged: (values) {
            setState(() {
              _currentRange = values;
            });
          },
          onChangeEnd: (values) {
            widget.onChanged(values);
          },
        ),
      ],
    );
  }
}

class _DynamicBooleanFilter extends StatelessWidget {
  final FilterDefinition filter;
  final bool? value;
  final ValueChanged<bool?> onChanged;
  final BuildContext context;

  const _DynamicBooleanFilter({
    required this.filter,
    required this.value,
    required this.onChanged,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          filter.label,
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _BooleanChip(
              label: AppLocalizations.of(context)!.any,
              isSelected: value == null,
              onSelected: () => onChanged(null),
            ),
            _BooleanChip(
              label: AppLocalizations.of(context)!.yes,
              isSelected: value == true,
              onSelected: () => onChanged(true),
            ),
            _BooleanChip(
              label: AppLocalizations.of(context)!.no,
              isSelected: value == false,
              onSelected: () => onChanged(false),
            ),
          ],
        ),
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
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      // Style customization to match app theme if needed
    );
  }
}
