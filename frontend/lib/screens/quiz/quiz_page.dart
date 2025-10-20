/// This file defines the UI for the interactive PC builder quiz.
///
/// It guides the user through a series of questions to understand their needs
/// (e.g., occupation, budget, usage) and then presents recommended PC builds
/// based on their answers. The state is managed using Riverpod.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/widgets/quiz_result_page.dart';
import 'package:frontend/widgets/navigation_bar.dart';
import 'package:frontend/screens/quiz/quiz_provider.dart';

/// The main widget for the interactive quiz.
class QuizPage extends ConsumerStatefulWidget {
  const QuizPage({super.key});

  @override
  ConsumerState<QuizPage> createState() => _QuizPageState();
}

/// The state for the [QuizPage].
///
/// Manages the current step of the quiz and handles user interactions.
class _QuizPageState extends ConsumerState<QuizPage> {
  //for questions for now empty
  List<Map<String, dynamic>> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  /// Fetches quiz questions from the backend.
  void _fetchQuestions() {
    // TODO: Fetch the quiz questions from your backend API here.
    // After fetching, update the state, for example:
    // setState(() { _questions = fetchedQuestions; });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Watch the providers to get the current state and the notifiers to update it.
    final currentStep = ref.watch(quizStepProvider);
    final quizAnswers = ref.watch(quizProvider);
    final quizNotifier = ref.read(quizProvider.notifier);
    final stepNotifier = ref.read(quizStepProvider.notifier);

    final bool hasQuestions = _questions.isNotEmpty;
    final Map<String, dynamic>? currentQuestion =
        hasQuestions && currentStep < _questions.length
        ? _questions[currentStep]
        : null;

    /// A helper function to retrieve the currently selected answer for the current step.
    String? getSelectedAnswer() {
      if (!hasQuestions || currentQuestion == null) return null;
      switch (currentStep) {
        case 0:
          return quizAnswers.occupation;
        case 1:
          return quizAnswers.budgetRange;
        case 2:
          return quizAnswers.usagePurpose;
        default:
          return null;
      }
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: Column(
        children: [
          const CustomNavigationBar(),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 800),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // A progress bar to show the user's progress through the quiz.
                      LinearProgressIndicator(
                        value: hasQuestions && _questions.isNotEmpty
                            ? (currentStep + 1) / _questions.length
                            : 0,
                        backgroundColor: theme.colorScheme.surfaceVariant
                            .withOpacity(0.5),
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                        minHeight: 10,
                      ),
                      const SizedBox(height: 32),

                      // Displays the current question text.
                      Text(
                        currentQuestion != null
                            ? currentQuestion['question'] as String
                            : 'Quiz Loading...',
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),

                      // If questions are loaded, display the answer options in a grid.
                      hasQuestions && currentQuestion != null
                          ? GridView.builder(
                              shrinkWrap: true,
                              // The grid displays 2 options per row.
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 3,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                              itemCount:
                                  (currentQuestion['options'] as List).length,
                              itemBuilder: (context, index) {
                                final option =
                                    currentQuestion['options'][index];
                                final isSelected =
                                    option == getSelectedAnswer();
                                return GestureDetector(
                                  // When an option is tapped, update the state using the answer_setter function.
                                  onTap: () {
                                    final answerSetter =
                                        currentQuestion['answer_setter']
                                            as void Function(
                                              QuizNotifier,
                                              String,
                                            );
                                    answerSetter(quizNotifier, option);
                                  },
                                  child: AnimatedContainer(
                                    // Provides a smooth visual feedback when an option is selected.
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.outline
                                                  .withOpacity(0.2),
                                        width: 2,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: theme.colorScheme.primary
                                                    .withOpacity(0.3),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Center(
                                      child: Text(
                                        option as String,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                              color: isSelected
                                                  ? theme.colorScheme.onPrimary
                                                  : theme.colorScheme.onSurface,
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.normal,
                                            ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          // If questions are not loaded, show a placeholder.
                          : Container(
                              height: 250,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surface.withOpacity(
                                  0.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Center(
                                child: Text(
                                  'Options will be loaded from the backend.',
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                      const SizedBox(height: 32),

                      // Navigation buttons to move between steps or finish the quiz.
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Opacity(
                            opacity: currentStep > 0 && hasQuestions
                                ? 1.0
                                : 0.0,
                            // The "Back" button is only visible after the first step.
                            child: TextButton.icon(
                              onPressed: currentStep > 0 && hasQuestions
                                  ? () => stepNotifier.state--
                                  : null,
                              icon: const Icon(Icons.arrow_back_ios),
                              label: const Text('Back'),
                              style: TextButton.styleFrom(
                                foregroundColor: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),

                          // Displays the current step number.
                          Text(
                            hasQuestions
                                ? 'Step ${currentStep + 1} of ${_questions.length}'
                                : 'Step ${currentStep + 1}',
                            style: theme.textTheme.bodyMedium,
                          ),

                          // The "Next" or "Finish" button.
                          ElevatedButton.icon(
                            onPressed:
                                !hasQuestions ||
                                    getSelectedAnswer() == null ||
                                    currentQuestion == null
                                ? null
                                : () {
                                    // If not the last step, go to the next one.
                                    if (currentStep < _questions.length - 1) {
                                      stepNotifier.state++;
                                    } else {
                                      // If it is the last step, navigate to the results page.
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const QuizResultsPage(),
                                        ),
                                      );
                                    }
                                  },
                            icon: Icon(
                              hasQuestions &&
                                      currentStep < _questions.length - 1
                                  ? Icons.arrow_forward_ios
                                  : Icons.check,
                              size: 18,
                            ),
                            label: Text(
                              hasQuestions &&
                                      currentStep < _questions.length - 1
                                  ? 'Next'
                                  : 'Finish',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
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
    );
  }
}
