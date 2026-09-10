import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Casilla con una medida estadística: valor grande, etiqueta pequeña y una
/// nota opcional que explica cómo se lee.
///
/// La nota no es decorativa: es la respuesta al problema que da origen a la
/// app. Un número sin lectura es exactamente lo que el estudiante ya sabe
/// producir.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit = '',
    this.note,
    this.color,
    this.emphasis = false,
    this.compact = false,
  });

  final String label;
  final String value;
  final String unit;
  final String? note;
  final Color? color;
  final bool emphasis;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color c = color ?? theme.colorScheme.onSurface;
    return Container(
      padding: EdgeInsets.all(compact ? AppSpacing.md : AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: emphasis
            ? c.withValues(alpha: 0.09)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        border: Border.all(
          color: emphasis ? c.withValues(alpha: 0.42) : theme.colorScheme.outline,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Flexible(
                child: Text(
                  value,
                  style: (compact
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.headlineSmall)
                      ?.copyWith(color: c, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...<Widget>[
                const SizedBox(width: 3),
                Text(unit, style: theme.textTheme.labelSmall),
              ],
            ],
          ),
          if (note != null) ...<Widget>[
            const SizedBox(height: 5),
            Text(note!, style: theme.textTheme.bodySmall?.copyWith(fontSize: 11.5)),
          ],
        ],
      ),
    );
  }
}
