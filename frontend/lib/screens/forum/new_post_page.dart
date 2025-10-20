/// This file defines the UI for creating a new forum post.
///
/// It provides a form for users to enter a title, message, and category for
/// their new discussion. It also includes functionality to attach one of their
/// saved PC builds to the post.

import 'package:flutter/material.dart';

import 'package:frontend/models/component_models.dart';
import 'package:frontend/screens/explore_build/explore_build_model.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

/// The state for the [NewPostPage].
///
/// Manages the form state, animations, and the logic for submitting the new post.
class _NewPostPageState extends State<NewPostPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  /// The currently selected category for the new post.
  String? _selectedCategory;
  final List<String> _categories = [
    'Troubleshooting',
    'Build Advice',
    'Show Off Your Build',
    'General Discussion',
  ];

  /// Controllers for the title and content text fields.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  /// The [CommunityBuild] object that the user has chosen to attach to the post.
  CommunityBuild? _attachedBuild;

  // TODO: This list should be populated by fetching the current user's saved builds from a service.
  /// A list of the user's saved builds, available to be attached to the post.
  final List<CommunityBuild> _userBuilds = [];

  /// A flag to indicate if the post is currently being submitted to the backend.
  bool _isLoading = false;

  /// Animation controller for the page's entrance animation.
  late AnimationController _animationController;

  /// Fade animation for the page content.
  late Animation<double> _fadeAnimation;

  /// Slide animation for the page content.
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    // Initialize and start the entrance animations for the page.
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  /// Returns a specific color based on the post's category for styling UI elements.
  Color _getCategoryColor(String category, ThemeData theme) {
    switch (category) {
      case 'Troubleshooting':
        return theme.colorScheme.error;
      case 'Build Advice':
        return theme.colorScheme.tertiary;
      case 'Show Off Your Build':
        return theme.colorScheme.secondary;
      case 'General Discussion':
        return theme.colorScheme.primary;
      default:
        return theme.colorScheme.primary;
    }
  }

  /// Handles the form validation and submission of the new post.
  Future<void> _submitPost() async {
    // First, validate all form fields.
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      // TODO: Replace this with a real API call to the backend service.
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      // Print the form data to the console for debugging.
      print('Title: ${_titleController.text}');
      print('Content: ${_contentController.text}');
      print('Category: $_selectedCategory');
      print('Attached Build ID: ${_attachedBuild?.id}');

      setState(() => _isLoading = false);

      // Show a success message to the user.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Post created successfully! 🎉')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      // Pop the current page to return to the main forum page.
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('New Discussion'),
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        // The "Post" button in the AppBar, which shows a loading indicator when busy.
        actions: [
          TextButton.icon(
            onPressed: _isLoading ? null : _submitPost,
            icon: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send, size: 18, color: Colors.white),
            label: Text(
              _isLoading ? 'Posting...' : 'Post',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
      // The main body is animated to fade and slide in on page load.
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SlideTransition(
          position: _slideAnimation,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildHeader(theme),
                  // The main form fields for creating the post.
                  const SizedBox(height: 24),
                  _buildCategorySection(theme),
                  const SizedBox(height: 24),
                  _buildTitleField(theme),
                  const SizedBox(height: 24),
                  _buildContentField(theme),
                  const SizedBox(height: 24),

                  // Section for attaching a PC build to the post.
                  _buildAttachBuildSection(theme),
                  const SizedBox(height: 32),
                  // The main submit button at the bottom of the form.
                  _buildSubmitButton(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the header widget with a title and icon.
  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(Icons.edit, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Start a new discussion',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the dropdown form field for selecting the post category.
  Widget _buildCategorySection(ThemeData theme) {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category *',
        prefixIcon: Icon(Icons.category, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category,
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _getCategoryColor(category, theme),
                  shape: BoxShape.circle,
                ),
              ),
              Text(category),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategory = value),
      validator: (value) => value == null ? 'Please select a category' : null,
    );
  }

  /// Builds the text form field for the post title.
  Widget _buildTitleField(ThemeData theme) {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title *',
        prefixIcon: Icon(Icons.title, color: theme.colorScheme.primary),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a title';
        }
        return null;
      },
    );
  }

  /// Builds the text form field for the main content/message of the post.
  Widget _buildContentField(ThemeData theme) {
    return TextFormField(
      controller: _contentController,
      maxLines: 8,
      minLines: 5,
      decoration: InputDecoration(
        labelText: 'Message *',
        alignLabelWithHint: true,
        prefixIcon: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Icon(Icons.message, color: theme.colorScheme.primary),
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Please enter a message';
        }
        return null;
      },
    );
  }

  /// Builds the section for attaching a build.
  /// It shows a button if no build is attached, or a summary card if one is.
  Widget _buildAttachBuildSection(ThemeData theme) {
    if (_attachedBuild == null) {
      return OutlinedButton.icon(
        icon: const Icon(Icons.add_circle_outline),
        label: const Text('Attach Your Build'),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          foregroundColor: theme.colorScheme.primary,
          side: BorderSide(color: theme.colorScheme.outline.withOpacity(0.5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _showBuildSelectionSheet,
      );
    } else {
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: theme.colorScheme.primary),
        ),
        color: theme.colorScheme.primary.withOpacity(0.05),
        child: ListTile(
          leading: Icon(Icons.memory, color: theme.colorScheme.primary),
          title: Text(
            _attachedBuild!.title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Total: \$${_attachedBuild!.totalPrice.toStringAsFixed(2)}',
          ),
          trailing: IconButton(
            tooltip: 'Remove Build',
            icon: Icon(Icons.cancel, color: theme.colorScheme.error),
            onPressed: () => setState(() => _attachedBuild = null),
          ),
        ),
      );
    }
  }

  /// Shows a modal bottom sheet that lists the user's saved builds for selection.
  void _showBuildSelectionSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Select a Build to Attach',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),

            // If there are no saved builds, this list will be empty.
            // TODO: Add a message for when `_userBuilds` is empty.
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _userBuilds.length,
                itemBuilder: (context, index) {
                  final build = _userBuilds[index];
                  return ListTile(
                    leading: const Icon(Icons.memory_outlined),
                    title: Text(build.title),
                    subtitle: Text(() {
                      // Safely try to find the CPU component to display its name.
                      try {
                        final cpu = build.components.firstWhere(
                          (c) => c.type == ComponentType.cpu,
                        );
                        return 'CPU: ${cpu.name}';
                      } catch (e) {
                        return 'CPU: N/A';
                      }
                    }()),
                    onTap: () {
                      setState(() => _attachedBuild = build);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  /// Builds the main submit button at the bottom of the page.
  Widget _buildSubmitButton(ThemeData theme) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _submitPost,
      icon: _isLoading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Icon(Icons.send),
      label: Text(_isLoading ? 'Creating Post...' : 'Create Discussion'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
