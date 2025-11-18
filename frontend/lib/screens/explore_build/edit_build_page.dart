/// This file defines the edit page for a PC build.
///
/// It allows the build owner to modify the build's name, description, and status.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/l10n/app_localization.dart';
import 'package:flutter/foundation.dart';

/// A page that allows editing a build's details.
class EditBuildPage extends ConsumerStatefulWidget {
  final String buildId;

  const EditBuildPage({super.key, required this.buildId});

  @override
  ConsumerState<EditBuildPage> createState() => _EditBuildPageState();
}

class _EditBuildPageState extends ConsumerState<EditBuildPage> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String? _selectedStatus;
  bool _isLoading = false;
  bool _isSaving = false;
  Map<String, String> _buildComponentIdMap = {}; // Maps componentId -> buildComponentId for deletion

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final buildAsync = ref.watch(buildDetailProvider(widget.buildId));
    final currentUser = ref.watch(authProvider).valueOrNull;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: buildAsync.when(
              data: (build) {
                // Check if user is the owner
                if (currentUser == null || currentUser.uid != build.userId) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Unauthorized',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'You can only edit your own builds.',
                            style: theme.textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => context.go('/build/${widget.buildId}'),
                            child: const Text('Go Back'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Initialize form fields if not already set
                if (!_isLoading && _nameController.text.isEmpty) {
                  _nameController.text = build.name;
                  _descriptionController.text = build.description ?? '';
                  _selectedStatus = build.status;
                  _isLoading = true;
                  // Load BuildComponent IDs for deletion
                  _loadBuildComponentIds(ref);
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 800),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.arrow_back),
                                onPressed: () => context.go('/build/${widget.buildId}'),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Edit Build',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          // Build Name
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Build Name',
                              hintText: 'Enter build name',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.title),
                            ),
                            maxLength: 50,
                          ),
                          const SizedBox(height: 24),
                          // Description
                          TextField(
                            controller: _descriptionController,
                            decoration: InputDecoration(
                              labelText: 'Description',
                              hintText: 'Enter description',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.description),
                              alignLabelWithHint: true,
                            ),
                            maxLines: 10,
                            maxLength: 5000,
                          ),
                          const SizedBox(height: 24),
                          // Status
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: const OutlineInputBorder(),
                              prefixIcon: const Icon(Icons.info_outline),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'DRAFT',
                                child: Text('Draft'),
                              ),
                              DropdownMenuItem(
                                value: 'PUBLISHED',
                                child: Text('Published'),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() {
                                _selectedStatus = value;
                              });
                            },
                          ),
                          const SizedBox(height: 32),
                          // Components Section
                          _buildComponentsSection(context, ref, theme, build),
                          const SizedBox(height: 32),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              OutlinedButton(
                                onPressed: _isSaving
                                    ? null
                                    : () => context.go('/build/${widget.buildId}'),
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton.icon(
                                onPressed: _isSaving ? null : () => _saveBuild(context, ref),
                                icon: _isSaving
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.save),
                                label: const Text('Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading build',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        err.toString(),
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => context.go('/build/${widget.buildId}'),
                        child: const Text('Go Back'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBuild(BuildContext context, WidgetRef ref) async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Build name is required'),
        ),
      );
      return;
    }

    if (_nameController.text.trim().length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Build name must be at least 3 characters'),
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final buildService = ref.read(buildServiceProvider);
      // Backend expects PascalCase property names
      final updateData = <String, dynamic>{
        'Name': _nameController.text.trim(),
        'Description': _descriptionController.text.trim().isEmpty 
            ? 'No description provided.' 
            : _descriptionController.text.trim(),
      };

      if (_selectedStatus != null) {
        updateData['Status'] = _selectedStatus;
      }

      await buildService.updateBuild(widget.buildId, updateData);

      // Invalidate the build detail provider to refresh the data
      ref.invalidate(buildDetailProvider(widget.buildId));
      
      // Get current user to invalidate their builds list
      final currentUser = ref.read(authProvider).valueOrNull;
      if (currentUser != null) {
        ref.invalidate(userBuildsProvider(currentUser.uid));
      }
      
      // If status was changed to PUBLISHED, invalidate explore builds to refresh the list
      if (_selectedStatus == 'PUBLISHED') {
        // Invalidate all explore builds providers by invalidating the family provider
        // This will refresh the explore builds page when user navigates to it
        ref.invalidate(exploreBuildsProvider);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully saved'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        // Wait a bit to show the snackbar before navigating
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/build/${widget.buildId}');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating build: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _loadBuildComponentIds(WidgetRef ref) async {
    try {
      final buildService = ref.read(buildServiceProvider);
      final buildComponents = await buildService.getBuildComponentIds(widget.buildId);
      
      setState(() {
        _buildComponentIdMap = {};
        for (var bc in buildComponents) {
          final componentId = (bc['componentId'] ?? bc['ComponentId'] ?? '').toString();
          final buildComponentId = (bc['id'] ?? bc['Id'] ?? '').toString();
          if (componentId.isNotEmpty && buildComponentId.isNotEmpty) {
            _buildComponentIdMap[componentId] = buildComponentId;
          }
        }
      });
    } catch (e) {
      debugPrint('Error loading build component IDs: $e');
    }
  }

  Widget _buildComponentsSection(BuildContext context, WidgetRef ref, ThemeData theme, Build build) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Components',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddComponentDialog(context, ref, theme, build),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Component'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (build.components.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.1),
              ),
            ),
            child: Center(
              child: Text(
                'No components added yet. Click "Add Component" to add components to your build.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ),
          )
        else
          ...build.components.map((component) {
            return _buildComponentCard(context, ref, theme, component);
          }).toList(),
      ],
    );
  }

  Widget _buildComponentCard(BuildContext context, WidgetRef ref, ThemeData theme, BaseComponent component) {
    final buildComponentId = _buildComponentIdMap[component.id];
    final lowestPrice = component.prices.isNotEmpty
        ? component.prices.map((p) => p.price).reduce((a, b) => a < b ? a : b)
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getComponentTypeIcon(component.type),
              size: 24,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  component.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  component.manufacturer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                if (lowestPrice != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '\$${lowestPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: buildComponentId != null
                ? () => _removeComponent(context, ref, buildComponentId)
                : null,
            tooltip: 'Remove component',
          ),
        ],
      ),
    );
  }

  IconData _getComponentTypeIcon(ComponentType type) {
    switch (type) {
      case ComponentType.cpu:
        return Icons.memory;
      case ComponentType.gpu:
        return Icons.videocam;
      case ComponentType.motherboard:
        return Icons.dashboard;
      case ComponentType.ram:
        return Icons.view_module;
      case ComponentType.storage:
        return Icons.storage;
      case ComponentType.psu:
        return Icons.power;
      case ComponentType.cooler:
        return Icons.ac_unit;
      case ComponentType.caseFan:
        return Icons.toys;
      case ComponentType.pcCase:
        return Icons.view_in_ar;
      case ComponentType.monitor:
        return Icons.monitor;
    }
  }

  Future<void> _showAddComponentDialog(BuildContext context, WidgetRef ref, ThemeData theme, Build build) async {
    // Show dialog to select component type
    final componentType = await showDialog<ComponentType>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Component Type'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: ComponentType.values.map((type) {
              return ListTile(
                leading: Icon(_getComponentTypeIcon(type)),
                title: Text(_getComponentTypeName(context, type)),
                onTap: () => Navigator.of(context).pop(type),
              );
            }).toList(),
          ),
        ),
      ),
    );

    if (componentType != null && mounted) {
      // Navigate to part picker with callback to handle component selection
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PartPickerPage(
            componentType: componentType,
            currentBuild: null, // We don't need compatibility check in edit mode
            onComponentSelected: (BaseComponent selected) async {
              // Handle component selection directly
              if (selected.id.isEmpty) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Selected component has no ID. Try another.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
                return;
              }

              try {
                final buildService = ref.read(buildServiceProvider);
                await buildService.addComponentToBuild(widget.buildId, selected.id, 1);
                
                // Refresh build data
                ref.invalidate(buildDetailProvider(widget.buildId));
                await _loadBuildComponentIds(ref);

                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Component added successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error adding component: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
          ),
        ),
      );

    }
  }

  String _getComponentTypeName(BuildContext context, ComponentType type) {
    final l10n = AppLocalizations.of(context)!;
    switch (type) {
      case ComponentType.cpu:
        return l10n.cpu;
      case ComponentType.gpu:
        return l10n.gpu;
      case ComponentType.motherboard:
        return l10n.motherboard;
      case ComponentType.ram:
        return l10n.memoryRam;
      case ComponentType.storage:
        return l10n.storage;
      case ComponentType.psu:
        return l10n.powerSupply;
      case ComponentType.cooler:
        return l10n.cooler;
      case ComponentType.caseFan:
        return l10n.caseFan;
      case ComponentType.pcCase:
        return l10n.pcCase;
      case ComponentType.monitor:
        return l10n.monitor;
    }
  }

  Future<void> _removeComponent(BuildContext context, WidgetRef ref, String buildComponentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Component'),
        content: const Text('Are you sure you want to remove this component from the build?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final buildService = ref.read(buildServiceProvider);
        await buildService.removeComponentFromBuild(buildComponentId);
        
        // Refresh build data
        ref.invalidate(buildDetailProvider(widget.buildId));
        await _loadBuildComponentIds(ref);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Component removed successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error removing component: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}

