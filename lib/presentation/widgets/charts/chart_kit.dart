import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/utils/number_format.dart';

/// Utilidades compartidas por todos los gráficos.
///
/// Los gráficos de esta app se dibujan con `CustomPainter` propio y no con una
/// librería. Tres razones, en orden de peso:
///
/// 1. **Control pedagógico.** El histograma necesita marcar la media y la
///    mediana con colores fijos, el diagrama de caja necesita pintar las vallas
///    de Tukey y el laboratorio del eje truncado necesita mover el origen del
///    eje en vivo. Todo eso es exactamente lo que las librerías generalistas
///    hacen difícil.
/// 2. **Cero riesgo de versión.** Una dependencia de gráficos es la que más
///    probabilidades tiene de romper el build dentro de un año.
/// 3. **Tamaño.** Son unas mil líneas de Dart frente a un paquete completo.
class ChartTheme {
  const ChartTheme({
    required this.axis,
    required this.grid,
    required this.label,
    required this.surface,
    required this.emphasis,
  });

  final Color axis;
  final Color grid;
  final Color label;
  final Color surface;
  final Color emphasis;

  factory ChartTheme.of(BuildContext context) {
    final ColorScheme s = Theme.of(context).colorScheme;
    return ChartTheme(
      axis: s.outline,
      grid: s.outlineVariant.withValues(alpha: 0.55),
      label: s.onSurfaceVariant,
      surface: s.surface,
      emphasis: s.onSurface,
    );
  }
}

/// Rango de un eje con marcas "redondas".
class AxisRange {
  const AxisRange(this.min, this.max, this.ticks);

  final double min;
  final double max;
  final List<double> ticks;

  double get span => max - min == 0 ? 1 : max - min;

  /// Calcula un rango legible que contenga [lo, hi].
  ///
  /// Si [zeroBased] es cierto el eje arranca en cero: es la regla para gráficos
  /// de barras, donde el lector compara longitudes. El laboratorio del módulo 5
  /// desactiva esta opción a propósito para mostrar el efecto del eje truncado.
  factory AxisRange.nice(double lo, double hi,
      {int desired = 5, bool zeroBased = false}) {
    if (zeroBased && lo > 0) lo = 0;
    if (zeroBased && hi < 0) hi = 0;
    if (lo == hi) {
      lo = lo - 1;
      hi = hi + 1;
    }
    final double rawStep = (hi - lo) / math.max(1, desired);
    final double magnitude =
        math.pow(10, (math.log(rawStep) / math.ln10).floor()).toDouble();
    final double residual = rawStep / magnitude;
    final double step = residual > 5
        ? 10 * magnitude
        : residual > 2
            ? 5 * magnitude
            : residual > 1
                ? 2 * magnitude
                : magnitude;
    final double niceMin = (lo / step).floor() * step;
    final double niceMax = (hi / step).ceil() * step;
    final List<double> ticks = <double>[];
    for (double v = niceMin; v <= niceMax + step * 0.5; v += step) {
      // Se redondea para evitar residuos de coma flotante del tipo 0.30000000004.
      ticks.add(double.parse(v.toStringAsFixed(8)));
    }
    return AxisRange(niceMin, niceMax, ticks);
  }

  /// Rango exacto, sin redondear. Lo usa el laboratorio del eje truncado.
  factory AxisRange.exact(double lo, double hi, {int desired = 5}) {
    if (lo == hi) {
      lo -= 1;
      hi += 1;
    }
    final double step = (hi - lo) / desired;
    final List<double> ticks = <double>[];
    for (int i = 0; i <= desired; i++) {
      ticks.add(lo + step * i);
    }
    return AxisRange(lo, hi, ticks);
  }
}

/// Dibuja texto centrado en un punto o alineado a un borde.
void paintLabel(
  Canvas canvas,
  String text,
  Offset anchor, {
  required Color color,
  double size = 10,
  FontWeight weight = FontWeight.w500,
  TextAlign align = TextAlign.center,
  Alignment anchorAlign = Alignment.center,
  double maxWidth = 200,
  double angle = 0,
}) {
  final TextPainter tp = TextPainter(
    text: TextSpan(
      text: text,
      style: TextStyle(color: color, fontSize: size, fontWeight: weight),
    ),
    textDirection: TextDirection.ltr,
    textAlign: align,
    maxLines: 2,
    ellipsis: '…',
  )..layout(maxWidth: maxWidth);

  final double dx = anchor.dx - tp.width * (anchorAlign.x + 1) / 2;
  final double dy = anchor.dy - tp.height * (anchorAlign.y + 1) / 2;

  if (angle == 0) {
    tp.paint(canvas, Offset(dx, dy));
    return;
  }
  canvas.save();
  canvas.translate(anchor.dx, anchor.dy);
  canvas.rotate(angle);
  tp.paint(canvas, Offset(-tp.width * (anchorAlign.x + 1) / 2,
      -tp.height * (anchorAlign.y + 1) / 2));
  canvas.restore();
}

