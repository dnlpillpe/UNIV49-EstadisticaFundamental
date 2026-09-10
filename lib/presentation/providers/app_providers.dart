import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/asset_content_repository.dart';
import '../../data/repositories/local_tutor_repository.dart';
import '../../data/repositories/prefs_progress_repository.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../../domain/services/grading_service.dart';
import '../../domain/services/progress_service.dart';
import '../../domain/services/statistics_service.dart';
import '../../domain/services/tutor_engine.dart';

// ---------------------------------------------------------------------------
// Servicios de dominio. Son inmutables y sin estado, así que una instancia
// única basta y se puede sustituir en los tests con `overrideWithValue`.
// ---------------------------------------------------------------------------

final Provider<StatisticsService> statisticsServiceProvider =
    Provider<StatisticsService>((Ref ref) => const StatisticsService());

final Provider<GradingService> gradingServiceProvider =
    Provider<GradingService>((Ref ref) => const GradingService());

final Provider<ProgressService> progressServiceProvider =
    Provider<ProgressService>((Ref ref) => const ProgressService());

// ---------------------------------------------------------------------------
// Repositorios
// ---------------------------------------------------------------------------

final Provider<ContentRepository> contentRepositoryProvider =
    Provider<ContentRepository>((Ref ref) => const AssetContentRepository());

final Provider<ProgressRepository> progressRepositoryProvider =
    Provider<ProgressRepository>((Ref ref) => PrefsProgressRepository());

/// Contenido educativo completo. Se carga una vez al arrancar.
final FutureProvider<ContentBundle> contentProvider =
    FutureProvider<ContentBundle>((Ref ref) async {
  return ref.watch(contentRepositoryProvider).load();
});

/// Acceso síncrono al contenido. Solo es válido después de que
/// [contentProvider] haya resuelto, cosa que la pantalla de arranque garantiza
/// antes de construir cualquier otra pantalla.
final Provider<ContentBundle> bundleProvider =
    Provider<ContentBundle>((Ref ref) {
  final ContentBundle? bundle = ref.watch(contentProvider).value;
  if (bundle == null) {
    throw StateError(
        'El contenido aún no está cargado. Se accedió a bundleProvider antes '
        'de que la pantalla de arranque terminara.');
  }
  return bundle;
});

final Provider<TutorEngine> tutorEngineProvider =
    Provider<TutorEngine>((Ref ref) {
  final ContentBundle bundle = ref.watch(bundleProvider);
  return TutorEngine(
    topics: bundle.tutorTopics,
    misconceptions: bundle.misconceptions,
  );
});

/// Implementación activa del tutor.
///
/// Para activar un tutor con modelo de lenguaje se sustituye esta línea por
/// `RemoteTutorRepository(fallbackEngine: ..., endpoint: ...)`, y no hace falta
/// tocar nada de la interfaz. Las condiciones para hacerlo están documentadas
/// en `remote_tutor_repository.dart`.
final Provider<TutorRepository> tutorRepositoryProvider =
    Provider<TutorRepository>((Ref ref) {
  return LocalTutorRepository(ref.watch(tutorEngineProvider));
});

// ---------------------------------------------------------------------------
// Estado del estudiante
// ---------------------------------------------------------------------------

class LearnerController extends Notifier<LearnerState> {
  @override
  LearnerState build() => const LearnerState.empty();

  ProgressRepository get _repo => ref.read(progressRepositoryProvider);

  /// Carga el estado persistido. La llama la pantalla de arranque.
  Future<void> hydrate() async {
    state = await _repo.load();
  }

  Future<void> _persist() => _repo.save(state);

  Future<void> markLessonRead(String lessonId) async {
    if (state.readLessons.contains(lessonId)) return;
    state = state.copyWith(
      readLessons: <String>{...state.readLessons, lessonId},
    );
    await _persist();
  }

  Future<void> markLabCompleted(String labId) async {
    if (state.completedLabs.contains(labId)) return;
    state = state.copyWith(
      completedLabs: <String>{...state.completedLabs, labId},
    );
    await _persist();
  }

