import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Marca gráfica de la aplicación: una curva de distribución sobre un
/// histograma, dibujada con el mismo código que genera el icono.
///
/// La elección del símbolo no es decorativa. Una curva sobre barras es
/// exactamente la idea que la app enseña: los datos brutos (las barras) y la
/// lectura que se hace de ellos (la curva y las marcas de centro).
class BrandMark extends StatelessWidget {
  const BrandMark({
    super.key,
    this.size = 72,
    this.background,
    this.rounded = true,
  });

  final double size;
  final Color? background;
  final bool rounded;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: BrandMarkPainter(
          background: background ?? AppColors.navy,
          rounded: rounded,
        ),
      ),
    );
  }
}

class BrandMarkPainter extends CustomPainter {
  const BrandMarkPainter({
    this.background = AppColors.navy,
    this.rounded = true,
    this.padding = 0.14,
  });

  final Color background;
  final bool rounded;

  /// Margen interior como fracción del lado. En los iconos adaptativos de
  /// Android el sistema recorta hasta un 25 % del borde, así que el dibujo se
  /// mantiene dentro de la zona segura.
  final double padding;

  @override
  void paint(Canvas canvas, Size size) {
    final double s = math.min(size.width, size.height);
    final Rect full = Rect.fromLTWH(0, 0, size.width, size.height);

    if (background.a > 0) {
      final RRect bg = rounded
          ? RRect.fromRectAndRadius(full, Radius.circular(s * 0.22))
          : RRect.fromRectAndRadius(full, Radius.zero);
      canvas.drawRRect(bg, Paint()..color = background);
    }

    final double pad = s * padding;
    final Rect plot = Rect.fromLTRB(
        pad, pad + s * 0.06, size.width - pad, size.height - pad);

    // Barras: alturas de una distribución acampanada ligeramente asimétrica.
    const List<double> heights = <double>[0.18, 0.42, 0.74, 1.0, 0.82, 0.5, 0.26];
    final double barW = plot.width / heights.length;

    for (int i = 0; i < heights.length; i++) {
      final double h = plot.height * heights[i] * 0.86;
      final Rect bar = Rect.fromLTWH(
        plot.left + barW * i + barW * 0.06,
        plot.bottom - h,
        barW * 0.88,
        h,
      );
      final Color c = i == 3
          ? AppColors.modDispersion
          : Color.lerp(
              AppColors.primaryLight,
              AppColors.modCentrales,
              (i / (heights.length - 1)).clamp(0.0, 1.0),
            )!;
      canvas.drawRRect(
        RRect.fromRectAndCorners(bar,
            topLeft: Radius.circular(s * 0.022),
            topRight: Radius.circular(s * 0.022)),
        Paint()..color = c,
      );
    }

    // Curva normal superpuesta.
    final Path curve = Path();
    const int steps = 60;
    for (int i = 0; i <= steps; i++) {
      final double t = i / steps;
      final double x = plot.left + plot.width * t;
      // Gaussiana centrada en 0,47 del ancho, para acompañar la asimetría.
      final double z = (t - 0.47) / 0.20;
      final double y =
          plot.bottom - plot.height * 0.94 * math.exp(-0.5 * z * z);
      if (i == 0) {
        curve.moveTo(x, y);
      } else {
        curve.lineTo(x, y);
      }
    }
    canvas.drawPath(
      curve,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.030
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Línea de la media: el detalle que convierte el símbolo en estadística
    // descriptiva y no en un gráfico genérico.
    final double meanX = plot.left + plot.width * 0.47;
    final Paint meanPaint = Paint()
      ..color = AppColors.warning
      ..strokeWidth = s * 0.024
      ..strokeCap = StrokeCap.round;
    double y = plot.top;
    while (y < plot.bottom) {
      final double end = math.min(y + s * 0.055, plot.bottom);
      canvas.drawLine(Offset(meanX, y), Offset(meanX, end), meanPaint);
      y = end + s * 0.04;
    }

    // Eje base.
    canvas.drawLine(
      Offset(plot.left, plot.bottom),
      Offset(plot.right, plot.bottom),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..strokeWidth = s * 0.03
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant BrandMarkPainter old) =>
      old.background != background || old.rounded != rounded;
}
