import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import '../../domain/entities/dataset.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/glossary_term.dart';
import '../../domain/entities/misconception.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/entities/tutor.dart';
import '../../domain/repositories/content_repository.dart';

/// Carga el contenido desde `assets/data/`.
///
/// El contenido va empaquetado en el APK y no se descarga: la app funciona
/// entera sin conexión, que es la condición real de uso en muchas aulas. El
/// coste es que actualizar contenido exige publicar versión; a cambio no hay
/// backend, ni servidor caído, ni estudiante bloqueado por falta de datos.
class AssetContentRepository implements ContentRepository {
  const AssetContentRepository();

  static const String _base = 'assets/data';

  @override
  Future<ContentBundle> load() async {
    final List<dynamic> modulesJson = await _loadList('modules.json');
    final List<dynamic> datasetsJson = await _loadList('datasets.json');
    final List<dynamic> exercisesJson = await _loadList('exercises.json');
    final List<dynamic> glossaryJson = await _loadList('glossary.json');
    final List<dynamic> misconceptionsJson =
        await _loadList('misconceptions.json');
    final List<dynamic> tutorJson = await _loadList('tutor_corpus.json');

    final List<StudyModule> modules = modulesJson
        .map((dynamic e) => StudyModule.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((StudyModule a, StudyModule b) => a.order.compareTo(b.order));

    return ContentBundle(
      modules: modules,
      datasets: datasetsJson
          .map((dynamic e) => Dataset.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      exercises: exercisesJson
          .map((dynamic e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      glossary: glossaryJson
          .map((dynamic e) => GlossaryTerm.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      misconceptions: misconceptionsJson
          .map((dynamic e) => Misconception.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      tutorTopics: tutorJson
          .map((dynamic e) => TutorTopic.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Future<List<dynamic>> _loadList(String fileName) async {
    final String raw = await rootBundle.loadString('$_base/$fileName');
    return jsonDecode(raw) as List<dynamic>;
  }
}
