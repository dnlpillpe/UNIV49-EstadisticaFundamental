import 'measurement.dart';

/// Tipo de tarjeta dentro de una lección. Determina el tratamiento visual.
enum CardKind {
  concept,
  warning,
  example,
  formula,
  insight;

  static CardKind fromKey(String key) {
    switch (key) {
      case 'concepto':
        return CardKind.concept;
      case 'aviso':
        return CardKind.warning;
      case 'ejemplo':
        return CardKind.example;
      case 'formula':
        return CardKind.formula;
      case 'clave':
        return CardKind.insight;
      default:
        throw ArgumentError('Tipo de tarjeta desconocido: $key');
    }
  }
}

/// Una tarjeta conceptual. Unidad mínima de teoría de la app.
class ConceptCard {
  const ConceptCard({
    required this.heading,
    required this.body,
    required this.kind,
    this.formula,
    this.caption,
  });

  final String heading;
  final String body;
  final CardKind kind;

  /// Notación en texto plano (no LaTeX: renderizar LaTeX exigiría una
  /// dependencia pesada para ganar poco en fórmulas de este nivel).
  final String? formula;
  final String? caption;

  factory ConceptCard.fromJson(Map<String, dynamic> json) => ConceptCard(
        heading: json['heading'] as String,
        body: json['body'] as String,
        kind: CardKind.fromKey(json['kind'] as String),
        formula: json['formula'] as String?,
        caption: json['caption'] as String?,
      );
}

/// Una lección: un puñado de tarjetas y una idea que retener.
class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.intro,
    required this.cards,
    required this.keyIdea,
    required this.readingMinutes,
  });

  final String id;
  final String title;
  final String intro;
  final List<ConceptCard> cards;

  /// La frase que el estudiante debería poder repetir una semana después.
  final String keyIdea;
  final int readingMinutes;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
        id: json['id'] as String,
        title: json['title'] as String,
        intro: json['intro'] as String,
        cards: (json['cards'] as List<dynamic>)
            .map((dynamic e) => ConceptCard.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        keyIdea: json['keyIdea'] as String,
        readingMinutes: (json['readingMinutes'] as num?)?.toInt() ?? 3,
      );
}

/// Los laboratorios interactivos disponibles. Cada valor corresponde a una
/// pantalla concreta: no son datos configurables, son código.
enum LabKind {
  variableClassifier,
  frequencyBuilder,
  outlierSandbox,
  dispersionComparator,
  misleadingChart;

  static LabKind fromKey(String key) {
    switch (key) {
      case 'clasificador_variables':
        return LabKind.variableClassifier;
      case 'constructor_frecuencias':
        return LabKind.frequencyBuilder;
      case 'sandbox_atipicos':
        return LabKind.outlierSandbox;
      case 'comparador_dispersion':
        return LabKind.dispersionComparator;
      case 'grafico_enganoso':
        return LabKind.misleadingChart;
      default:
        throw ArgumentError('Laboratorio desconocido: $key');
    }
  }
}

/// Descripción editorial de un laboratorio.
class LabInfo {
  const LabInfo({
    required this.id,
    required this.kind,
    required this.title,
    required this.subtitle,
    required this.goal,
    required this.steps,
    required this.datasetIds,
  });

  final String id;
  final LabKind kind;
  final String title;
  final String subtitle;

  /// Qué debe descubrir el estudiante. Se muestra *después* de experimentar,
  /// no antes: adelantar la conclusión anula el laboratorio.
  final String goal;
  final List<String> steps;
  final List<String> datasetIds;

  factory LabInfo.fromJson(Map<String, dynamic> json) => LabInfo(
        id: json['id'] as String,
        kind: LabKind.fromKey(json['kind'] as String),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        goal: json['goal'] as String,
        steps: (json['steps'] as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList(growable: false),
        datasetIds: (json['datasetIds'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
      );
}

/// Un módulo del curso.
class StudyModule {
  const StudyModule({
    required this.id,
    required this.order,
    required this.title,
    required this.subtitle,
    required this.colorKey,
    required this.iconKey,
    required this.problem,
    required this.goal,
    required this.bigIdea,
    required this.competencies,
    required this.lessons,
    required this.lab,
  });

  final String id;
  final int order;
  final String title;
  final String subtitle;

  /// Clave de color del módulo; se resuelve en la capa de presentación.
  final String colorKey;
  final String iconKey;

  /// El error real que este módulo intenta corregir.
  final String problem;
  final String goal;
  final String bigIdea;
  final List<Competency> competencies;
  final List<Lesson> lessons;
  final LabInfo lab;

  int get totalReadingMinutes =>
      lessons.fold<int>(0, (int a, Lesson l) => a + l.readingMinutes);

  factory StudyModule.fromJson(Map<String, dynamic> json) => StudyModule(
        id: json['id'] as String,
        order: (json['order'] as num).toInt(),
        title: json['title'] as String,
        subtitle: json['subtitle'] as String,
        colorKey: json['colorKey'] as String,
        iconKey: json['iconKey'] as String,
        problem: json['problem'] as String,
        goal: json['goal'] as String,
        bigIdea: json['bigIdea'] as String,
        competencies: (json['competencies'] as List<dynamic>)
            .map((dynamic e) => Competency.fromKey(e as String))
            .toList(growable: false),
        lessons: (json['lessons'] as List<dynamic>)
            .map((dynamic e) => Lesson.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
        lab: LabInfo.fromJson(json['lab'] as Map<String, dynamic>),
      );
}
