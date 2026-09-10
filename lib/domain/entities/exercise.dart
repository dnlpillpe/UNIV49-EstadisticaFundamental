import 'measurement.dart';

/// Tipos de ejercicio soportados por el ejecutor.
///
/// Deliberadamente son tres y no diez. El valor educativo lo aporta la
/// *pregunta*, no el mecanismo de respuesta; multiplicar mecanismos habría
/// multiplicado el código de la interfaz sin enseñar nada nuevo.
enum ExerciseType {
  /// Elegir una alternativa. Cubre lectura de gráficos, interpretación y
  /// decisión profesional; el campo [Exercise.visual] cambia lo que se muestra.
  choice,

  /// Introducir un número. Se acepta con tolerancia declarada.
  numeric,

  /// Asignar cada elemento a una categoría (escalas, tipos de variable,
  /// tipo de gráfico adecuado).
  classify;

  static ExerciseType fromKey(String key) {
    switch (key) {
      case 'choice':
        return ExerciseType.choice;
      case 'numeric':
        return ExerciseType.numeric;
      case 'classify':
        return ExerciseType.classify;
      default:
        throw ArgumentError('Tipo de ejercicio desconocido: $key');
    }
  }
}

/// Qué se dibuja junto al enunciado.
enum ExerciseVisual {
  none,
  dataList,
  table,
  histogram,
  bar,
  boxPlot,
  scatter,
  dotPlot,
  line,
  pie,
  comparison;

  static ExerciseVisual fromKey(String? key) {
    switch (key) {
      case null:
      case 'none':
        return ExerciseVisual.none;
      case 'datos':
        return ExerciseVisual.dataList;
      case 'tabla':
        return ExerciseVisual.table;
      case 'histograma':
        return ExerciseVisual.histogram;
      case 'barras':
        return ExerciseVisual.bar;
      case 'caja':
        return ExerciseVisual.boxPlot;
      case 'dispersion':
        return ExerciseVisual.scatter;
      case 'puntos':
        return ExerciseVisual.dotPlot;
      case 'lineas':
        return ExerciseVisual.line;
      case 'circular':
        return ExerciseVisual.pie;
      case 'comparacion':
        return ExerciseVisual.comparison;
      default:
        throw ArgumentError('Visual desconocido: $key');
    }
  }
}

/// Una alternativa de respuesta.
///
/// [tags] es la pieza clave del sistema: cada distractor declara qué confusión
/// conceptual representa. Ese historial —y no el porcentaje de aciertos— es lo
/// que permite al tutor decir "estás confundiendo rango con desviación" en
/// lugar de "te falta estudiar dispersión".
class AnswerOption {
  const AnswerOption({
    required this.id,
    required this.text,
    required this.correct,
    required this.feedback,
    required this.tags,
  });

  final String id;
  final String text;
  final bool correct;
  final String feedback;
  final List<String> tags;

  factory AnswerOption.fromJson(Map<String, dynamic> json) => AnswerOption(
        id: json['id'] as String,
        text: json['text'] as String,
        correct: json['correct'] as bool? ?? false,
        feedback: json['feedback'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
      );
}

/// Respuesta numérica con tolerancia explícita.
class NumericAnswer {
  const NumericAnswer({
    required this.value,
    required this.tolerance,
    required this.unit,
  });

  final double value;

  /// Tolerancia absoluta. Se declara por ejercicio porque redondear a un
  /// decimal es aceptable en minutos y no lo es en una proporción.
  final double tolerance;
  final String unit;

  bool accepts(double answer) => (answer - value).abs() <= tolerance + 1e-9;

  factory NumericAnswer.fromJson(Map<String, dynamic> json) => NumericAnswer(
        value: (json['value'] as num).toDouble(),
        tolerance: (json['tolerance'] as num?)?.toDouble() ?? 0.05,
        unit: json['unit'] as String? ?? '',
      );
}

/// Contenedor de una categoría en un ejercicio de clasificación.
class ClassifyBucket {
  const ClassifyBucket({
    required this.id,
    required this.label,
    required this.description,
  });

  final String id;
  final String label;
  final String description;

