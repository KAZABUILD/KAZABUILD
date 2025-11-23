/// This file defines the state management for the interactive PC builder quiz.
///
/// It uses Riverpod to manage the user's answers and the current step of the quiz.
/// - `QuizAnswers`: An immutable model to hold the user's responses to the quiz questions.
/// - `QuizNotifier`: A `StateNotifier` to manage the state of the `QuizAnswers`.
/// - `quizProvider`: A global provider to access the quiz state.
/// - `quizStepProvider`: A simple provider to track the current question number.
library;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/models/api_constants.dart';
import 'package:frontend/models/auth_provider.dart';
import 'package:frontend/models/explore_build_model.dart' as build_model;

@immutable
class QuizAnswerOption {
  const QuizAnswerOption({
    required this.id,
    required this.questionId,
    required this.text,
    this.followUpQuestionId,
  });

  final String id;
  final String questionId;
  final String text;
  final String? followUpQuestionId;

  QuizAnswerOption copyWith({String? followUpQuestionId}) {
    return QuizAnswerOption(
      id: id,
      questionId: questionId,
      text: text,
      followUpQuestionId: followUpQuestionId ?? this.followUpQuestionId,
    );
  }
}

@immutable
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.text,
    this.parentAnswerId,
    this.options = const [],
  });

  final String id;
  final String text;
  final String? parentAnswerId;
  final List<QuizAnswerOption> options;

  QuizQuestion copyWith({List<QuizAnswerOption>? options}) {
    return QuizQuestion(
      id: id,
      text: text,
      parentAnswerId: parentAnswerId,
      options: options ?? this.options,
    );
  }
}

@immutable
class QuizAnswerSelection {
  const QuizAnswerSelection({
    required this.questionId,
    required this.questionText,
    required this.answerId,
    required this.answerText,
    this.userAnswerId,
  });

  final String questionId;
  final String questionText;
  final String answerId;
  final String answerText;
  final String? userAnswerId;

  QuizAnswerSelection copyWith({
    String? answerId,
    String? answerText,
    String? userAnswerId,
  }) {
    return QuizAnswerSelection(
      questionId: questionId,
      questionText: questionText,
      answerId: answerId ?? this.answerId,
      answerText: answerText ?? this.answerText,
      userAnswerId: userAnswerId ?? this.userAnswerId,
    );
  }
}

@immutable
class QuizAnswers {
  const QuizAnswers({this.selections = const {}});

  final Map<String, QuizAnswerSelection> selections;

  QuizAnswerSelection? selectionForQuestion(String questionId) {
    return selections[questionId];
  }

  QuizAnswers copyWith({Map<String, QuizAnswerSelection>? selections}) {
    return QuizAnswers(
      selections: selections ?? this.selections,
    );
  }
}

class QuizNotifier extends StateNotifier<QuizAnswers> {
  QuizNotifier() : super(const QuizAnswers());

  void setSelection(QuizAnswerSelection selection) {
    final updated = Map<String, QuizAnswerSelection>.from(state.selections)
      ..[selection.questionId] = selection;
    state = state.copyWith(selections: updated);
  }

  void removeSelection(String questionId) {
    if (!state.selections.containsKey(questionId)) return;
    final updated = Map<String, QuizAnswerSelection>.from(state.selections)
      ..remove(questionId);
    state = state.copyWith(selections: updated);
  }

  void setSelections(Iterable<QuizAnswerSelection> selections) {
    final mapped = {
      for (final selection in selections) selection.questionId: selection,
    };
    state = state.copyWith(selections: mapped);
  }

  void resetQuiz() {
    state = const QuizAnswers();
  }
}

final quizProvider = StateNotifierProvider<QuizNotifier, QuizAnswers>((ref) {
  return QuizNotifier();
});

final quizStepProvider = StateProvider<int>((ref) => 0);

class QuizService {
  QuizService(this._dio);

  final Dio _dio;

