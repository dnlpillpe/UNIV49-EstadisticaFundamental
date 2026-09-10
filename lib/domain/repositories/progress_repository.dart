import '../entities/progress.dart';

abstract class ProgressRepository {
  Future<LearnerState> load();
  Future<void> save(LearnerState state);
  Future<void> reset();
}
