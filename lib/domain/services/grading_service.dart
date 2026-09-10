import '../entities/exercise.dart';

/// Resultado de corregir un intento.
class GradedAttempt {
  const GradedAttempt({
    required this.score,
    required this.choiceCorrect,
    required this.justificationCorrect,
    required this.errorTags,
    required this.choiceFeedback,
    required this.justificationFeedback,
    required this.detail,
  });

  /// 0..1
  final double score;
  final bool choiceCorrect;
  final bool? justificationCorrect;
  final List<String> errorTags;
  final String choiceFeedback;
  final String justificationFeedback;

  /// Detalle por elemento para los ejercicios de clasificación.
  final Map<String, bool> detail;

  bool get perfect => score >= 0.999;
}

/// Corrección de ejercicios.
///
/// **Regla 60/40.** Cuando un ejercicio pide justificación, la elección vale
/// 0,6 y el porqué vale 0,4. El motivo es el problema que la app ataca: en
/// estadística descriptiva se puede acertar la alternativa correcta por
/// eliminación o por costumbre ("ante la duda, la mediana") sin entender nada.
/// Separar la puntuación hace visible ese acierto vacío, tanto para el
/// estudiante como para el tutor.
class GradingService {
  const GradingService();

  static const double choiceWeight = 0.6;
  static const double justificationWeight = 0.4;

  GradedAttempt gradeChoice(
    Exercise exercise, {
    required String selectedOptionId,
    String? justificationOptionId,
  }) {
    final AnswerOption selected = exercise.options.firstWhere(
      (AnswerOption o) => o.id == selectedOptionId,
      orElse: () => throw ArgumentError(
          'Alternativa $selectedOptionId no existe en ${exercise.id}'),
    );

    final List<String> tags = <String>[];
    if (!selected.correct) tags.addAll(selected.tags);

    if (!exercise.hasJustification) {
      return GradedAttempt(
        score: selected.correct ? 1 : 0,
        choiceCorrect: selected.correct,
        justificationCorrect: null,
        errorTags: tags,
        choiceFeedback: selected.feedback,
        justificationFeedback: '',
        detail: const <String, bool>{},
      );
    }

    if (justificationOptionId == null) {
      // Fase intermedia: se eligió alternativa pero aún no el porqué.
      return GradedAttempt(
        score: selected.correct ? choiceWeight : 0,
        choiceCorrect: selected.correct,
        justificationCorrect: null,
        errorTags: tags,
        choiceFeedback: selected.feedback,
        justificationFeedback: '',
        detail: const <String, bool>{},
      );
    }

    final AnswerOption reason = exercise.justification!.options.firstWhere(
      (AnswerOption o) => o.id == justificationOptionId,
      orElse: () => throw ArgumentError(
          'Justificación $justificationOptionId no existe en ${exercise.id}'),
    );
    if (!reason.correct) tags.addAll(reason.tags);

    final double score = (selected.correct ? choiceWeight : 0) +
        (reason.correct ? justificationWeight : 0);

    return GradedAttempt(
      score: score,
      choiceCorrect: selected.correct,
      justificationCorrect: reason.correct,
      errorTags: tags,
      choiceFeedback: selected.feedback,
      justificationFeedback: reason.feedback,
      detail: const <String, bool>{},
    );
  }

  GradedAttempt gradeNumeric(Exercise exercise, {required double answer}) {
    final NumericAnswer expected = exercise.numericAnswer!;
    final bool ok = expected.accepts(answer);
    return GradedAttempt(
      score: ok ? 1 : 0,
      choiceCorrect: ok,
      justificationCorrect: null,
      errorTags: ok ? const <String>[] : exercise.concepts,
      choiceFeedback: ok
          ? 'Correcto.'
          : 'El valor esperado es ${_trim(expected.value)}'
              '${expected.unit.isEmpty ? '' : ' ${expected.unit}'} '
              '(tolerancia ±${_trim(expected.tolerance)}).',
      justificationFeedback: '',
      detail: const <String, bool>{},
    );
  }

  /// Clasificación: puntuación proporcional a los elementos bien ubicados.
  /// No es todo o nada porque colocar 7 de 8 escalas correctamente no es el
  /// mismo estado de conocimiento que colocar 2 de 8.
  GradedAttempt gradeClassify(
    Exercise exercise, {
    required Map<String, String> assignment,
  }) {
    final Map<String, bool> detail = <String, bool>{};
    final List<String> tags = <String>[];
    int correct = 0;
    final StringBuffer feedback = StringBuffer();

    for (final ClassifyItem item in exercise.items) {
      final String? given = assignment[item.id];
      final bool ok = given == item.bucketId;
      detail[item.id] = ok;
      if (ok) {
        correct++;
      } else {
        tags.addAll(item.tags);
        if (item.feedback.isNotEmpty) {
          feedback.writeln('• ${item.text}: ${item.feedback}');
        }
      }
    }

    final int total = exercise.items.length;
    final double score = total == 0 ? 0 : correct / total;

    return GradedAttempt(
      score: score,
      choiceCorrect: correct == total,
      justificationCorrect: null,
      errorTags: tags,
      choiceFeedback: correct == total
          ? 'Los $total elementos están bien clasificados.'
          : '$correct de $total correctos.\n${feedback.toString().trim()}',
      justificationFeedback: '',
      detail: detail,
    );
  }

  String _trim(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(2);
  }
}
