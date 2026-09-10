import '../../domain/entities/tutor.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../../domain/services/tutor_engine.dart';

/// Adaptador preparado —y desactivado— para un tutor con modelo de lenguaje.
///
/// Activarlo es sustituir una línea en `app_providers.dart`. Que no esté
/// activado no es una carencia: es la conclusión del análisis de IA. Antes de
/// encenderlo deben cumplirse cuatro condiciones, y ninguna es negociable:
///
/// 1. **Anclaje al corpus.** El modelo responde *con* los temas del corpus
///    como contexto, no de memoria. Si la pregunta no está cubierta, degrada al
///    motor local en lugar de improvisar.
/// 2. **Un único origen para los números.** El modelo nunca calcula. Cualquier
///    cifra que aparezca en una respuesta sale de `StatisticsService`. Dos
///    fuentes de cálculo discrepando es la forma más rápida de perder la
///    confianza del estudiante.
/// 3. **Guardarraíl de causalidad.** Filtro previo que impide afirmar que una
///    variable causa otra a partir de una correlación. Es el error que la app
///    enseña a evitar; sería absurdo que el tutor lo cometiera.
/// 4. **Degradación garantizada.** Sin red, con error o con tiempo agotado, se
///    responde con el motor local. La app no depende de conexión.
///
/// Además: sin datos personales del estudiante en la petición, y evaluación
/// previa sobre 100 consultas reales de aula antes de publicar.
class RemoteTutorRepository implements TutorRepository {
  const RemoteTutorRepository({
    required TutorEngine fallbackEngine,
    required this.endpoint,
    this.timeout = const Duration(seconds: 8),
  }) : _fallback = fallbackEngine;

  final TutorEngine _fallback;
  final String endpoint;
  final Duration timeout;

  @override
  Future<TutorAnswer> ask(String query) async {
    // Sin implementación de red por decisión de producto (ver arriba).
    // El contrato se respeta degradando al motor local, que es exactamente el
    // comportamiento esperado ante cualquier fallo remoto.
    return _fallback.ask(query);
  }
}
