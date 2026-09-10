import '../../domain/entities/tutor.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../../domain/services/tutor_engine.dart';

/// Implementación activa del tutor: motor determinista sobre corpus curado.
class LocalTutorRepository implements TutorRepository {
  const LocalTutorRepository(this._engine);

  final TutorEngine _engine;

  @override
  Future<TutorAnswer> ask(String query) async => _engine.ask(query);
}
