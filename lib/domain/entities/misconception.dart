/// Una confusión conceptual identificada, con su corrección.
///
/// Las etiquetas de [id] son las mismas que aparecen en `tags` de los
/// distractores. Ese acoplamiento es intencional y está verificado por el test
/// de integridad de contenido: si un distractor apunta a una etiqueta que no
/// existe aquí, la suite falla antes de llegar al APK.
class Misconception {
  const Misconception({
    required this.id,
    required this.label,
    required this.whatStudentsThink,
    required this.whyItIsWrong,
    required this.correction,
    required this.moduleId,
    required this.checkYourself,
  });

  final String id;
  final String label;
  final String whatStudentsThink;
  final String whyItIsWrong;
  final String correction;
  final String moduleId;

  /// Una pregunta corta que el estudiante puede hacerse para detectar si está
  /// cayendo otra vez en el mismo error.
  final String checkYourself;

  factory Misconception.fromJson(Map<String, dynamic> json) => Misconception(
        id: json['id'] as String,
        label: json['label'] as String,
        whatStudentsThink: json['whatStudentsThink'] as String,
        whyItIsWrong: json['whyItIsWrong'] as String,
        correction: json['correction'] as String,
        moduleId: json['moduleId'] as String,
        checkYourself: json['checkYourself'] as String,
      );
}
