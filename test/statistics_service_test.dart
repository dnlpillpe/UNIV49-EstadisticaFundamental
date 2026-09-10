import 'package:estadistica_fundamental/domain/entities/dataset.dart';
import 'package:estadistica_fundamental/domain/entities/descriptive_stats.dart';
import 'package:estadistica_fundamental/domain/entities/frequency_table.dart';
import 'package:estadistica_fundamental/domain/repositories/content_repository.dart';
import 'package:estadistica_fundamental/domain/services/statistics_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/file_content_repository.dart';

void main() {
  const StatisticsService service = StatisticsService();

  group('Medidas de tendencia central', () {
    test('media, mediana y moda en un caso conocido', () {
      final List<double> v = <double>[2, 4, 4, 4, 5, 5, 7, 9];
      expect(service.mean(v), closeTo(5.0, 1e-9));
      expect(service.median(v), closeTo(4.5, 1e-9));
      expect(service.modes(v), <double>[4]);
    });

    test('conjunto amodal: ningún valor se repite', () {
      expect(service.modes(<double>[1, 2, 3, 4]), isEmpty);
    });

    test('conjunto bimodal devuelve las dos modas ordenadas', () {
      expect(service.modes(<double>[5, 1, 2, 2, 3, 3, 4]), <double>[2, 3]);
    });

    test('la mediana con n par promedia los dos centrales', () {
      expect(service.median(<double>[1, 2, 3, 4]), closeTo(2.5, 1e-9));
    });

    test('media ponderada: el caso del promedio con créditos', () {
      expect(
        service.weightedMean(
            <double>[18, 12, 14], <double>[2, 4, 4]),
        closeTo(14.0, 1e-9),
      );
      // La media simple da 14,67: la diferencia es el peso de más que recibe
      // la nota alta del curso pequeño.
      expect(service.mean(<double>[18, 12, 14]), closeTo(14.6667, 1e-4));
    });

    test('describe() rechaza un conjunto vacío', () {
      expect(() => service.describe(<double>[]), throwsArgumentError);
    });
  });

  group('Cuantiles por interpolación lineal (método de Excel)', () {
    test('cuartiles de un conjunto de referencia', () {
      final List<double> v = <double>[1, 2, 3, 4, 5, 6, 7, 8, 9, 10];
      expect(service.quantile(v, 0.25), closeTo(3.25, 1e-9));
      expect(service.quantile(v, 0.5), closeTo(5.5, 1e-9));
      expect(service.quantile(v, 0.75), closeTo(7.75, 1e-9));
    });

    test('los extremos devuelven mínimo y máximo', () {
      final List<double> v = <double>[4, 8, 15, 16, 23, 42];
      expect(service.quantile(v, 0), closeTo(4, 1e-9));
      expect(service.quantile(v, 1), closeTo(42, 1e-9));
    });

    test('p fuera de [0, 1] es un error de quien llama', () {
      expect(() => service.quantile(<double>[1, 2], 1.5), throwsArgumentError);
    });
  });

  group('Dispersión', () {
    final List<double> v = <double>[2, 4, 4, 4, 5, 5, 7, 9];

    test('varianza poblacional y muestral', () {
      expect(service.variance(v, sample: false), closeTo(4.0, 1e-9));
      expect(service.variance(v), closeTo(4.5714286, 1e-6));
    });

    test('desviación estándar poblacional', () {
      expect(service.stdDev(v, sample: false), closeTo(2.0, 1e-9));
    });

    test('la varianza muestral no está definida con un solo dato', () {
      expect(service.variance(<double>[5]).isNaN, isTrue);
    });

    test('coeficiente de variación con media cero no está definido', () {
      expect(service.coefficientOfVariation(<double>[-1, 1]).isNaN, isTrue);
    });

    test('puntuación z', () {
      expect(service.zScore(9, v, sample: false), closeTo(2.0, 1e-9));
    });

    test('cota de Chebyshev', () {
      expect(service.chebyshevLowerBound(2), closeTo(75.0, 1e-9));
      expect(service.chebyshevLowerBound(3), closeTo(88.8889, 1e-4));
      expect(service.chebyshevLowerBound(1), 0);
    });
  });

  group('Tabla de frecuencias', () {
    test('Sturges sugiere 6 clases para n = 40', () {
      expect(service.sturgesClassCount(40), 6);
      expect(service.sturgesClassCount(45), 6);
      expect(service.sturgesClassCount(20), 5);
    });

    test('las frecuencias absolutas suman n y la última acumulada es n', () {
      final List<double> v =
          List<double>.generate(53, (int i) => (i * 7 % 41).toDouble());
      final FrequencyTable t = service.buildFrequencyTable(v);
      expect(
        t.rows.fold<int>(0, (int a, FrequencyRow r) => a + r.absolute),
        v.length,
      );
      expect(t.rows.last.cumulativeAbsolute, v.length);
      expect(t.rows.last.cumulativeRelative, closeTo(1.0, 1e-9));
    });

    test('un valor en el límite cae en una sola clase', () {
      // Clases de ancho 10 sobre [0, 40]: el 10 debe estar en [10, 20) y no en
      // [0, 10). Si se contara dos veces, el total no daría 5.
      final FrequencyTable t =
          service.buildFrequencyTable(<double>[0, 10, 20, 30, 40], classCount: 4);
      expect(t.total, 5);
      expect(t.rows.map((FrequencyRow r) => r.absolute).toList(),
          <int>[1, 1, 1, 2]);
    });

    test('todos los valores iguales no rompe el cálculo', () {
      final FrequencyTable t =
          service.buildFrequencyTable(<double>[7, 7, 7, 7]);
      expect(t.total, 4);
      expect(t.rows.isNotEmpty, isTrue);
    });

    test('la tabla categórica se ordena por frecuencia descendente', () {
      final FrequencyTable t = service.buildCategoricalTable(<CategoryCount>[
        const CategoryCount(label: 'B', count: 5),
        const CategoryCount(label: 'A', count: 12),
        const CategoryCount(label: 'C', count: 8),
      ]);
      expect(t.rows.map((FrequencyRow r) => r.label).toList(),
          <String>['A', 'C', 'B']);
      expect(t.total, 25);
      expect(t.modalClass!.label, 'A');
    });
  });

  group('Correlación', () {
    test('relación lineal perfecta da r = 1', () {
      final LinearFit fit = service.linearFit(const <DataPair>[
        DataPair(1, 2),
        DataPair(2, 4),
        DataPair(3, 6),
        DataPair(4, 8),
      ]);
      expect(fit.correlation, closeTo(1.0, 1e-9));
      expect(fit.slope, closeTo(2.0, 1e-9));
      expect(fit.intercept, closeTo(0.0, 1e-9));
    });

    test('relación en U perfecta da r ≈ 0 pese a ser predecible', () {
      // Es el contraejemplo del módulo 5: r mide relación *lineal*.
      final LinearFit fit = service.linearFit(const <DataPair>[
        DataPair(-2, 4),
        DataPair(-1, 1),
        DataPair(0, 0),
        DataPair(1, 1),
        DataPair(2, 4),
      ]);
      expect(fit.correlation.abs(), lessThan(1e-9));
    });
  });

  group('Cifras que aparecen en el contenido del curso', () {
    late ContentBundle bundle;

    setUpAll(() async {
      bundle = await const FileContentRepository().load();
    });

    // Estas comprobaciones son la red que impide que una edición del JSON de
    // datos deje inconsistentes los enunciados y las respuestas numéricas.

    test('ds_traslado', () {
      final DescriptiveStats s =
          service.describe(bundle.dataset('ds_traslado').values);
      expect(s.n, 40);
      expect(s.mean, closeTo(50.75, 0.005));
      expect(s.median, closeTo(40.0, 0.005));
      expect(s.modes, <double>[30]);
      expect(s.range, closeTo(138, 0.005));
      expect(s.q1, closeTo(29.5, 0.005));
      expect(s.q3, closeTo(61.25, 0.005));
      expect(s.iqr, closeTo(31.75, 0.005));
      expect(s.sampleStdDev, closeTo(33.089, 0.005));
      expect(s.coefficientOfVariation, closeTo(65.2, 0.05));
      expect(s.outliers, <double>[120, 135, 150]);
      expect(s.skewnessSign, 1);
    });

    test('ds_traslado agrupado en 6 clases', () {
      final FrequencyTable t = service.buildFrequencyTable(
          bundle.dataset('ds_traslado').values,
          classCount: 6);
      expect(t.classWidth, closeTo(23, 1e-9));
      expect(t.rows.map((FrequencyRow r) => r.absolute).toList(),
          <int>[15, 13, 6, 2, 2, 2]);
      expect(t.rows[2].cumulativeRelative, closeTo(0.85, 1e-9));
      expect(t.modalClass!.absolute, 15);
      expect(t.groupedMean, closeTo(51.675, 0.005));
    });

    test('ds_sueldos_egresados: media y mediana muy separadas', () {
      final DescriptiveStats s =
          service.describe(bundle.dataset('ds_sueldos_egresados').values);
      expect(s.mean, closeTo(2556.667, 0.01));
      expect(s.median, closeTo(1825, 0.005));
      expect(s.q1, closeTo(1600, 0.005));
      expect(s.q3, closeTo(2275, 0.005));
      expect(s.iqr, closeTo(675, 0.005));
      expect(s.upperFence, closeTo(3287.5, 0.005));
      expect(s.outliers, <double>[9500, 14000]);
    });

    test('secciones A y B: mismo centro, dispersión opuesta', () {
      final DescriptiveStats a =
          service.describe(bundle.dataset('ds_seccion_a').values);
      final DescriptiveStats b =
          service.describe(bundle.dataset('ds_seccion_b').values);

      // El caso que sostiene todo el módulo 4: si esto deja de cumplirse, el
      // laboratorio y cuatro ejercicios pierden su sentido.
      expect(a.mean, closeTo(b.mean, 1e-9));
      expect(a.median, closeTo(b.median, 1e-9));
      expect(a.modes, b.modes);
      expect(a.mean, closeTo(13.15, 0.005));
      expect(a.sampleStdDev, closeTo(0.671, 0.005));
      expect(b.sampleStdDev, closeTo(4.428, 0.005));
      expect(b.sampleStdDev / a.sampleStdDev, greaterThan(6));
    });

    test('ds_horas_sueno cumple la regla empírica', () {
      final List<double> v = bundle.dataset('ds_horas_sueno').values;
      expect(service.mean(v), closeTo(6.5, 0.005));
      expect(service.proportionWithin(v, 1), closeTo(68.42, 0.05));
      expect(service.proportionWithin(v, 2), closeTo(94.74, 0.05));
      expect(service.proportionWithin(v, 3), closeTo(100.0, 0.05));
    });

    test('ds_sueldos_egresados NO cumple la regla empírica', () {
      // El contraejemplo del ejercicio ex_m4_09.
      final List<double> v = bundle.dataset('ds_sueldos_egresados').values;
      expect(service.proportionWithin(v, 1), closeTo(93.33, 0.05));
    });

    test('ds_estudio_nota: correlación fuerte y positiva', () {
      final LinearFit fit =
          service.linearFit(bundle.dataset('ds_estudio_nota').pairs);
      expect(fit.correlation, closeTo(0.931, 0.005));
      expect(fit.rSquared, closeTo(0.867, 0.005));
      expect(fit.strengthLabel, 'muy fuerte');
      expect(fit.directionLabel, 'positiva');
    });

    test('ds_bebidas_insolacion: correlación espuria muy alta', () {
      final LinearFit fit =
          service.linearFit(bundle.dataset('ds_bebidas_insolacion').pairs);
      expect(fit.correlation, greaterThan(0.95));
    });

    test('ds_ley_cobre frente a ds_traslado por coeficiente de variación', () {
      final double cobre = service
          .coefficientOfVariation(bundle.dataset('ds_ley_cobre').values);
      final double traslado = service
          .coefficientOfVariation(bundle.dataset('ds_traslado').values);
      expect(cobre, closeTo(10.09, 0.05));
      expect(traslado, closeTo(65.2, 0.05));
      expect(traslado, greaterThan(cobre));
    });

    test('ds_asistencia_semanal es amodal', () {
      final DescriptiveStats s =
          service.describe(bundle.dataset('ds_asistencia_semanal').values);
      expect(s.modes, isEmpty);
      expect(s.mean, closeTo(87.5, 0.005));
    });
  });
}
