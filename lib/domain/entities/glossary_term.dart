/// Entrada del glosario.
///
/// Cada término lleva dos redacciones: la formal, que el estudiante encontrará
/// en el examen, y la de andar por casa, que es la que hace que entienda. Las
/// dos se muestran juntas a propósito.
class GlossaryTerm {
  const GlossaryTerm({
    required this.id,
    required this.term,
    required this.formalDefinition,
    required this.plainDefinition,
    required this.moduleId,
    required this.related,
    this.formula,
    this.caution,
  });

  final String id;
  final String term;
  final String formalDefinition;
  final String plainDefinition;
  final String moduleId;
  final List<String> related;
  final String? formula;

  /// El error más frecuente asociado a este término.
  final String? caution;

  factory GlossaryTerm.fromJson(Map<String, dynamic> json) => GlossaryTerm(
        id: json['id'] as String,
        term: json['term'] as String,
        formalDefinition: json['formalDefinition'] as String,
        plainDefinition: json['plainDefinition'] as String,
        moduleId: json['moduleId'] as String,
        related: (json['related'] as List<dynamic>? ?? <dynamic>[])
            .map((dynamic e) => e as String)
            .toList(growable: false),
        formula: json['formula'] as String?,
        caution: json['caution'] as String?,
      );
}
