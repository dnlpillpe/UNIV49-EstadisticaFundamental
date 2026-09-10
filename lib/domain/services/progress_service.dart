import '../entities/exercise.dart';
import '../entities/measurement.dart';
import '../entities/progress.dart';
import '../entities/study_module.dart';

/// Reglas de avance. Dart puro y sin estado: todas las decisiones sobre
/// "¿está completo este módulo?" viven aquí y se prueban sin interfaz.
class ProgressService {
  const ProgressService();

  /// Umbral de dominio de un módulo. 0,7 y no 0,6: con justificaciones que
  /// valen 0,4, un 0,6 se alcanza acertando siempre la alternativa y fallando
  /// siempre el porqué, que es justamente el perfil que la app quiere detectar.
  static const double masteryThreshold = 0.7;

  ModuleProgress moduleProgress(
    StudyModule module,
    List<Exercise> moduleExercises,
    LearnerState state,
  ) {
    final int lessonsRead = module.lessons
        .where((Lesson l) => state.readLessons.contains(l.id))
        .length;
    final bool labDone = state.completedLabs.contains(module.lab.id);

    final List<double> scores = <double>[];
    for (final Exercise e in moduleExercises) {
      final double? best = state.bestScores[e.id];
      if (best != null) scores.add(best);
    }
    final double avg = scores.isEmpty
        ? 0
        : scores.reduce((double a, double b) => a + b) / scores.length;

    final bool completed = lessonsRead == module.lessons.length &&
        labDone &&
        scores.length == moduleExercises.length &&
        moduleExercises.isNotEmpty &&
        avg >= masteryThreshold;

    return ModuleProgress(
      moduleId: module.id,
      lessonsRead: lessonsRead,
      lessonsTotal: module.lessons.length,
      labDone: labDone,
      exercisesAttempted: scores.length,
      exercisesTotal: moduleExercises.length,
      averageScore: avg,
      completed: completed,
    );
  }

  /// Avance global en 0..1.
  double overallFraction(List<ModuleProgress> progresses) {
    if (progresses.isEmpty) return 0;
    final double sum = progresses.fold<double>(
        0, (double a, ModuleProgress p) => a + p.fraction);
    return sum / progresses.length;
  }

  /// Confusiones ordenadas por frecuencia y, a igualdad, por recencia.
  List<MisconceptionTally> rankMisconceptions(LearnerState state) {
    final Map<String, int> counts = <String, int>{};
    final Map<String, int> last = <String, int>{};
    for (final ExerciseAttempt a in state.attempts) {
      for (final String tag in a.errorTags) {
        counts[tag] = (counts[tag] ?? 0) + 1;
        final int prev = last[tag] ?? 0;
        if (a.timestampMs > prev) last[tag] = a.timestampMs;
      }
    }
    final List<MisconceptionTally> tallies = counts.entries
        .map((MapEntry<String, int> e) => MisconceptionTally(
              tag: e.key,
              count: e.value,
              lastSeenMs: last[e.key] ?? 0,
            ))
        .toList()
      ..sort((MisconceptionTally a, MisconceptionTally b) {
        final int byCount = b.count.compareTo(a.count);
        if (byCount != 0) return byCount;
        return b.lastSeenMs.compareTo(a.lastSeenMs);
      });
    return tallies;
  }

  /// Puntuación media por competencia (0..1). Solo cuenta el mejor intento de
  /// cada ejercicio, para que insistir no baje la nota.
  Map<Competency, double> competencyScores(
    List<Exercise> allExercises,
    LearnerState state,
  ) {
    final Map<Competency, List<double>> buckets =
        <Competency, List<double>>{};
    for (final Exercise e in allExercises) {
      final double? best = state.bestScores[e.id];
      if (best == null) continue;
      buckets.putIfAbsent(e.competency, () => <double>[]).add(best);
    }
    return buckets.map((Competency k, List<double> v) => MapEntry<Competency, double>(
        k, v.reduce((double a, double b) => a + b) / v.length));
  }

  /// Diferencia entre acertar y entender: porcentaje de intentos en los que la
  /// alternativa fue correcta pero la justificación no. Es el indicador que da
  /// sentido a toda la regla 60/40.
  double blindHitRate(LearnerState state) {
    final List<ExerciseAttempt> withJustification = state.attempts
        .where((ExerciseAttempt a) => a.justificationCorrect != null)
        .toList();
    if (withJustification.isEmpty) return 0;
    final int blind = withJustification
        .where((ExerciseAttempt a) =>
            a.choiceCorrect && a.justificationCorrect == false)
        .length;
    return blind / withJustification.length;
  }

  /// Siguiente acción recomendada. Prioridad: terminar lo empezado antes de
  /// abrir algo nuevo.
  ({String moduleId, String kind, String label})? nextAction(
    List<StudyModule> modules,
    Map<String, List<Exercise>> exercisesByModule,
    LearnerState state,
  ) {
    for (final StudyModule m in modules) {
      final ModuleProgress p = moduleProgress(
        m,
        exercisesByModule[m.id] ?? const <Exercise>[],
        state,
      );
      if (p.lessonsRead < p.lessonsTotal) {
        return (
          moduleId: m.id,
          kind: 'lesson',
          label: 'Continuar la teoría de ${m.title}',
        );
      }
      if (!p.labDone) {
        return (
          moduleId: m.id,
          kind: 'lab',
          label: 'Hacer el laboratorio: ${m.lab.title}',
        );
      }
      if (p.exercisesAttempted < p.exercisesTotal) {
        return (
          moduleId: m.id,
          kind: 'exercise',
          label: 'Practicar ${m.title}',
        );
      }
      if (p.averageScore < masteryThreshold) {
        return (
          moduleId: m.id,
          kind: 'review',
          label: 'Repasar ${m.title} (puntuación por debajo del umbral)',
        );
      }
    }
    return null;
  }
}
