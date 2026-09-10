import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import 'chart_kit.dart';

/// Gráfico de líneas para series temporales.
///
/// Expone [axisMin] y [axisMax] a propósito: son el mando con el que el
/// laboratorio del módulo 5 trunca el eje en vivo. En el resto de la app se
/// dejan en nulo y el eje se calcula desde cero.
class LineChart extends StatelessWidget {
  const LineChart({
    super.key,
    required this.values,
    this.labels = const <String>[],
    this.color = AppColors.modGraficos,
    this.axisMin,
    this.axisMax,
    this.zeroBased = true,
    this.fill = true,
    this.height = 230,
    this.title,
    this.subtitle,
    this.xTitle = '',
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final double? axisMin;
  final double? axisMax;
  final bool zeroBased;
  final bool fill;
  final double height;
  final String? title;
  final String? subtitle;
  final String xTitle;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      child: CustomPaint(
        painter: _LinePainter(
          values: values,
          labels: labels,
          color: color,
          theme: ChartTheme.of(context),
          axisMin: axisMin,
          axisMax: axisMax,
          zeroBased: zeroBased,
          fill: fill,
          xTitle: xTitle,
        ),
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.values,
    required this.labels,
    required this.color,
    required this.theme,
    required this.axisMin,
    required this.axisMax,
    required this.zeroBased,
    required this.fill,
    required this.xTitle,
  });

  final List<double> values;
  final List<String> labels;
  final Color color;
  final ChartTheme theme;
  final double? axisMin;
  final double? axisMax;
  final bool zeroBased;
  final bool fill;
  final String xTitle;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final Rect plot = Rect.fromLTRB(
        40, 12, size.width - 10, size.height - (xTitle.isEmpty ? 26 : 38));
    if (plot.width <= 10 || plot.height <= 10) return;

    final double dataLo = values.reduce(math.min);
    final double dataHi = values.reduce(math.max);
    final AxisRange range = (axisMin != null || axisMax != null)
        ? AxisRange.exact(axisMin ?? dataLo, axisMax ?? dataHi, desired: 4)
        : AxisRange.nice(dataLo, dataHi, desired: 4, zeroBased: zeroBased);

    paintValueAxis(canvas, plot, range, theme);

    double xOf(int i) => values.length == 1
        ? plot.center.dx
        : plot.left + i / (values.length - 1) * plot.width;
    double yOf(double v) =>
        plot.bottom - (v - range.min) / range.span * plot.height;

    final Path path = Path();
    for (int i = 0; i < values.length; i++) {
      final Offset o = Offset(xOf(i), yOf(values[i]).clamp(plot.top, plot.bottom));
      if (i == 0) {
        path.moveTo(o.dx, o.dy);
      } else {
        path.lineTo(o.dx, o.dy);
      }
    }

    if (fill) {
      final Path area = Path.from(path)
        ..lineTo(xOf(values.length - 1), plot.bottom)
        ..lineTo(xOf(0), plot.bottom)
        ..close();
      canvas.drawPath(
        area,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              color.withValues(alpha: 0.28),
              color.withValues(alpha: 0.02),
            ],
          ).createShader(plot),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );

    for (int i = 0; i < values.length; i++) {
      final Offset o = Offset(xOf(i), yOf(values[i]).clamp(plot.top, plot.bottom));
      canvas.drawCircle(o, 3.2, Paint()..color = color);
      canvas.drawCircle(
          o,
          3.2,
          Paint()
            ..color = theme.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    final int step = math.max(1, (values.length / 6).ceil());
    for (int i = 0; i < values.length; i += step) {
      final String label =
          i < labels.length ? labels[i] : Num.axis((i + 1).toDouble());
      paintLabel(canvas, label, Offset(xOf(i), plot.bottom + 5),
          color: theme.label, anchorAlign: Alignment.topCenter, maxWidth: 54);
    }

    if (xTitle.isNotEmpty) {
      paintLabel(canvas, xTitle, Offset(plot.center.dx, size.height - 13),
          color: theme.label,
          size: 11,
          weight: FontWeight.w600,
          anchorAlign: Alignment.topCenter,
          maxWidth: plot.width);
    }
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.values != values ||
      old.axisMin != axisMin ||
      old.axisMax != axisMax ||
      old.fill != fill;
}
