/// Una entrada del corpus del tutor: una pregunta que el estudiante hace de
/// verdad, con su respuesta revisada.
class TutorTopic {
  const TutorTopic({
    required this.id,
    required this.title,
    required this.answer,
    required this.keywords,
    required this.moduleId,
    required this.concepts,
    required this.followUps,
    this.example,
  });

  final String id;
  final String title;
  final String answer;

  /// Palabras y giros con los que un estudiante formularía esta duda. Se
  /// normalizan (sin tildes, en minúsculas) antes de comparar.
  final List<String> keywords;
  final String moduleId;
  final List<String> concepts;

  /// Preguntas sugeridas después de responder. Mantienen la conversación
  /// dentro del corpus, que es donde el tutor es fiable.
  final List<String> followUps;
  final String? example;

  factory TutorTopic.fromJson(Map<String, dynamic> json) => TutorTopic(
        id: json['id'] as String,
        title: json['title'] as String,
        answer: json['answer'] as String,
        keywords: (json['keywords'] as List<dynamic>)
            .map((dynamic e) => e as String)
            .toList(growable: false),
        moduleId: json['moduleId'] as String? ?? '',
        concepts: (json['concepts'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
        followUps: (json['followUps'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
        example: json['example'] as String?,
      );
}

enum TutorRole { student, tutor }

/// Un mensaje de la conversación con el tutor.
class TutorMessage {
  const TutorMessage({
    required this.role,
    required this.text,
    this.topicId,
    this.suggestions = const <String>[],
    this.isFallback = false,
    this.example,
  });

  final TutorRole role;
  final String text;
  final String? topicId;
  final List<String> suggestions;

  /// `true` cuando el tutor no encontró nada en el corpus y lo está diciendo.
  /// Es un estado de primera clase, no un error: el tutor que inventa es peor
  /// que el tutor que admite su límite.
  final bool isFallback;
  final String? example;
}

/// Resultado de una consulta al motor del tutor.
class TutorAnswer {
  const TutorAnswer({
    required this.text,
    required this.suggestions,
    required this.isFallback,
    this.topicId,
    this.example,
  });

  final String text;
  final List<String> suggestions;
  final bool isFallback;
  final String? topicId;
  final String? example;
}
