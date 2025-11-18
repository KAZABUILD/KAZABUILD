/// This file defines the UI for creating a new forum post.
///
/// It includes a form for the post title, content, and topic selection.
/// If a `buildId` is provided in the route, it fetches the build details
/// and pre-populates the form, making it easy to share a PC build.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/build_provider.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/utils/error_utils.dart';

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
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  String _selectedTopic = 'General Discussion';
  bool _isLoading = false;

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
        'buildId': widget.buildId, // This will now be correctly handled by the backend.
      };

      await ref.read(forumProvider.notifier).createForumPost(postData);

      if (mounted) {
        // Show success message first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Post created successfully!',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
        
        // Navigate to forums page after a short delay to ensure message is visible
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            context.go('/forums');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(getUserFriendlyError(e)),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
          ],
        ),
      ),
    );
  }
}
