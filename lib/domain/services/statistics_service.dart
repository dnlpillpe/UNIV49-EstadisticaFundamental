import 'dart:math' as math;

import '../entities/dataset.dart';
import '../entities/descriptive_stats.dart';
import '../entities/frequency_table.dart';

/// Motor estadístico de la aplicación. Dart puro, sin dependencias de Flutter:
/// se puede probar entero sin arrancar la interfaz.
///
/// Decisión de método para cuantiles: se usa **interpolación lineal sobre la
/// posición `(n - 1) · p`** (equivalente al tipo 7 de Hyndman–Fan y a
/// `PERCENTIL.INC` de Excel y Google Sheets). Se eligió éste, y no la regla
/// `(n + 1) · p` de varios textos, por una razón pedagógica concreta: el
/// estudiante va a contrastar los resultados de la app con una hoja de cálculo,
/// y una discrepancia sin explicación destruye la confianza en la herramienta.
/// El método está declarado dentro de la app (pantalla "Cómo calcula") junto a
/// la advertencia de que existen otras convenciones.
class StatisticsService {
  const StatisticsService();

  // ---------------------------------------------------------------------
  // Resumen descriptivo
  // ---------------------------------------------------------------------

  /// Calcula todas las medidas descriptivas de una muestra numérica.
  ///
  /// Lanza [ArgumentError] si la lista está vacía: un resumen de cero datos no
  /// es un caso límite razonable, es un error de quien llama.
  DescriptiveStats describe(List<double> input) {
    if (input.isEmpty) {
      throw ArgumentError('No se puede describir un conjunto vacío.');
    }
    final List<double> sorted = List<double>.of(input)..sort();
    final int n = sorted.length;

    final double sum = sorted.fold<double>(0, (double a, double b) => a + b);
    final double mean = sum / n;
    final double median = _quantileOfSorted(sorted, 0.5);
    final double q1 = _quantileOfSorted(sorted, 0.25);
    final double q3 = _quantileOfSorted(sorted, 0.75);
    final double iqr = q3 - q1;

    double squaredDeviations = 0;
    for (final double v in sorted) {
      final double d = v - mean;
      squaredDeviations += d * d;
    }
    final double populationVariance = squaredDeviations / n;
    final double sampleVariance =
        n > 1 ? squaredDeviations / (n - 1) : double.nan;
    final double populationStdDev = math.sqrt(populationVariance);
    final double sampleStdDev =
        n > 1 ? math.sqrt(sampleVariance) : double.nan;

    final double cv = mean == 0
        ? double.nan
        : (n > 1 ? sampleStdDev : populationStdDev) / mean.abs() * 100;

    final double lowerFence = q1 - 1.5 * iqr;
    final double upperFence = q3 + 1.5 * iqr;
    final List<double> outliers = sorted
        .where((double v) => v < lowerFence || v > upperFence)
        .toList(growable: false);

    final double min = sorted.first;
    final double max = sorted.last;
    final double range = max - min;

    // Umbral del 2 % del rango: por debajo de eso la diferencia entre media y
    // mediana no es interpretable a ojo en un gráfico y llamarla "asimetría"
    // enseñaría a leer ruido.
    final double gap = mean - median;
    final int skewnessSign = range == 0 || gap.abs() < range * 0.02
        ? 0
        : (gap > 0 ? 1 : -1);

    return DescriptiveStats(
      n: n,
      sum: sum,
      min: min,
      max: max,
      range: range,
      mean: mean,
      median: median,
      modes: modes(sorted),
      q1: q1,
      q2: median,
      q3: q3,
      iqr: iqr,
      populationVariance: populationVariance,
      sampleVariance: sampleVariance,
      populationStdDev: populationStdDev,
      sampleStdDev: sampleStdDev,
      coefficientOfVariation: cv,
      lowerFence: lowerFence,
      upperFence: upperFence,
      outliers: outliers,
      skewnessSign: skewnessSign,
      sorted: sorted,
    );
  }

  // ---------------------------------------------------------------------
  // Medidas individuales
  // ---------------------------------------------------------------------

  double mean(List<double> values) {
    if (values.isEmpty) return double.nan;
    return values.fold<double>(0, (double a, double b) => a + b) /
        values.length;
  }

  /// Media ponderada. Usada en el módulo 3 para el caso "promedio de notas con
  /// créditos", que es donde el estudiante descubre que la media simple miente.
  double weightedMean(List<double> values, List<double> weights) {
    if (values.length != weights.length) {
      throw ArgumentError('Valores y pesos deben tener la misma longitud.');
    }
    if (values.isEmpty) return double.nan;
    double num = 0;
    double den = 0;
    for (int i = 0; i < values.length; i++) {
      num += values[i] * weights[i];
      den += weights[i];
    }
    if (den == 0) return double.nan;
    return num / den;
  }

