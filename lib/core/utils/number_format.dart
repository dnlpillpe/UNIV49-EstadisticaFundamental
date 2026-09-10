/// Formateo numérico con convenciones locales del español: coma decimal y
/// espacio fino como separador de millares.
///
/// No se usa el paquete `intl` para esto. Sería una dependencia más para
/// resolver un caso que cabe en cuarenta líneas, y en una app cuyo contenido
/// está escrito en un solo idioma la localización completa no aporta nada.
class Num {
  const Num._();

  /// Formatea con [decimals] decimales fijos.
  static String fixed(double value, int decimals) {
    if (value.isNaN) return '—';
    if (value.isInfinite) return value.isNegative ? '−∞' : '∞';
    final String raw = value.toStringAsFixed(decimals);
    return _localize(raw);
  }

  /// Formatea eligiendo automáticamente los decimales: los enteros se muestran
  /// sin decimales y el resto con dos, que es la precisión con la que se
  /// trabaja en estadística descriptiva de un curso general.
  static String auto(double value) {
    if (value.isNaN) return '—';
    if (value.isInfinite) return value.isNegative ? '−∞' : '∞';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return _localize(value.toStringAsFixed(0));
    }
    if (value.abs() >= 1000) return _localize(value.toStringAsFixed(1));
    if (value.abs() >= 10) return _localize(value.toStringAsFixed(2));
    return _localize(value.toStringAsFixed(3));
  }

  /// Versión compacta para etiquetas de ejes, donde el espacio es escaso.
  static String axis(double value) {
    if (value.isNaN) return '';
    final double a = value.abs();
    if (a >= 1000000) return '${_localize((value / 1000000).toStringAsFixed(1))}M';
    if (a >= 1000) return '${_localize((value / 1000).toStringAsFixed(a >= 10000 ? 0 : 1))}k';
    if (value == value.roundToDouble()) return _localize(value.toStringAsFixed(0));
    if (a >= 10) return _localize(value.toStringAsFixed(1));
    return _localize(value.toStringAsFixed(2));
  }

  static String percent(double value, {int decimals = 1}) =>
      '${fixed(value, decimals)} %';

  static String signed(double value, {int decimals = 2}) {
    final String base = fixed(value.abs(), decimals);
    if (value > 0) return '+$base';
    if (value < 0) return '−$base';
    return base;
  }

  /// Coma decimal y separador de millares con espacio fino (U+2009), que es la
  /// convención tipográfica correcta en español y no se confunde con un punto.
  static String _localize(String raw) {
    final bool negative = raw.startsWith('-');
    final String body = negative ? raw.substring(1) : raw;
    final List<String> parts = body.split('.');
    final String intPart = parts.first;
    final StringBuffer grouped = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      final int fromEnd = intPart.length - i;
      grouped.write(intPart[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1 && intPart.length > 4) {
        grouped.write(' ');
      }
    }
    final String result =
        parts.length > 1 ? '$grouped,${parts[1]}' : grouped.toString();
    return negative ? '−$result' : result;
  }
}
