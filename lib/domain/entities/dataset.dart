import 'measurement.dart';

enum DatasetKind {
  numeric,
  categorical,
  bivariate;

  static DatasetKind fromKey(String key) {
    switch (key) {
      case 'numerico':
        return DatasetKind.numeric;
      case 'categorico':
        return DatasetKind.categorical;
      case 'bivariado':
        return DatasetKind.bivariate;
      default:
        throw ArgumentError('Tipo de conjunto desconocido: $key');
    }
  }
}

/// Una categoría de una variable cualitativa con su frecuencia observada.
class CategoryCount {
  const CategoryCount({required this.label, required this.count});

  final String label;
  final int count;

  factory CategoryCount.fromJson(Map<String, dynamic> json) => CategoryCount(
        label: json['label'] as String,
        count: (json['count'] as num).toInt(),
      );
}

/// Un par (x, y) de un conjunto bivariado.
class DataPair {
  const DataPair(this.x, this.y);

  final double x;
  final double y;

  factory DataPair.fromJson(List<dynamic> json) =>
      DataPair((json[0] as num).toDouble(), (json[1] as num).toDouble());
}

/// Conjunto de datos con su contexto.
///
/// El contexto no es adorno: sin saber de dónde salen los números, "interpretar"
/// se reduce a describir. Todos los conjuntos de la app llevan población,
/// unidad y una nota sobre cómo se obtuvieron.
class Dataset {
  const Dataset({
    required this.id,
    required this.name,
    required this.kind,
    required this.context,
    required this.population,
    required this.unit,
    required this.variableName,
    required this.variableKind,
    required this.scale,
    required this.source,
    required this.decimals,
    required this.tags,
    this.values = const <double>[],
    this.categories = const <CategoryCount>[],
    this.pairs = const <DataPair>[],
    this.xName = '',
    this.yName = '',
    this.xUnit = '',
    this.yUnit = '',
    this.note,
  });

  final String id;
  final String name;
  final DatasetKind kind;
  final String context;
  final String population;
  final String unit;
  final String variableName;
  final VariableKind variableKind;
  final MeasurementScale scale;
  final String source;
  final int decimals;
  final List<String> tags;

  final List<double> values;
  final List<CategoryCount> categories;
  final List<DataPair> pairs;
  final String xName;
  final String yName;
  final String xUnit;
  final String yUnit;

  /// Advertencia opcional sobre el conjunto (sesgo, dato sospechoso, etc.).
  final String? note;

  int get size => switch (kind) {
        DatasetKind.numeric => values.length,
        DatasetKind.categorical =>
          categories.fold<int>(0, (int a, CategoryCount c) => a + c.count),
        DatasetKind.bivariate => pairs.length,
      };

  Dataset copyWithValues(List<double> newValues) => Dataset(
        id: id,
        name: name,
        kind: kind,
        context: context,
        population: population,
        unit: unit,
        variableName: variableName,
        variableKind: variableKind,
        scale: scale,
        source: source,
        decimals: decimals,
        tags: tags,
        values: newValues,
        categories: categories,
        pairs: pairs,
        xName: xName,
        yName: yName,
        xUnit: xUnit,
        yUnit: yUnit,
        note: note,
      );

  factory Dataset.fromJson(Map<String, dynamic> json) {
    return Dataset(
      id: json['id'] as String,
      name: json['name'] as String,
      kind: DatasetKind.fromKey(json['kind'] as String),
      context: json['context'] as String,
      population: json['population'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
      variableName: json['variableName'] as String? ?? json['name'] as String,
      variableKind: VariableKind.fromKey(json['variableKind'] as String),
      scale: MeasurementScale.fromKey(json['scale'] as String),
      source: json['source'] as String? ?? '',
      decimals: (json['decimals'] as num?)?.toInt() ?? 1,
      tags: (json['tags'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => e as String)
          .toList(growable: false),
      values: (json['values'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => (e as num).toDouble())
          .toList(growable: false),
      categories: (json['categories'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => CategoryCount.fromJson(e as Map<String, dynamic>))
          .toList(growable: false),
      pairs: (json['pairs'] as List<dynamic>? ?? <dynamic>[])
          .map((dynamic e) => DataPair.fromJson(e as List<dynamic>))
          .toList(growable: false),
      xName: json['xName'] as String? ?? '',
      yName: json['yName'] as String? ?? '',
      xUnit: json['xUnit'] as String? ?? '',
      yUnit: json['yUnit'] as String? ?? '',
      note: json['note'] as String?,
    );
  }
}
