/// This file defines the UI for creating a new forum post.
///
/// It includes a form for the post title, content, and topic selection.
/// If a `buildId` is provided in the route, it fetches the build details
/// and pre-populates the form, making it easy to share a PC build.
library;

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/error_utils.dart';
import 'package:frontend/models/api_constants.dart';
import 'dart:html' as html;

/// A page for creating a new forum post.
class NewPostPage extends ConsumerStatefulWidget {
  /// An optional ID of a PC build to associate with this post.
  final String? buildId;

  const NewPostPage({super.key, this.buildId});

  @override
  ConsumerState<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends ConsumerState<NewPostPage> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedTopic = 'General Discussion';
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();

  final List<String> _topicOptions = [
    'General Discussion',
    'Build Advice',
    'Troubleshooting',
    'Showcase',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.buildId != null) {
      _prefillFromBuild();
    }
  }

  /// Fetches build data and pre-populates the form fields.
  Future<void> _prefillFromBuild() async {
    // This is a simple way to pre-fill. For a more robust solution,
    // you might show a loading indicator.
    final build = await ref.read(buildDetailProvider(widget.buildId!).future);

    setState(() {
      _titleController.text = "Check out my new build: ${build.name}";
      _contentController.text =
          "I just finished planning my new PC build and wanted to share it with the community!\n\n**Build Name:** ${build.name}\n**Description:** ${build.description ?? 'N/A'}\n\nLet me know what you think!";
      _selectedTopic = 'Showcase';
    });
  }

  Future<void> _uploadImages(String postId) async {
    final dio = ref.read(authProvider.notifier).getDioInstance();
    
    for (int i = 0; i < _selectedImages.length; i++) {
      final image = _selectedImages[i];
      try {
        debugPrint('Uploading image ${i + 1}/${_selectedImages.length}: ${image.name}');
        final fileBytes = await image.readAsBytes();
        var fileName = image.name;
        if (fileName.isEmpty || !fileName.contains('.')) {
          fileName = 'image_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        }
        
        final formData = FormData.fromMap({
          'File': MultipartFile.fromBytes(
            fileBytes,
            filename: fileName,
          ),
          'TargetId': postId,
          'LocationType': 'FORUM',
          'Name': 'forum_post_${DateTime.now().millisecondsSinceEpoch}_$i',
        });
        
        final response = await dio.post('$apiBaseUrl/Images/add', data: formData);
        debugPrint('Image ${i + 1} uploaded successfully: ${response.data}');
      } catch (e, stackTrace) {
        debugPrint('Error uploading image ${i + 1}: $e');
        debugPrint('Stack trace: $stackTrace');
        // Re-throw to be caught by caller
        throw Exception('Failed to upload image ${i + 1}: $e');
      }
    }
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
          // Limit to 5 images
          if (_selectedImages.length > 5) {
            _selectedImages.removeRange(5, _selectedImages.length);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Maximum 5 images allowed. Only first 5 will be uploaded.'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(getUserFriendlyError(e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Handles the submission of the new post.
  void _submitPost() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final user = ref.read(authProvider).valueOrNull;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to post.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final postData = {
        'title': _titleController.text,
        'content': _contentController.text,
        'topic': _selectedTopic,
        'creatorId': user.uid,
        'buildId': widget.buildId,
      };

      // Create the post
      final response = await ref.read(forumProvider.notifier).createForumPost(postData);
      final postId = response['id']?.toString();
      
      // STOP LOADING FIRST
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Upload images in background (don't wait for it)
      if (_selectedImages.isNotEmpty && postId != null) {
        _uploadImages(postId).catchError((e) {
          debugPrint('Image upload error: $e');
        });
      }
      
      // SHOW SUCCESS DIALOG - This ALWAYS works, no matter what
      if (!mounted) return;
      
      // Show dialog and wait for user to click OK
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
          title: const Text(
            'Success!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          content: const Text(
            'Your post has been created successfully!',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            FilledButton(
              onPressed: () {
                // Close dialog first
                Navigator.of(dialogContext).pop();
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('OK', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      );
      
      // AFTER dialog is closed, navigate to HOME directly
      // User wants to go to home page after creating post
      if (mounted) {
        // Wait a tiny bit to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (!mounted) return;
        
        // Navigate to home page - use window.location.href for web to avoid hash issues
        if (kIsWeb) {
          try {
            // Directly set the full URL to home - this bypasses all router logic
            final origin = html.window.location.origin;
            final targetUrl = '$origin/home';
            
            // Use window.location.href to completely replace the URL
            // This ensures no hash is added
            html.window.location.href = targetUrl;
          } catch (e) {
            debugPrint('Error navigating on web: $e');
            // Fallback: try router
            context.go('/home');
          }
        } else {
          // Non-web: just navigate normally
          context.go('/home');
        }
      }
    } catch (e) {
      // STOP LOADING ON ERROR TOO
      if (mounted) {
        setState(() => _isLoading = false);
      }
      
      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${getUserFriendlyError(e)}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface.withValues(alpha: 0.3),
            ],
          ),
        ),
        child: Column(
          children: [
            const CustomNavigationBar(),
            Expanded(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Header Section
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Icon(
                                  Icons.edit_note,
                                  size: 32,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Create New Post',
                                      style: theme.textTheme.headlineLarge?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Share your thoughts with the community',
                                      style: theme.textTheme.bodyLarge?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Title Field
                          Container(
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _titleController,
                            decoration: InputDecoration(
                              labelText: 'Post Title',
                              hintText: 'Enter a catchy title for your post...',
                              prefixIcon: Icon(
                                Icons.title,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            style: theme.textTheme.titleMedium,
                            validator: (value) =>
                                value == null || value.isEmpty ? 'Title cannot be empty' : null,
                          ),
                          ),
                          const SizedBox(height: 20),

                          // Topic Dropdown
                          Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _selectedTopic,
                            decoration: InputDecoration(
                              labelText: 'Topic',
                              prefixIcon: Icon(
                                Icons.category,
                                color: theme.colorScheme.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 16,
                              ),
                            ),
                            items: _topicOptions
                                .map((topic) => DropdownMenuItem(
                                      value: topic,
                                      child: Text(topic),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _selectedTopic = value);
                              }
                            },
                          ),
                          ),
                          const SizedBox(height: 20),

                          // Content Field
                          Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: TextFormField(
                            controller: _contentController,
                            decoration: InputDecoration(
                              labelText: 'Content',
                              hintText: 'Write your post content here...',
                              alignLabelWithHint: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: theme.colorScheme.surface,
                              contentPadding: const EdgeInsets.all(20),
                            ),
                            maxLines: 12,
                            validator: (value) => value == null || value.isEmpty
                                ? 'Content cannot be empty'
                                : null,
                          ),
                          ),
                          const SizedBox(height: 20),

                          // Image Upload Section
                          Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.image,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Attach Images',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const Spacer(),
                                  if (_selectedImages.length < 5)
                                    OutlinedButton.icon(
                                      onPressed: _pickImages,
                                      icon: const Icon(Icons.add_photo_alternate, size: 18),
                                      label: const Text('Add Images'),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              if (_selectedImages.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Text(
                                  '${_selectedImages.length} image${_selectedImages.length > 1 ? 's' : ''} selected',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 100,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: _selectedImages.length,
                                    itemBuilder: (context, index) {
                                      final image = _selectedImages[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Stack(
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(8),
                                              child: FutureBuilder<Uint8List>(
                                                future: image.readAsBytes(),
                                                builder: (context, snapshot) {
                                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                                    return Container(
                                                      width: 100,
                                                      height: 100,
                                                      color: theme.colorScheme.surfaceVariant,
                                                      child: const Center(
                                                        child: CircularProgressIndicator(strokeWidth: 2),
                                                      ),
                                                    );
                                                  }
                                                  if (snapshot.hasError || !snapshot.hasData) {
                                                    return Container(
                                                      width: 100,
                                                      height: 100,
                                                      color: theme.colorScheme.surfaceVariant,
                                                      child: const Icon(Icons.broken_image),
                                                    );
                                                  }
                                                  return Image.memory(
                                                    snapshot.data!,
                                                    width: 100,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  );
                                                },
                                              ),
                                            ),
                                            Positioned(
                                              top: 4,
                                              right: 4,
                                              child: Material(
                                                color: Colors.red,
                                                borderRadius: BorderRadius.circular(12),
                                                child: InkWell(
                                                  onTap: () => _removeImage(index),
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.close,
                                                      size: 16,
                                                      color: Colors.white,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                          ),
                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : () => context.pop(),
                                  style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: FilledButton(
                                onPressed: _isLoading ? null : _submitPost,
                                style: FilledButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.send, size: 20),
                                          SizedBox(width: 8),
                                          Text('Submit Post'),
                                        ],
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
