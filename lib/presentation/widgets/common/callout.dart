import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

enum CalloutKind { info, warning, success, danger, insight }

/// Bloque destacado con icono. Los cuatro tonos se usan de forma consistente en
/// toda la app: aviso para errores frecuentes, clave para las ideas que hay que
/// retener, éxito para respuestas correctas y peligro para incorrectas.
class Callout extends StatelessWidget {
  const Callout({
    super.key,
    required this.text,
    this.title,
    this.kind = CalloutKind.info,
    this.icon,
    this.child,
  });

  final String text;
  final String? title;
  final CalloutKind kind;
  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final bool dark = Theme.of(context).brightness == Brightness.dark;
    final (Color fg, Color bg, IconData defaultIcon) = switch (kind) {
      CalloutKind.info => (AppColors.info, AppColors.infoBg, Icons.info_outline),
      CalloutKind.warning => (
          AppColors.warning,
          AppColors.warningBg,
          Icons.report_problem_outlined
        ),
      CalloutKind.success => (
          AppColors.success,
          AppColors.successBg,
          Icons.check_circle_outline
        ),
      CalloutKind.danger => (
          AppColors.danger,
          AppColors.dangerBg,
          Icons.cancel_outlined
        ),
      CalloutKind.insight => (
          AppColors.modCentrales,
          AppColors.successBg,
          Icons.lightbulb_outline
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg - 2),
      decoration: BoxDecoration(
        color: dark ? fg.withValues(alpha: 0.12) : bg,
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        border: Border.all(color: fg.withValues(alpha: dark ? 0.4 : 0.32)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon ?? defaultIcon, size: 19, color: fg),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                if (title != null) ...<Widget>[
                  Text(
                    title!,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(color: fg),
                  ),
                  const SizedBox(height: 4),
                ],
                if (text.isNotEmpty)
                  Text(text, style: Theme.of(context).textTheme.bodyMedium),
                if (child != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.sm),
                  child!,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
