import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/quiz_provider.dart';
import '../../widgets/navigation_bar.dart';
import '../../utils/error_utils.dart';
import '../../l10n/app_localization.dart';

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
                  return const Center(
                    child: Text(
                      'Quiz completed!',
                      style: TextStyle(color: Colors.white, fontSize: 24),
                    ),
                  );
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
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: isMobile ? 5 : 4,
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
              if (_selectedAnswerIds.contains(option.id)) {
                // Deselect if already selected
                _selectedAnswerIds.remove(option.id);
                // Remove from quiz provider
                ref.read(quizProvider.notifier).removeSelection(
                  '${question.id}_${option.id}',
                );
              } else {
                // Add to selection
                _selectedAnswerIds.add(option.id);
                // Save to quiz provider with unique key
                ref.read(quizProvider.notifier).setSelection(
                  QuizAnswerSelection(
                    questionId: '${question.id}_${option.id}',
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
              onPressed: _selectedAnswerIds.isNotEmpty
                  ? () async {
                      final currentStep = ref.read(quizStepProvider);
                      
                      // Move to next step
                      setState(() {
                        _selectedAnswerIds = {};
                      });
                      ref.read(quizStepProvider.notifier).state = currentStep + 1;
                    }
                  : null,
              icon: const Icon(Icons.arrow_forward, size: 18),
              label: const Text('Next'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6B46FF),
                disabledBackgroundColor: const Color(0xFF2A2838),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF6B6B6B),
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
