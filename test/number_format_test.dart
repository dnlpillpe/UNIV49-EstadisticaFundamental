import 'package:estadistica_fundamental/core/utils/number_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Formato en español', () {
    test('usa coma decimal', () {
      expect(Num.fixed(13.15, 2), '13,15');
      expect(Num.fixed(0.5, 1), '0,5');
    });

    test('los enteros no llevan decimales en modo automático', () {
      expect(Num.auto(138), '138');
      expect(Num.auto(40), '40');
    });

    test('separa millares a partir de cinco cifras', () {
      // El separador es el espacio fino U+2009, no un espacio normal: se
      // escribe escapado para que ningún editor lo convierta por el camino.
      expect(Num.fixed(14000, 0), '14 000');
      expect(Num.fixed(1250, 0), '1250');
    });

    test('el signo menos es el tipográfico, no el guion', () {
      expect(Num.fixed(-51.7, 1), '−51,7');
      expect(Num.signed(-2.5), '−2,50');
      expect(Num.signed(2.5), '+2,50');
      expect(Num.signed(0), '0,00');
    });

    test('NaN e infinito se muestran, no rompen', () {
      expect(Num.fixed(double.nan, 2), '—');
      expect(Num.auto(double.nan), '—');
      expect(Num.auto(double.infinity), '∞');
    });

    test('las etiquetas de eje se compactan', () {
      expect(Num.axis(2600), '2,6k');
      expect(Num.axis(1500000), '1,5M');
      expect(Num.axis(40), '40');
    });

    test('porcentajes', () {
      expect(Num.percent(68.42), '68,4 %');
      expect(Num.percent(100, decimals: 0), '100 %');
    });
  });
}