  /// Registra un intento. Guarda **la mejor** puntuación de cada ejercicio, no
  /// la última: reintentar nunca debe penalizar. El historial completo sí
  /// conserva todos los intentos, porque es lo que alimenta al tutor.
  Future<void> recordAttempt(ExerciseAttempt attempt) async {
    final double previous = state.bestScores[attempt.exerciseId] ?? -1;
    final Map<String, double> scores =
        Map<String, double>.of(state.bestScores);
    if (attempt.score > previous) {
      scores[attempt.exerciseId] = attempt.score;
    }
    // El historial se acota a los 500 intentos más recientes. Con un uso
    // intensivo de un ciclo completo no se llega, y evita que el documento
    // persistido crezca sin límite.
    final List<ExerciseAttempt> attempts = <ExerciseAttempt>[
      ...state.attempts,
      attempt,
    ];
    state = state.copyWith(
      bestScores: scores,
      attempts: attempts.length > 500
          ? attempts.sublist(attempts.length - 500)
          : attempts,
    );
    await _persist();
  }

  Future<void> markTutorTopicAsked(String topicId) async {
    if (state.tutorAskedTopics.contains(topicId)) return;
    state = state.copyWith(
      tutorAskedTopics: <String>{...state.tutorAskedTopics, topicId},
    );
    await _persist();
  }

  Future<void> setDisplayName(String name) async {
    state = state.copyWith(displayName: name.trim());
    await _persist();
  }

  Future<void> reset() async {
    await _repo.reset();
    state = const LearnerState.empty()
        .copyWith(startedAtMs: DateTime.now().millisecondsSinceEpoch);
  }
}

final NotifierProvider<LearnerController, LearnerState> learnerProvider =
    NotifierProvider<LearnerController, LearnerState>(LearnerController.new);

// ---------------------------------------------------------------------------
// Vistas derivadas
// ---------------------------------------------------------------------------

final Provider<List<ModuleProgress>> allModuleProgressProvider =
    Provider<List<ModuleProgress>>((Ref ref) {
  final ContentBundle bundle = ref.watch(bundleProvider);
  final LearnerState state = ref.watch(learnerProvider);
  final ProgressService service = ref.watch(progressServiceProvider);
  return bundle.modules
      .map((StudyModule m) =>
          service.moduleProgress(m, bundle.exercisesOf(m.id), state))
      .toList(growable: false);
});

final ProviderFamily<ModuleProgress, String> moduleProgressProvider =
    Provider.family<ModuleProgress, String>((Ref ref, String moduleId) {
  return ref
      .watch(allModuleProgressProvider)
      .firstWhere((ModuleProgress p) => p.moduleId == moduleId);
});

final Provider<double> overallProgressProvider = Provider<double>((Ref ref) {
  return ref
      .watch(progressServiceProvider)
      .overallFraction(ref.watch(allModuleProgressProvider));
});

final Provider<List<MisconceptionTally>> misconceptionRankingProvider =
    Provider<List<MisconceptionTally>>((Ref ref) {
  return ref
      .watch(progressServiceProvider)
      .rankMisconceptions(ref.watch(learnerProvider));
});

final Provider<Map<Competency, double>> competencyScoresProvider =
    Provider<Map<Competency, double>>((Ref ref) {
  return ref.watch(progressServiceProvider).competencyScores(
        ref.watch(bundleProvider).exercises,
        ref.watch(learnerProvider),
      );
});

final Provider<double> blindHitRateProvider = Provider<double>((Ref ref) {
  return ref
      .watch(progressServiceProvider)
      .blindHitRate(ref.watch(learnerProvider));
});

final Provider<({String moduleId, String kind, String label})?>
    nextActionProvider =
    Provider<({String moduleId, String kind, String label})?>((Ref ref) {
  final ContentBundle bundle = ref.watch(bundleProvider);
  return ref.watch(progressServiceProvider).nextAction(
        bundle.modules,
        bundle.exercisesByModule,
        ref.watch(learnerProvider),
      );
});
