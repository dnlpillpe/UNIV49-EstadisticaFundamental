import '../entities/misconception.dart';
import '../entities/progress.dart';
import '../entities/tutor.dart';

/// Motor determinista del tutor estadístico.
///
/// **Por qué no un LLM en el MVP.** La personalización que importa aquí no es
/// de redacción sino de contenido: qué confusión concreta tiene *este*
/// estudiante. Eso lo produce el historial de etiquetas de error, no un modelo
/// generativo. A cambio, un modelo generativo introduce tres riesgos que en
/// estadística son caros: inventar una fórmula, afirmar causalidad a partir de
/// una correlación, y dar un número distinto al del motor de cálculo de la
/// propia app. El corpus curado no tiene ninguno de los tres.
///
/// El límite del motor es explícito: cuando la consulta no supera el umbral de
/// coincidencia, lo dice y ofrece los temas que sí conoce. Un tutor que
/// responde siempre es un tutor en el que no se puede confiar nunca.
class TutorEngine {
  const TutorEngine({
    required this.topics,
    required this.misconceptions,
  });

  final List<TutorTopic> topics;
  final List<Misconception> misconceptions;

  /// Coincidencia mínima para dar una respuesta del corpus.
  static const double matchThreshold = 0.34;

  /// Palabras sin valor discriminante en español. Se descartan antes de puntuar
  /// para que "qué es la media" no coincida con "qué es la moda" por el "qué".
  static const Set<String> _stopWords = <String>{
    'que', 'de', 'la', 'el', 'los', 'las', 'un', 'una', 'unos', 'unas', 'y',
    'o', 'en', 'con', 'por', 'para', 'del', 'al', 'se', 'es', 'son', 'como',
    'cual', 'cuales', 'cuando', 'donde', 'mi', 'me', 'te', 'lo', 'su', 'sus',
    'este', 'esta', 'esto', 'ese', 'esa', 'eso', 'hay', 'ser', 'estar', 'tiene',
    'tengo', 'puedo', 'porque', 'sobre', 'entre', 'mas', 'pero', 'si', 'no',
    'a', 'e', 'u', 'yo', 'tu', 'ella', 'usted', 'dime', 'explicame',
    'explica', 'ayuda', 'ayudame', 'saber', 'quiero', 'necesito', 'sirve',
  };

