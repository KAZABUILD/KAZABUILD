/// Admin Guides Management Page
///
/// Provides guide content management interface.
/// Uses frontend guide data since backend doesn't have Guides entity yet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import '../../core/constants/app_color.dart';
import 'package:frontend/models/guide_model.dart';
import 'package:frontend/models/guide_provider.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/api_constants.dart';

class AdminGuidesPage extends ConsumerStatefulWidget {
  const AdminGuidesPage({super.key});

  @override
  ConsumerState<AdminGuidesPage> createState() => _AdminGuidesPageState();
}

class _AdminGuidesPageState extends ConsumerState<AdminGuidesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  // Get all guides from frontend
  List<Guide> _allGuides = [];
  List<Guide> _filteredGuides = [];
  List<String> _categories = ['All'];

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final guideService = ref.read(guideServiceProvider);
      final guides = await guideService.fetchGuides(sortDirection: 'desc');
      if (!mounted) return;
      _allGuides = guides;
      _updateCategories();
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateCategories() {
    final categoriesSet = _allGuides.map((g) => g.category).toSet().toList()
      ..sort();
    setState(() {
      _categories = ['All', ...categoriesSet];
    });
  }

  void _applyFilters() {
    List<Guide> filtered = _allGuides;

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered
          .where((g) => g.category == _selectedCategory)
          .toList();
    }

    // Apply search filter
    final searchQuery = _searchController.text.toLowerCase();
    if (searchQuery.isNotEmpty) {
      filtered = filtered.where((g) {
        return g.title.toLowerCase().contains(searchQuery) ||
            g.author.toLowerCase().contains(searchQuery) ||
            g.category.toLowerCase().contains(searchQuery);
      }).toList();
    }

    setState(() {
      _filteredGuides = filtered;
    });
  }

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
          Expanded(child: _buildContent(isDark)),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                'Guides Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? AppColorsDark.textWhite
                      : AppColorsLight.textBlack,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : () => _showGuideFormDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Create Guide'),
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
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search guides by title, author, or category...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        _applyFilters();
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
            onChanged: (value) => _applyFilters(),
          ),
          const SizedBox(height: 16),
          // Category filter chips
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _categories.map((category) {
              final isSelected = _selectedCategory == category;
              return FilterChip(
                label: Text(category),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    _selectedCategory = category;
                  });
                  _applyFilters();
                },
                selectedColor:
                    (isDark
                            ? AppColorsDark.buttonBlue
                            : AppColorsLight.buttonBlue)
                        .withValues(alpha: 0.3),
                checkmarkColor: isDark
                    ? AppColorsDark.buttonBlue
                    : AppColorsLight.buttonBlue,
                labelStyle: TextStyle(
                  color: isSelected
                      ? (isDark
                            ? AppColorsDark.buttonBlue
                            : AppColorsLight.buttonBlue)
                      : (isDark
                            ? AppColorsDark.textWhite
                            : AppColorsLight.textBlack),
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStatsRow(isDark),
          const SizedBox(height: 24),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? _buildErrorPlaceholder(isDark)
                : _filteredGuides.isEmpty
                ? _buildEmptyState(isDark)
                : RefreshIndicator(
                    onRefresh: _loadGuides,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 20,
                            mainAxisSpacing: 20,
                            childAspectRatio: 0.7,
                          ),
                      itemCount: _filteredGuides.length,
                      itemBuilder: (context, index) {
                        return _buildGuideCard(_filteredGuides[index], isDark);
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.article_outlined,
            size: 64,
            color: isDark
                ? AppColorsDark.textWhite.withValues(alpha: 0.3)
                : AppColorsLight.textBlack.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No guides found',
            style: TextStyle(
              fontSize: 18,
              color: isDark
                  ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                  : AppColorsLight.textBlack.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: AppColorsDark.warning,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load guides',
            style: TextStyle(
              fontSize: 18,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark
                    ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                    : AppColorsLight.textBlack.withValues(alpha: 0.7),
              ),
            ),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _loadGuides, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    final totalGuides = _allGuides.length;
    final publishedGuides =
        _allGuides.length; // All guides are considered published in frontend
    final categories = _allGuides.map((g) => g.category).toSet().length;

    final stats = [
      {
        'label': 'Total Guides',
        'value': totalGuides.toString(),
        'icon': Icons.book,
        'color': AppColorsDark.buttonPurple,
      },
      {
        'label': 'Categories',
        'value': categories.toString(),
        'icon': Icons.category,
        'color': AppColorsDark.buttonBlue,
      },
      {
        'label': 'Published',
        'value': publishedGuides.toString(),
        'icon': Icons.publish,
        'color': AppColorsDark.buttonGreen,
      },
      {
        'label': 'Showing',
        'value': '${_filteredGuides.length} guides',
        'icon': Icons.visibility,
        'color': AppColorsDark.warning,
      },
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
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (stat['color'] as Color).withValues(alpha: 0.2),
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
                              ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                              : AppColorsLight.textBlack.withValues(alpha: 0.7),
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

  Widget _buildGuideCard(Guide guide, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColorsDark.backgroundSecondary
            : AppColorsLight.backgroundTertiary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Guide image
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColorsDark.buttonPurple.withValues(alpha: 0.3),
                  AppColorsDark.buttonBlue.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
              child: guide.imageUrl == null || guide.imageUrl!.isEmpty
                  ? Container(
                      color: AppColorsDark.buttonPurple.withValues(alpha: 0.2),
                      child: const Center(
                        child: Icon(
                          Icons.book,
                          size: 48,
                          color: AppColorsDark.buttonPurple,
                        ),
                      ),
                    )
                  : Image.network(
                      guide.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColorsDark.buttonPurple.withValues(
                            alpha: 0.2,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.book,
                              size: 48,
                              color: AppColorsDark.buttonPurple,
                            ),
                          ),
                        );
                      },
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          color: AppColorsDark.buttonPurple.withValues(
                            alpha: 0.2,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        );
                      },
                    ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  guide.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark
                        ? AppColorsDark.textWhite
                        : AppColorsLight.textBlack,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColorsDark.buttonBlue.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        guide.category,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColorsDark.buttonBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      guide.readTime,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                            : AppColorsLight.textBlack.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'By ${guide.author}',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark
                        ? AppColorsDark.textWhite.withValues(alpha: 0.7)
                        : AppColorsLight.textBlack.withValues(alpha: 0.7),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _formatDate(guide.publishedDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColorsDark.textWhite.withValues(alpha: 0.5)
                              : AppColorsLight.textBlack.withValues(alpha: 0.5),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showEditGuideDialog(context, guide);
                          },
                          tooltip: 'Edit',
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, size: 20),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            _showDeleteGuideConfirmation(context, guide);
                          },
                          tooltip: 'Delete',
                          color: AppColorsDark.error,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditGuideDialog(BuildContext context, Guide guide) {
    _showGuideFormDialog(guide: guide);
  }

  void _showGuideFormDialog({Guide? guide}) {
    final isEditing = guide != null;
    final titleController = TextEditingController(text: guide?.title ?? '');
    final authorController = TextEditingController(text: guide?.author ?? '');
    final categoryController = TextEditingController(
      text: guide?.category ?? '',
    );
    final timeController = TextEditingController(
      text: guide != null ? guide.timeToReadMinutes.toString() : '',
    );
    final textController = TextEditingController(text: guide?.text ?? '');
    final noteController = TextEditingController(text: guide?.note ?? '');
    DateTime selectedDate = guide?.publishedDate ?? DateTime.now();
    final formKey = GlobalKey<FormState>();
    String? currentGuideId = guide?.id;
    String? currentImageUrl = guide?.imageUrl;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        bool isSubmitting = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            bool isUploadingImage = false;
            bool imageUploaded = false;

            Future<void> uploadGuideImage(String guideId) async {
              final ImagePicker picker = ImagePicker();

              try {
                final XFile? image = await picker.pickImage(
                  source: ImageSource.gallery,
                  maxWidth: 1920,
                  maxHeight: 1080,
                  imageQuality: 85,
                );

                if (image == null) return;

                setStateDialog(() {
                  isUploadingImage = true;
                });

                try {
                  final fileBytes = await image.readAsBytes();
                  var fileName = image.name;
                  if (fileName.isEmpty || !fileName.contains('.')) {
                    fileName =
                        'guide_${DateTime.now().millisecondsSinceEpoch}.jpg';
                  }

                  final formData = FormData.fromMap({
                    'File': MultipartFile.fromBytes(
                      fileBytes,
                      filename: fileName,
                    ),
                    'TargetId': guideId,
                    'LocationType': 'GUIDE',
                    'Name':
                        'guide_image_${DateTime.now().millisecondsSinceEpoch}',
                  });

                  final dio = ref.read(authProvider.notifier).getDioInstance();
                  final imageResponse = await dio.post(
                    '$apiBaseUrl/Images/add',
                    data: formData,
                  );

                  final imageId =
                      imageResponse.data['id'] ?? imageResponse.data['Id'];
                  if (imageId != null) {
                    final imageUrl = '$apiBaseUrl/Images/download/$imageId';
                    setStateDialog(() {
                      currentImageUrl = imageUrl;
                      isUploadingImage = false;
                      imageUploaded = true;
                    });
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Image uploaded successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  }
                } catch (e) {
                  setStateDialog(() {
                    isUploadingImage = false;
                  });
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Failed to upload image: ${e.toString()}',
                        ),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                setStateDialog(() {
                  isUploadingImage = false;
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to pick image: ${e.toString()}'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            }

            return AlertDialog(
              title: Text(isEditing ? 'Edit Guide' : 'Create Guide'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: titleController,
                        decoration: const InputDecoration(labelText: 'Title'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Title is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Title must be at least 5 characters';
                          }
                          if (value.trim().length > 100) {
                            return 'Title cannot be longer than 100 characters';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: authorController,
                        decoration: const InputDecoration(labelText: 'Author'),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Author is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Author must be at least 5 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Author cannot be longer than 50 characters';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Category is required';
                          }
                          if (value.trim().length < 5) {
                            return 'Category must be at least 5 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Category cannot be longer than 50 characters';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: timeController,
                        decoration: const InputDecoration(
                          labelText: 'Time to read (minutes)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Time to read is required';
                          }
                          final parsed = double.tryParse(value.trim());
                          if (parsed == null) {
                            return 'Enter a valid number';
                          }
                          if (parsed < 0 || parsed > 1000) {
                            return 'Time to read must be between 0 and 1000 minutes';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Published date: ${selectedDate.toLocal().toString().split(' ').first}',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() {
                              selectedDate = picked;
                            });
                          }
                        },
                        child: const Text('Change date'),
                      ),
                      TextFormField(
                        controller: textController,
                        decoration: const InputDecoration(
                          labelText: 'Guide content',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 6,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Content is required';
                          }
                          if (value.trim().length < 50) {
                            return 'Content must be at least 50 characters';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: noteController,
                        decoration: const InputDecoration(
                          labelText: 'Note (optional)',
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Image upload section
                      if (currentGuideId != null) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Guide Image',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            if (currentImageUrl != null &&
                                currentImageUrl!.isNotEmpty)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    currentImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surfaceVariant,
                                        child: const Icon(Icons.broken_image),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            if (currentImageUrl == null ||
                                currentImageUrl!.isEmpty)
                              Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.surfaceVariant,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline
                                        .withValues(alpha: 0.3),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.image_outlined,
                                  size: 32,
                                ),
                              ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: isUploadingImage
                                    ? null
                                    : () => uploadGuideImage(currentGuideId!),
                                icon: isUploadingImage
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(Icons.upload),
                                label: Text(
                                  isUploadingImage
                                      ? 'Uploading...'
                                      : currentImageUrl != null &&
                                            currentImageUrl!.isNotEmpty
                                      ? 'Change Image'
                                      : 'Upload Image',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                      ] else if (isEditing) ...[
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'Save the guide first to upload an image',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                        ),
                      ],
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          dialogError ?? '',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                if (currentGuideId != null && !isEditing)
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () {
                            Navigator.of(dialogContext).pop();
                            _loadGuides();
                          },
                    child: const Text('Skip'),
                  ),
                FilledButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          // If guide is already created and user clicks Done, close dialog
                          if (currentGuideId != null && !isEditing) {
                            Navigator.of(dialogContext).pop();
                            await _loadGuides();
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  imageUploaded
                                      ? 'Guide created and image uploaded successfully!'
                                      : 'Guide created successfully!',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!formKey.currentState!.validate()) return;
                          final parsedTime = double.tryParse(
                            timeController.text.trim(),
                          );
                          if (parsedTime == null) {
                            setStateDialog(() {
                              dialogError = 'Time to read must be a number';
                            });
                            return;
                          }
                          setStateDialog(() {
                            isSubmitting = true;
                            dialogError = null;
                          });
                          try {
                            final service = ref.read(guideServiceProvider);
                            String? createdGuideId;
                            if (isEditing) {
                              await service.updateGuide(
                                guide.id,
                                title: titleController.text.trim(),
                                author: authorController.text.trim(),
                                category: categoryController.text.trim(),
                                timeToReadMinutes: parsedTime,
                                postedAt: selectedDate,
                                text: textController.text.trim(),
                                note: noteController.text,
                              );
                              createdGuideId = guide.id;
                            } else {
                              final createdGuide = await service.createGuide(
                                title: titleController.text.trim(),
                                author: authorController.text.trim(),
                                category: categoryController.text.trim(),
                                timeToReadMinutes: parsedTime,
                                postedAt: selectedDate,
                                text: textController.text.trim(),
                              );
                              createdGuideId = createdGuide.id;
                              setStateDialog(() {
                                currentGuideId = createdGuideId;
                              });
                            }
                            if (!mounted) return;

                            // If this was a new guide, keep dialog open for image upload
                            if (!isEditing) {
                              setStateDialog(() {
                                isSubmitting = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Guide created! You can now upload an image.',
                                  ),
                                ),
                              );
                            } else {
                              Navigator.of(dialogContext).pop();
                              await _loadGuides();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isEditing
                                        ? 'Guide updated successfully'
                                        : 'Guide created successfully',
                                  ),
                                ),
                              );
                            }
                          } catch (e) {
                            setStateDialog(() {
                              dialogError = e.toString();
                            });
                          } finally {
                            setStateDialog(() {
                              isSubmitting = false;
                            });
                          }
                        },
                  child: Text(
                    isEditing
                        ? 'Save'
                        : currentGuideId != null
                        ? 'Done'
                        : 'Create',
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showDeleteGuideConfirmation(BuildContext context, Guide guide) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;
        String? error;

        return StatefulBuilder(
          builder: (context, setStateDialog) => AlertDialog(
            title: const Text('Delete Guide'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Are you sure you want to delete "${guide.title}"?'),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setStateDialog(() {
                          isDeleting = true;
                          error = null;
                        });
                        try {
                          final service = ref.read(guideServiceProvider);
                          await service.deleteGuide(guide.id);
                          if (!mounted) return;
                          Navigator.of(dialogContext).pop();
                          await _loadGuides();
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Guide "${guide.title}" deleted'),
                            ),
                          );
                        } catch (e) {
                          setStateDialog(() {
                            error = e.toString();
                          });
                        } finally {
                          setStateDialog(() {
                            isDeleting = false;
                          });
                        }
                      },
                style: TextButton.styleFrom(
                  foregroundColor: AppColorsDark.error,
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Delete'),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
