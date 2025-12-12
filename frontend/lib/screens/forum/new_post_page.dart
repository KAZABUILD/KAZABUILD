/// This file defines the UI for creating a new forum post.
///
/// It includes a form for the post title, content, and topic selection.
/// If a `buildId` is provided in the route, it fetches the build details
/// and pre-populates the form, making it easy to share a PC build.
library;

import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
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
import '../../core/constants/app_color.dart';


/// A page for creating a new forum post or editing an existing one.
class NewPostPage extends ConsumerStatefulWidget {
  /// An optional ID of a PC build to associate with this post.
  final String? buildId;

  /// An optional ID of a forum post to edit.
  final String? postId;

  /// An optional route to return to after creating/editing the post.
  final String? returnTo;

  const NewPostPage({super.key, this.buildId, this.postId, this.returnTo});

  @override
  ConsumerState<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends ConsumerState<NewPostPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedTopic = 'General Discussion';
  bool _isLoading = false;
  final List<XFile> _selectedImages = [];
  final ImagePicker _imagePicker = ImagePicker();
  late AnimationController _headerAnimationController;
  late AnimationController _backgroundAnimationController;
  late Animation<double> _headerFadeAnimation;

  final List<String> _topicOptions = [
    'General Discussion',
    'Build Advice',
    'Troubleshooting',
    'Showcase',
  ];

  @override
  void initState() {
    super.initState();
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _headerFadeAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOutCubic,
    );
    
    _backgroundAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    
    _headerAnimationController.forward();
    
