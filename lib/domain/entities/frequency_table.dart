/// Una fila de una tabla de distribución de frecuencias.
class FrequencyRow {
  const FrequencyRow({
    required this.label,
    required this.lowerBound,
    required this.upperBound,
    required this.midpoint,
    required this.absolute,
    required this.relative,
    required this.cumulativeAbsolute,
    required this.cumulativeRelative,
  });

  final String label;
  final double lowerBound;
  final double upperBound;

  /// Marca de clase. Es el valor que representa a toda la clase cuando se
  /// calculan medidas a partir de datos agrupados.
  final double midpoint;

  final int absolute;
  final double relative;
  final int cumulativeAbsolute;
  final double cumulativeRelative;

  double get width => upperBound - lowerBound;
}

/// Tabla de distribución de frecuencias para datos agrupados o categóricos.
class FrequencyTable {
  const FrequencyTable({
    required this.rows,
    required this.total,
    required this.classCount,
    required this.classWidth,
    required this.isCategorical,
  });

  final List<FrequencyRow> rows;
  final int total;
  final int classCount;
  final double classWidth;
  final bool isCategorical;

  /// Clase con mayor frecuencia absoluta (clase modal).
  FrequencyRow? get modalClass {
    if (rows.isEmpty) return null;
    FrequencyRow best = rows.first;
    for (final FrequencyRow r in rows) {
      if (r.absolute > best.absolute) best = r;
    }
    return best;
  }

  /// Media estimada a partir de datos agrupados (marcas de clase).
  /// Se expone para que el estudiante compare el valor agrupado con el exacto y
  /// entienda qué información pierde al agrupar.
  double get groupedMean {
    if (total == 0) return double.nan;
    double acc = 0;
    for (final FrequencyRow r in rows) {
      acc += r.midpoint * r.absolute;
    }
    return acc / total;
  }
}
