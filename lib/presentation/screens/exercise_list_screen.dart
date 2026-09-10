import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/module_visuals.dart';

/// Lista de ejercicios de un módulo, con la mejor puntuación de cada uno.
class ExerciseListScreen extends ConsumerWidget {
  const ExerciseListScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StudyModule module = bundle.module(moduleId);
    final List<Exercise> exercises = bundle.exercisesOf(moduleId);
    final LearnerState learner = ref.watch(learnerProvider);
    final Color color = ModuleVisuals.color(module.colorKey);

    return Scaffold(
      appBar: AppBar(title: Text('Práctica · ${module.title}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          const Callout(
            title: 'Cómo se puntúa',
            kind: CalloutKind.info,
            text:
                'En los ejercicios con justificación, elegir bien vale 0,6 y '
                'explicar por qué vale 0,4. Acertar la alternativa sin poder '
                'justificarla es el error que esta app está diseñada para '
                'detectar, y se queda en 6 sobre 10.',
          ),
          const SizedBox(height: AppSpacing.lg),
          for (final Exercise e in exercises) ...<Widget>[
            _ExerciseTile(
              exercise: e,
              color: color,
              best: learner.bestScores[e.id],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    required this.exercise,
    required this.color,
    required this.best,
  });

  final Exercise exercise;
  final Color color;
  final double? best;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool done = best != null;
    final bool good = (best ?? 0) >= 0.7;

    return AppCard(
      onTap: () => Navigator.pushNamed(context, AppRouter.exercise,
          arguments: ExerciseArgs(exerciseId: exercise.id)),
      accent: done ? (good ? AppColors.success : AppColors.warning) : null,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    _Difficulty(level: exercise.difficulty, color: color),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        exercise.competency.label.toUpperCase(),
                        style: theme.textTheme.labelSmall
                            ?.copyWith(letterSpacing: 0.6),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(exercise.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 3),
                Text(
                  exercise.prompt,
                  style: theme.textTheme.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (exercise.hasJustification) ...<Widget>[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(Icons.forum_outlined,
                          size: 13, color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Pide justificación',
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (done)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: (good ? AppColors.success : AppColors.warning)
                    .withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: Text(
                '${(best! * 100).round()} %',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: good ? AppColors.success : AppColors.warning,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            Icon(Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _Difficulty extends StatelessWidget {
  const _Difficulty({required this.level, required this.color});

  final int level;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List<Widget>.generate(
        3,
        (int i) => Padding(
          padding: const EdgeInsets.only(right: 2.5),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < level
                  ? color
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
        ),
      ),
    );
  }
}