  factory ClassifyBucket.fromJson(Map<String, dynamic> json) => ClassifyBucket(
        id: json['id'] as String,
        label: json['label'] as String,
        description: json['description'] as String? ?? '',
      );
}

/// Elemento a clasificar.
class ClassifyItem {
  const ClassifyItem({
    required this.id,
    required this.text,
    required this.bucketId,
    required this.feedback,
    required this.tags,
  });

  final String id;
  final String text;
  final String bucketId;
  final String feedback;
  final List<String> tags;

  factory ClassifyItem.fromJson(Map<String, dynamic> json) => ClassifyItem(
        id: json['id'] as String,
        text: json['text'] as String,
        bucketId: json['bucketId'] as String,
        feedback: json['feedback'] as String? ?? '',
        tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
      );
}

/// Segunda fase de un ejercicio: por qué esa respuesta es la correcta.
class JustificationStep {
  const JustificationStep({required this.prompt, required this.options});

  final String prompt;
  final List<AnswerOption> options;

  factory JustificationStep.fromJson(Map<String, dynamic> json) =>
      JustificationStep(
        prompt: json['prompt'] as String,
        options: (json['options'] as List<dynamic>)
            .map((dynamic e) =>
                AnswerOption.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
}

/// Un ejercicio completo.
class Exercise {
  const Exercise({
    required this.id,
    required this.moduleId,
    required this.type,
    required this.title,
    required this.prompt,
    required this.context,
    required this.visual,
    required this.difficulty,
    required this.competency,
    required this.concepts,
    required this.hint,
    required this.explanation,
    this.datasetId,
    this.secondaryDatasetId,
    this.options = const <AnswerOption>[],
    this.numericAnswer,
    this.buckets = const <ClassifyBucket>[],
    this.items = const <ClassifyItem>[],
    this.justification,
    this.classCount,
  });

  final String id;
  final String moduleId;
  final ExerciseType type;
  final String title;
  final String prompt;
  final String context;
  final ExerciseVisual visual;

  /// 1 = reconocer, 2 = aplicar, 3 = decidir/justificar.
  final int difficulty;
  final Competency competency;
  final List<String> concepts;
  final String hint;
  final String explanation;

  final String? datasetId;

  /// Segundo conjunto, para los ejercicios de comparación (dos grupos con la
  /// misma media y distinta dispersión, por ejemplo).
  final String? secondaryDatasetId;

  final List<AnswerOption> options;
  final NumericAnswer? numericAnswer;
  final List<ClassifyBucket> buckets;
  final List<ClassifyItem> items;
  final JustificationStep? justification;

  /// Número de clases a usar si el visual es una tabla o un histograma.
  final int? classCount;

  bool get hasJustification => justification != null;

  AnswerOption? get correctOption {
    for (final AnswerOption o in options) {
      if (o.correct) return o;
    }
    return null;
  }

  factory Exercise.fromJson(Map<String, dynamic> json) => Exercise(
        id: json['id'] as String,
        moduleId: json['moduleId'] as String,
        type: ExerciseType.fromKey(json['type'] as String),
        title: json['title'] as String,
        prompt: json['prompt'] as String,
        context: json['context'] as String? ?? '',
        visual: ExerciseVisual.fromKey(json['visual'] as String?),
        difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
        competency: Competency.fromKey(json['competency'] as String),
        concepts: (json['concepts'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
        hint: json['hint'] as String? ?? '',
        explanation: json['explanation'] as String? ?? '',
        datasetId: json['datasetId'] as String?,
        secondaryDatasetId: json['secondaryDatasetId'] as String?,
        options: (json['options'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                AnswerOption.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        numericAnswer: json['answer'] == null
            ? null
            : NumericAnswer.fromJson(json['answer'] as Map<String, dynamic>),
        buckets: (json['buckets'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                ClassifyBucket.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        items: (json['items'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) =>
                ClassifyItem.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        justification: json['justification'] == null
            ? null
            : JustificationStep.fromJson(
                json['justification'] as Map<String, dynamic>),
        classCount: (json['classCount'] as num?)?.toInt(),
      );
}
