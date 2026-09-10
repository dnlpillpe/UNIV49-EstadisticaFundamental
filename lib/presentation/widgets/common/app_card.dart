import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Tarjeta base de la app.
///
/// Se implementa a mano en lugar de usar `Card` con `cardTheme` porque el tipo
/// de ese campo del tema cambió entre versiones de Flutter y fijarlo ataría el
/// proyecto a un rango estrecho del SDK.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.accent,
    this.radius = AppSpacing.radiusMd,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  /// Franja de color en el borde izquierdo. Se usa para vincular una tarjeta
  /// con su módulo sin recurrir a fondos de color que reducen el contraste.
  final Color? accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Widget content = Container(
      decoration: BoxDecoration(
        color: color ?? scheme.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          if (accent != null) Container(width: 4, color: accent),
          Expanded(child: Padding(padding: padding, child: child)),
        ],
      ),
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: content,
      ),
    );
  }
}
