import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/screens/explore_build/explore_builds_page.dart';
import 'package:frontend/screens/auth/auth_provider.dart';
import 'package:frontend/models/component_models.dart';

// Quiz cevaplarını tutan model
class QuizAnswers {
  final String? occupation;
  final String? budgetRange;
  final String? usagePurpose;

  QuizAnswers({this.occupation, this.budgetRange, this.usagePurpose});

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

// Quiz'in durumunu yöneten StateNotifier
class QuizNotifier extends StateNotifier<QuizAnswers> {
  QuizNotifier() : super(QuizAnswers());

  void setOccupation(String? occupation) {
    state = state.copyWith(occupation: occupation);
  }

  void setBudgetRange(String? budgetRange) {
    state = state.copyWith(budgetRange: budgetRange);
  }

  void setUsagePurpose(String? usagePurpose) {
    state = state.copyWith(usagePurpose: usagePurpose);
  }

  List<CommunityBuild> getRecommendedBuilds(AppUser? user) {
    // Backend entegrasyonu burada olacak
    print('Kullanıcı Cevapları:');
    print('Meslek: ${state.occupation ?? "Seçilmedi"}');
    print('Bütçe: ${state.budgetRange ?? "Seçilmedi"}');
    print('Kullanım Amacı: ${state.usagePurpose ?? "Seçilmedi"}');

    return [];
  }

  void resetQuiz() {
    state = QuizAnswers();
  }
}

// Quiz cevaplarını tutan ana provider
final quizProvider = StateNotifierProvider<QuizNotifier, QuizAnswers>((ref) {
  return QuizNotifier();
});

// Quiz'in o anki adımını tutan provider
final quizStepProvider = StateProvider<int>((ref) => 0);
