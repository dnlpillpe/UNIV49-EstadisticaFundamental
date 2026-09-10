/// Resumen descriptivo completo de una variable numérica.
///
/// Se calcula de una sola pasada por el motor estadístico y viaja como valor
/// inmutable: cualquier pantalla que necesite "la media" recibe también la
/// mediana, la desviación y los atípicos, de modo que la interfaz siempre puede
/// mostrar la comparación que el estudiante necesita ver.
class DescriptiveStats {
  const DescriptiveStats({
    required this.n,
    required this.sum,
    required this.min,
    required this.max,
    required this.range,
    required this.mean,
    required this.median,
    required this.modes,
    required this.q1,
    required this.q2,
    required this.q3,
    required this.iqr,
    required this.populationVariance,
    required this.sampleVariance,
    required this.populationStdDev,
    required this.sampleStdDev,
    required this.coefficientOfVariation,
    required this.lowerFence,
    required this.upperFence,
    required this.outliers,
    required this.skewnessSign,
    required this.sorted,
  });

  final int n;
  final double sum;
  final double min;
  final double max;
  final double range;
  final double mean;
  final double median;

  /// Puede estar vacío (sin moda), tener un valor (unimodal) o varios.
  final List<double> modes;

  final double q1;
  final double q2;
  final double q3;
  final double iqr;

  final double populationVariance;
  final double sampleVariance;
  final double populationStdDev;
  final double sampleStdDev;

  /// Desviación muestral / media, en porcentaje. Es `double.nan` si la media
  /// es cero, porque en ese caso el coeficiente no está definido.
  final double coefficientOfVariation;

  final double lowerFence;
  final double upperFence;
  final List<double> outliers;

  /// -1 asimetría negativa, 0 aproximadamente simétrica, 1 positiva.
  /// Se deriva de la relación media–mediana, que es la comparación que el
  /// estudiante puede hacer a ojo y la que el curso pide justificar.
  final int skewnessSign;

  final List<double> sorted;

  bool get hasOutliers => outliers.isNotEmpty;
  bool get isBimodalOrMore => modes.length > 1;

  String get skewnessLabel {
    if (skewnessSign > 0) return 'Asimétrica a la derecha';
    if (skewnessSign < 0) return 'Asimétrica a la izquierda';
    return 'Aproximadamente simétrica';
  }

  /// Diferencia relativa entre media y mediana, en porcentaje del rango.
  /// Es el indicador que la app usa para avisar "aquí la media engaña".
  double get meanMedianGapRatio {
    if (range == 0) return 0;
    return ((mean - median).abs() / range) * 100;
  }
}

/// Resultado de un ajuste lineal simple, usado en el módulo de gráficos.
class LinearFit {
  const LinearFit({
    required this.slope,
    required this.intercept,
    required this.correlation,
    required this.rSquared,
  });

  final double slope;
  final double intercept;
  final double correlation;
  final double rSquared;

  String get strengthLabel {
    final double r = correlation.abs();
    if (r >= 0.9) return 'muy fuerte';
    if (r >= 0.7) return 'fuerte';
    if (r >= 0.4) return 'moderada';
    if (r >= 0.2) return 'débil';
    return 'prácticamente nula';
  }

  String get directionLabel => correlation >= 0 ? 'positiva' : 'negativa';
}
