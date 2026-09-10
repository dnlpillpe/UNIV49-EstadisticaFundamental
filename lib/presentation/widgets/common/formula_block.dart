import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';

/// Fórmula en texto plano sobre fondo diferenciado.
///
/// No se usa LaTeX: renderizarlo exigiría una dependencia pesada para ganar muy
/// poco en fórmulas de este nivel, y el texto plano con símbolos Unicode
/// (x̄, Σ, √) se lee bien y es accesible para un lector de pantalla.
class FormulaBlock extends StatelessWidget {
  const FormulaBlock({super.key, required this.formula, this.caption});

  final String formula;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Text(
              formula,
              style: theme.textTheme.titleMedium?.copyWith(
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
                letterSpacing: 0.2,
              ),
            ),
          ),
          if (caption != null) ...<Widget>[
            const SizedBox(height: 6),
            Text(caption!, style: theme.textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