  double median(List<double> values) {
    if (values.isEmpty) return double.nan;
    final List<double> sorted = List<double>.of(values)..sort();
    return _quantileOfSorted(sorted, 0.5);
  }

  /// Devuelve todas las modas. Lista vacía cuando todos los valores tienen la
  /// misma frecuencia (el conjunto es amodal), que es un caso que los libros
  /// suelen omitir y los estudiantes suelen encontrar.
  List<double> modes(List<double> values) {
    if (values.isEmpty) return const <double>[];
    final Map<double, int> counts = <double, int>{};
    for (final double v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    final int maxCount =
        counts.values.reduce((int a, int b) => a > b ? a : b);
    if (maxCount == 1) return const <double>[];
    final List<double> result = counts.entries
        .where((MapEntry<double, int> e) => e.value == maxCount)
        .map((MapEntry<double, int> e) => e.key)
        .toList()
      ..sort();
    return result;
  }

  /// Cuantil de orden [p] (0..1) por interpolación lineal.
  double quantile(List<double> values, double p) {
    if (values.isEmpty) return double.nan;
    if (p < 0 || p > 1) {
      throw ArgumentError('p debe estar entre 0 y 1, recibido: $p');
    }
    final List<double> sorted = List<double>.of(values)..sort();
    return _quantileOfSorted(sorted, p);
  }

  double _quantileOfSorted(List<double> sorted, double p) {
    final int n = sorted.length;
    if (n == 1) return sorted.first;
    final double pos = (n - 1) * p;
    final int lower = pos.floor();
    final int upper = pos.ceil();
    if (lower == upper) return sorted[lower];
    final double weight = pos - lower;
    return sorted[lower] * (1 - weight) + sorted[upper] * weight;
  }

  double variance(List<double> values, {bool sample = true}) {
    final int n = values.length;
    if (n == 0) return double.nan;
    if (sample && n < 2) return double.nan;
    final double m = mean(values);
    double acc = 0;
    for (final double v in values) {
      final double d = v - m;
      acc += d * d;
    }
    return acc / (sample ? n - 1 : n);
  }

  double stdDev(List<double> values, {bool sample = true}) =>
      math.sqrt(variance(values, sample: sample));

  /// Coeficiente de variación en porcentaje. Es la única medida de dispersión
  /// comparable entre variables con unidades distintas, y por eso el módulo 4
  /// la usa como respuesta a "¿cuál de los dos procesos es más inestable?".
  double coefficientOfVariation(List<double> values, {bool sample = true}) {
    final double m = mean(values);
    if (m == 0) return double.nan;
    return stdDev(values, sample: sample) / m.abs() * 100;
  }

  /// Puntuación z de [value] respecto al conjunto.
  double zScore(double value, List<double> values, {bool sample = true}) {
    final double s = stdDev(values, sample: sample);
    if (s == 0 || s.isNaN) return double.nan;
    return (value - mean(values)) / s;
  }

  /// Proporción de datos dentro de `k` desviaciones estándar de la media.
  /// Sirve para contrastar la regla empírica (68–95–99,7) con datos reales y
  /// para que el estudiante vea cuándo esa regla no aplica.
  double proportionWithin(List<double> values, double k, {bool sample = true}) {
    if (values.isEmpty) return double.nan;
    final double m = mean(values);
    final double s = stdDev(values, sample: sample);
    if (s == 0 || s.isNaN) return double.nan;
    final int inside = values
        .where((double v) => (v - m).abs() <= k * s)
        .length;
    return inside / values.length * 100;
  }

  /// Cota inferior de Chebyshev: proporción mínima garantizada dentro de k
  /// desviaciones, para cualquier distribución. Válida solo para k > 1.
  double chebyshevLowerBound(double k) {
    if (k <= 1) return 0;
    return (1 - 1 / (k * k)) * 100;
  }

  // ---------------------------------------------------------------------
  // Distribución de frecuencias
  // ---------------------------------------------------------------------

  /// Número de clases sugerido por la regla de Sturges.
  int sturgesClassCount(int n) {
    if (n <= 0) return 1;
    final int k = (1 + 3.322 * (math.log(n) / math.ln10)).round();
    return k.clamp(2, 20);
  }

  /// Construye una tabla de frecuencias para datos numéricos agrupados.
  ///
  /// Los intervalos son cerrados por la izquierda y abiertos por la derecha
  /// `[Li, Ls)`, salvo el último, que incluye el máximo. Esta convención evita
  /// el error clásico de contar dos veces un valor que cae justo en un límite.
  FrequencyTable buildFrequencyTable(
    List<double> values, {
    int? classCount,
  }) {
    if (values.isEmpty) {
      return const FrequencyTable(
        rows: <FrequencyRow>[],
        total: 0,
        classCount: 0,
        classWidth: 0,
        isCategorical: false,
      );
    }
    final List<double> sorted = List<double>.of(values)..sort();
    final int n = sorted.length;
    final int k = (classCount ?? sturgesClassCount(n)).clamp(2, 20);

    final double min = sorted.first;
    final double max = sorted.last;
    double width = (max - min) / k;
    if (width <= 0) width = 1; // todos los valores iguales

    final List<int> counts = List<int>.filled(k, 0);
    for (final double v in sorted) {
      int index = ((v - min) / width).floor();
      if (index >= k) index = k - 1; // el máximo entra en la última clase
      if (index < 0) index = 0;
      counts[index]++;
    }

    final List<FrequencyRow> rows = <FrequencyRow>[];
    int cumulative = 0;
    for (int i = 0; i < k; i++) {
      final double lower = min + width * i;
      final double upper = i == k - 1 ? max : min + width * (i + 1);
      cumulative += counts[i];
      rows.add(
        FrequencyRow(
          label: '[${_fmt(lower)} – ${_fmt(upper)}${i == k - 1 ? ']' : ')'}',
          lowerBound: lower,
          upperBound: upper,
          midpoint: (lower + upper) / 2,
          absolute: counts[i],
          relative: counts[i] / n,
          cumulativeAbsolute: cumulative,
          cumulativeRelative: cumulative / n,
        ),
      );
    }

