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
import 'package:frontend/models/explore_build_model.dart';
import 'package:frontend/models/forum_provider.dart';
import 'package:frontend/screens/auth/auth_widgets.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Go back to the forums page after successful creation.
        context.go('/forums');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to create post: ${e.toString()}'),
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
      appBar: AppBar(
        title: const Text('Create New Post'),
        backgroundColor: theme.colorScheme.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Post Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Title cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedTopic,
                decoration: const InputDecoration(labelText: 'Topic'),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(
                  labelText: 'Content',
                  alignLabelWithHint: true,
                ),
                maxLines: 10,
                validator: (value) => value == null || value.isEmpty
                    ? 'Content cannot be empty'
                    : null,
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                text: _isLoading ? 'Submitting...' : 'Submit Post',
                onPressed: _isLoading ? null : _submitPost,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
