import '../entities/tutor.dart';

/// Contrato del tutor.
///
/// Existe como interfaz —y no como llamada directa a `TutorEngine`— porque el
/// día que se active un modelo remoto, la interfaz de usuario no debe cambiar
/// ni una línea. Ver `RemoteTutorRepository` para las condiciones bajo las
/// cuales ese cambio sería aceptable.
abstract class TutorRepository {
  Future<TutorAnswer> ask(String query);
}
