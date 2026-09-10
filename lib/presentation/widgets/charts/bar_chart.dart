import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import 'chart_kit.dart';

class BarEntry {
  const BarEntry(this.label, this.value, {this.color, this.highlight = false});

  final String label;
  final double value;
  final Color? color;
  final bool highlight;
}

/// Gráfico de barras horizontales para variables cualitativas.
///
/// Horizontal y no vertical por una razón práctica: las etiquetas de categoría
/// ("Papel y cartón", "Ing. de Sistemas") no caben bajo una barra vertical en
/// pantalla de móvil, y girarlas 90° las vuelve ilegibles.
///
/// [zeroBased] está en `true` por defecto y solo el laboratorio del módulo 5
/// lo desactiva, para demostrar la distorsión.
class BarChart extends StatelessWidget {
  const BarChart({
    super.key,
    required this.entries,
    this.color = AppColors.modTablas,
    this.zeroBased = true,
    this.axisMin,
    this.showPercent = false,
    this.total,
    this.height = 230,
    this.title,
    this.subtitle,
    this.unit = '',
  });

  final List<BarEntry> entries;
  final Color color;
  final bool zeroBased;
  final double? axisMin;
  final bool showPercent;
  final int? total;
  final double height;
  final String? title;
  final String? subtitle;
  final String unit;

  @override
  Widget build(BuildContext context) {
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      child: CustomPaint(
        painter: _BarPainter(
          entries: entries,
          color: color,
          theme: ChartTheme.of(context),
          zeroBased: zeroBased,
          axisMin: axisMin,
          showPercent: showPercent,
          total: total,
          unit: unit,
        ),
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.entries,
    required this.color,
    required this.theme,
    required this.zeroBased,
    required this.axisMin,
    required this.showPercent,
    required this.total,
    required this.unit,
  });

  final List<BarEntry> entries;
  final Color color;
  final ChartTheme theme;
  final bool zeroBased;
  final double? axisMin;
  final bool showPercent;
  final int? total;
  final String unit;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;

    final double labelWidth = (size.width * 0.36).clamp(70.0, 140.0);
    final Rect plot =
        Rect.fromLTRB(labelWidth, 4, size.width - 44, size.height - 20);
    if (plot.width <= 10 || plot.height <= 10) return;

    final double maxValue =
        entries.map((BarEntry e) => e.value).reduce((double a, double b) => a > b ? a : b);
    final double lo = axisMin ?? (zeroBased ? 0 : entries
        .map((BarEntry e) => e.value)
        .reduce((double a, double b) => a < b ? a : b) * 0.95);
    // Con un origen fijado se usa el rango exacto: redondear las marcas a
    // valores "bonitos" movería el origen y suavizaría precisamente la
    // distorsión que el laboratorio del módulo 5 quiere hacer visible.
    final AxisRange range = axisMin != null
        ? AxisRange.exact(axisMin!, maxValue, desired: 4)
        : AxisRange.nice(lo, maxValue, desired: 4, zeroBased: zeroBased);

    // Rejilla vertical.
    final Paint grid = Paint()
      ..color = theme.grid
      ..strokeWidth = 1;
    for (final double tick in range.ticks) {
      final double x =
          plot.left + (tick - range.min) / range.span * plot.width;
      if (x < plot.left - 0.5 || x > plot.right + 0.5) continue;
      canvas.drawLine(Offset(x, plot.top), Offset(x, plot.bottom), grid);
      paintLabel(canvas, Num.axis(tick), Offset(x, plot.bottom + 4),
          color: theme.label, anchorAlign: Alignment.topCenter, maxWidth: 60);
    }
    canvas.drawLine(Offset(plot.left, plot.top), Offset(plot.left, plot.bottom),
        Paint()
          ..color = theme.axis
          ..strokeWidth = 1.4);

    final double slot = plot.height / entries.length;
    final double barHeight = (slot * 0.62).clamp(6.0, 30.0);

    for (int i = 0; i < entries.length; i++) {
      final BarEntry e = entries[i];
      final double cy = plot.top + slot * (i + 0.5);
      final double x =
          plot.left + (e.value - range.min) / range.span * plot.width;
      final Rect bar = Rect.fromLTRB(
          plot.left, cy - barHeight / 2, x.clamp(plot.left, plot.right), cy + barHeight / 2);

      final Color c = e.color ?? color;
      if (bar.width > 0.5) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar, const Radius.circular(4)),
          Paint()..color = e.highlight ? c : c.withValues(alpha: 0.85),
        );
      }
      if (e.highlight) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(bar.inflate(1.5), const Radius.circular(5)),
          Paint()
            ..color = theme.emphasis
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.6,
        );
      }

      paintLabel(canvas, e.label, Offset(plot.left - 8, cy),
          color: theme.emphasis,
          size: 11,
          weight: FontWeight.w600,
          anchorAlign: Alignment.centerRight,
          align: TextAlign.right,
          maxWidth: labelWidth - 12);

      final String valueText = showPercent && total != null && total! > 0
          ? '${Num.fixed(e.value / total! * 100, 1)} %'
          : '${Num.auto(e.value)}${unit.isEmpty ? '' : ' $unit'}';
      paintLabel(canvas, valueText, Offset(bar.right + 6, cy),
          color: theme.label,
          size: 11,
          weight: FontWeight.w600,
          anchorAlign: Alignment.centerLeft,
          align: TextAlign.left,
          maxWidth: 44);
    }
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.entries != entries ||
      old.zeroBased != zeroBased ||
      old.axisMin != axisMin ||
      old.color != color;
}
