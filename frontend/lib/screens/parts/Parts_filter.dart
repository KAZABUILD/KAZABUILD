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
      data: (filters) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Iterate through filter definitions and render corresponding widgets
          ...filters.map((filter) {
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
      ),
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
        ),
        const SizedBox(height: 8),
        TextField(
          decoration: InputDecoration(
            hintText: 'Enter ${filter.label}...',
            border: const OutlineInputBorder(),
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

class _DynamicSelectFilter extends StatelessWidget {
  final FilterDefinition filter;
  final dynamic value;
  final ValueChanged<dynamic> onChanged;

  const _DynamicSelectFilter({
    required this.filter,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if we're in multi-select mode (value is List) or single-select
    final selectedValues =
        value is List ? List<String>.from(value as List) : <String>[];

    // If no options, show disabled text
    if (filter.options == null || filter.options!.isEmpty) {
      return ListTile(
        title: Text(
          filter.label,
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

    return ExpansionTile(
      title: Text(
        filter.label,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: selectedValues.isNotEmpty
          ? Text(
              '${selectedValues.length} selected',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : null,
      tilePadding: EdgeInsets.zero,
      children: [
        Container(
          constraints: const BoxConstraints(maxHeight: 200),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: filter.options!.length,
            itemBuilder: (context, index) {
              final option = filter.options![index].toString();
              final isSelected = selectedValues.contains(option);
              return CheckboxListTile(
                title: Text(option, style: const TextStyle(fontSize: 13)),
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
                  onChanged(newValues.isEmpty ? null : newValues);
                },
              );
            },
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
            Text(
              widget.filter.label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(
              '${formatValue(_currentRange.start)} - ${formatValue(_currentRange.end)} $unit',
              style: TextStyle(
                color: Theme.of(context).colorScheme.secondary,
                fontWeight: FontWeight.w500,
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

  const _DynamicBooleanFilter({
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
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _BooleanChip(
              label: 'Any',
              isSelected: value == null,
              onSelected: () => onChanged(null),
            ),
            const SizedBox(width: 8),
            _BooleanChip(
              label: 'Yes',
              isSelected: value == true,
              onSelected: () => onChanged(true),
            ),
            const SizedBox(width: 8),
            _BooleanChip(
              label: 'No',
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