    if (widget.postId != null) {
      _loadPostForEdit();
    } else if (widget.buildId != null) {
      _prefillFromBuild();
    }
  }

  /// Loads post data for editing
  Future<void> _loadPostForEdit() async {
    try {
      final forumService = ref.read(forumServiceProvider);
      final post = await forumService.getPostById(widget.postId!);

      setState(() {
        _titleController.text = post.title;
        _contentController.text = post.content;
        _selectedTopic = post.topic;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading post: ${getUserFriendlyError(e)}'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    _headerAnimationController.dispose();
    _backgroundAnimationController.dispose();
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

      String? postId;

      // If editing, update the post
      if (widget.postId != null) {
        final updateData = {
          'title': _titleController.text,
          'content': _contentController.text,
          'topic': _selectedTopic,
        };

        await ref.read(forumProvider.notifier).updateForumPost(widget.postId!, updateData);
        postId = widget.postId;

        // STOP LOADING FIRST
        if (mounted) {
          setState(() => _isLoading = false);
        }

        // SHOW SUCCESS DIALOG
        if (!mounted) return;

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
              'Your post has been updated successfully!',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              FilledButton(
                onPressed: () {
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

        // Navigate back to returnTo route or default to profile page
        if (mounted) {
          await Future.delayed(const Duration(milliseconds: 100));
          if (!mounted) return;
          final targetRoute = widget.returnTo ?? '/profile';
          context.go(targetRoute);
        }
        return;
      }

      // Create the post
      final response = await ref.read(forumProvider.notifier).createForumPost(postData);
      postId = response['id']?.toString();

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

      // AFTER dialog is closed, navigate to returnTo route or default to /forums
      if (mounted) {
        // Wait a tiny bit to ensure dialog is fully closed
        await Future.delayed(const Duration(milliseconds: 100));

        if (!mounted) return;

        // Use GoRouter's context.go() for proper navigation
        // If returnTo is provided (e.g., from admin panel), go there; otherwise go to forums
        final targetRoute = widget.returnTo ?? '/forums';
        context.go(targetRoute);
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
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    // Use the same background color as forums page
    final backgroundColor = isDarkMode 
        ? const Color(0xFF0B0B0F) 
        : AppColorsLight.backgroundPrimary;
    
    return Scaffold(
      key: _scaffoldKey,
      drawer: CustomDrawer(showProfileArea: true),
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // Animated Background (matching forums page)
          AnimatedBuilder(
            animation: _backgroundAnimationController,
            builder: (context, child) {
              return CustomPaint(
                painter: _AnimatedBackgroundPainter(
                  progress: _backgroundAnimationController.value,
                  isDarkMode: isDarkMode,
                ),
                size: Size.infinite,
              );
            },
          ),
          Column(
            children: [
              const CustomNavigationBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : 32,
                    vertical: isMobile ? 20 : 40,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? double.infinity : 800,
                      ),
                      child: FadeTransition(
                        opacity: _headerFadeAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Premium Header (matching forums page style)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: isMobile ? 20 : 32,
                                vertical: isMobile ? 20 : 40,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Minimal Badge
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isMobile ? 12 : 16,
                                      vertical: isMobile ? 6 : 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDarkMode 
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.black.withValues(alpha: 0.05),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: (isDarkMode ? Colors.white : Colors.black)
                                            .withValues(alpha: 0.1),
                                      ),
                                    ),
                                    child: Text(
                                      'COMMUNITY FORUM',
                                      style: theme.textTheme.labelLarge?.copyWith(
                                        fontWeight: FontWeight.w900,
                                        color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                                        letterSpacing: 2,
                                        fontSize: isMobile ? 10 : 11,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 16 : 24),
                                  
                                  // Main Title
                                  Text(
                                    widget.postId != null ? 'Edit Post' : 'Start Discussion',
                                    style: theme.textTheme.displayLarge?.copyWith(
                                      fontWeight: FontWeight.w900,
                                      fontSize: isMobile ? 32 : 42,
                                      letterSpacing: -1,
                                      color: isDarkMode ? Colors.white : Colors.black87,
                                      height: 1.1,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 8 : 12),
                                  
                                  Text(
                                    widget.postId != null
                                        ? 'Update your post content'
                                        : 'Share your thoughts with the community',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontSize: isMobile ? 14 : 16,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                      height: 1.4,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  SizedBox(height: isMobile ? 20 : 32),
                                ],
                              ),
                            ),
                            
                            // Form Section
                            Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [

                                  // Title Field
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode 
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode 
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _titleController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Post Title',
                                        labelStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        hintText: 'Enter a catchy title for your post...',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                        helperText: 'Choose a clear and descriptive title that summarizes your post',
                                        helperStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                        helperMaxLines: 2,
                                        prefixIcon: Icon(
                                          Icons.title,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDarkMode 
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.black.withValues(alpha: 0.05),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDarkMode 
                                                ? AppColorsDark.textNeon
                                                : AppColorsLight.textNeon,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      validator: (value) =>
                                          value == null || value.isEmpty ? 'Title cannot be empty' : null,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Topic Dropdown
                                  Container(
                                    decoration: BoxDecoration(
                                      color: isDarkMode 
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode 
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: DropdownButtonFormField<String>(
                                      value: _selectedTopic,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Topic',
                                        labelStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        prefixIcon: Icon(
                                          Icons.category,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                          size: 20,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDarkMode 
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.black.withValues(alpha: 0.05),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDarkMode 
                                                ? AppColorsDark.textNeon
                                                : AppColorsLight.textNeon,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 16,
                                        ),
                                      ),
                                      dropdownColor: isDarkMode 
                                          ? const Color(0xFF0B0B0F)
                                          : AppColorsLight.backgroundPrimary,
                                      items: _topicOptions
                                          .map((topic) => DropdownMenuItem(
                                                value: topic,
                                                child: Text(
                                                  topic,
                                                  style: TextStyle(
                                                    color: isDarkMode ? Colors.white : Colors.black87,
                                                  ),
                                                ),
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
                                      color: isDarkMode 
                                          ? Colors.white.withValues(alpha: 0.05)
                                          : Colors.grey.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isDarkMode 
                                            ? Colors.white.withValues(alpha: 0.1)
                                            : Colors.black.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: TextFormField(
                                      controller: _contentController,
                                      style: TextStyle(
                                        color: isDarkMode ? Colors.white : Colors.black87,
                                      ),
                                      decoration: InputDecoration(
                                        labelText: 'Content',
                                        labelStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                        ),
                                        hintText: 'Write your post content here...',
                                        hintStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                        ),
                                        helperText: 'Share your thoughts, questions, or experiences. You can also attach images below.',
                                        helperStyle: TextStyle(
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                          fontSize: 12,
                                        ),
                                        helperMaxLines: 2,
                                        alignLabelWithHint: true,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide.none,
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDarkMode 
                                                ? Colors.white.withValues(alpha: 0.1)
                                                : Colors.black.withValues(alpha: 0.05),
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDarkMode 
                                                ? AppColorsDark.textNeon
                                                : AppColorsLight.textNeon,
                                            width: 2,
                                          ),
                                        ),
                                        filled: true,
                                        fillColor: Colors.transparent,
                                        contentPadding: const EdgeInsets.all(16),
                                      ),
                                      maxLines: 12,
                                      validator: (value) => value == null || value.isEmpty
                                          ? 'Content cannot be empty'
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 20),

                                  // Image Upload Section (only show when creating new post, not editing)
                                  if (widget.postId == null) ...[
                                    Container(
                                      decoration: BoxDecoration(
                                        color: isDarkMode 
                                            ? Colors.white.withValues(alpha: 0.05)
                                            : Colors.grey.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: isDarkMode 
                                              ? Colors.white.withValues(alpha: 0.1)
                                              : Colors.black.withValues(alpha: 0.05),
                                        ),
                                      ),
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.image,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Attach Images',
                                                style: theme.textTheme.titleMedium?.copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color: isDarkMode ? Colors.white : Colors.black87,
                                                ),
                                              ),
                                              const Spacer(),
                                              if (_selectedImages.length < 5)
                                                OutlinedButton.icon(
                                                  onPressed: _pickImages,
                                                  icon: Icon(
                                                    Icons.add_photo_alternate,
                                                    size: 18,
                                                    color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                                                  ),
                                                  label: Text(
                                                    'Add Images',
                                                    style: TextStyle(
                                                      color: isDarkMode ? AppColorsDark.textNeon : AppColorsLight.textNeon,
                                                      fontWeight: FontWeight.w600,
                                                    ),
                                                  ),
                                                  style: OutlinedButton.styleFrom(
                                                    padding: const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                    side: BorderSide(
                                                      color: isDarkMode 
                                                          ? AppColorsDark.textNeon.withValues(alpha: 0.5)
                                                          : AppColorsLight.textNeon.withValues(alpha: 0.5),
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
                                  ],
                                  const SizedBox(height: 32),

                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: _isLoading ? null : () {
                                            // Navigate back to forums page
                                            final returnRoute = widget.returnTo ?? '/forums';
                                            context.go(returnRoute);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(vertical: 16),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            side: BorderSide(
                                              color: isDarkMode 
                                                  ? Colors.white.withValues(alpha: 0.2)
                                                  : Colors.black.withValues(alpha: 0.1),
                                            ),
                                          ),
                                          child: Text(
                                            'Cancel',
                                            style: TextStyle(
                                              color: isDarkMode ? Colors.white : Colors.black87,
                                            ),
                                          ),
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
                                            backgroundColor: isDarkMode 
                                                ? AppColorsDark.textNeon
                                                : AppColorsLight.textNeon,
                                          ),
                                          child: _isLoading
                                              ? const SizedBox(
                                                  height: 20,
                                                  width: 20,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2,
                                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                                  ),
                                                )
                                              : Row(
                                                  mainAxisAlignment: MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      widget.postId != null ? Icons.save : Icons.send,
                                                      size: 20,
                                                      color: Colors.black,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      widget.postId != null ? 'Update Post' : 'Submit Post',
                                                      style: const TextStyle(
                                                        color: Colors.black,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
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
        ],
      ),
    );
  }
}

// Animated Background Painter (matching forums page)
class _AnimatedBackgroundPainter extends CustomPainter {
  final double progress;
  final bool isDarkMode;

  _AnimatedBackgroundPainter({
    required this.progress,
    required this.isDarkMode,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Keep it extremely subtle for the clean screenshot look
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120);

    for (int i = 0; i < 2; i++) {
      final offset = progress + (i * 0.5);
      final x = size.width * (0.3 + 0.4 * math.sin(offset * 2 * math.pi));
      final y = size.height * (0.2 + 0.3 * math.cos(offset * 2 * math.pi));
      
      paint.shader = RadialGradient(
        colors: [
          (isDarkMode ? AppColorsDark.textPurple : AppColorsLight.textPurple)
              .withValues(alpha: 0.05), // Extremely low opacity
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: Offset(x, y), radius: 400));
      
      canvas.drawCircle(Offset(x, y), 400, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
