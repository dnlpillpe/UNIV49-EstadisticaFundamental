import 'package:estadistica_fundamental/domain/entities/dataset.dart';
import 'package:estadistica_fundamental/domain/entities/exercise.dart';
import 'package:estadistica_fundamental/domain/entities/glossary_term.dart';
import 'package:estadistica_fundamental/domain/entities/misconception.dart';
import 'package:estadistica_fundamental/domain/entities/study_module.dart';
import 'package:estadistica_fundamental/domain/entities/tutor.dart';
import 'package:estadistica_fundamental/domain/repositories/content_repository.dart';
import 'package:estadistica_fundamental/domain/services/tutor_engine.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/file_content_repository.dart';

/// Test de integridad del contenido.
///
/// El contenido educativo vive en JSON para que lo pueda editar alguien que no
/// programa. El precio de esa flexibilidad es que un error de edición —un id
/// mal escrito, un ejercicio con dos alternativas correctas, una etiqueta de
/// confusión inexistente— no lo detecta el compilador.
///
/// Esta suite es la red que lo detecta antes de que llegue al APK, y es la
/// pieza más reutilizable del proyecto: sirve igual para cualquier otra app de
/// la fábrica que guarde su contenido en JSON.
void main() {
  late ContentBundle bundle;

  setUpAll(() async {
    bundle = await const FileContentRepository().load();
  });

  group('Identificadores', () {
    test('no hay ids duplicados en ninguna colección', () {
      void unique(String what, Iterable<String> ids) {
        final List<String> list = ids.toList();
        expect(list.toSet().length, list.length, reason: '$what con id repetido');
      }

      unique('módulos', bundle.modules.map((StudyModule m) => m.id));
      unique('conjuntos', bundle.datasets.map((Dataset d) => d.id));
      unique('ejercicios', bundle.exercises.map((Exercise e) => e.id));
      unique('glosario', bundle.glossary.map((GlossaryTerm g) => g.id));
      unique('confusiones',
          bundle.misconceptions.map((Misconception m) => m.id));
      unique('temas del tutor',
          bundle.tutorTopics.map((TutorTopic t) => t.id));
      unique(
        'lecciones',
        bundle.modules.expand((StudyModule m) => m.lessons.map((Lesson l) => l.id)),
      );
    });

    test('el orden de los módulos es 1..n sin huecos', () {
      final List<int> orders =
          bundle.modules.map((StudyModule m) => m.order).toList()..sort();
      expect(orders, List<int>.generate(bundle.modules.length, (int i) => i + 1));
    });
  });

  group('Referencias cruzadas', () {
    test('todo ejercicio apunta a un módulo existente', () {
      final Set<String> ids =
          bundle.modules.map((StudyModule m) => m.id).toSet();
      for (final Exercise e in bundle.exercises) {
        expect(ids.contains(e.moduleId), isTrue,
            reason: '${e.id} apunta al módulo inexistente ${e.moduleId}');
      }
    });

    test('todo conjunto referenciado existe', () {
      final Set<String> ids = bundle.datasets.map((Dataset d) => d.id).toSet();
      for (final Exercise e in bundle.exercises) {
        for (final String? id in <String?>[e.datasetId, e.secondaryDatasetId]) {
          if (id == null) continue;
          expect(ids.contains(id), isTrue,
              reason: '${e.id} usa el conjunto inexistente $id');
        }
      }
      for (final StudyModule m in bundle.modules) {
        for (final String id in m.lab.datasetIds) {
          expect(ids.contains(id), isTrue,
              reason: 'El laboratorio de ${m.id} usa el conjunto $id');
        }
      }
    });

    test('toda etiqueta de error corresponde a una confusión catalogada', () {
      final Set<String> known =
          bundle.misconceptions.map((Misconception m) => m.id).toSet();
      for (final Exercise e in bundle.exercises) {
        final List<String> tags = <String>[
          for (final AnswerOption o in e.options) ...o.tags,
          for (final AnswerOption o in e.justification?.options ?? const <AnswerOption>[])
            ...o.tags,
          for (final ClassifyItem i in e.items) ...i.tags,
        ];
        for (final String tag in tags) {
          expect(known.contains(tag), isTrue,
              reason: '${e.id} usa la etiqueta desconocida "$tag"');
        }
      }
    });

    test('toda confusión catalogada aparece en algún ejercicio', () {
      // Si no aparece, el tutor nunca podrá diagnosticarla y sobra.
      final Set<String> used = <String>{
        for (final Exercise e in bundle.exercises) ...<String>[
          for (final AnswerOption o in e.options) ...o.tags,
          for (final AnswerOption o in e.justification?.options ?? const <AnswerOption>[])
            ...o.tags,
          for (final ClassifyItem i in e.items) ...i.tags,
        ],
      };
      for (final Misconception m in bundle.misconceptions) {
        expect(used.contains(m.id), isTrue,
            reason: 'La confusión "${m.id}" no la produce ningún distractor');
      }
    });

    test('todo término del glosario apunta a un módulo y a términos existentes',
        () {
      final Set<String> modules =
          bundle.modules.map((StudyModule m) => m.id).toSet();
      final Set<String> terms =
          bundle.glossary.map((GlossaryTerm g) => g.id).toSet();
      for (final GlossaryTerm g in bundle.glossary) {
        expect(modules.contains(g.moduleId), isTrue, reason: g.id);
        for (final String r in g.related) {
          expect(terms.contains(r), isTrue,
              reason: '${g.id} referencia el término inexistente $r');
        }
      }
    });

    test('todo conjunto de datos se usa en algún sitio', () {
      final Set<String> used = <String>{
        for (final Exercise e in bundle.exercises) ...<String>[
          if (e.datasetId != null) e.datasetId!,
          if (e.secondaryDatasetId != null) e.secondaryDatasetId!,
        ],
        for (final StudyModule m in bundle.modules) ...m.lab.datasetIds,
      };
      for (final Dataset d in bundle.datasets) {
        expect(used.contains(d.id), isTrue,
            reason: 'El conjunto ${d.id} no lo usa nadie');
      }
    });
  });

  group('Ejercicios bien formados', () {
    test('las preguntas de elección tienen exactamente una correcta', () {
      for (final Exercise e in bundle.exercises) {
        if (e.type != ExerciseType.choice) continue;
        final int correct =
            e.options.where((AnswerOption o) => o.correct).length;
        expect(correct, 1,
            reason: '${e.id} tiene $correct alternativas correctas');
        expect(e.options.length, greaterThanOrEqualTo(3), reason: e.id);
      }
    });

    test('toda justificación tiene exactamente una opción correcta', () {
      for (final Exercise e in bundle.exercises) {
        final JustificationStep? j = e.justification;
        if (j == null) continue;
        expect(j.options.where((AnswerOption o) => o.correct).length, 1,
            reason: e.id);
        expect(j.options.length, greaterThanOrEqualTo(2), reason: e.id);
      }
    });

    test('toda alternativa lleva retroalimentación propia', () {
      for (final Exercise e in bundle.exercises) {
        for (final AnswerOption o
            in <AnswerOption>[...e.options, ...?e.justification?.options]) {
          expect(o.feedback.trim(), isNotEmpty,
              reason: '${e.id}/${o.id} sin retroalimentación');
        }
      }
    });

    test('los distractores declaran qué confusión representan', () {
      for (final Exercise e in bundle.exercises) {
        if (e.type != ExerciseType.choice) continue;
        final Iterable<AnswerOption> wrong =
            e.options.where((AnswerOption o) => !o.correct);
        expect(wrong.any((AnswerOption o) => o.tags.isNotEmpty), isTrue,
            reason: '${e.id}: ningún distractor lleva etiqueta conceptual');
      }
    });

    test('los ejercicios numéricos tienen respuesta y tolerancia positiva', () {
      for (final Exercise e in bundle.exercises) {
        if (e.type != ExerciseType.numeric) continue;
        expect(e.numericAnswer, isNotNull, reason: e.id);
        expect(e.numericAnswer!.tolerance, greaterThan(0), reason: e.id);
        expect(e.numericAnswer!.value.isFinite, isTrue, reason: e.id);
      }
    });

    test('los ejercicios de clasificación apuntan a categorías existentes', () {
      for (final Exercise e in bundle.exercises) {
        if (e.type != ExerciseType.classify) continue;
        final Set<String> buckets =
            e.buckets.map((ClassifyBucket b) => b.id).toSet();
        expect(buckets.length, greaterThanOrEqualTo(2), reason: e.id);
        expect(e.items.length, greaterThanOrEqualTo(3), reason: e.id);
        for (final ClassifyItem i in e.items) {
          expect(buckets.contains(i.bucketId), isTrue,
              reason: '${e.id}/${i.id} usa la categoría ${i.bucketId}');
        }
        // Toda categoría debe usarse al menos una vez: una categoría vacía es
        // un distractor gratuito que no enseña nada.
        for (final String b in buckets) {
          expect(e.items.any((ClassifyItem i) => i.bucketId == b), isTrue,
              reason: '${e.id}: la categoría $b no la usa ningún elemento');
        }
      }
    });

    test('todo ejercicio tiene explicación', () {
      for (final Exercise e in bundle.exercises) {
        expect(e.explanation.trim(), isNotEmpty, reason: e.id);
        expect(e.difficulty, inInclusiveRange(1, 3), reason: e.id);
      }
    });

    test('cada módulo tiene al menos ocho ejercicios', () {
      for (final StudyModule m in bundle.modules) {
        expect(bundle.exercisesOf(m.id).length, greaterThanOrEqualTo(8),
            reason: m.id);
      }
    });

    test('cada módulo tiene al menos dos ejercicios con justificación', () {
      for (final StudyModule m in bundle.modules) {
        final int withJustification = bundle
            .exercisesOf(m.id)
            .where((Exercise e) => e.hasJustification)
            .length;
        expect(withJustification, greaterThanOrEqualTo(2), reason: m.id);
      }
    });
  });

  group('Módulos y datos', () {
    test('cada módulo tiene lecciones con tarjetas e idea clave', () {
      for (final StudyModule m in bundle.modules) {
        expect(m.lessons.length, greaterThanOrEqualTo(3), reason: m.id);
        for (final Lesson l in m.lessons) {
          expect(l.cards.length, greaterThanOrEqualTo(3), reason: l.id);
          expect(l.keyIdea.trim(), isNotEmpty, reason: l.id);
          for (final ConceptCard c in l.cards) {
            expect(c.body.trim(), isNotEmpty, reason: l.id);
          }
        }
        expect(m.problem.trim(), isNotEmpty, reason: m.id);
        expect(m.bigIdea.trim(), isNotEmpty, reason: m.id);
        expect(m.lab.steps, isNotEmpty, reason: m.id);
      }
    });

    test('todo conjunto declara contexto, población y origen', () {
      for (final Dataset d in bundle.datasets) {
        expect(d.context.trim(), isNotEmpty, reason: d.id);
        expect(d.population.trim(), isNotEmpty, reason: d.id);
        expect(d.source.trim(), isNotEmpty, reason: d.id);
        expect(d.size, greaterThan(0), reason: d.id);
      }
    });

    test('el tipo de conjunto coincide con los datos que trae', () {
      for (final Dataset d in bundle.datasets) {
        switch (d.kind) {
          case DatasetKind.numeric:
            expect(d.values.length, greaterThanOrEqualTo(10), reason: d.id);
            expect(d.categories, isEmpty, reason: d.id);
          case DatasetKind.categorical:
            expect(d.categories.length, greaterThanOrEqualTo(2), reason: d.id);
            expect(d.values, isEmpty, reason: d.id);
          case DatasetKind.bivariate:
            expect(d.pairs.length, greaterThanOrEqualTo(5), reason: d.id);
            expect(d.xName.trim(), isNotEmpty, reason: d.id);
            expect(d.yName.trim(), isNotEmpty, reason: d.id);
        }
      }
    });
  });

  group('Corpus del tutor', () {
    test('cada tema tiene palabras clave y respuesta', () {
      for (final TutorTopic t in bundle.tutorTopics) {
        expect(t.keywords.length, greaterThanOrEqualTo(3), reason: t.id);
        expect(t.answer.trim().length, greaterThan(80), reason: t.id);
        expect(t.title.trim(), isNotEmpty, reason: t.id);
      }
    });

    test('las preguntas sugeridas encuentran su propio tema', () {
      // Si una sugerencia no dispara ninguna respuesta, el chip lleva al
      // estudiante a un callejón sin salida.
      final TutorEngine engine = TutorEngine(
        topics: bundle.tutorTopics,
        misconceptions: bundle.misconceptions,
      );
      for (final TutorTopic t in bundle.tutorTopics) {
        for (final String followUp in t.followUps) {
          expect(engine.ask(followUp).isFallback, isFalse,
              reason: 'La sugerencia "$followUp" de ${t.id} no encuentra tema');
        }
        expect(engine.ask(t.title).isFallback, isFalse,
            reason: 'El propio título de ${t.id} no encuentra tema');
      }
    });
  });
}
