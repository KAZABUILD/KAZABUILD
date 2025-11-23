library;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_color.dart';
import '../../models/admin_provider.dart';

class AdminQuizPage extends ConsumerStatefulWidget {
  const AdminQuizPage({super.key});

  @override
  ConsumerState<AdminQuizPage> createState() => _AdminQuizPageState();
}

class _AdminQuizPageState extends ConsumerState<AdminQuizPage> {
  static const int _minAnswerLength = 8;
  bool _isProcessing = false;
  bool _hasInitialized = false;
  List<AdminQuizQuestion> _questions = [];
  List<AdminQuizAnswer> _answers = [];
  final Map<String, TextEditingController> _answerControllers = {};
  final Map<String, String?> _answerErrors = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final asyncData = ref.watch(adminQuizDataProvider);

    return Scaffold(
      backgroundColor: isDark
          ? AppColorsDark.backgroundPrimary
          : AppColorsLight.backgroundPrimary,
      body: asyncData.when(
        data: (data) {
          if (!_hasInitialized) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _syncLocalData(data);
            });
          }

          final questions = _hasInitialized ? _questions : data.questions;
          final answers = _hasInitialized ? _answers : data.answers;
          final answersByQuestion = _groupAnswers(answers);
          return Stack(
            children: [
              Column(
                children: [
                  _buildHeader(isDark, answers),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: _buildQuestionList(
                        questions,
                        answersByQuestion,
                        isDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
              if (_isProcessing)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48),
              const SizedBox(height: 16),
              Text('Failed to load quiz data\n$error',
                  textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(adminQuizDataProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in _answerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildHeader(bool isDark, List<AdminQuizAnswer> allAnswers) {
    return Container(
      width: double.infinity,
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quiz Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColorsDark.textWhite
                  : AppColorsLight.textBlack,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isProcessing
                ? null
                : () => _showQuestionDialog(
                      allAnswers: allAnswers,
                    ),
            icon: const Icon(Icons.add),
            label: const Text('Add Question'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? AppColorsDark.buttonGreen
                  : AppColorsLight.buttonGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionList(
    List<AdminQuizQuestion> questions,
    Map<String, List<AdminQuizAnswer>> answersByQuestion,
    bool isDark,
  ) {
    if (questions.isEmpty) {
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColorsDark.backgroundSecondary
              : AppColorsLight.backgroundTertiary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: Text('No quiz questions found.'),
        ),
      );
    }

    final allAnswers =
        answersByQuestion.values.expand((list) => list).toList();

    return ListView.separated(
      itemCount: questions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final question = questions[index];
        final answers = answersByQuestion[question.id] ?? const [];
        return _buildQuestionCard(
          question: question,
          answers: answers,
           allAnswers: allAnswers,
          isDark: isDark,
        );
      },
    );
  }

  Widget _buildQuestionCard({
    required AdminQuizQuestion question,
    required List<AdminQuizAnswer> answers,
    required List<AdminQuizAnswer> allAnswers,
    required bool isDark,
  }) {
    final controller = _answerControllers.putIfAbsent(
      question.id,
      () => TextEditingController(),
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        question.question,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Chip(
                            label: Text('${answers.length} answers'),
                          ),
                          if (question.parentAnswerId != null)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                avatar: const Icon(Icons.subdirectory_arrow_right, size: 16),
                                label: const Text('Follow-up question'),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                Wrap(
                  children: [
                    IconButton(
                      tooltip: 'Edit question',
                      icon: const Icon(Icons.edit),
                      onPressed: _isProcessing
                          ? null
                          : () => _showQuestionDialog(
                                existing: question,
                                allAnswers: allAnswers,
                              ),
                    ),
                    IconButton(
                      tooltip: 'Delete question',
                      icon: const Icon(Icons.delete_outline),
                      onPressed: _isProcessing
                          ? null
                          : () => _confirmDeleteQuestion(question),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildAnswerList(
              question: question,
              answers: answers,
            ),
            const SizedBox(height: 16),
            _buildInlineAnswerForm(
              question: question,
              controller: controller,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Map<String, List<AdminQuizAnswer>> _groupAnswers(
      List<AdminQuizAnswer> answers) {
    final map = <String, List<AdminQuizAnswer>>{};
    for (final answer in answers) {
      map.putIfAbsent(answer.questionId, () => []).add(answer);
    }
    return map;
  }

  Future<void> _showQuestionDialog({
    AdminQuizQuestion? existing,
    required List<AdminQuizAnswer> allAnswers,
  }) async {
    final result = await showDialog<_QuestionFormResult>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: existing?.question ?? '');
        String? selectedParent = existing?.parentAnswerId;
        String? error;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Question' : 'Edit Question'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Question',
                      errorText: error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String?>(
                    value: selectedParent,
                    decoration: const InputDecoration(
                      labelText: 'Follow-up answer (optional)',
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('No parent (primary question)'),
                      ),
                      ...allAnswers.map(
                        (answer) => DropdownMenuItem<String?>(
                          value: answer.id,
                          child: Text(answer.answer),
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() => selectedParent = value);
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (controller.text.trim().isEmpty) {
                      setState(() => error = 'Question text is required');
                      return;
                    }
                    Navigator.of(context).pop(
                      _QuestionFormResult(
                        question: controller.text.trim(),
                        parentAnswerId: selectedParent,
                      ),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final adminService = ref.read(adminServiceProvider);
    _setProcessing(true);
    try {
      if (existing == null) {
        await adminService.createQuizQuestion(
          question: result.question,
          parentAnswerId: result.parentAnswerId,
        );
        _showSnack('Question created');
      } else {
        await adminService.updateQuizQuestion(
          existing.id,
          question: result.question,
          parentAnswerId: result.parentAnswerId,
        );
        _showSnack('Question updated');
      }
      await _loadData();
    } catch (e) {
      _showSnack('Operation failed: $e');
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _showAnswerDialog({
    required AdminQuizQuestion question,
    AdminQuizAnswer? existing,
  }) async {
    final result = await showDialog<_AnswerFormResult>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: existing?.answer ?? '');
        String? error;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(existing == null ? 'Add Answer' : 'Edit Answer'),
              content: TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Answer (min $_minAnswerLength chars)',
                  errorText: error,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final trimmed = controller.text.trim();
                    if (trimmed.length < _minAnswerLength) {
                      setState(
                        () => error =
                            'Answer must be at least $_minAnswerLength characters long',
                      );
                      return;
                    }
                    Navigator.of(context).pop(
                      _AnswerFormResult(answer: trimmed),
                    );
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result == null) return;

    final adminService = ref.read(adminServiceProvider);
    _setProcessing(true);
    try {
      if (existing == null) {
        await adminService.createQuizAnswer(
          questionId: question.id,
          answer: result.answer,
        );
        _showSnack('Answer created');
      } else {
        await adminService.updateQuizAnswer(
          existing.id,
          answer: result.answer,
        );
        _showSnack('Answer updated');
      }
      await _loadData();
    } on DioException catch (error) {
      _showSnack(_extractServerMessage(error));
    } catch (e) {
      _showSnack('Operation failed: $e');
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _confirmDeleteQuestion(AdminQuizQuestion question) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete question'),
        content: const Text(
          'Deleting this question will also remove its answers. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final adminService = ref.read(adminServiceProvider);
    _setProcessing(true);
    try {
      await adminService.deleteQuizQuestion(question.id);
      _showSnack('Question deleted');
      await _loadData();
    } catch (e) {
      _showSnack('Failed to delete question: $e');
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _confirmDeleteAnswer(AdminQuizAnswer answer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete answer'),
        content: const Text('Are you sure you want to delete this answer?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final adminService = ref.read(adminServiceProvider);
    _setProcessing(true);
    try {
      await adminService.deleteQuizAnswer(answer.id);
      _showSnack('Answer deleted');
      await _loadData();
    } catch (e) {
      _showSnack('Failed to delete answer: $e');
    } finally {
      _setProcessing(false);
    }
  }

  void _setProcessing(bool value) {
    if (!mounted) return;
    setState(() {
      _isProcessing = value;
    });
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _syncLocalData(AdminQuizData data) {
    setState(() {
      _questions = data.questions;
      _answers = data.answers;
      _hasInitialized = true;
    });
    _cleanupAnswerControllers(data.questions);
  }

  Future<void> _loadData() async {
    try {
      final data = await ref.refresh(adminQuizDataProvider.future);
      if (!mounted) return;
      setState(() {
        _questions = data.questions;
        _answers = data.answers;
        _hasInitialized = true;
      });
      _cleanupAnswerControllers(data.questions);
    } catch (e) {
      _showSnack('Failed to refresh quiz data: $e');
    }
  }

  void _cleanupAnswerControllers(List<AdminQuizQuestion> questions) {
    final ids = questions.map((q) => q.id).toSet();
    final removed = _answerControllers.keys
        .where((key) => !ids.contains(key))
        .toList(growable: false);
    for (final key in removed) {
      _answerControllers.remove(key)?.dispose();
      _answerErrors.remove(key);
    }
  }

  Widget _buildAnswerList({
    required AdminQuizQuestion question,
    required List<AdminQuizAnswer> answers,
  }) {
    if (answers.isEmpty) {
      return Text(
        'No answers defined for this question yet.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: Theme.of(context).colorScheme.outline),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: answers.length,
      separatorBuilder: (_, __) => const Divider(),
      itemBuilder: (context, index) {
        final answer = answers[index];
        return ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(answer.answer),
          subtitle: Text(
            'Created ${answer.createdAt?.toLocal().toString().split(".").first ?? "--"}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          trailing: Wrap(
            children: [
              IconButton(
                tooltip: 'Edit answer',
                icon: const Icon(Icons.edit),
                onPressed: _isProcessing
                    ? null
                    : () => _showAnswerDialog(
                          question: question,
                          existing: answer,
                        ),
              ),
              IconButton(
                tooltip: 'Delete answer',
                icon: const Icon(Icons.delete_outline),
                onPressed: _isProcessing
                    ? null
                    : () => _confirmDeleteAnswer(answer),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInlineAnswerForm({
    required AdminQuizQuestion question,
    required TextEditingController controller,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick add answers',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 128,
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Enter answer with min $_minAnswerLength chars',
                  errorText: _answerErrors[question.id],
                  filled: true,
                  fillColor: isDark
                      ? AppColorsDark.backgroundTertiary
                      : AppColorsLight.backgroundSecondary,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton.icon(
              onPressed: _isProcessing
                  ? null
                  : () => _submitInlineAnswer(question, controller),
              icon: const Icon(Icons.send),
              label: const Text('Add'),
            ),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed:
                _isProcessing ? null : () => _showBulkAddDialog(question),
            icon: const Icon(Icons.playlist_add),
            label: const Text('Bulk add answers'),
          ),
        ),
      ],
    );
  }

  Future<void> _submitInlineAnswer(
    AdminQuizQuestion question,
    TextEditingController controller,
  ) async {
    final value = controller.text.trim();
    if (value.length < _minAnswerLength) {
      setState(() {
        _answerErrors[question.id] =
            'Answer must be at least $_minAnswerLength characters.';
      });
      return;
    }

    setState(() {
      _answerErrors[question.id] = null;
    });

    final adminService = ref.read(adminServiceProvider);
    _setProcessing(true);
    try {
      await adminService.createQuizAnswer(
        questionId: question.id,
        answer: value,
      );
      controller.clear();
      _showSnack('Answer added');
      await _loadData();
    } on DioException catch (error) {
      _showSnack(_extractServerMessage(error));
    } catch (e) {
      _showSnack('Failed to add answer: $e');
    } finally {
      _setProcessing(false);
    }
  }

  Future<void> _showBulkAddDialog(AdminQuizQuestion question) async {
    final controller = TextEditingController();
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Bulk add answers'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Enter one answer per line. '
                    'Each answer must be at least 8 characters.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: controller,
                    maxLines: 6,
                    decoration: InputDecoration(
                      hintText: 'Example:\nGaming on ultra\nStreaming setup\nVideo editing workhorse',
                      errorText: errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton.icon(
                  onPressed: () {
                    final entries = controller.text
                        .split('\n')
                        .map((line) => line.trim())
                        .where((line) => line.isNotEmpty)
                        .toList();

                    final invalid = entries.any((line) => line.length < _minAnswerLength);
                    if (entries.isEmpty) {
                      setState(() => errorText = 'Please enter at least one answer.');
                      return;
                    }
                    if (invalid) {
                      setState(() => errorText =
                          'Every answer must be at least $_minAnswerLength characters.');
                      return;
                    }
                    Navigator.of(context).pop(true);
                  },
                  icon: const Icon(Icons.playlist_add_check),
                  label: const Text('Add All'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true) return;

    final entries = controller.text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.length >= _minAnswerLength)
        .toList();

    final adminService = ref.read(adminServiceProvider);
    _setProcessing(true);
    try {
      for (final answer in entries) {
        await adminService.createQuizAnswer(
          questionId: question.id,
          answer: answer,
        );
      }
      _showSnack('${entries.length} answers added');
      await _loadData();
    } on DioException catch (error) {
      _showSnack(_extractServerMessage(error));
    } catch (e) {
      _showSnack('Failed to add answers: $e');
    } finally {
      _setProcessing(false);
    }
  }

  String _extractServerMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['message'] is String) {
        return data['message'] as String;
      }
      if (data['errors'] is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>;
        if (errors.isNotEmpty) {
          final value = errors.values.first;
          if (value is List && value.isNotEmpty) {
            return value.first.toString();
          }
          return value.toString();
        }
      }
    }
    return error.message ?? 'Unknown server error';
  }
}

class _QuestionFormResult {
  final String question;
  final String? parentAnswerId;

  _QuestionFormResult({required this.question, this.parentAnswerId});
}

class _AnswerFormResult {
  final String answer;

  _AnswerFormResult({required this.answer});
}