  Future<List<QuizQuestion>> fetchQuestions() async {
    final prefsResponse = await _dio.post(
      '$apiBaseUrl/UserPreferences/get',
      data: {
        'Paging': false,
        'OrderBy': 'DatabaseEntryAt',
        'SortDirection': 'asc',
      },
    );

    final List<dynamic> preferenceJson =
        prefsResponse.data as List<dynamic>? ?? [];
    final Map<String, QuizQuestion> questions = {};

    for (final dynamic pref in preferenceJson) {
      if (pref is! Map<String, dynamic>) continue;
      final id = _asString(pref['id'] ?? pref['Id']);
      final question = _asString(pref['question'] ?? pref['Question']);
      if (id == null || question == null) continue;
      final parentAnswerId =
          _asString(pref['userPreferenceAnswerId'] ?? pref['UserPreferenceAnswerId']);

      questions[id] = QuizQuestion(
        id: id,
        text: question,
        parentAnswerId:
            parentAnswerId != null && parentAnswerId.isNotEmpty ? parentAnswerId : null,
      );
    }

    final answersResponse = await _dio.post(
      '$apiBaseUrl/UserPreferenceAnswers/get',
      data: {
        'Paging': false,
      },
    );

    final List<dynamic> answersJson =
        answersResponse.data as List<dynamic>? ?? [];
    final Map<String, List<QuizAnswerOption>> optionsByQuestion = {};

    for (final dynamic answer in answersJson) {
      if (answer is! Map<String, dynamic>) continue;
      final id = _asString(answer['id'] ?? answer['Id']);
      final questionId =
          _asString(answer['userPreferenceId'] ?? answer['UserPreferenceId']);
      final text = _asString(answer['answer'] ?? answer['Answer']);

      if (id == null || questionId == null || text == null) continue;
      final option = QuizAnswerOption(
        id: id,
        questionId: questionId,
        text: text,
      );
      optionsByQuestion.putIfAbsent(questionId, () => []).add(option);
    }

    final Map<String, String> followUpMap = {};
    for (final entry in questions.values) {
      if (entry.parentAnswerId != null) {
        followUpMap[entry.parentAnswerId!] = entry.id;
      }
    }

    final List<QuizQuestion> output = [];
    for (final question in questions.values) {
      final options = (optionsByQuestion[question.id] ?? [])
          .map(
            (option) => option.copyWith(
              followUpQuestionId: followUpMap[option.id],
            ),
          )
          .toList()
        ..sort((a, b) => a.text.compareTo(b.text));
      output.add(question.copyWith(options: options));
    }

    output.sort((a, b) {
      final aHasParent = a.parentAnswerId != null;
      final bHasParent = b.parentAnswerId != null;
      if (aHasParent && !bHasParent) return 1;
      if (!aHasParent && bHasParent) return -1;
      return a.text.compareTo(b.text);
    });

    return output;
  }

  Future<List<QuizAnswerSelection>> fetchUserSelections({
    required String userId,
    required Map<String, QuizQuestion> questionLookup,
    required Map<String, QuizAnswerOption> answerLookup,
  }) async {
    final response = await _dio.post(
      '$apiBaseUrl/UserAnswers/get',
      data: {
        'UserId': [userId],
        'Paging': false,
      },
    );

    final List<dynamic> answers = response.data as List<dynamic>? ?? [];
    final List<QuizAnswerSelection> selections = [];
    for (final dynamic answer in answers) {
      if (answer is! Map<String, dynamic>) continue;
      final answerId =
          _asString(answer['userPreferenceAnswerId'] ?? answer['UserPreferenceAnswerId']);
      final recordId = _asString(answer['id'] ?? answer['Id']);
      if (answerId == null) continue;
      final option = answerLookup[answerId];
      if (option == null) continue;
      final question = questionLookup[option.questionId];
      if (question == null) continue;
      selections.add(
        QuizAnswerSelection(
          questionId: question.id,
          questionText: question.text,
          answerId: option.id,
          answerText: option.text,
          userAnswerId: recordId,
        ),
      );
    }
    return selections;
  }

