import 'package:estadistica_fundamental/domain/entities/exercise.dart';
import 'package:estadistica_fundamental/domain/entities/measurement.dart';
import 'package:estadistica_fundamental/domain/services/grading_service.dart';
import 'package:flutter_test/flutter_test.dart';

Exercise _choiceExercise({bool withJustification = true}) => Exercise(
      id: 'x1',
      moduleId: 'm3',
      type: ExerciseType.choice,
      title: 'Prueba',
      prompt: '¿Qué medida usarías?',
      context: '',
      visual: ExerciseVisual.none,
      difficulty: 2,
      competency: Competency.interpretation,
      concepts: const <String>['media'],
      hint: '',
      explanation: 'Explicación.',
      options: const <AnswerOption>[
        AnswerOption(
            id: 'a',
            text: 'La media',
            correct: false,
            feedback: 'No.',
            tags: <String>['media_siempre']),
        AnswerOption(
            id: 'b',
            text: 'La mediana',
            correct: true,
            feedback: 'Sí.',
            tags: <String>[]),
      ],
      justification: withJustification
          ? const JustificationStep(
              prompt: '¿Por qué?',
              options: <AnswerOption>[
                AnswerOption(
                    id: 'j1',
                    text: 'Porque hay asimetría',
                    correct: true,
                    feedback: 'Exacto.',
                    tags: <String>[]),
                AnswerOption(
                    id: 'j2',
                    text: 'Porque siempre es mejor',
                    correct: false,
                    feedback: 'No siempre.',
                    tags: <String>['media_vs_mediana']),
              ],
            )
          : null,
    );

