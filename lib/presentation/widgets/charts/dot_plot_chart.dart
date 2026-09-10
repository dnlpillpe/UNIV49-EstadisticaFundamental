import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/descriptive_stats.dart';
import 'chart_kit.dart';

/// Diagrama de puntos: un punto por observación, apilados cuando se repiten.
///
/// Es el gráfico más honesto para conjuntos pequeños porque no agrupa nada: el
/// estudiante ve los datos reales, no una versión resumida. En el laboratorio
/// del valor atípico es el gráfico principal, porque permite seguir con la
/// vista el dato que se está arrastrando.
class DotPlotChart extends StatelessWidget {
  const DotPlotChart({
    super.key,
    required this.values,
    this.stats,
    this.color = AppColors.modCentrales,
    this.showMean = true,
    this.showMedian = true,
    this.highlightValue,
    this.height = 190,
    this.title,
    this.subtitle,
  });

  final List<double> values;
  final DescriptiveStats? stats;
  final Color color;
  final bool showMean;
  final bool showMedian;

  /// Valor que se resalta (el que el estudiante está moviendo en el laboratorio).
  final double? highlightValue;
  final double height;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final List<ChartLegendEntry> legend = <ChartLegendEntry>[];
    if (stats != null && showMean) {
      legend.add(ChartLegendEntry(
          'Media ${Num.auto(stats!.mean)}', AppColors.mean,
          dashed: true));
    }
    if (stats != null && showMedian) {
      legend.add(ChartLegendEntry(
          'Mediana ${Num.auto(stats!.median)}', AppColors.median,
          dashed: true));
    }
    if (stats != null && stats!.hasOutliers) {
      legend.add(const ChartLegendEntry('Atípico', AppColors.outlier));
    }
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      legend: legend,
      child: CustomPaint(
        painter: _DotPainter(
          values: values,
          stats: stats,
          color: color,
          theme: ChartTheme.of(context),
          showMean: showMean,
          showMedian: showMedian,
          highlightValue: highlightValue,
        ),
      ),
    );
  }
}

class _DotPainter extends CustomPainter {
  _DotPainter({
    required this.values,
    required this.stats,
    required this.color,
    required this.theme,
    required this.showMean,
    required this.showMedian,
    required this.highlightValue,
  });

  final List<double> values;
  final DescriptiveStats? stats;
  final Color color;
  final ChartTheme theme;
  final bool showMean;
  final bool showMedian;
  final double? highlightValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final Rect plot =
        Rect.fromLTRB(10, 22, size.width - 10, size.height - 24);
    if (plot.width <= 10 || plot.height <= 10) return;

    final double lo = values.reduce(math.min);
    final double hi = values.reduce(math.max);
    final AxisRange range = AxisRange.nice(lo, hi, desired: 5);
    double xOf(double v) =>
        plot.left + (v - range.min) / range.span * plot.width;

    final Paint axis = Paint()
      ..color = theme.axis
      ..strokeWidth = 1.4;
    canvas.drawLine(Offset(plot.left, plot.bottom),
        Offset(plot.right, plot.bottom), axis);

    for (final double tick in range.ticks) {
      final double x = xOf(tick);
      if (x < plot.left - 0.5 || x > plot.right + 0.5) continue;
      canvas.drawLine(Offset(x, plot.bottom), Offset(x, plot.bottom + 4),
          Paint()..color = theme.axis..strokeWidth = 1);
      paintLabel(canvas, Num.axis(tick), Offset(x, plot.bottom + 6),
          color: theme.label, anchorAlign: Alignment.topCenter, maxWidth: 60);
    }

    // Apilado: se agrupan valores que caerían en el mismo píxel para que la
    // altura de la pila represente la frecuencia local.
    final double radius = (plot.width / (values.length * 2.6)).clamp(3.0, 7.0);
    final Map<int, int> stackCount = <int, int>{};
    final List<double> sorted = List<double>.of(values)..sort();

    for (final double v in sorted) {
      final double x = xOf(v);
      final int bucket = (x / (radius * 2.05)).round();
      final int level = stackCount[bucket] ?? 0;
      stackCount[bucket] = level + 1;
      final double y = plot.bottom - radius - level * (radius * 2.15);
      if (y < plot.top - radius) continue;

      final bool isOutlier = stats?.outliers.contains(v) ?? false;
      final bool isHighlight =
          highlightValue != null && (v - highlightValue!).abs() < 1e-9;

      canvas.drawCircle(
        Offset(x, y),
        isHighlight ? radius + 1.6 : radius,
        Paint()
          ..color = isOutlier
              ? AppColors.outlier
              : (isHighlight ? AppColors.warning : color),
      );
      if (isHighlight) {
        canvas.drawCircle(
          Offset(x, y),
          radius + 3.4,
          Paint()
            ..color = AppColors.warning
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.8,
        );
      }
    }

    if (stats != null && showMean) {
      paintReferenceLine(canvas, plot,
          position: xOf(stats!.mean).clamp(plot.left, plot.right),
          color: AppColors.mean,
          label: 'x̄',
          theme: theme);
    }
    if (stats != null && showMedian) {
      paintReferenceLine(canvas, plot,
          position: xOf(stats!.median).clamp(plot.left, plot.right),
          color: AppColors.median,
          label: 'Me',
          theme: theme,
          labelOffset: -12);
    }
  }

  @override
  bool shouldRepaint(covariant _DotPainter old) =>
      old.values != values ||
      old.stats != stats ||
      old.highlightValue != highlightValue;
}