    return FrequencyTable(
      rows: rows,
      total: n,
      classCount: k,
      classWidth: width,
      isCategorical: false,
    );
  }

  /// Tabla de frecuencias para una variable cualitativa: sin intervalos, una
  /// fila por categoría, ordenada de mayor a menor frecuencia.
  FrequencyTable buildCategoricalTable(List<CategoryCount> categories) {
    final int total =
        categories.fold<int>(0, (int a, CategoryCount c) => a + c.count);
    final List<CategoryCount> ordered = List<CategoryCount>.of(categories)
      ..sort((CategoryCount a, CategoryCount b) => b.count.compareTo(a.count));

    final List<FrequencyRow> rows = <FrequencyRow>[];
    int cumulative = 0;
    for (int i = 0; i < ordered.length; i++) {
      cumulative += ordered[i].count;
      rows.add(
        FrequencyRow(
          label: ordered[i].label,
          lowerBound: i.toDouble(),
          upperBound: (i + 1).toDouble(),
          midpoint: i + 0.5,
          absolute: ordered[i].count,
          relative: total == 0 ? 0 : ordered[i].count / total,
          cumulativeAbsolute: cumulative,
          cumulativeRelative: total == 0 ? 0 : cumulative / total,
        ),
      );
    }

    return FrequencyTable(
      rows: rows,
      total: total,
      classCount: ordered.length,
      classWidth: 1,
      isCategorical: true,
    );
  }

  // ---------------------------------------------------------------------
  // Bivariado
  // ---------------------------------------------------------------------

  /// Correlación de Pearson y recta de mínimos cuadrados.
  LinearFit linearFit(List<DataPair> pairs) {
    final int n = pairs.length;
    if (n < 2) {
      return const LinearFit(
        slope: double.nan,
        intercept: double.nan,
        correlation: double.nan,
        rSquared: double.nan,
      );
    }
    double sx = 0, sy = 0;
    for (final DataPair p in pairs) {
      sx += p.x;
      sy += p.y;
    }
    final double mx = sx / n;
    final double my = sy / n;

    double sxy = 0, sxx = 0, syy = 0;
    for (final DataPair p in pairs) {
      final double dx = p.x - mx;
      final double dy = p.y - my;
      sxy += dx * dy;
      sxx += dx * dx;
      syy += dy * dy;
    }
    if (sxx == 0 || syy == 0) {
      return const LinearFit(
        slope: double.nan,
        intercept: double.nan,
        correlation: double.nan,
        rSquared: double.nan,
      );
    }
    final double slope = sxy / sxx;
    final double intercept = my - slope * mx;
    final double r = sxy / math.sqrt(sxx * syy);
    return LinearFit(
      slope: slope,
      intercept: intercept,
      correlation: r,
      rSquared: r * r,
    );
  }

  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