  Future<String> submitAnswer({
    required String userId,
    required String answerId,
  }) async {
    final response = await _dio.post(
      '$apiBaseUrl/UserAnswers/add',
      data: {
        'UserId': userId,
        'UserPreferenceAnswerId': answerId,
      },
    );

    final data = response.data;
    if (data is Map<String, dynamic>) {
      final id = _asString(data['id'] ?? data['Id']);
      if (id != null) {
        return id;
      }
    }
    return '';
  }

  Future<void> deleteUserAnswer(String userAnswerId) async {
    if (userAnswerId.isEmpty) return;
    await _dio.delete('$apiBaseUrl/UserAnswers/$userAnswerId');
  }

  Future<void> generateBuilds() async {
    await _dio.post('$apiBaseUrl/Builds/generate');
  }

  Future<List<build_model.Build>> fetchGeneratedBuilds({required String userId}) async {
    final response = await _dio.post(
      '$apiBaseUrl/Builds/get',
      data: {
        'UserId': [userId],
        'Status': ['GENERATED'],
        'Paging': false,
        'OrderBy': 'DatabaseEntryAt',
        'SortDirection': 'desc',
      },
    );

    final List<dynamic> buildsJson = response.data as List<dynamic>? ?? [];
    final List<build_model.Build> builds = [];
    for (final dynamic build in buildsJson) {
      if (build is Map<String, dynamic>) {
        try {
          builds.add(build_model.Build.fromJson(build));
        } catch (_) {
          continue;
        }
      }
    }

    if (builds.isEmpty) return builds;

    final imageResponse = await _dio.post(
      '$apiBaseUrl/Images/get',
      data: {
        'BuildId': builds.map((b) => b.id).toList(),
        'LocationType': ['BUILD'],
        'Paging': false,
      },
    );

    final List<dynamic> images = imageResponse.data as List<dynamic>? ?? [];
    final Map<String, String?> imageByBuildId = {};
    for (final dynamic image in images) {
      if (image is! Map<String, dynamic>) continue;
      final targetId = _asString(image['targetId'] ?? image['TargetId']);
      final imageId = _asString(image['id'] ?? image['Id']);
      if (targetId == null || imageId == null) continue;
      imageByBuildId[targetId] = '$apiBaseUrl/Images/download/$imageId';
    }

    return builds
        .map(
          (build) => build_model.Build(
            id: build.id,
            userId: build.userId,
            name: build.name,
            description: build.description,
            status: build.status,
            imageUrl: imageByBuildId[build.id] ?? build.imageUrl,
            author: build.author,
            databaseEntryAt: build.databaseEntryAt,
            lastEditedAt: build.lastEditedAt,
            averageRating: build.averageRating,
            ratingsCount: build.ratingsCount,
            userRating: build.userRating,
            components: build.components,
            tags: build.tags,
          ),
        )
        .toList();
  }

  static String? _asString(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    return value.toString();
  }
}

final quizServiceProvider = Provider<QuizService>((ref) {
  final dio = ref.watch(authProvider.notifier).getDioInstance();
  return QuizService(dio);
});

final quizQuestionsProvider =
    FutureProvider.autoDispose<List<QuizQuestion>>((ref) async {
  final authState = ref.watch(authProvider);
  final user = authState.valueOrNull;
  final service = ref.watch(quizServiceProvider);
  final questions = await service.fetchQuestions();

  final questionLookup = {
    for (final question in questions) question.id: question,
  };
  final answerLookup = <String, QuizAnswerOption>{};
  for (final question in questions) {
    for (final option in question.options) {
      answerLookup[option.id] = option;
    }
  }

  if (user != null) {
    final selections = await service.fetchUserSelections(
      userId: user.uid,
      questionLookup: questionLookup,
      answerLookup: answerLookup,
    );
    ref.read(quizProvider.notifier).setSelections(selections);
  } else {
    ref.read(quizProvider.notifier).resetQuiz();
  }

  ref.read(quizStepProvider.notifier).state = 0;
  return questions;
});

final quizRecommendedBuildsProvider = FutureProvider.autoDispose
    .family<List<build_model.Build>, String>((ref, userId) async {
  if (userId.isEmpty) return [];
  final service = ref.watch(quizServiceProvider);
  return service.fetchGeneratedBuilds(userId: userId);
});
