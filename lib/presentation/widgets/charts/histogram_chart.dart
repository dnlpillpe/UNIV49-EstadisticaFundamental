import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/descriptive_stats.dart';
import '../../../domain/entities/frequency_table.dart';
import 'chart_kit.dart';

/// Histograma con barras contiguas.
///
/// Las barras se tocan a propósito y el widget no ofrece opción de separarlas:
/// la separación significa "variable categórica", y permitir dibujar un
/// histograma con huecos sería enseñar el error que el módulo 5 corrige.
class HistogramChart extends StatelessWidget {
  const HistogramChart({
    super.key,
    required this.table,
    this.stats,
    this.color = AppColors.modDatos,
    this.showMean = false,
    this.showMedian = false,
    this.useRelative = false,
    this.height = 230,
    this.title,
    this.subtitle,
  });

  final FrequencyTable table;
  final DescriptiveStats? stats;
  final Color color;
  final bool showMean;
  final bool showMedian;
  final bool useRelative;
  final double height;
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final List<ChartLegendEntry> legend = <ChartLegendEntry>[];
    if (showMean && stats != null) {
      legend.add(ChartLegendEntry(
          'Media ${Num.auto(stats!.mean)}', AppColors.mean,
          dashed: true));
    }
    if (showMedian && stats != null) {
      legend.add(ChartLegendEntry(
          'Mediana ${Num.auto(stats!.median)}', AppColors.median,
          dashed: true));
    }
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      legend: legend,
      child: CustomPaint(
        painter: _HistogramPainter(
          table: table,
          stats: stats,
          color: color,
          theme: ChartTheme.of(context),
          showMean: showMean,
          showMedian: showMedian,
          useRelative: useRelative,
        ),
      ),
    );
  }
}

class _HistogramPainter extends CustomPainter {
  _HistogramPainter({
    required this.table,
    required this.stats,
    required this.color,
    required this.theme,
    required this.showMean,
    required this.showMedian,
    required this.useRelative,
  });

  final FrequencyTable table;
  final DescriptiveStats? stats;
  final Color color;
  final ChartTheme theme;
  final bool showMean;
  final bool showMedian;
  final bool useRelative;

  @override
  void paint(Canvas canvas, Size size) {
    if (table.rows.isEmpty) return;

    const double leftPad = 38;
    const double bottomPad = 34;
    const double topPad = 18;
    final Rect plot = Rect.fromLTRB(
        leftPad, topPad, size.width - 8, size.height - bottomPad);
    if (plot.width <= 0 || plot.height <= 0) return;

    final double maxValue = table.rows
        .map((FrequencyRow r) => useRelative ? r.relative * 100 : r.absolute.toDouble())
        .reduce((double a, double b) => a > b ? a : b);
    final AxisRange yRange =
        AxisRange.nice(0, maxValue, desired: 4, zeroBased: true);

    paintValueAxis(canvas, plot, yRange, theme,
        format: useRelative ? (double v) => '${Num.axis(v)}%' : Num.axis);

    // Escala horizontal: continua, desde el límite inferior de la primera clase
    // hasta el superior de la última. Así el ancho de cada barra es proporcional
    // al ancho real de su intervalo, que es lo que hace comparable el área.
    final double xMin = table.rows.first.lowerBound;
    final double xMax = table.rows.last.upperBound;
    final double xSpan = xMax - xMin == 0 ? 1 : xMax - xMin;

    double xOf(double v) => plot.left + (v - xMin) / xSpan * plot.width;
    double yOf(double v) =>
        plot.bottom - (v - yRange.min) / yRange.span * plot.height;

    for (int i = 0; i < table.rows.length; i++) {
      final FrequencyRow r = table.rows[i];
      final double value = useRelative ? r.relative * 100 : r.absolute.toDouble();
      final double left = xOf(r.lowerBound);
      final double right = xOf(r.upperBound);
      final Rect bar = Rect.fromLTRB(left, yOf(value), right, plot.bottom);
      if (bar.height > 0.5) {
        final Paint fill = Paint()..shader = barShader(color, bar);
        canvas.drawRRect(
          RRect.fromRectAndCorners(bar,
              topLeft: const Radius.circular(3),
              topRight: const Radius.circular(3)),
          fill,
        );
      }
      // Separador fino entre clases: el histograma va pegado, pero el ojo
      // necesita distinguir dónde acaba una clase y empieza la siguiente.
      canvas.drawLine(
        Offset(right, plot.bottom),
        Offset(right, bar.top),
        Paint()
          ..color = theme.surface.withValues(alpha: 0.85)
          ..strokeWidth = 1,
      );
      if (r.absolute > 0 && bar.height > 16 && bar.width > 22) {
        paintLabel(
          canvas,
          useRelative ? '${Num.fixed(r.relative * 100, 1)}%' : '${r.absolute}',
          Offset(bar.center.dx, bar.top + 4),
          color: Colors.white,
          size: 10,
          weight: FontWeight.w700,
          anchorAlign: Alignment.topCenter,
          maxWidth: bar.width,
        );
      }
    }

    // Etiquetas del eje horizontal: solo los límites de clase, girados si el
    // espacio no alcanza.
    final bool tight = plot.width / table.rows.length < 52;
    for (int i = 0; i <= table.rows.length; i++) {
      final double bound = i == table.rows.length
          ? table.rows.last.upperBound
          : table.rows[i].lowerBound;
      if (tight && i.isOdd && i != table.rows.length) continue;
      paintLabel(
        canvas,
        Num.axis(bound),
        Offset(xOf(bound), plot.bottom + 6),
        color: theme.label,
        anchorAlign: Alignment.topCenter,
        maxWidth: 60,
      );
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
  bool shouldRepaint(covariant _HistogramPainter old) =>
      old.table != table ||
      old.stats != stats ||
      old.color != color ||
      old.showMean != showMean ||
      old.showMedian != showMedian ||
      old.useRelative != useRelative;
}