/// Dibuja la rejilla horizontal y las etiquetas del eje vertical.
void paintValueAxis(
  Canvas canvas,
  Rect plot,
  AxisRange range,
  ChartTheme theme, {
  String Function(double)? format,
  bool drawGrid = true,
}) {
  final Paint gridPaint = Paint()
    ..color = theme.grid
    ..strokeWidth = 1;
  for (final double tick in range.ticks) {
    final double t = (tick - range.min) / range.span;
    final double y = plot.bottom - t * plot.height;
    if (y < plot.top - 0.5 || y > plot.bottom + 0.5) continue;
    if (drawGrid) {
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }
    paintLabel(
      canvas,
      (format ?? Num.axis)(tick),
      Offset(plot.left - 6, y),
      color: theme.label,
      anchorAlign: Alignment.centerRight,
      maxWidth: 60,
    );
  }
  final Paint axisPaint = Paint()
    ..color = theme.axis
    ..strokeWidth = 1.4;
  canvas.drawLine(
      Offset(plot.left, plot.top), Offset(plot.left, plot.bottom), axisPaint);
  canvas.drawLine(Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom), axisPaint);
}

/// Línea de referencia horizontal o vertical con etiqueta (media, mediana…).
void paintReferenceLine(
  Canvas canvas,
  Rect plot, {
  required double position,
  required Color color,
  required String label,
  required ChartTheme theme,
  bool vertical = true,
  bool dashed = true,
  double labelOffset = 0,
}) {
  final Paint p = Paint()
    ..color = color
    ..strokeWidth = 2
    ..strokeCap = StrokeCap.round;

  final Offset a = vertical
      ? Offset(position, plot.top)
      : Offset(plot.left, position);
  final Offset b = vertical
      ? Offset(position, plot.bottom)
      : Offset(plot.right, position);

  if (dashed) {
    _drawDashed(canvas, a, b, p);
  } else {
    canvas.drawLine(a, b, p);
  }

  final Offset labelAnchor = vertical
      ? Offset(position, plot.top - 4 + labelOffset)
      : Offset(plot.right - 2, position - 8 + labelOffset);
  paintLabel(
    canvas,
    label,
    labelAnchor,
    color: color,
    size: 10,
    weight: FontWeight.w700,
    anchorAlign: vertical ? Alignment.bottomCenter : Alignment.centerRight,
    maxWidth: 120,
  );
}

void _drawDashed(Canvas canvas, Offset a, Offset b, Paint paint,
    {double dash = 5, double gap = 4}) {
  final double total = (b - a).distance;
  if (total == 0) return;
  final Offset dir = (b - a) / total;
  double drawn = 0;
  while (drawn < total) {
    final double end = math.min(drawn + dash, total);
    canvas.drawLine(a + dir * drawn, a + dir * end, paint);
    drawn = end + gap;
  }
}

/// Contenedor común: título, altura fija y leyenda opcional.
class ChartFrame extends StatelessWidget {
  const ChartFrame({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.height = 220,
    this.legend = const <ChartLegendEntry>[],
  });

  final Widget child;
  final String? title;
  final String? subtitle;
  final double height;
  final List<ChartLegendEntry> legend;

  @override
  Widget build(BuildContext context) {
    final TextTheme t = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (title != null) ...<Widget>[
          Text(title!, style: t.titleSmall),
          const SizedBox(height: 2),
        ],
        if (subtitle != null) ...<Widget>[
          Text(subtitle!, style: t.bodySmall),
          const SizedBox(height: 8),
        ],
        SizedBox(height: height, width: double.infinity, child: child),
        if (legend.isNotEmpty) ...<Widget>[
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: legend
                .map((ChartLegendEntry e) => _LegendChip(entry: e))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

class ChartLegendEntry {
  const ChartLegendEntry(this.label, this.color, {this.dashed = false});

  final String label;
  final Color color;
  final bool dashed;
}

class _LegendChip extends StatelessWidget {
  const _LegendChip({required this.entry});

  final ChartLegendEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: entry.dashed ? 16 : 11,
          height: entry.dashed ? 3 : 11,
          decoration: BoxDecoration(
            color: entry.color,
            borderRadius: BorderRadius.circular(entry.dashed ? 2 : 3),
          ),
        ),
        const SizedBox(width: 6),
        Text(entry.label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

/// Gradiente vertical suave para las barras, que da profundidad sin recurrir a
/// sombras (que en pantallas pequeñas ensucian la lectura de longitudes).
ui.Shader barShader(Color color, Rect rect) => ui.Gradient.linear(
      rect.topCenter,
      rect.bottomCenter,
      <Color>[color, Color.lerp(color, Colors.black, 0.18)!],
    );
