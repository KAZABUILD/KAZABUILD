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
import 'package:go_router/go_router.dart';
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

  /// Resets the build to its initial empty state.
  void clearBuild() {
    state = _initialState.map((c) => PcComponent(name: c.name, type: c.type)).toList();
  }

  /// Saves the current build to the backend.
  Future<String> saveBuild(WidgetRef ref, String name, String description, {List<String>? tagIds}) async {
    debugPrint('BuildNotifier.saveBuild: Starting to save build');
    final buildService = ref.read(buildServiceProvider);
    final userId = ref.read(authProvider).valueOrNull?.uid;

    if (userId == null) {
      debugPrint('BuildNotifier.saveBuild: User not logged in');
      throw Exception('You must be logged in to save a build.');
    }
    debugPrint('BuildNotifier.saveBuild: User ID: $userId');

    // Count components
    final componentCount = state.where((slot) => slot.selectedProduct != null).length;
    debugPrint('BuildNotifier.saveBuild: Building with $componentCount components');

    // 1. Create the main build entry.
    debugPrint('BuildNotifier.saveBuild: Creating build with name: $name');
    try {
      final newBuildId = await buildService.createBuild({
        'userId': userId,
        'name': name,
        'description': description,
        'status': 'DRAFT', // Save as draft by default
      });
      debugPrint('BuildNotifier.saveBuild: Build created with ID: $newBuildId');

      // 2. Add each selected component to the newly created build.
      int componentIndex = 0;
      for (final componentSlot in state) {
        if (componentSlot.selectedProduct != null) {
          componentIndex++;
          debugPrint('BuildNotifier.saveBuild: Adding component $componentIndex/${componentCount}: ${componentSlot.selectedProduct!.id}');
          try {
            await buildService.addComponentToBuild(
              newBuildId,
              componentSlot.selectedProduct!.id,
              1, // Assuming quantity is always 1 for now
            );
            debugPrint('BuildNotifier.saveBuild: Component $componentIndex added successfully');
          } catch (e) {
            debugPrint('BuildNotifier.saveBuild: Error adding component $componentIndex: $e');
            // Continue with other components even if one fails
          }
        }
      }

      // 3. Add tags to the build if provided
      // tagIds is actually a list of tag names, not IDs
      if (tagIds != null && tagIds.isNotEmpty) {
        debugPrint('BuildNotifier.saveBuild: Adding ${tagIds.length} tags to build');
        for (final tagName in tagIds) {
          try {
            // Try to find the actual tag ID in backend by name
            final tagId = await buildService.findTagIdByName(tagName);
            if (tagId != null) {
              await buildService.addTagToBuild(newBuildId, tagId);
              debugPrint('BuildNotifier.saveBuild: Tag "$tagName" (ID: $tagId) added successfully');
            } else {
              debugPrint('BuildNotifier.saveBuild: Warning - Tag "$tagName" not found in backend. Skipping.');
            }
          } catch (e) {
            debugPrint('BuildNotifier.saveBuild: Error adding tag "$tagName": $e');
            // Continue with other tags even if one fails
          }
        }
      }

      debugPrint('BuildNotifier.saveBuild: Build saved successfully with ID: $newBuildId');
      return newBuildId;
    } catch (e) {
      debugPrint('BuildNotifier.saveBuild: Error creating build: $e');
      rethrow;
    }
  }

  /// Publishes a build by updating its status.
  Future<void> publishBuild(WidgetRef ref, String buildId) async {
    final buildService = ref.read(buildServiceProvider);
    try {
      // Update build status to PUBLISHED
      await buildService.updateBuild(buildId, {'status': 'PUBLISHED'});
      // Invalidate the providers so the UI updates with the new status
      // This will trigger a refresh when the provider is next accessed
      ref.invalidate(allBuildsProvider);
      final userId = ref.read(authProvider).valueOrNull?.uid;
      if (userId != null) {
        ref.invalidate(userBuildsProvider(userId));
      }
    } catch (e) {
      // Log the error for debugging
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

/// The state for the [BuildNowPage].
class _BuildNowPageState extends ConsumerState<BuildNowPage> {
  /// A key to manage the Scaffold, particularly for opening the drawer on mobile.
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// A mock link for sharing the build.
  // TODO: This should be generated dynamically based on the build's state.
  final String buildLink = 'https://kazabuild.com/b/somerandom123';

  /// A computed property to check if any components have been selected in the build.
  bool _isBuildEmpty(List<PcComponent> components) {
    return components.every((component) => component.selectedProduct == null);
  }

  /// A computed property to calculate the total price of all selected components.
  double _totalPrice(List<PcComponent> components) {
    return components.fold(
      0.0,
      (sum, item) => sum + (item.selectedProduct?.lowestPrice ?? 0.0),
    );
  }

  /// A computed property to calculate the estimated power consumption in watts.
  int _estimatedWattage(List<PcComponent> components) {
    return components.fold(0, (sum, item) {
      final product = item.selectedProduct;
      if (product is CPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      if (product is GPUComponent) {
        return sum + product.thermalDesignPower.toInt();
      }
      // Add wattage for other components if available
      if (product is PowerSupplyComponent) {
        // PSU itself doesn't add to wattage, but we could estimate other parts
      }
      if (product is MotherboardComponent) {
        // Estimate ~30-50W for motherboard
        return sum + 40;
      }
      if (product is MemoryComponent) {
        // Estimate ~5W per stick
        return sum + (5 * product.moduleQuantity);
      }
      if (product is StorageComponent) {
        // Estimate ~10W for SSD/HDD
        return sum + 10;
      }
      return sum;
    });
  }

  /// A computed property to determine the overall compatibility status of the build.
  // TODO: Implement a real compatibility check engine instead of this placeholder logic.
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

  /// Shows a dialog to get the build name and description, then saves it.
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

    if (shouldSave == true && mounted) {
      try {
        final newBuildId = await ref
            .read(buildProvider.notifier)
            .saveBuild(ref, nameController.text, descriptionController.text, tagIds: selectedTagIds.toList());

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.buildSavedSuccessfully),
            backgroundColor: Colors.green,
          ),
        );
        return newBuildId;
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)!.failedToSaveBuild}: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
    return null;
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
    
    // Store a reference to the current context for navigation
    final BuildContext? currentContext = mounted ? context : null;
    
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
        rethrow;
      }

      if (!mounted) {
        debugPrint('_showPostBuildDialog: Widget not mounted after publish, returning null');
        return null;
      }

      // 4. Verify the build was published by fetching it
      debugPrint('Verifying build was published...');
      try {
        final buildService = ref.read(buildServiceProvider);
        final publishedBuild = await buildService.getBuildById(newBuildId);
        debugPrint('Build status after publish: ${publishedBuild.status}');
        if (publishedBuild.status != 'PUBLISHED') {
          debugPrint('ERROR: Build status is ${publishedBuild.status}, expected PUBLISHED');
          throw Exception('Build was not published correctly. Status: ${publishedBuild.status}');
        }
        debugPrint('Build verified as PUBLISHED');
      } catch (e) {
        debugPrint('Error verifying build: $e');
        // Continue anyway - might be a temporary issue
      }

      if (!mounted) return null;

      // 5. Invalidate and refresh the explore builds provider
      debugPrint('Invalidating allBuildsProvider');
      ref.invalidate(allBuildsProvider);
      
      // Wait a moment for backend to process the status update
      debugPrint('Waiting for backend to process...');
      await Future.delayed(const Duration(milliseconds: 2500));
      
      if (!mounted) return null;

      // Force refresh by reading the provider to ensure it fetches fresh data
      debugPrint('Refreshing allBuildsProvider');
      try {
        // Clear any cached data first
        ref.invalidate(allBuildsProvider);
        await Future.delayed(const Duration(milliseconds: 500));
        
        final builds = await ref.read(allBuildsProvider.future);
        debugPrint('Builds refreshed. Total builds: ${builds.length}');
        
        // Check if our build is in the list
        final foundBuild = builds.any((build) => build.id == newBuildId);
        debugPrint('Our build found in list: $foundBuild');
        
        if (foundBuild) {
          debugPrint('SUCCESS: Published build found in list!');
        } else {
          debugPrint('WARNING: Published build not found in refreshed list');
          debugPrint('Build IDs in list: ${builds.map((b) => b.id).toList()}');
          // Try one more refresh after a delay
          await Future.delayed(const Duration(milliseconds: 1000));
          ref.invalidate(allBuildsProvider);
        }
      } catch (e, stackTrace) {
        debugPrint('Error refreshing builds: $e');
        debugPrint('Stack trace: $stackTrace');
        // Even if refresh fails, continue - the page will refresh when navigated to
      }

      if (!mounted) return null;

      // Navigate to explore page - this will refresh the builds list
      debugPrint('_showPostBuildDialog: Build published successfully, navigating to explore page');
      
      // Use a post-frame callback to ensure navigation happens after the current frame
      if (mounted && currentContext != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && currentContext.mounted) {
            try {
              debugPrint('_showPostBuildDialog: Navigating to explore page');
              currentContext.go('/explore');
            } catch (e) {
              debugPrint('_showPostBuildDialog: Navigation error: $e');
              // Try alternative navigation method
              try {
                Navigator.of(currentContext).pushNamedAndRemoveUntil('/explore', (route) => false);
              } catch (e2) {
                debugPrint('_showPostBuildDialog: Alternative navigation also failed: $e2');
              }
            }
          }
        });
      } else {
        debugPrint('_showPostBuildDialog: Cannot navigate - context not available');
      }
      
      return newBuildId;
    } catch (e, stackTrace) {
      debugPrint('_showPostBuildDialog: Error publishing build: $e');
      debugPrint('_showPostBuildDialog: Stack trace: $stackTrace');
      
      // Log the error - we can't show snackbar due to context issues
      debugPrint('_showPostBuildDialog: ERROR - Failed to publish build: $e');
      debugPrint('_showPostBuildDialog: Stack trace: $stackTrace');
      
      // Try to show error message if context is still available
      if (mounted && currentContext != null && currentContext.mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (currentContext.mounted) {
            try {
              ScaffoldMessenger.of(currentContext).showSnackBar(
                SnackBar(
                  content: Text('Failed to publish your build: ${e.toString()}'),
                  backgroundColor: Colors.red,
                  duration: const Duration(seconds: 5),
                ),
              );
            } catch (snackbarError) {
              debugPrint('_showPostBuildDialog: Could not show error snackbar: $snackbarError');
            }
          }
        });
      }
      
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in to publish your build.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    debugPrint('User logged in: ${user.uid}');

    // Check if build has at least one component
    final components = ref.read(buildProvider);
    if (_isBuildEmpty(components)) {
      debugPrint('Build is empty');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one component to your build before posting.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    debugPrint('Build has ${components.length} components');

    // Show the post build dialog
    debugPrint('Showing post build dialog...');
    final result = await _showPostBuildDialog();
    debugPrint('Post build dialog returned: $result');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final components = ref.watch(buildProvider);
    final isMobile = MediaQuery.of(context).size.width < 700;

    /// Watches the selected currency and gets its details for price conversion.
    final selectedCurrency = ref.watch(currencyProvider);
    final currencyData = currencyDetails[selectedCurrency]!;
    final totalPrice = _totalPrice(components);
    final convertedPrice = totalPrice * currencyData.exchangeRate;
    final estimatedWattage = _estimatedWattage(components);

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
                    components: components,
                    totalPrice: convertedPrice,
                    currencyData: currencyData,
                    estimatedWattage: estimatedWattage,
                    onSave: _showSaveBuildDialog,
                    onNew: _startNewBuild, // This remains the same
                    onPost: _publishBuild, // Changed to publish function
                    isMobile: isMobile,
                  ),
                  // The compatibility and price bar is only shown if the build is not empty.
                  if (!_isBuildEmpty(components)) ...[
                    const SizedBox(height: 16),
                    _CompatibilityAndPriceBar(
                      theme: theme,
                      totalPrice: convertedPrice,
                      currencyData: currencyData,
                      statusMessage: _compatibilityStatus(components),
                      isMobile: isMobile,
                    ),
                  ],
                  const SizedBox(height: 24),
                  _ComponentTable(
                    theme: theme,
                    components: components,
                    onRemove: (index) {
                      final componentType = components[index].type;
                      ref.read(buildProvider.notifier).removeComponent(componentType);
                    },
                    onAdd: (index) async {
                      /// Navigates to the PartPickerPage to let the user select a component.
                      /// The result (the selected component) is returned via `Navigator.pop`.
                      final BaseComponent? selectedComponent =
                          await Navigator.push<BaseComponent>(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PartPickerPage(
                                componentType: components[index].type,
                                currentBuild: components,
                              ),
                            ),
                          );

                      /// If a component was selected and the widget is still mounted, update the state.
                      if (selectedComponent != null && mounted) {
                        ref.read(buildProvider.notifier).addComponent(selectedComponent);
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
  final VoidCallback onSave;
  final VoidCallback onNew;
  final VoidCallback onPost;
  final bool isMobile; // Added isMobile

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
