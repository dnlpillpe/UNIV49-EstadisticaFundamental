/// Registro de un intento de ejercicio.
class ExerciseAttempt {
  const ExerciseAttempt({
    required this.exerciseId,
    required this.moduleId,
    required this.competencyKey,
    required this.score,
    required this.choiceCorrect,
    required this.justificationCorrect,
    required this.errorTags,
    required this.timestampMs,
  });

  final String exerciseId;
  final String moduleId;
  final String competencyKey;

  /// Puntuación en 0..1 (ver `GradingService`).
  final double score;
  final bool choiceCorrect;

  /// `null` cuando el ejercicio no pedía justificación.
  final bool? justificationCorrect;

  /// Etiquetas conceptuales de los errores cometidos en este intento.
  final List<String> errorTags;
  final int timestampMs;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'e': exerciseId,
        'm': moduleId,
        'c': competencyKey,
        's': score,
        'ok': choiceCorrect,
        'j': justificationCorrect,
        't': errorTags,
        'ts': timestampMs,
      };

  factory ExerciseAttempt.fromJson(Map<String, dynamic> json) =>
      ExerciseAttempt(
        exerciseId: json['e'] as String,
        moduleId: json['m'] as String,
        competencyKey: json['c'] as String? ?? 'interpretacion',
        score: (json['s'] as num).toDouble(),
        choiceCorrect: json['ok'] as bool? ?? false,
        justificationCorrect: json['j'] as bool?,
        errorTags: (json['t'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
        timestampMs: (json['ts'] as num?)?.toInt() ?? 0,
      );
}

/// Estado completo del aprendizaje de una persona en el dispositivo.
///
/// Es un único objeto serializable en lugar de una tabla por entidad: el
/// volumen es pequeño (decenas de kB) y guardarlo entero evita estados
/// parcialmente escritos si la app se cierra a mitad de una operación.
class LearnerState {
  const LearnerState({
    required this.readLessons,
    required this.completedLabs,
    required this.bestScores,
    required this.attempts,
    required this.tutorAskedTopics,
    required this.startedAtMs,
    required this.displayName,
  });

  const LearnerState.empty()
      : readLessons = const <String>{},
        completedLabs = const <String>{},
        bestScores = const <String, double>{},
        attempts = const <ExerciseAttempt>[],
        tutorAskedTopics = const <String>{},
        startedAtMs = 0,
        displayName = '';

  final Set<String> readLessons;
  final Set<String> completedLabs;

  /// Mejor puntuación por ejercicio (0..1). Se guarda la mejor y no la última
  /// para que reintentar nunca penalice.
  final Map<String, double> bestScores;

  /// Historial completo de intentos. Es lo que alimenta al tutor.
  final List<ExerciseAttempt> attempts;

  final Set<String> tutorAskedTopics;
  final int startedAtMs;
  final String displayName;

  LearnerState copyWith({
    Set<String>? readLessons,
    Set<String>? completedLabs,
    Map<String, double>? bestScores,
    List<ExerciseAttempt>? attempts,
    Set<String>? tutorAskedTopics,
    int? startedAtMs,
    String? displayName,
  }) =>
      LearnerState(
        readLessons: readLessons ?? this.readLessons,
        completedLabs: completedLabs ?? this.completedLabs,
        bestScores: bestScores ?? this.bestScores,
        attempts: attempts ?? this.attempts,
        tutorAskedTopics: tutorAskedTopics ?? this.tutorAskedTopics,
        startedAtMs: startedAtMs ?? this.startedAtMs,
        displayName: displayName ?? this.displayName,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'readLessons': readLessons.toList(),
        'completedLabs': completedLabs.toList(),
        'bestScores': bestScores,
        'attempts': attempts
            .map((ExerciseAttempt a) => a.toJson())
            .toList(growable: false),
        'tutorAskedTopics': tutorAskedTopics.toList(),
        'startedAtMs': startedAtMs,
        'displayName': displayName,
      };

  factory LearnerState.fromJson(Map<String, dynamic> json) => LearnerState(
        readLessons: (json['readLessons'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toSet(),
        completedLabs: (json['completedLabs'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toSet(),
        bestScores: (json['bestScores'] as Map<dynamic, dynamic>? ??
                <dynamic, dynamic>{})
            .map<String, double>((dynamic k, dynamic v) =>
                MapEntry<String, double>(k as String, (v as num).toDouble())),
        attempts: (json['attempts'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                ExerciseAttempt.fromJson(e as Map<String, dynamic>))
            .toList(),
        tutorAskedTopics:
            (json['tutorAskedTopics'] as List<dynamic>? ?? <dynamic>[])
                .map((dynamic e) => e as String)
                .toSet(),
        startedAtMs: (json['startedAtMs'] as num?)?.toInt() ?? 0,
        displayName: json['displayName'] as String? ?? '',
      );
}

/// Vista calculada del avance en un módulo.
class ModuleProgress {
  const ModuleProgress({
    required this.moduleId,
    required this.lessonsRead,
    required this.lessonsTotal,
    required this.labDone,
    required this.exercisesAttempted,
    required this.exercisesTotal,
    required this.averageScore,
    required this.completed,
  });

  final String moduleId;
  final int lessonsRead;
  final int lessonsTotal;
  final bool labDone;
  final int exercisesAttempted;
  final int exercisesTotal;

  /// Media de las mejores puntuaciones de los ejercicios intentados (0..1).
  final double averageScore;
  final bool completed;

  /// Avance global del módulo repartido en tres tercios: teoría, laboratorio y
  /// práctica. Que el laboratorio pese un tercio entero es una decisión de
  /// producto: es la parte que más enseña y la que un estudiante saltaría.
  double get fraction {
    final double theory =
        lessonsTotal == 0 ? 1 : lessonsRead / lessonsTotal;
    final double lab = labDone ? 1 : 0;
    final double practice =
        exercisesTotal == 0 ? 1 : exercisesAttempted / exercisesTotal;
    return (theory + lab + practice) / 3;
  }
}

/// Recuento de una confusión conceptual detectada en el historial.
class MisconceptionTally {
  const MisconceptionTally({
    required this.tag,
    required this.count,
    required this.lastSeenMs,
  });

  final String tag;
  final int count;
  final int lastSeenMs;
}
