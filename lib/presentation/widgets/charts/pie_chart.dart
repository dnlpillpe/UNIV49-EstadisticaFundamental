import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/number_format.dart';
import 'chart_kit.dart';

class PieEntry {
  const PieEntry(this.label, this.value);

  final String label;
  final double value;
}

/// Gráfico circular (de anillo).
///
/// Se incluye porque el módulo 5 necesita **mostrar por qué suele ser mala
/// elección** con muchas categorías: es difícil argumentarlo sin poner el
/// gráfico delante. Fuera de ese contexto la app usa barras.
class PieChart extends StatelessWidget {
  const PieChart({
    super.key,
    required this.entries,
    this.height = 240,
    this.title,
    this.subtitle,
    this.showLabels = false,
  });

  final List<PieEntry> entries;
  final double height;
  final String? title;
  final String? subtitle;

  /// Si es falso, el gráfico se dibuja sin etiquetas: exactamente la situación
  /// en que el lector tiene que comparar ángulos a ojo.
  final bool showLabels;

  @override
  Widget build(BuildContext context) {
    final double total =
        entries.fold<double>(0, (double a, PieEntry e) => a + e.value);
    return ChartFrame(
      title: title,
      subtitle: subtitle,
      height: height,
      legend: <ChartLegendEntry>[
        for (int i = 0; i < entries.length; i++)
          ChartLegendEntry(
            total == 0
                ? entries[i].label
                : '${entries[i].label} · ${Num.fixed(entries[i].value / total * 100, 1)} %',
            AppColors.series[i % AppColors.series.length],
          ),
      ],
      child: CustomPaint(
        painter: _PiePainter(
          entries: entries,
          theme: ChartTheme.of(context),
          showLabels: showLabels,
        ),
      ),
    );
  }
}

class _PiePainter extends CustomPainter {
  _PiePainter({
    required this.entries,
    required this.theme,
    required this.showLabels,
  });

  final List<PieEntry> entries;
  final ChartTheme theme;
  final bool showLabels;

  @override
  void paint(Canvas canvas, Size size) {
    final double total =
        entries.fold<double>(0, (double a, PieEntry e) => a + e.value);
    if (total <= 0) return;

    final double radius = math.min(size.width, size.height) / 2 - 8;
    final Offset center = Offset(size.width / 2, size.height / 2);
    final Rect rect = Rect.fromCircle(center: center, radius: radius);

    double start = -math.pi / 2;
    for (int i = 0; i < entries.length; i++) {
      final double sweep = entries[i].value / total * 2 * math.pi;
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()..color = AppColors.series[i % AppColors.series.length],
      );
      canvas.drawArc(
        rect,
        start,
        sweep,
        true,
        Paint()
          ..color = theme.surface
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      if (showLabels && sweep > 0.32) {
        final double mid = start + sweep / 2;
        final Offset p = center +
            Offset(math.cos(mid), math.sin(mid)) * (radius * 0.68);
        paintLabel(
          canvas,
          '${Num.fixed(entries[i].value / total * 100, 0)} %',
          p,
          color: Colors.white,
          size: 11,
          weight: FontWeight.w700,
          maxWidth: 60,
        );
      }
      start += sweep;
    }

    // Anillo: el hueco central reduce ligeramente el sesgo de comparación de
    // áreas y deja sitio para el total.
    canvas.drawCircle(center, radius * 0.5, Paint()..color = theme.surface);
    paintLabel(canvas, Num.auto(total), center.translate(0, -7),
        color: theme.emphasis, size: 16, weight: FontWeight.w700, maxWidth: 90);
    paintLabel(canvas, 'total', center.translate(0, 10),
        color: theme.label, size: 10, maxWidth: 90);
  }

  @override
  bool shouldRepaint(covariant _PiePainter old) =>
      old.entries != entries || old.showLabels != showLabels;
}
