/// This file defines the state management for the interactive PC builder quiz.
///
/// It uses Riverpod to manage the user's answers and the current step of the quiz.
/// - [QuizAnswers]: A model to hold the user's responses to the quiz questions.
/// - [QuizNotifier]: A `StateNotifier` to manage the state of the `QuizAnswers`.
/// - [quizProvider]: A global provider to access the quiz state.
/// - [quizStepProvider]: A simple provider to track the current question number.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/explore_build/explore_build_model.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/models/component_models.dart';

/// A data class that holds the user's answers from the quiz.
class QuizAnswers {
  /// The user's selected occupation or hobby (e.g., "Gamer", "Developer").
  final String? occupation;

  /// The user's selected budget range (e.g., "$1000 - $1500").
  final String? budgetRange;

  /// The user's primary intended use for the PC (e.g., "Gaming", "Work").
  final String? usagePurpose;

  QuizAnswers({this.occupation, this.budgetRange, this.usagePurpose});

  /// Creates a copy of this `QuizAnswers` instance with the given fields
  /// replaced with the new values. This is useful for immutable state updates.
  QuizAnswers copyWith({
    String? occupation,
    String? budgetRange,
    String? usagePurpose,
  }) {
    return QuizAnswers(
      occupation: occupation ?? this.occupation,
      budgetRange: budgetRange ?? this.budgetRange,
      usagePurpose: usagePurpose ?? this.usagePurpose,
    );
  }
}

/// Manages the state of the [QuizAnswers].
///
/// This notifier provides methods to update each answer individually and to
/// eventually get build recommendations based on the collected answers.
class QuizNotifier extends StateNotifier<QuizAnswers> {
  /// Initializes the notifier with an empty `QuizAnswers` object.
  QuizNotifier() : super(QuizAnswers());

  /// Updates the user's selected occupation in the state.
  void setOccupation(String? occupation) {
    state = state.copyWith(occupation: occupation);
  }

  /// Updates the user's selected budget range in the state.
  void setBudgetRange(String? budgetRange) {
    state = state.copyWith(budgetRange: budgetRange);
  }

  /// Updates the user's primary usage purpose in the state.
  void setUsagePurpose(String? usagePurpose) {
    state = state.copyWith(usagePurpose: usagePurpose);
  }

  /// Fetches recommended builds based on the current quiz answers.
  ///
  /// [user] is the currently authenticated user, which might be used for
  /// personalization in the future.
  // TODO: Implement the backend API call to get recommendations.
  List<CommunityBuild> getRecommendedBuilds(AppUser? user) {
    return [];
  }

  /// Resets all quiz answers to their initial empty state.
  void resetQuiz() {
    state = QuizAnswers();
  }
}

/// A global provider that exposes the [QuizNotifier] to the entire app.
///
/// Widgets can use this to read the current answers or to call methods to update them.
final quizProvider = StateNotifierProvider<QuizNotifier, QuizAnswers>((ref) {
  return QuizNotifier();
});

/// A simple provider that holds the current step (question index) of the quiz.
///
/// This is used by the UI to know which question to display.
final quizStepProvider = StateProvider<int>((ref) => 0);
