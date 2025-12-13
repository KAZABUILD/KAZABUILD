import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz_provider.dart';
import '../../models/auth_provider.dart';
import '../../widgets/navigation_bar.dart';
import '../../utils/error_utils.dart';
import '../../l10n/app_localization.dart';
import 'quiz_result_page.dart';

/// Quiz page that displays questions and answers from the backend.
/// Integrates with quiz_provider for state management.
class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends ConsumerState<QuizPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  Set<String> _selectedAnswerIds = {};
  bool _generationStarted = false;
  Future<void>? _generationFuture;
  String? _generationError;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final questionsAsync = ref.watch(quizQuestionsProvider);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFF0B0A14),
      drawer: isMobile ? const CustomDrawer() : null,
      body: Column(
        children: [
          CustomNavigationBar(scaffoldKey: _scaffoldKey),
          Expanded(
            child: questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return const Center(
                    child: Text(
                      'No questions available',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final currentStep = ref.watch(quizStepProvider);
                
                // Filter out follow-up questions for now, show only main questions
                final mainQuestions = questions.where((q) => q.parentAnswerId == null).toList();
                
                if (currentStep >= mainQuestions.length) {
                  if (_generationError != null) {
                    return _GenerationError(
                      message: _generationError!,
                      onRetry: () {
                        ref.read(quizProvider.notifier).resetQuiz();
                        ref.read(quizStepProvider.notifier).state = 0;
                        setState(() {
                          _generationStarted = false;
                          _generationFuture = null;
                          _generationError = null;
                          _selectedAnswerIds.clear();
                        });
                      },
                    );
                  }
                  _startGeneration(context);
                  return const _GenerationLoading();
                }

                final currentQuestion = mainQuestions[currentStep];
                final quizState = ref.watch(quizProvider);
                
                // Load existing selections for this question
                final existingSelections = quizState.selections.values
                    .where((s) => s.questionId.startsWith(currentQuestion.id))
                    .map((s) => s.answerId)
                    .toSet();
                
                if (existingSelections.isNotEmpty && _selectedAnswerIds.isEmpty) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _selectedAnswerIds = existingSelections;
                    });
                  });
                }

                return _buildQuizContent(
                  context,
                  currentQuestion,
                  mainQuestions.length,
                  currentStep,
                  isMobile,
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: Color(0xFF6B46FF),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading questions',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        getUserFriendlyError(error),
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.refresh(quizQuestionsProvider),
                        child: Text(AppLocalizations.of(context)!.retry),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizContent(
    BuildContext context,
    QuizQuestion question,
    int totalSteps,
    int currentStep,
    bool isMobile,
  ) {
    final isDesktop = MediaQuery.of(context).size.width > 768;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 24.0 : 48.0,
          vertical: 32.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStepIndicator(totalSteps, currentStep),
            const SizedBox(height: 48),
            Text(
              question.text,
              style: TextStyle(
                color: Colors.white,
                fontSize: isMobile ? 28 : 36,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 900 : double.infinity,
                  ),
                  child: _buildAnswersGrid(question, isMobile),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildBottomNavigation(context, question, totalSteps, currentStep),
          ],
        ),
      ),
    );
  }

  Future<void> _startGeneration(BuildContext context) async {
    if (_generationStarted) return;
    _generationStarted = true;

    final messenger = ScaffoldMessenger.of(context);
    try {
      final user = ref.read(authProvider).valueOrNull;
      if (user != null) {
        final quizState = ref.read(quizProvider);
        final selections = quizState.selections.values.toList();

        final quizService = ref.read(quizServiceProvider);

        // Rebuild lookups (if questions are loaded) so we can clean stale server answers
        final questionsAsync = ref.read(quizQuestionsProvider);
        final questions = questionsAsync.valueOrNull ?? [];
        final questionLookup = {
          for (final q in questions) q.id: q,
        };
        final answerLookup = <String, QuizAnswerOption>{};
        for (final q in questions) {
          for (final opt in q.options) {
            answerLookup[opt.id] = opt;
          }
        }

        // Delete all previously saved answers for this user (generated builds will use fresh answers)
        if (questions.isNotEmpty) {
          try {
            final existingSelections = await quizService.fetchUserSelections(
              userId: user.uid,
              questionLookup: questionLookup,
              answerLookup: answerLookup,
            );
            await Future.wait(existingSelections
                .map((s) => s.userAnswerId)
                .where((id) => (id ?? '').isNotEmpty)
                .map((id) => quizService.deleteUserAnswer(id!)));
          } catch (_) {
            // best-effort cleanup; continue even if it fails
          }
        }

        // Persist current selections (always submit all to ensure latest answers are used)
        await Future.wait(
          selections.map((s) async {
            try {
              await quizService.submitAnswer(userId: user.uid, answerId: s.answerId);
            } on DioException catch (e) {
              // Ignore duplicates already recorded server-side
              if (e.response?.statusCode != 409) rethrow;
            }
          }),
        );

        // Always trigger a fresh generation for a new batch of 3 builds
        _generationFuture = quizService.generateBuilds();
        await _generationFuture;
        _generationFuture = null;

        // Delete older GENERATED builds, keep the latest 3
        await quizService.pruneGeneratedBuilds(userId: user.uid, keepLatest: 3);

        // Ensure recommended builds provider refreshes with the new generation
        ref.invalidate(quizRecommendedBuildsProvider(user.uid));
      }

      if (mounted) {
        setState(() {
          _generationError = null;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const QuizResultsPage()),
        );
      }
    } catch (e) {
      _generationStarted = false;
      _generationFuture = null;
      final errMsg = e.toString().contains('No Components Found')
          ? 'We could not find components that match your answers. Please retake the quiz.'
          : 'Failed to generate builds. Please try again.';
      setState(() {
        _generationError = errMsg;
      });
      messenger.showSnackBar(SnackBar(content: Text(errMsg)));
    }
  }

  Widget _buildStepIndicator(int totalSteps, int currentStep) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(totalSteps, (index) {
        final isActive = index == currentStep;
        final isCompleted = index < currentStep;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          width: isActive ? 32 : 12,
          height: 12,
          decoration: BoxDecoration(
            color: isActive || isCompleted
                ? const Color(0xFF6B46FF)
                : const Color(0xFF2A2838),
            borderRadius: BorderRadius.circular(6),
          ),
        );
      }),
    );
  }

  Widget _buildAnswersGrid(QuizQuestion question, bool isMobile) {
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = isMobile
        ? 1
        : width > 1200
            ? 3
            : 2;
    final aspectRatio = isMobile
        ? 4.5
        : width > 1200
            ? 3.5
            : 4.0;

    return GridView.builder(
      shrinkWrap: false,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: aspectRatio,
      ),
      itemCount: question.options.length,
      itemBuilder: (context, index) {
        final option = question.options[index];
        final isSelected = _selectedAnswerIds.contains(option.id);

        return _buildAnswerButton(
          option: option,
          question: question,
          isSelected: isSelected,
          onTap: () {
            setState(() {
              final selectionKey = '${question.id}_${option.id}';
              if (_selectedAnswerIds.contains(option.id)) {
                // Deselect if already selected
                _selectedAnswerIds.remove(option.id);
                // Remove from quiz provider
                ref.read(quizProvider.notifier).removeSelection(selectionKey);
              } else {
                // Multi-select: add without clearing others
                _selectedAnswerIds.add(option.id);
                // Save with unique key per option
                ref.read(quizProvider.notifier).setSelection(
                  QuizAnswerSelection(
                    questionId: selectionKey,
                    questionText: question.text,
                    answerId: option.id,
                    answerText: option.text,
                  ),
                );
              }
            });
          },
        );
      },
    );
  }

  Widget _buildAnswerButton({
    required QuizAnswerOption option,
    required QuizQuestion question,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6B46FF).withOpacity(0.15)
                : Colors.transparent,
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF6B46FF)
                  : const Color(0xFF2A2838),
              width: isSelected ? 2 : 1.5,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                option.text,
                style: TextStyle(
                  color: isSelected ? Colors.white : const Color(0xFFB0B0B0),
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context,
    QuizQuestion question,
    int totalSteps,
    int currentStep,
  ) {
    return Column(
      children: [
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: const TextStyle(
            color: Color(0xFF6B6B6B),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Back button - smaller and text-only
            TextButton.icon(
              onPressed: currentStep > 0
                  ? () {
                      setState(() {
                        _selectedAnswerIds = {};
                      });
                      ref.read(quizStepProvider.notifier).state = currentStep - 1;
                    }
                  : null,
              icon: const Icon(Icons.arrow_back, size: 18),
              label: const Text('Back'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF6B6B6B),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(width: 24),
            // Next button - smaller and distinct
            ElevatedButton.icon(
              onPressed: () async {
                if (_selectedAnswerIds.isEmpty) {
                  await showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      backgroundColor: const Color(0xFF1A1926),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Selection required',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: const Text(
                        'Please choose at least one answer to continue.',
                        style: TextStyle(color: Color(0xFFB0B0B0)),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                final step = ref.read(quizStepProvider);
                final nextStep = step + 1;
                final isLast = nextStep >= totalSteps;

                // Move to next step (or finalize) after a selection is made
                setState(() {
                  _selectedAnswerIds = {};
                });
                ref.read(quizStepProvider.notifier).state = nextStep;

                if (isLast) {
                  _startGeneration(context);
                }
              },
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GenerationLoading extends StatelessWidget {
  const _GenerationLoading();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircularProgressIndicator(color: Color(0xFF6B46FF)),
            SizedBox(height: 16),
            Text(
              'Generating your 3 recommended builds...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Text(
              'We\'re preparing a batch of 3 builds based on your answers.',
              style: TextStyle(
                color: Color(0xFFB0B0B0),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GenerationError extends StatelessWidget {
  const _GenerationError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.orange, size: 48),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Retake Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}
