import 'dart:convert';
import 'dart:io';

import 'package:estadistica_fundamental/domain/entities/dataset.dart';
import 'package:estadistica_fundamental/domain/entities/exercise.dart';
import 'package:estadistica_fundamental/domain/entities/glossary_term.dart';
import 'package:estadistica_fundamental/domain/entities/misconception.dart';
import 'package:estadistica_fundamental/domain/entities/study_module.dart';
import 'package:estadistica_fundamental/domain/entities/tutor.dart';
import 'package:estadistica_fundamental/domain/repositories/content_repository.dart';

/// Carga el contenido desde el sistema de archivos en lugar del bundle.
///
/// Permite que las pruebas del contenido corran como tests de Dart puro, sin
/// arrancar el binding de Flutter. Es lo que hace que el test de integridad sea
/// rápido y utilizable como puerta de CI.
class FileContentRepository implements ContentRepository {
  const FileContentRepository([this.base = 'assets/data']);

  final String base;

  @override
  Future<ContentBundle> load() async {
    final List<StudyModule> modules = (await _list('modules.json'))
        .map((dynamic e) => StudyModule.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((StudyModule a, StudyModule b) => a.order.compareTo(b.order));

    return ContentBundle(
      modules: modules,
      datasets: (await _list('datasets.json'))
          .map((dynamic e) => Dataset.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      exercises: (await _list('exercises.json'))
          .map((dynamic e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      glossary: (await _list('glossary.json'))
          .map((dynamic e) => GlossaryTerm.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      misconceptions: (await _list('misconceptions.json'))
          .map((dynamic e) => Misconception.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      tutorTopics: (await _list('tutor_corpus.json'))
          .map((dynamic e) => TutorTopic.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
    );
  }

  Future<List<dynamic>> _list(String name) async {
    final String raw = await File('$base/$name').readAsString();
    return jsonDecode(raw) as List<dynamic>;
  }
}
