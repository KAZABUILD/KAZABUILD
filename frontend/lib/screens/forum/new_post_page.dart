import 'package:flutter/material.dart';
import 'package:frontend/screens/forum/forum_model.dart';

class NewPostPage extends StatefulWidget {
  const NewPostPage({super.key});

  @override
  State<NewPostPage> createState() => _NewPostPageState();
}

class _NewPostPageState extends State<NewPostPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  String? _selectedCategory;
  final List<String> _categories = [
    'Troubleshooting',
    'Build Advice',
    'Show Off Your Build',
    'General Discussion',
  ];

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();

  String? _attachedBuildId;

  UserBuild? get _attachedBuild =>
      _attachedBuildId != null ? getBuildById(_attachedBuildId!) : null;

  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
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

  Future<void> _submitPost() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return;

      print('Title: ${_titleController.text}');
      print('Content: ${_contentController.text}');
      print('Category: $_selectedCategory');
      print('Attached Build ID: $_attachedBuildId');

      setState(() => _isLoading = false);

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
                  const SizedBox(height: 24),
                  _buildCategorySection(theme),
                  const SizedBox(height: 24),
                  _buildTitleField(theme),
                  const SizedBox(height: 24),
                  _buildContentField(theme),
                  const SizedBox(height: 24),

                  _buildAttachBuildSection(theme),
                  const SizedBox(height: 32),
                  _buildSubmitButton(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

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
            _attachedBuild!.name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            'Total: \$${_attachedBuild!.totalPrice.toStringAsFixed(2)}',
          ),
          trailing: IconButton(
            tooltip: 'Remove Build',
            icon: Icon(Icons.cancel, color: theme.colorScheme.error),
            onPressed: () => setState(() => _attachedBuildId = null),
          ),
        ),
      );
    }
  }

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

            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: mockUserBuilds.length,
                itemBuilder: (context, index) {
                  final build = mockUserBuilds[index];
                  return ListTile(
                    leading: const Icon(Icons.memory_outlined),
                    title: Text(build.name),
                    subtitle: Text(
                      'CPU: ${build.components.firstWhere(
                        (c) => c.type == 'CPU',
                        orElse: () => PCComponent(type: '', name: 'N/A'),
                      ).name}',
                    ),
                    onTap: () {
                      setState(() => _attachedBuildId = build.id);
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
