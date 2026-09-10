/// Constantes de identidad de la aplicación.
class AppInfo {
  const AppInfo._();

  static const String name = 'Estadística Fundamental';
  static const String tagline = 'Aprende a interpretar datos, no solo a calcularlos';
  static const String version = '1.0.0';
  static const String area = 'Estadística universitaria';
  static const String audience = 'Estudiantes de todas las carreras';

  /// Método de cálculo de cuantiles, declarado dentro de la app.
  static const String quantileMethod =
      'Interpolación lineal sobre la posición (n − 1)·p, equivalente a '
      'PERCENTIL.INC de Excel y Google Sheets (tipo 7 de Hyndman–Fan).';
}
