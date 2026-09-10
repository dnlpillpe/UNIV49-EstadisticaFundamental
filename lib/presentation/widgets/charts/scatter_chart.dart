import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/entities/descriptive_stats.dart';
import 'chart_kit.dart';

/// Gráfico de dispersión con recta de mínimos cuadrados opcional.
class ScatterChart extends StatelessWidget {
  const ScatterChart({
    super.key,
    required this.pairs,
    this.fit,
    this.xName = '',
    this.yName = '',
    this.color = AppColors.modGraficos,
    this.showFit = true,
    this.height = 250,
    this.title,
    this.subtitle,
  });

  final List<DataPair> pairs;
  final LinearFit? fit;
  final String xName;
  final String yName;
  final Color color;
  final bool showFit;
  final double height;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      legend: <ChartLegendEntry>[
        ChartLegendEntry('Observaciones (${pairs.length})', color),
        if (showFit && fit != null && !fit!.correlation.isNaN)
          ChartLegendEntry(
              'Recta de ajuste · r = ${Num.fixed(fit!.correlation, 2)}',
              AppColors.warning,
              dashed: true),
      ],
      child: CustomPaint(
        painter: _ScatterPainter(
          pairs: pairs,
          fit: showFit ? fit : null,
          xName: xName,
          yName: yName,
          color: color,
          theme: ChartTheme.of(context),
        ),
      ),
    );
  }
}

class _ScatterPainter extends CustomPainter {
  _ScatterPainter({
    required this.pairs,
    required this.fit,
    required this.xName,
    required this.yName,
    required this.color,
    required this.theme,
  });

  final List<DataPair> pairs;
  final LinearFit? fit;
  final String xName;
  final String yName;
  final Color color;
  final ChartTheme theme;

  @override
  void paint(Canvas canvas, Size size) {
    if (pairs.isEmpty) return;

    final Rect plot =
        Rect.fromLTRB(40, 10, size.width - 10, size.height - 38);
    if (plot.width <= 10 || plot.height <= 10) return;

    final double xLo = pairs.map((DataPair p) => p.x).reduce(math.min);
    final double xHi = pairs.map((DataPair p) => p.x).reduce(math.max);
    final double yLo = pairs.map((DataPair p) => p.y).reduce(math.min);
    final double yHi = pairs.map((DataPair p) => p.y).reduce(math.max);

    final AxisRange xr = AxisRange.nice(xLo, xHi, desired: 5);
    final AxisRange yr = AxisRange.nice(yLo, yHi, desired: 4);

    double xOf(double v) => plot.left + (v - xr.min) / xr.span * plot.width;
    double yOf(double v) => plot.bottom - (v - yr.min) / yr.span * plot.height;

    paintValueAxis(canvas, plot, yr, theme);

    final Paint grid = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;
    for (final double tick in xr.ticks) {
      final double x = xOf(tick);
      if (x < plot.left - 0.5 || x > plot.right + 0.5) continue;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      paintLabel(canvas, Num.axis(tick), Offset(x, plot.bottom + 5),
          color: theme.label, anchorAlign: Alignment.topCenter, maxWidth: 60);
    }

    if (fit != null && !fit!.slope.isNaN) {
      final double y1 = fit!.intercept + fit!.slope * xr.min;
      final double y2 = fit!.intercept + fit!.slope * xr.max;
      canvas.save();
      canvas.clipRect(plot);
      canvas.drawLine(
        Offset(xOf(xr.min), yOf(y1)),
        Offset(xOf(xr.max), yOf(y2)),
        Paint()
          ..color = AppColors.warning
          ..strokeWidth = 2.2
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    for (final DataPair p in pairs) {
      final Offset o = Offset(xOf(p.x), yOf(p.y));
      canvas.drawCircle(o, 4.6, Paint()..color = color.withValues(alpha: 0.75));
      canvas.drawCircle(
          o,
          4.6,
          Paint()
            ..color = theme.surface
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2);
    }

    if (xName.isNotEmpty) {
      paintLabel(canvas, xName, Offset(plot.center.dx, size.height - 14),
          color: theme.label,
          size: 11,
          weight: FontWeight.w600,
          anchorAlign: Alignment.topCenter,
          maxWidth: plot.width);
    }
    if (yName.isNotEmpty) {
      paintLabel(canvas, yName, Offset(12, plot.center.dy),
          color: theme.label,
          size: 11,
          weight: FontWeight.w600,
          angle: -math.pi / 2,
          maxWidth: plot.height);
    }
  }

  @override
  bool shouldRepaint(covariant _ScatterPainter old) =>
      old.pairs != pairs || old.fit != fit;
}
