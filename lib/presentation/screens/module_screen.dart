import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/module_visuals.dart';
import '../widgets/common/progress_ring.dart';
import '../widgets/common/section_header.dart';

/// Detalle de un módulo: problema que resuelve, lecciones, laboratorio y
/// práctica.
class ModuleScreen extends ConsumerWidget {
  const ModuleScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StudyModule module = bundle.module(moduleId);
    final ModuleProgress progress = ref.watch(moduleProgressProvider(moduleId));
    final LearnerState learner = ref.watch(learnerProvider);
    final List<Exercise> exercises = bundle.exercisesOf(moduleId);
    final Color color = ModuleVisuals.color(module.colorKey);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Módulo ${module.order} · ${module.title}'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(module.title, style: theme.textTheme.displaySmall),
                    const SizedBox(height: 4),
                    Text(module.subtitle, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              ProgressRing(
                  fraction: progress.fraction, size: 62, color: color),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Callout(
            title: 'El error que este módulo corrige',
            text: module.problem,
            kind: CalloutKind.warning,
          ),
          const SizedBox(height: AppSpacing.md),
          Callout(
            title: 'Idea central',
            text: module.bigIdea,
            kind: CalloutKind.insight,
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Teoría',
            subtitle:
                '${module.lessons.length} lecciones · ${module.totalReadingMinutes} min de lectura',
            icon: Icons.article_outlined,
            color: color,
          ),
          for (final Lesson lesson in module.lessons) ...<Widget>[
            _LessonTile(
              lesson: lesson,
              color: color,
              read: learner.readLessons.contains(lesson.id),
              onTap: () => Navigator.pushNamed(
                context,
                AppRouter.lesson,
                arguments:
                    LessonArgs(moduleId: module.id, lessonId: lesson.id),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Laboratorio',
            subtitle: 'La parte que más enseña y la que da tentación de saltarse',
            icon: Icons.science_outlined,
            color: color,
          ),
          AppCard(
            accent: color,
            onTap: () => Navigator.pushNamed(context, AppRouter.lab,
                arguments: module.id),
            child: Row(
              children: <Widget>[
                Icon(
                  progress.labDone
                      ? Icons.check_circle
                      : Icons.play_circle_outline,
                  color: color,
                  size: 30,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(module.lab.title,
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(module.lab.subtitle,
                          style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SectionHeader(
            title: 'Práctica',
            subtitle:
                '${exercises.length} ejercicios · elección 60 % + justificación 40 %',
            icon: Icons.task_alt_outlined,
            color: color,
          ),
          AppCard(
            accent: color,
            onTap: () => Navigator.pushNamed(context, AppRouter.exercises,
                arguments: module.id),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${progress.exercisesAttempted} de ${exercises.length} intentados',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        progress.exercisesAttempted == 0
                            ? 'Aún no has empezado la práctica de este módulo.'
                            : 'Puntuación media: ${(progress.averageScore * 100).round()} %'
                                '${progress.averageScore >= 0.7 ? '' : ' · por debajo del umbral de dominio (70 %)'}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Competencias que desarrolla',
              style: theme.textTheme.titleSmall),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: module.competencies
                .map((c) => Chip(
                      label: Text(c.label),
                      avatar: Icon(Icons.check, size: 15, color: color),
                    ))
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.color,
    required this.read,
    required this.onTap,
  });

  final Lesson lesson;
  final Color color;
  final bool read;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      onTap: onTap,
      child: Row(
        children: <Widget>[
          Icon(read ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: read ? color : theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(lesson.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 2),
                Text('${lesson.cards.length} tarjetas · ${lesson.readingMinutes} min',
                    style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              size: 20, color: theme.colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}
