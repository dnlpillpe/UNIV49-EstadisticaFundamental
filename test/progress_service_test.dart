import 'package:estadistica_fundamental/domain/entities/exercise.dart';
import 'package:estadistica_fundamental/domain/entities/measurement.dart';
import 'package:estadistica_fundamental/domain/entities/progress.dart';
import 'package:estadistica_fundamental/domain/entities/study_module.dart';
import 'package:estadistica_fundamental/domain/repositories/content_repository.dart';
import 'package:estadistica_fundamental/domain/services/progress_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/file_content_repository.dart';

ExerciseAttempt _attempt(
  String id, {
  required double score,
  required bool choiceOk,
  bool? justificationOk,
  List<String> tags = const <String>[],
  int at = 1000,
  String module = 'm3',
}) =>
    ExerciseAttempt(
      exerciseId: id,
      moduleId: module,
      competencyKey: 'interpretacion',
      score: score,
      choiceCorrect: choiceOk,
      justificationCorrect: justificationOk,
      errorTags: tags,
      timestampMs: at,
    );

void main() {
  const ProgressService service = ProgressService();
  late ContentBundle bundle;

  setUpAll(() async {
    bundle = await const FileContentRepository().load();
  });

  group('Avance de módulo', () {
    test('un módulo intacto está a cero', () {
      final StudyModule m = bundle.modules.first;
      final ModuleProgress p = service.moduleProgress(
          m, bundle.exercisesOf(m.id), const LearnerState.empty());
      expect(p.fraction, 0);
      expect(p.completed, isFalse);
    });

    test('la teoría sola no pasa de un tercio', () {
      final StudyModule m = bundle.modules.first;
      final LearnerState state = const LearnerState.empty().copyWith(
        readLessons: m.lessons.map((Lesson l) => l.id).toSet(),
      );
      final ModuleProgress p =
          service.moduleProgress(m, bundle.exercisesOf(m.id), state);
      expect(p.fraction, closeTo(1 / 3, 1e-9));
      expect(p.completed, isFalse);
    });

    test('el laboratorio pesa un tercio entero', () {
      final StudyModule m = bundle.modules.first;
      final LearnerState state = const LearnerState.empty()
          .copyWith(completedLabs: <String>{m.lab.id});
      expect(
        service.moduleProgress(m, bundle.exercisesOf(m.id), state).fraction,
        closeTo(1 / 3, 1e-9),
      );
    });

    test('no se domina un módulo con puntuación por debajo del umbral', () {
      final StudyModule m = bundle.modules.first;
      final List<Exercise> exercises = bundle.exercisesOf(m.id);
      final LearnerState state = const LearnerState.empty().copyWith(
        readLessons: m.lessons.map((Lesson l) => l.id).toSet(),
        completedLabs: <String>{m.lab.id},
        bestScores: <String, double>{
          for (final Exercise e in exercises) e.id: 0.6,
        },
      );
      final ModuleProgress p = service.moduleProgress(m, exercises, state);
      expect(p.fraction, closeTo(1.0, 1e-9));
      expect(p.averageScore, closeTo(0.6, 1e-9));
      // Todo hecho y aun así no dominado: 0,6 es exactamente lo que saca quien
      // acierta siempre la alternativa y falla siempre la justificación.
      expect(p.completed, isFalse);
    });

    test('se domina con todo hecho y puntuación sobre el umbral', () {
      final StudyModule m = bundle.modules.first;
      final List<Exercise> exercises = bundle.exercisesOf(m.id);
      final LearnerState state = const LearnerState.empty().copyWith(
        readLessons: m.lessons.map((Lesson l) => l.id).toSet(),
        completedLabs: <String>{m.lab.id},
        bestScores: <String, double>{
          for (final Exercise e in exercises) e.id: 0.85,
        },
      );
      expect(service.moduleProgress(m, exercises, state).completed, isTrue);
    });
  });

  group('Confusiones', () {
    test('se ordenan por frecuencia y, a igualdad, por recencia', () {
      final LearnerState state =
          const LearnerState.empty().copyWith(attempts: <ExerciseAttempt>[
        _attempt('a', score: 0, choiceOk: false, tags: <String>['media_siempre'], at: 100),
        _attempt('b', score: 0, choiceOk: false, tags: <String>['media_siempre'], at: 200),
        _attempt('c', score: 0, choiceOk: false, tags: <String>['eje_truncado'], at: 900),
        _attempt('d', score: 0, choiceOk: false, tags: <String>['n_vs_n1'], at: 300),
      ]);
      final List<MisconceptionTally> ranking = service.rankMisconceptions(state);
      expect(ranking.first.tag, 'media_siempre');
      expect(ranking.first.count, 2);
      // Empatados a 1: primero el más reciente.
      expect(ranking[1].tag, 'eje_truncado');
    });

    test('sin errores no hay confusiones', () {
      expect(service.rankMisconceptions(const LearnerState.empty()), isEmpty);
    });
  });

  group('Tasa de acierto ciego', () {
    test('cuenta solo los intentos con justificación', () {
      final LearnerState state =
          const LearnerState.empty().copyWith(attempts: <ExerciseAttempt>[
        _attempt('a', score: 0.6, choiceOk: true, justificationOk: false),
        _attempt('b', score: 1.0, choiceOk: true, justificationOk: true),
        _attempt('c', score: 1.0, choiceOk: true), // sin justificación
        _attempt('d', score: 0.0, choiceOk: false, justificationOk: false),
      ]);
      // 1 acierto ciego sobre 3 intentos con justificación.
      expect(service.blindHitRate(state), closeTo(1 / 3, 1e-9));
    });

    test('sin intentos con justificación la tasa es cero', () {
      expect(service.blindHitRate(const LearnerState.empty()), 0);
    });
  });

  group('Competencias', () {
    test('promedia las mejores puntuaciones por competencia', () {
      final List<Exercise> all = bundle.exercises;
      final Exercise first = all.firstWhere(
          (Exercise e) => e.competency == Competency.interpretation);
      final LearnerState state = const LearnerState.empty()
          .copyWith(bestScores: <String, double>{first.id: 0.8});
      final Map<Competency, double> scores =
          service.competencyScores(all, state);
      expect(scores[Competency.interpretation], closeTo(0.8, 1e-9));
      expect(scores.length, 1);
    });
  });

  group('Siguiente acción', () {
    test('propone empezar por la teoría del primer módulo', () {
      final ({String moduleId, String kind, String label})? next =
          service.nextAction(bundle.modules, bundle.exercisesByModule,
              const LearnerState.empty());
      expect(next, isNotNull);
      expect(next!.moduleId, bundle.modules.first.id);
      expect(next.kind, 'lesson');
    });

    test('pasa al laboratorio cuando la teoría está leída', () {
      final StudyModule m = bundle.modules.first;
      final LearnerState state = const LearnerState.empty().copyWith(
        readLessons: m.lessons.map((Lesson l) => l.id).toSet(),
      );
      final ({String moduleId, String kind, String label})? next = service
          .nextAction(bundle.modules, bundle.exercisesByModule, state);
      expect(next!.kind, 'lab');
    });

    test('con el curso entero dominado no queda nada por proponer', () {
      final LearnerState state = const LearnerState.empty().copyWith(
        readLessons: <String>{
          for (final StudyModule m in bundle.modules)
            for (final Lesson l in m.lessons) l.id,
        },
        completedLabs: <String>{
          for (final StudyModule m in bundle.modules) m.lab.id,
        },
        bestScores: <String, double>{
          for (final Exercise e in bundle.exercises) e.id: 1.0,
        },
      );
      expect(
        service.nextAction(bundle.modules, bundle.exercisesByModule, state),
        isNull,
      );
    });
  });
}
