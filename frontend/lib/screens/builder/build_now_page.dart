/// This file defines the main PC builder interface, the "Build Now" page.
///
/// It allows users to view and manage a list of PC component slots. Users can
/// add components by navigating to the `PartPickerPage`, remove them, and see
/// a running total of the price and estimated wattage.
/// The state of the build is managed using Riverpod, with `BuildNotifier` holding
/// the list of selected components. The page is responsive, adapting its layout
/// for mobile and desktop screens.
/// for mobile and desktop screens.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/component_models.dart';
import 'package:frontend/models/currency_provider.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/screens/parts/part_picker_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:frontend/l10n/app_localization.dart';

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
    PcComponent(name: 'GPU (Video Card)', type: ComponentType.gpu),
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

  /// Resets the build to its initial empty state.
  void clearBuild() {
    state = _initialState.map((c) => PcComponent(name: c.name, type: c.type)).toList();
  }

  /// Saves the current build to the backend.
  Future<String> saveBuild(WidgetRef ref, String name, String description, {List<String>? tagIds}) async {
    final buildService = ref.read(buildServiceProvider);
    final userId = ref.read(authProvider).valueOrNull?.uid;

    if (userId == null) {
      throw Exception('You must be logged in to save a build.');
    }

    // 1. Create the main build entry.
    // Backend expects PascalCase property names and Description is required (cannot be empty)
    final newBuildId = await buildService.createBuild({
      'UserId': userId,
      'Name': name.trim(),
      'Description': description.trim().isEmpty ? 'No description provided.' : description.trim(),
      'Status': 'DRAFT',
    });

    // 2. Add each selected component to the newly created build in parallel
    final selectedComponents = state.where((slot) => slot.selectedProduct != null).toList();
    debugPrint('saveBuild: Found ${selectedComponents.length} selected components in state');
    
    if (selectedComponents.isNotEmpty) {
      final componentFutures = selectedComponents.map((componentSlot) async {
        final component = componentSlot.selectedProduct!;
        final componentId = component.id;
        
        debugPrint('saveBuild: Processing component ${component.name} (ID: $componentId, Type: ${component.type})');
        
        if (componentId.isEmpty) {
          debugPrint('saveBuild: ERROR - Component ${component.name} has empty ID! Skipping.');
          return;
        }
        
        try {
          await buildService.addComponentToBuild(
            newBuildId,
            componentId,
            1,
          );
          debugPrint('saveBuild: Successfully added component ${component.name} to build');
        } catch (e) {
          debugPrint('saveBuild: ERROR adding component ${component.name} to build: $e');
          // Don't throw - continue with other components
        }
      }).toList();
      
      // Wait for all components to be added in parallel
      await Future.wait(componentFutures, eagerError: false);
    }

    // 3. Add tags to the build if provided (in parallel)
    if (tagIds != null && tagIds.isNotEmpty) {
      final tagFutures = tagIds.map((tagName) async {
        try {
          final tagId = await buildService.findTagIdByName(tagName);
          if (tagId != null) {
            await buildService.addTagToBuild(newBuildId, tagId);
          }
        } catch (e) {
          debugPrint('saveBuild: ERROR adding tag $tagName to build: $e');
          // Continue with other tags even if one fails
        }
      }).toList();
      
      // Wait for all tags to be added in parallel
      await Future.wait(tagFutures, eagerError: false);
    }

    return newBuildId;
  }

  /// Publishes a build by updating its status.
  Future<void> publishBuild(WidgetRef ref, String buildId) async {
    final buildService = ref.read(buildServiceProvider);
    try {
      // Update build status to PUBLISHED
      await buildService.updateBuild(buildId, {'status': 'PUBLISHED'});
    } catch (e) {
      debugPrint('Error in publishBuild: $e');
      rethrow;
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

class _BuildNowPageState extends ConsumerState<BuildNowPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
  final String buildLink = 'https://kazabuild.com/b/somerandom123';

  bool _isBuildEmpty(List<PcComponent> components) {
    return components.every((component) => component.selectedProduct == null);
  }

  double _totalPrice(List<PcComponent> components) {
    return components.fold(
      0.0,
      (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
    );
  }

  int _estimatedWattage(List<PcComponent> components) {
    return components.fold(0, (sum, item) {
      final product = item.selectedProduct;
      if (product is CPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      if (product is GPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      if (product is MotherboardComponent) {
        return sum + 40;
      }
      if (product is MemoryComponent) {
        return sum + (5 * product.moduleQuantity);
      }
      if (product is StorageComponent) {
        return sum + 10;
      }
      return sum;
    });
  }

  String _compatibilityStatus(List<PcComponent> components) {
    final selectedComponents = components
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

  void _showSnackBar({
    required String message,
    Color? backgroundColor,
    Duration duration = const Duration(seconds: 3),
  }) {
    _scaffoldMessengerKey.currentState?.clearSnackBars();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
      ),
    );
  }

  Future<String?> _showSaveBuildDialog() async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedTagIds = <String>{};

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(AppLocalizations.of(context)!.saveBuild),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: nameController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.buildName),
                      validator: (value) =>
                          value == null || value.isEmpty ? AppLocalizations.of(context)!.pleaseEnterName : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: descriptionController,
                      decoration: InputDecoration(labelText: AppLocalizations.of(context)!.description),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)!.tags,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8), 
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () {
                  if (formKey.currentState!.validate()) {
                    Navigator.of(context).pop(true);
                  }
                },
                child: Text(AppLocalizations.of(context)!.save),
              ),
            ],
          );
        },
      ),
    );

    if (shouldSave == true) {
      try {
        final newBuildId = await ref
            .read(buildProvider.notifier)
            .saveBuild(ref, nameController.text, descriptionController.text, tagIds: selectedTagIds.toList());

        _showSnackBar(
          message: 'Build successfully saved to your profile',
          backgroundColor: Colors.green,
        );
        return newBuildId;
      } catch (e) {
        _showSnackBar(
          message: '${AppLocalizations.of(context)!.failedToSaveBuild}: $e',
          backgroundColor: Theme.of(context).colorScheme.error,
        );
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = ref.watch(buildProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    final selectedCurrency = ref.watch(currencyProvider);
    final currencyData = currencyDetails[selectedCurrency]!;
    final totalPrice = _totalPrice(components) * currencyData.exchangeRate;
    final estimatedWattage = _estimatedWattage(components);

    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: CustomDrawer(showProfileArea: true),
        backgroundColor: theme.colorScheme.background,
        body: Column(
          children: [
            CustomNavigationBar(scaffoldKey: _scaffoldKey),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    _TopBar(
                      theme: theme,
                      buildLink: buildLink,
                      components: components,
                      totalPrice: totalPrice,
                      currencyData: currencyData,
                      estimatedWattage: estimatedWattage,
                      onSave: _showSaveBuildDialog,
                      onNew: _startNewBuild,
                      onPost: _publishBuild,
                      isMobile: isMobile,
                      onShowSnackBar: _showSnackBar,
                    ),
                    if (!_isBuildEmpty(components)) ...[
                      const SizedBox(height: 16),
                      _CompatibilityAndPriceBar(
                        theme: theme,
                        totalPrice: totalPrice,
                        currencyData: currencyData,
                        statusMessage: _compatibilityStatus(components),
                        isMobile: isMobile,
                      ),
                    ],
                    const SizedBox(height: 24),
                    _ComponentTable(
                      theme: theme,
                      components: components,
                      onRemove: (i) => ref.read(buildProvider.notifier).removeComponent(components[i].type),
                      onAdd: (i) async {
                        final selected = await Navigator.push<BaseComponent>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PartPickerPage(
                              componentType: components[i].type,
                              currentBuild: components,
                            ),
                          ),
                        );
                        if (selected != null && mounted) {
                          if (selected.id.isEmpty) {
                            _showSnackBar(
                              message: 'Selected component has no ID. Try another.',
                              backgroundColor: Colors.red,
                            );
                            return;
                          }
                          ref.read(buildProvider.notifier).addComponent(selected);
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
      ),
    );
  }

  /// Clears the current build, with a confirmation dialog if it's not empty.
  Future<void> _startNewBuild() async {
    final components = ref.read(buildProvider);
    if (_isBuildEmpty(components)) {
      ref.read(buildProvider.notifier).clearBuild();
      return;
    }

    final bool? shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.startNewBuild),
        content: Text(AppLocalizations.of(context)!.unsavedChanges),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context)!.clearBuild),
            style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.error),
          ),
        ],
      ),
    );

    if (shouldClear == true) {
      ref.read(buildProvider.notifier).clearBuild();
    }
  }

  /// Shows a dialog to get build name, description, and image, then saves and publishes it.
  Future<String?> _showPostBuildDialog() async {
    debugPrint('_showPostBuildDialog: Starting dialog');
    
    // Check if widget is mounted before opening dialog
    if (!mounted) {
      debugPrint('_showPostBuildDialog: Widget not mounted, cannot show dialog');
      return null;
    }
    
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final selectedTagIds = <String>{};
    
    // Use a ValueNotifier to preserve image state outside the dialog
    final selectedImageNotifier = ValueNotifier<XFile?>(null);
    final imagePathNotifier = ValueNotifier<String?>(null);

    debugPrint('_showPostBuildDialog: Showing dialog');
    final bool? shouldPost = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
          title: Text(AppLocalizations.of(context)!.postBuild),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '${AppLocalizations.of(context)!.buildName} *',
                      hintText: AppLocalizations.of(context)!.enterBuildName,
                    ),
                    validator: (value) =>
                        value == null || value.isEmpty ? AppLocalizations.of(context)!.pleaseEnterName : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: descriptionController,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.description,
                      hintText: AppLocalizations.of(context)!.describeBuild,
                    ),
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    AppLocalizations.of(context)!.tags,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Consumer(
                    builder: (context, ref, child) {
                      final tagsAsync = ref.watch(tagsProvider);
                      return tagsAsync.when(
                        data: (tags) {
                          if (tags.isEmpty) {
                            return Text(
                              AppLocalizations.of(context)!.noTagsAvailable,
                              style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
                            );
                          }
                          return Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: tags.map((tag) {
                              // Store tag name instead of ID for easier matching
                              final isSelected = selectedTagIds.contains(tag.name);
                              return FilterChip(
                                label: Text(tag.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setDialogState(() {
                                    if (selected) {
                                      selectedTagIds.add(tag.name);
                                    } else {
                                      selectedTagIds.remove(tag.name);
                                    }
                                  });
                                },
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const CircularProgressIndicator(),
                        error: (error, stack) => Text('${AppLocalizations.of(context)!.errorLoadingTags}: $error'),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Build Image (Optional)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<XFile?>(
                    valueListenable: selectedImageNotifier,
                    builder: (context, selectedImage, _) {
                      if (selectedImage == null) {
                        return OutlinedButton.icon(
                          onPressed: () async {
                            debugPrint('Select Image button pressed');
                            final ImagePicker picker = ImagePicker();
                            final XFile? image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1920,
                              maxHeight: 1080,
                              imageQuality: 90,
                            );
                            if (image != null) {
                              debugPrint('Image selected: ${image.path}');
                              setDialogState(() {
                                selectedImageNotifier.value = image;
                                imagePathNotifier.value = image.path;
                              });
                            }
                          },
                          icon: const Icon(Icons.image),
                          label: const Text('Select Image'),
                        );
                      }
                      return Column(
                        children: [
                          FutureBuilder<Uint8List>(
                            future: selectedImage.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: const Center(child: CircularProgressIndicator()),
                          );
                        }
                        if (snapshot.hasData) {
                          return Container(
                            height: 150,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.memory(
                                snapshot.data!,
                                fit: BoxFit.cover,
                              ),
                            ),
                          );
                        }
                        return Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey),
                            color: Colors.grey.shade200,
                          ),
                          child: const Icon(Icons.image, size: 50),
                        );
                      },
                    ),
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: () {
                              debugPrint('Remove Image button pressed');
                              setDialogState(() {
                                selectedImageNotifier.value = null;
                                imagePathNotifier.value = null;
                              });
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Remove Image'),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                debugPrint('Post Build button pressed in dialog');
                debugPrint('Form key current state: ${formKey.currentState}');
                if (formKey.currentState!.validate()) {
                  debugPrint('Form is valid, closing dialog with true');
                  debugPrint('Build name: ${nameController.text}');
                  debugPrint('Build description length: ${descriptionController.text.length}');
                  debugPrint('Selected image: ${selectedImageNotifier.value?.path ?? 'none'}');
                  Navigator.of(context).pop(true);
                } else {
                  debugPrint('Form validation failed - name is empty or invalid');
                }
              },
              child: Text(AppLocalizations.of(context)!.postBuild),
            ),
          ],
        );
        },
      ),
    );

    // If user cancelled, return early
    debugPrint('_showPostBuildDialog: Dialog returned: $shouldPost, mounted: $mounted');
    if (shouldPost != true || !mounted) {
      debugPrint('_showPostBuildDialog: User cancelled or widget not mounted, returning null');
      return null;
    }
    debugPrint('_showPostBuildDialog: Proceeding with build publish');

    // Store values before async operations
    final buildName = nameController.text.trim();
    final buildDescription = descriptionController.text.trim();
    final imageFile = selectedImageNotifier.value;
    final imagePathValue = imagePathNotifier.value;
    
    debugPrint('_showPostBuildDialog: Stored values - name: "$buildName", description: "${buildDescription.length} chars", image: ${imageFile?.path ?? 'none'}');

    // Don't show loading snackbar here - it causes context issues
    // We'll show a success message after publishing or navigate directly

    try {
      // 1. Save the build first to get the build ID
      debugPrint('_showPostBuildDialog: Saving build with name: $buildName, description length: ${buildDescription.length}');
      final newBuildId = await ref
          .read(buildProvider.notifier)
          .saveBuild(ref, buildName, buildDescription, tagIds: selectedTagIds.toList());
      debugPrint('_showPostBuildDialog: Build saved with ID: $newBuildId');

      if (!mounted) {
        debugPrint('_showPostBuildDialog: Widget not mounted after save, returning null');
        return null;
      }

      // 2. Upload image if one was selected
      if (imageFile != null) {
        try {
          debugPrint('_showPostBuildDialog: Uploading image...');
          final dio = ref.read(authProvider.notifier).getDioInstance();
          
          // Check if it's a blob URL - if so, read bytes directly
          MultipartFile filePart;
          if (imagePathValue != null && imagePathValue.startsWith('blob:')) {
            // For blob URLs, read the file bytes directly
            debugPrint('_showPostBuildDialog: Image is blob URL, reading bytes...');
            final bytes = await imageFile.readAsBytes();
            filePart = MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name,
            );
          } else if (imagePathValue != null && imagePathValue.isNotEmpty) {
            // For real file paths, use fromFile
            debugPrint('_showPostBuildDialog: Image is file path: $imagePathValue');
            filePart = await MultipartFile.fromFile(imagePathValue, filename: imageFile.name);
          } else {
            // Fallback: read bytes from XFile
            debugPrint('_showPostBuildDialog: Reading image bytes from XFile...');
            final bytes = await imageFile.readAsBytes();
            filePart = MultipartFile.fromBytes(
              bytes,
              filename: imageFile.name,
            );
          }
          
          final formData = FormData.fromMap({
            'File': filePart,
            'TargetId': newBuildId,
            'LocationType': 'BUILD',
            'Name': 'build_image_${imageFile.name}',
          });

          debugPrint('_showPostBuildDialog: Sending image upload request...');
          await dio.post('$apiBaseUrl/Images/add', data: formData);
          debugPrint('_showPostBuildDialog: Image uploaded successfully');
        } catch (e) {
          // Log error but continue with publishing
          debugPrint('_showPostBuildDialog: Image upload error: $e');
          // Don't show snackbar here - causes context issues
          // Image upload failure is not critical, build will still be published
        }
      } else {
        debugPrint('_showPostBuildDialog: No image selected, skipping image upload');
      }

      if (!mounted) {
        debugPrint('_showPostBuildDialog: Widget not mounted after image upload, returning null');
        return null;
      }

      // 3. Publish the build
      debugPrint('_showPostBuildDialog: Publishing build: $newBuildId');
      try {
        await ref.read(buildProvider.notifier).publishBuild(ref, newBuildId);
        debugPrint('_showPostBuildDialog: Build published successfully');
      } catch (e) {
        debugPrint('_showPostBuildDialog: Error publishing build: $e');
        _showSnackBar(
          message: 'Failed to publish build: ${e.toString()}',
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        );
        return null;
      }

      if (!mounted) {
        debugPrint('_showPostBuildDialog: Widget not mounted after publish, returning null');
        return null;
      }

      // 4. Invalidate providers to refresh explore builds
      ref.invalidate(allBuildsProvider);
      final userId = ref.read(authProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.invalidate(userBuildsProvider(userId));
      }

      // 5. Don't show snackbar here - widget might be disposed
      // Success message will be shown in _publishBuild after dialog returns
      return newBuildId;
    } catch (e, stackTrace) {
      debugPrint('_showPostBuildDialog: Error publishing build: $e');
      debugPrint('_showPostBuildDialog: Stack trace: $stackTrace');
      
      // Show error message to user
      _showSnackBar(
        message: 'Failed to publish build: ${e.toString()}',
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      );
      
      return null;
    }
  }

  /// Saves and then publishes the build to the Explore page.
  void _publishBuild() async {
    debugPrint('_publishBuild called');
    
    // Check if user is logged in
    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      debugPrint('User not logged in');
      _showSnackBar(
        message: 'Please log in to publish your build.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    debugPrint('User logged in: ${user.uid}');

    // Check if build has at least one component
    final components = ref.read(buildProvider);
    if (_isBuildEmpty(components)) {
      debugPrint('Build is empty');
      _showSnackBar(
        message: 'Please add at least one component to your build before posting.',
        backgroundColor: Colors.orange,
      );
      return;
    }
    debugPrint('Build has ${components.length} components');

    // Show the post build dialog
    debugPrint('Showing post build dialog...');
    final result = await _showPostBuildDialog();
    debugPrint('Post build dialog returned: $result');
    
    // Show success message if build was published successfully
    if (result != null) {
      _showSnackBar(
        message: 'Build successfully published',
        backgroundColor: Colors.green,
      );
    }
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
  final VoidCallback onSave;
  final VoidCallback onNew;
  final VoidCallback onPost;
  final bool isMobile; // Added isMobile
  final void Function({required String message, Color? backgroundColor, Duration duration}) onShowSnackBar;

  const _TopBar({
    required this.theme,
    required this.buildLink,
    required this.components,
    required this.totalPrice,
    required this.currencyData,
    required this.estimatedWattage,
    required this.onSave,
    required this.onNew,
    required this.onPost,
    required this.isMobile, // Added isMobile
    required this.onShowSnackBar,
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
                        onShowSnackBar(
                          message: 'Build link copied to clipboard!',
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
                        onShowSnackBar(
                          message: 'Reddit Markup copied to clipboard!',
                        );
                      },
                      icon: const Icon(Icons.code),
                      tooltip: 'Copy Reddit Markup',
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () {
                        debugPrint('Post Build button clicked in mobile layout');
                        onPost();
                      },
                      icon: const Icon(Icons.send, size: 18),
                      label: Text(AppLocalizations.of(context)!.postBuild),
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
                    onPressed: onNew,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('New Build'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      foregroundColor: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: ElevatedButton.icon(
                    onPressed: onSave,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: const Text('Save Build'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: theme.colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Estimated wattage: ${estimatedWattage}W',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            )
          : Row(
              /// Desktop layout for the top bar.
              children: [
                IconButton(
                  icon: const Icon(Icons.link, size: 20),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: buildLink));
                    onShowSnackBar(
                      message: 'Build link copied to clipboard!',
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
                    onShowSnackBar(
                      message: 'Reddit Markup copied to clipboard!',
                    );
                  },
                  icon: const Icon(Icons.code),
                  tooltip: 'Copy Reddit Markup',
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () {
                    debugPrint('Post Build button clicked in desktop layout');
                    onPost();
                  },
                  icon: const Icon(Icons.send, size: 18),
                  label: Text(AppLocalizations.of(context)!.postBuild),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.secondary,
                    foregroundColor: theme.colorScheme.onSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Build'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: onSave,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Save Build'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: theme.colorScheme.onPrimary,
                    backgroundColor: theme.colorScheme.primary,
                  ),
                ),
                const Spacer(),
                Text(
                  'Estimated wattage: ${estimatedWattage}W',
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
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
                        color: Colors.white.withValues(alpha: 0.8),
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
                    color: Colors.white.withValues(alpha: 0.8),
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
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
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
                  color: theme.colorScheme.surfaceVariant.withValues(alpha: 0.3),
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

