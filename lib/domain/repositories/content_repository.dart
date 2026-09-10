import '../entities/dataset.dart';
import '../entities/exercise.dart';
import '../entities/glossary_term.dart';
import '../entities/misconception.dart';
import '../entities/study_module.dart';
import '../entities/tutor.dart';

/// Todo el contenido educativo de la app.
///
/// Se carga una sola vez y se mantiene en memoria: son unos cientos de kB de
/// JSON y la alternativa (consultar en cada pantalla) añadiría asincronía a
/// toda la interfaz sin ahorrar nada relevante.
class ContentBundle {
  const ContentBundle({
    required this.modules,
    required this.datasets,
    required this.exercises,
    required this.glossary,
    required this.misconceptions,
    required this.tutorTopics,
  });

  final List<StudyModule> modules;
  final List<Dataset> datasets;
  final List<Exercise> exercises;
  final List<GlossaryTerm> glossary;
  final List<Misconception> misconceptions;
  final List<TutorTopic> tutorTopics;

  Dataset dataset(String id) => datasets.firstWhere(
        (Dataset d) => d.id == id,
        orElse: () => throw StateError('Conjunto de datos no encontrado: $id'),
      );

  Dataset? datasetOrNull(String? id) {
    if (id == null) return null;
    for (final Dataset d in datasets) {
      if (d.id == id) return d;
    }
    return null;
  }

  StudyModule module(String id) => modules.firstWhere(
        (StudyModule m) => m.id == id,
        orElse: () => throw StateError('Módulo no encontrado: $id'),
      );

  List<Exercise> exercisesOf(String moduleId) => exercises
      .where((Exercise e) => e.moduleId == moduleId)
      .toList(growable: false);

  Map<String, List<Exercise>> get exercisesByModule {
    final Map<String, List<Exercise>> map = <String, List<Exercise>>{};
    for (final Exercise e in exercises) {
      map.putIfAbsent(e.moduleId, () => <Exercise>[]).add(e);
    }
    return map;
  }

  Exercise exercise(String id) => exercises.firstWhere(
        (Exercise e) => e.id == id,
        orElse: () => throw StateError('Ejercicio no encontrado: $id'),
      );
}

abstract class ContentRepository {
  Future<ContentBundle> load();
}