  /// Normaliza: minúsculas, sin tildes, sin signos.
  ///
  /// Los subíndices y superíndices se convierten a su carácter base. Sin esa
  /// conversión, una consulta como «diferencia entre fᵢ y Fᵢ» perdería
  /// justamente los dos símbolos que la identifican.
  static String normalize(String input) {
    const Map<String, String> accents = <String, String>{
      'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
      'Á': 'a', 'É': 'e', 'Í': 'i', 'Ó': 'o', 'Ú': 'u', 'Ü': 'u', 'Ñ': 'n',
      'ᵢ': 'i', 'ₛ': 's', 'ₚ': 'p', 'ⱼ': 'j',
      '₀': '0', '₁': '1', '₂': '2', '₃': '3', '₄': '4',
      '⁰': '0', '¹': '1', '²': '2', '³': '3',
    };
    final StringBuffer buffer = StringBuffer();
    for (final int rune in input.toLowerCase().runes) {
      final String ch = String.fromCharCode(rune);
      buffer.write(accents[ch] ?? ch);
    }
    return buffer
        .toString()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static List<String> tokenize(String input) => normalize(input)
      .split(' ')
      .where((String w) => w.length > 2 && !_stopWords.contains(w))
      .toList(growable: false);

  /// Responde a una consulta libre.
  TutorAnswer ask(String query) {
    final String normalized = normalize(query);
    if (normalized.isEmpty) return _fallback();

    // La lista de tokens puede quedar vacía en consultas legítimas y muy
    // cortas —«¿por qué n-1?» se reduce a dos caracteres sueltos—, así que no
    // se descarta la consulta por eso: las palabras clave de varias palabras
    // se comparan igualmente contra el texto normalizado.
    final List<String> tokens = tokenize(query);

    TutorTopic? best;
    double bestScore = 0;

    for (final TutorTopic topic in topics) {
      final double score = _score(topic, tokens, query);
      if (score > bestScore) {
        bestScore = score;
        best = topic;
      }
    }

    if (best == null || bestScore < matchThreshold) {
      return _fallback();
    }

    return TutorAnswer(
      text: best.answer,
      suggestions: best.followUps,
      isFallback: false,
      topicId: best.id,
      example: best.example,
    );
  }

  double _score(TutorTopic topic, List<String> tokens, String rawQuery) {
    final String normalizedQuery = normalize(rawQuery);

    // El título de un tema es su formulación canónica: si la consulta coincide
    // con él, no hay nada que puntuar. Esto es lo que hace que los chips de
    // preguntas sugeridas siempre lleven a alguna parte, en lugar de a un
    // callejón sin salida cuando las palabras clave no cubren esa redacción.
    if (normalizedQuery == normalize(topic.title)) return 10;

    double hits = 0;

    // Las palabras del título cuentan como claves de una sola palabra. Es la
    // red que evita depender de que quien edita el corpus haya previsto todas
    // las formas de preguntar lo mismo.
    final Set<String> titleTokens = tokenize(topic.title).toSet();
    for (final String t in tokens) {
      if (titleTokens.contains(t)) hits += 1;
    }

    for (final String keyword in topic.keywords) {
      final String k = normalize(keyword);
      if (k.contains(' ')) {
        // Las palabras clave de varias palabras valen doble: "media ponderada"
        // identifica el tema mucho mejor que "media" suelta.
        if (normalizedQuery.contains(k)) hits += 2;
      } else {
        for (final String t in tokens) {
          if (t == k) {
            // Una coincidencia exacta con una palabra clave distintiva («ric»,
            // «sturges», «moda») es evidencia fuerte y pesa más que una
            // coincidencia por prefijo, que puede ser casual.
            hits += 1.5;
            break;
          }
          if ((t.length > 4 && k.startsWith(t)) ||
              (k.length > 4 && t.startsWith(k))) {
            hits += 1;
            break;
          }
        }
      }
    }
    if (hits == 0) return 0;
    // Se normaliza por el número de palabras de la consulta para que una
    // consulta larga y vaga no gane por acumulación.
    return hits / (tokens.length + 1.2);
  }

  TutorAnswer _fallback() {
    final List<String> sample = topics
        .take(60)
        .map((TutorTopic t) => t.title)
        .toList(growable: false);
    sample.shuffle();
    return TutorAnswer(
      text: 'No tengo una respuesta revisada para esa pregunta, y prefiero '
          'decírtelo antes que improvisar una.\n\n'
          'Puedo ayudarte con los temas de los cinco módulos: tipos de '
          'variable y escalas, tablas de frecuencias, medidas de tendencia '
          'central, dispersión y gráficos. Prueba a preguntar por uno de '
          'estos:',
      suggestions: sample.take(4).toList(growable: false),
      isFallback: true,
    );
  }

  /// Diagnóstico proactivo a partir del historial de errores.
  ///
  /// Devuelve las confusiones ordenadas por prioridad, ya emparejadas con su
  /// explicación. Es lo que la pantalla del tutor muestra sin que el estudiante
  /// pregunte nada, porque el estudiante que más lo necesita es justamente el
  /// que no sabe qué preguntar.
  List<({Misconception misconception, int count})> diagnose(
    List<MisconceptionTally> tallies, {
    int limit = 3,
  }) {
    final Map<String, Misconception> byId = <String, Misconception>{
      for (final Misconception m in misconceptions) m.id: m,
    };
    final List<({Misconception misconception, int count})> result =
        <({Misconception misconception, int count})>[];
    for (final MisconceptionTally t in tallies) {
      final Misconception? m = byId[t.tag];
      if (m == null) continue;
      result.add((misconception: m, count: t.count));
      if (result.length >= limit) break;
    }
    return result;
  }

  /// Busca la explicación de una etiqueta concreta, para mostrarla justo
  /// después de fallar un ejercicio.
  Misconception? explain(String tag) {
    for (final Misconception m in misconceptions) {
      if (m.id == tag) return m;
    }
    return null;
  }
}
