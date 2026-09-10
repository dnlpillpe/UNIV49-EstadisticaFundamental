import 'package:estadistica_fundamental/domain/entities/misconception.dart';
import 'package:estadistica_fundamental/domain/entities/progress.dart';
import 'package:estadistica_fundamental/domain/entities/tutor.dart';
import 'package:estadistica_fundamental/domain/repositories/content_repository.dart';
import 'package:estadistica_fundamental/domain/services/tutor_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/file_content_repository.dart';

void main() {
  late TutorEngine engine;
  late ContentBundle bundle;

  setUpAll(() async {
    bundle = await const FileContentRepository().load();
    engine = TutorEngine(
      topics: bundle.tutorTopics,
      misconceptions: bundle.misconceptions,
    );
  });

  group('Normalización', () {
    test('quita tildes, signos y mayúsculas', () {
      expect(TutorEngine.normalize('¿Qué es la MEDIANA?'),
          'que es la mediana');
    });

    test('convierte subíndices a su carácter base', () {
      expect(TutorEngine.normalize('diferencia entre fᵢ y Fᵢ'),
          'diferencia entre fi y fi');
      expect(TutorEngine.normalize('Q₁ y Q₃'), 'q1 y q3');
    });

    test('descarta palabras sin valor discriminante', () {
      expect(TutorEngine.tokenize('¿Qué es la media?'), <String>['media']);
    });
  });

  group('Respuestas', () {
    test('encuentra el tema de una pregunta típica', () {
      final TutorAnswer a = engine.ask('¿cuándo uso la mediana?');
      expect(a.isFallback, isFalse);
      expect(a.topicId, 't_media_vs_mediana');
      expect(a.suggestions, isNotEmpty);
    });

    test('distingue temas cercanos', () {
      expect(engine.ask('qué es la varianza').topicId, 't_varianza');
      expect(engine.ask('coeficiente de variación').topicId, 't_cv');
      expect(engine.ask('por qué se divide entre n-1').topicId, 't_n_menos_1');
    });

    test('admite su límite en lugar de improvisar', () {
      // Es la propiedad que hace confiable al tutor: un tutor que responde
      // siempre es un tutor en el que no se puede confiar nunca.
      for (final String off in <String>[
        'receta de ceviche',
        '¿quién ganó el mundial?',
        'asdfghjkl',
        '   ',
      ]) {
        final TutorAnswer a = engine.ask(off);
        expect(a.isFallback, isTrue, reason: off);
        expect(a.topicId, isNull);
        expect(a.suggestions, isNotEmpty,
            reason: 'El fallback debe ofrecer salidas, no dejar al estudiante '
                'parado');
      }
    });

    test('el título de cada tema encuentra su propio tema', () {
      for (final TutorTopic t in bundle.tutorTopics) {
        expect(engine.ask(t.title).isFallback, isFalse, reason: t.id);
      }
    });
  });

  group('Diagnóstico', () {
    test('empareja las etiquetas del historial con su explicación', () {
      final List<MisconceptionTally> tallies = <MisconceptionTally>[
        const MisconceptionTally(
            tag: 'media_siempre', count: 4, lastSeenMs: 900),
        const MisconceptionTally(
            tag: 'eje_truncado', count: 2, lastSeenMs: 800),
      ];
      final List<({Misconception misconception, int count})> d =
          engine.diagnose(tallies);
      expect(d.length, 2);
      expect(d.first.misconception.id, 'media_siempre');
      expect(d.first.count, 4);
      expect(d.first.misconception.correction, isNotEmpty);
    });

    test('ignora etiquetas que no están catalogadas', () {
      final List<({Misconception misconception, int count})> d =
          engine.diagnose(<MisconceptionTally>[
        const MisconceptionTally(tag: 'inventada', count: 9, lastSeenMs: 1),
      ]);
      expect(d, isEmpty);
    });

    test('respeta el límite pedido', () {
      final List<MisconceptionTally> many = bundle.misconceptions
          .map((Misconception m) =>
              MisconceptionTally(tag: m.id, count: 1, lastSeenMs: 1))
          .toList();
      expect(engine.diagnose(many, limit: 3).length, 3);
    });

    test('explain() encuentra una confusión por su etiqueta', () {
      expect(engine.explain('media_vs_mediana'), isNotNull);
      expect(engine.explain('no_existe'), isNull);
    });
  });
}
