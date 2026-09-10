import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/descriptive_stats.dart';
import 'chart_kit.dart';

class BoxSeries {
  const BoxSeries(this.label, this.stats, this.color);

  final String label;
  final DescriptiveStats stats;
  final Color color;
}

/// Diagrama de caja y bigotes, uno o varios en paralelo.
///
/// Los bigotes llegan al dato más extremo *dentro* de las vallas de Tukey, no
/// al mínimo y máximo absolutos. Es la definición correcta y la que hace que
/// los atípicos aparezcan como puntos sueltos, que es todo el valor del
/// gráfico para este curso.
class BoxPlotChart extends StatelessWidget {
  const BoxPlotChart({
    super.key,
    required this.series,
    this.height = 200,
    this.title,
    this.subtitle,
    this.unit = '',
  });

  final List<BoxSeries> series;
  final double height;
  final String? title;
  final String? subtitle;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final bool anyOutlier =
        series.any((BoxSeries s) => s.stats.hasOutliers);
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      legend: <ChartLegendEntry>[
        const ChartLegendEntry('Mediana', AppColors.median),
        if (anyOutlier) const ChartLegendEntry('Atípico', AppColors.outlier),
      ],
      child: CustomPaint(
        painter: _BoxPainter(
          series: series,
          theme: ChartTheme.of(context),
          unit: unit,
        ),
      ),
    );
  }
}

class _BoxPainter extends CustomPainter {
  _BoxPainter({required this.series, required this.theme, required this.unit});

  final List<BoxSeries> series;
  final ChartTheme theme;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (series.isEmpty) return;

    final double labelWidth = (size.width * 0.24).clamp(56.0, 110.0);
    final Rect plot =
        Rect.fromLTRB(labelWidth, 12, size.width - 10, size.height - 22);
    if (plot.width <= 10 || plot.height <= 10) return;

    double lo = double.infinity;
    double hi = double.negativeInfinity;
    for (final BoxSeries s in series) {
      lo = lo < s.stats.min ? lo : s.stats.min;
      hi = hi > s.stats.max ? hi : s.stats.max;
    }
    final AxisRange range = AxisRange.nice(lo, hi, desired: 4);
    double xOf(double v) =>
        plot.left + (v - range.min) / range.span * plot.width;

    final Paint grid = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;
    for (final double tick in range.ticks) {
      final double x = xOf(tick);
      if (x < plot.left - 0.5 || x > plot.right + 0.5) continue;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      paintLabel(canvas, Num.axis(tick), Offset(x, plot.bottom + 4),
          color: theme.label, anchorAlign: Alignment.topCenter, maxWidth: 64);
    }

    final double slot = plot.height / series.length;
    final double boxH = (slot * 0.44).clamp(16.0, 42.0);

    for (int i = 0; i < series.length; i++) {
      final BoxSeries s = series[i];
      final DescriptiveStats st = s.stats;
      final double cy = plot.top + slot * (i + 0.5);

      // Extremos de los bigotes: dato más lejano dentro de las vallas.
      double whiskerLow = st.max;
      double whiskerHigh = st.min;
      for (final double v in st.sorted) {
        if (v >= st.lowerFence && v <= st.upperFence) {
          if (v < whiskerLow) whiskerLow = v;
          if (v > whiskerHigh) whiskerHigh = v;
        }
      }
      if (whiskerLow > whiskerHigh) {
        whiskerLow = st.min;
        whiskerHigh = st.max;
      }

      final Paint line = Paint()
        ..color = s.color
        ..strokeWidth = 1.6
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(
          Offset(xOf(whiskerLow), cy), Offset(xOf(st.q1), cy), line);
      canvas.drawLine(
          Offset(xOf(st.q3), cy), Offset(xOf(whiskerHigh), cy), line);
      for (final double w in <double>[whiskerLow, whiskerHigh]) {
        canvas.drawLine(Offset(xOf(w), cy - boxH * 0.28),
            Offset(xOf(w), cy + boxH * 0.28), line);
      }

      final Rect box = Rect.fromLTRB(
          xOf(st.q1), cy - boxH / 2, xOf(st.q3), cy + boxH / 2);
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(4)),
        Paint()..color = s.color.withValues(alpha: 0.28),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(box, const Radius.circular(4)),
        Paint()
          ..color = s.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );

      canvas.drawLine(
        Offset(xOf(st.median), box.top),
        Offset(xOf(st.median), box.bottom),
        Paint()
          ..color = AppColors.median
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round,
      );

      for (final double o in st.outliers) {
        canvas.drawCircle(Offset(xOf(o), cy), 3.4,
            Paint()..color = AppColors.outlier);
        canvas.drawCircle(
            Offset(xOf(o), cy),
            3.4,
            Paint()
              ..color = theme.surface
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1);
      }

      paintLabel(canvas, s.label, Offset(plot.left - 8, cy),
          color: theme.emphasis,
          size: 11,
          weight: FontWeight.w600,
          anchorAlign: Alignment.centerRight,
          align: TextAlign.right,
          maxWidth: labelWidth - 12);
    }
  }

  @override
  bool shouldRepaint(covariant _BoxPainter old) => old.series != series;
}