void main() {
  const GradingService grading = GradingService();

  group('Regla 60/40', () {
    test('elección y justificación correctas dan la puntuación máxima', () {
      final GradedAttempt g = grading.gradeChoice(_choiceExercise(),
          selectedOptionId: 'b', justificationOptionId: 'j1');
      expect(g.score, closeTo(1.0, 1e-9));
      expect(g.perfect, isTrue);
      expect(g.errorTags, isEmpty);
    });

    test('acertar la alternativa y fallar el porqué se queda en 0,6', () {
      // Es el caso que da sentido a toda la regla: el «acierto ciego».
      final GradedAttempt g = grading.gradeChoice(_choiceExercise(),
          selectedOptionId: 'b', justificationOptionId: 'j2');
      expect(g.score, closeTo(0.6, 1e-9));
      expect(g.choiceCorrect, isTrue);
      expect(g.justificationCorrect, isFalse);
      expect(g.errorTags, contains('media_vs_mediana'));
    });

    test('fallar la alternativa y acertar el porqué da 0,4', () {
      final GradedAttempt g = grading.gradeChoice(_choiceExercise(),
          selectedOptionId: 'a', justificationOptionId: 'j1');
      expect(g.score, closeTo(0.4, 1e-9));
      expect(g.errorTags, contains('media_siempre'));
    });

    test('fallar las dos deja la puntuación en cero y acumula dos etiquetas',
        () {
      final GradedAttempt g = grading.gradeChoice(_choiceExercise(),
          selectedOptionId: 'a', justificationOptionId: 'j2');
      expect(g.score, 0);
      expect(g.errorTags.length, 2);
    });

    test('sin justificación el ejercicio vale todo o nada', () {
      final Exercise e = _choiceExercise(withJustification: false);
      expect(grading.gradeChoice(e, selectedOptionId: 'b').score, 1.0);
      expect(grading.gradeChoice(e, selectedOptionId: 'a').score, 0.0);
      expect(grading.gradeChoice(e, selectedOptionId: 'b').justificationCorrect,
          isNull);
    });

    test('fase intermedia: elegida la alternativa, aún sin justificar', () {
      final GradedAttempt g =
          grading.gradeChoice(_choiceExercise(), selectedOptionId: 'b');
      expect(g.score, closeTo(0.6, 1e-9));
      expect(g.justificationCorrect, isNull);
    });

    test('una alternativa inexistente es un error de programación', () {
      expect(
        () => grading.gradeChoice(_choiceExercise(), selectedOptionId: 'zzz'),
        throwsArgumentError,
      );
    });
  });

  group('Respuestas numéricas', () {
    final Exercise e = Exercise(
      id: 'n1',
      moduleId: 'm4',
      type: ExerciseType.numeric,
      title: 'Rango',
      prompt: '¿Cuál es el rango?',
      context: '',
      visual: ExerciseVisual.none,
      difficulty: 1,
      competency: Competency.descriptiveAnalysis,
      concepts: const <String>['rango'],
      hint: '',
      explanation: '150 − 12 = 138.',
      numericAnswer:
          const NumericAnswer(value: 138, tolerance: 0.5, unit: 'minutos'),
    );

    test('acepta dentro de la tolerancia declarada', () {
      expect(grading.gradeNumeric(e, answer: 138).score, 1.0);
      expect(grading.gradeNumeric(e, answer: 137.6).score, 1.0);
      expect(grading.gradeNumeric(e, answer: 138.5).score, 1.0);
    });

    test('rechaza fuera de la tolerancia', () {
      expect(grading.gradeNumeric(e, answer: 139).score, 0.0);
      expect(grading.gradeNumeric(e, answer: 0).score, 0.0);
    });

    test('el mensaje de error indica el valor esperado', () {
      expect(grading.gradeNumeric(e, answer: 100).choiceFeedback,
          contains('138'));
    });
  });

  group('Clasificación', () {
    final Exercise e = Exercise(
      id: 'c1',
      moduleId: 'm1',
      type: ExerciseType.classify,
      title: 'Escalas',
      prompt: 'Clasifica',
      context: '',
      visual: ExerciseVisual.none,
      difficulty: 2,
      competency: Competency.descriptiveAnalysis,
      concepts: const <String>['escala'],
      hint: '',
      explanation: '...',
      buckets: const <ClassifyBucket>[
        ClassifyBucket(id: 'nom', label: 'Nominal', description: ''),
        ClassifyBucket(id: 'raz', label: 'Razón', description: ''),
      ],
      items: const <ClassifyItem>[
        ClassifyItem(
            id: 'i1',
            text: 'DNI',
            bucketId: 'nom',
            feedback: 'Es una etiqueta.',
            tags: <String>['escala_numerica']),
        ClassifyItem(
            id: 'i2',
            text: 'Minutos',
            bucketId: 'raz',
            feedback: '',
            tags: <String>[]),
        ClassifyItem(
            id: 'i3',
            text: 'Soles',
            bucketId: 'raz',
            feedback: '',
            tags: <String>[]),
        ClassifyItem(
            id: 'i4',
            text: 'Carrera',
            bucketId: 'nom',
            feedback: '',
            tags: <String>[]),
      ],
    );

    test('la puntuación es proporcional a los aciertos, no todo o nada', () {
      final GradedAttempt g = grading.gradeClassify(e, assignment: <String, String>{
        'i1': 'nom',
        'i2': 'raz',
        'i3': 'raz',
        'i4': 'raz',
      });
      expect(g.score, closeTo(0.75, 1e-9));
      expect(g.choiceCorrect, isFalse);
      expect(g.detail['i4'], isFalse);
    });

    test('todo correcto da 1 y ninguna etiqueta de error', () {
      final GradedAttempt g = grading.gradeClassify(e, assignment: <String, String>{
        'i1': 'nom',
        'i2': 'raz',
        'i3': 'raz',
        'i4': 'nom',
      });
      expect(g.score, 1.0);
      expect(g.errorTags, isEmpty);
    });

    test('el elemento mal clasificado aporta su etiqueta conceptual', () {
      final GradedAttempt g = grading.gradeClassify(e, assignment: <String, String>{
        'i1': 'raz',
        'i2': 'raz',
        'i3': 'raz',
        'i4': 'nom',
      });
      expect(g.errorTags, contains('escala_numerica'));
      expect(g.choiceFeedback, contains('Es una etiqueta.'));
    });
  });
}
