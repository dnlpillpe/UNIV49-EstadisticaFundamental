import 'package:flutter/material.dart';

import '../../presentation/screens/about_screen.dart';
import '../../presentation/screens/data_lab_screen.dart';
import '../../presentation/screens/exercise_list_screen.dart';
import '../../presentation/screens/exercise_screen.dart';
import '../../presentation/screens/glossary_screen.dart';
import '../../presentation/screens/home_shell.dart';
import '../../presentation/screens/lab_screen.dart';
import '../../presentation/screens/lesson_screen.dart';
import '../../presentation/screens/module_screen.dart';

/// Enrutado con `Navigator` y rutas nombradas.
///
/// No se usa `go_router`. Esta app tiene ocho destinos, ninguno con enlaces
/// profundos ni con URL que un usuario vaya a compartir. Añadir un router
/// declarativo habría sido una dependencia más —con su propio historial de
/// cambios entre versiones mayores— para resolver un problema que aquí no
/// existe.
class AppRouter {
  const AppRouter._();

  static const String home = '/';
  static const String module = '/modulo';
  static const String lesson = '/leccion';
  static const String exercises = '/ejercicios';
  static const String exercise = '/ejercicio';
  static const String lab = '/laboratorio';
  static const String dataLab = '/datos';
  static const String glossary = '/glosario';
  static const String about = '/acerca';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case home:
        return _page(const HomeShell(), settings);
      case module:
        return _page(
            ModuleScreen(moduleId: settings.arguments! as String), settings);
      case lesson:
        final LessonArgs args = settings.arguments! as LessonArgs;
        return _page(
            LessonScreen(moduleId: args.moduleId, lessonId: args.lessonId),
            settings);
      case exercises:
        return _page(
            ExerciseListScreen(moduleId: settings.arguments! as String),
            settings);
      case exercise:
        final ExerciseArgs args = settings.arguments! as ExerciseArgs;
        return _page(ExerciseScreen(exerciseId: args.exerciseId), settings);
      case lab:
        return _page(LabScreen(moduleId: settings.arguments! as String), settings);
      case dataLab:
        return _page(
            DataLabScreen(initialDatasetId: settings.arguments as String?),
            settings);
      case glossary:
        return _page(const GlossaryScreen(), settings);
      case about:
        return _page(const AboutScreen(), settings);
      default:
        return _page(const HomeShell(), settings);
    }
  }

  static Route<dynamic> _page(Widget child, RouteSettings settings) =>
      MaterialPageRoute<dynamic>(builder: (_) => child, settings: settings);
}

class LessonArgs {
  const LessonArgs({required this.moduleId, required this.lessonId});

  final String moduleId;
  final String lessonId;
}

class ExerciseArgs {
  const ExerciseArgs({required this.exerciseId});

  final String exerciseId;
}
