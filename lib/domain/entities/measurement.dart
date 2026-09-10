/// Escala de medición de una variable (Stevens).
///
/// Es la primera decisión estadística real que toma un estudiante y la que más
/// silenciosamente arruina un análisis: calcular la media de un código postal
/// es un error de escala, no de aritmética.
enum MeasurementScale {
  nominal,
  ordinal,
  interval,
  ratio;

  static MeasurementScale fromKey(String key) {
    switch (key) {
      case 'nominal':
        return MeasurementScale.nominal;
      case 'ordinal':
        return MeasurementScale.ordinal;
      case 'intervalo':
      case 'interval':
        return MeasurementScale.interval;
      case 'razon':
      case 'ratio':
        return MeasurementScale.ratio;
      default:
        throw ArgumentError('Escala de medición desconocida: $key');
    }
  }

  String get label {
    switch (this) {
      case MeasurementScale.nominal:
        return 'Nominal';
      case MeasurementScale.ordinal:
        return 'Ordinal';
      case MeasurementScale.interval:
        return 'De intervalo';
      case MeasurementScale.ratio:
        return 'De razón';
    }
  }

  String get shortDescription {
    switch (this) {
      case MeasurementScale.nominal:
        return 'Solo distingue categorías. No hay orden.';
      case MeasurementScale.ordinal:
        return 'Hay orden, pero la distancia entre valores no es comparable.';
      case MeasurementScale.interval:
        return 'La distancia es comparable, pero el cero es convencional.';
      case MeasurementScale.ratio:
        return 'Hay cero absoluto: las razones tienen sentido.';
    }
  }

  /// Medidas de tendencia central admisibles en esta escala.
  List<String> get allowedCentralMeasures {
    switch (this) {
      case MeasurementScale.nominal:
        return const <String>['moda'];
      case MeasurementScale.ordinal:
        return const <String>['moda', 'mediana'];
      case MeasurementScale.interval:
      case MeasurementScale.ratio:
        return const <String>['moda', 'mediana', 'media'];
    }
  }
}

/// Naturaleza de la variable, independiente de la escala.
enum VariableKind {
  qualitative,
  discrete,
  continuous;

  static VariableKind fromKey(String key) {
    switch (key) {
      case 'cualitativa':
      case 'qualitative':
        return VariableKind.qualitative;
      case 'cuantitativa_discreta':
      case 'discrete':
        return VariableKind.discrete;
      case 'cuantitativa_continua':
      case 'continuous':
        return VariableKind.continuous;
      default:
        throw ArgumentError('Tipo de variable desconocido: $key');
    }
  }

  String get label {
    switch (this) {
      case VariableKind.qualitative:
        return 'Cualitativa';
      case VariableKind.discrete:
        return 'Cuantitativa discreta';
      case VariableKind.continuous:
        return 'Cuantitativa continua';
    }
  }
}

/// Competencia que ejercita una actividad. Se declara por ejercicio para poder
/// informar al estudiante en qué competencia está flojo, no solo en qué tema.
enum Competency {
  descriptiveAnalysis,
  interpretation,
  decisionMaking;

  static Competency fromKey(String key) {
    switch (key) {
      case 'analisis_descriptivo':
        return Competency.descriptiveAnalysis;
      case 'interpretacion':
        return Competency.interpretation;
      case 'toma_decisiones':
        return Competency.decisionMaking;
      default:
        throw ArgumentError('Competencia desconocida: $key');
    }
  }

  String get key {
    switch (this) {
      case Competency.descriptiveAnalysis:
        return 'analisis_descriptivo';
      case Competency.interpretation:
        return 'interpretacion';
      case Competency.decisionMaking:
        return 'toma_decisiones';
    }
  }

  String get label {
    switch (this) {
      case Competency.descriptiveAnalysis:
        return 'Análisis descriptivo';
      case Competency.interpretation:
        return 'Interpretación';
      case Competency.decisionMaking:
        return 'Toma de decisiones';
    }
  }
}
