import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/brand_mark.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/module_visuals.dart';
import '../widgets/common/progress_ring.dart';
import '../widgets/common/section_header.dart';

/// Ruta de aprendizaje: los cinco módulos en orden, con el avance de cada uno.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final List<ModuleProgress> progresses = ref.watch(allModuleProgressProvider);
    final double overall = ref.watch(overallProgressProvider);
    final ({String moduleId, String kind, String label})? next =
        ref.watch(nextActionProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: <Widget>[
          SliverAppBar(
            pinned: true,
            expandedHeight: 168,
            backgroundColor: AppColors.navy,
            foregroundColor: Colors.white,
            actions: <Widget>[
              IconButton(
                tooltip: 'Glosario',
                icon: const Icon(Icons.menu_book_outlined),
                onPressed: () =>
                    Navigator.pushNamed(context, AppRouter.glossary),
              ),
              IconButton(
                tooltip: 'Acerca de',
                icon: const Icon(Icons.info_outline),
                onPressed: () => Navigator.pushNamed(context, AppRouter.about),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(
                  left: AppSpacing.lg, bottom: AppSpacing.md, right: 96),
              title: const Text(
                AppInfo.name,
                style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              background: _Header(overall: overall),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
            sliver: SliverList(
              delegate: SliverChildListDelegate(<Widget>[
                if (next != null) ...<Widget>[
                  _NextAction(next: next),
                  const SizedBox(height: AppSpacing.xl),
                ],
                const SectionHeader(
                  title: 'Ruta de aprendizaje',
                  subtitle:
                      'Cinco módulos en orden. Cada uno tiene teoría breve, un '
                      'laboratorio y práctica con justificación.',
                  icon: Icons.route_outlined,
                ),
                for (int i = 0; i < bundle.modules.length; i++) ...<Widget>[
                  _ModuleCard(
                    module: bundle.modules[i],
                    progress: progresses[i],
                    exerciseCount:
                        bundle.exercisesOf(bundle.modules[i].id).length,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
                const Callout(
                  title: 'Por qué esta app existe',
                  kind: CalloutKind.insight,
                  text:
                      'Los estudiantes no fallan en calcular la media: fallan en '
                      'decidir si la media era la medida adecuada y en explicar '
                      'qué significa el número que obtuvieron. Por eso aquí la '
                      'calculadora está siempre disponible y lo que se evalúa es '
                      'la decisión y la justificación.',
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Versión ${AppInfo.version} · ${bundle.modules.length} módulos · '
                  '${bundle.exercises.length} ejercicios · '
                  '${bundle.datasets.length} conjuntos de datos reales',
                  style: theme.textTheme.bodySmall,
                  textAlign: TextAlign.center,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.overall});

  final double overall;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[AppColors.navyDeep, AppColors.primary],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, AppSpacing.xl, AppSpacing.lg, AppSpacing.xxl + 8),
          child: Row(
            children: <Widget>[
              const BrandMark(size: 54, background: Colors.transparent),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      AppInfo.tagline,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              ProgressRing(
                fraction: overall,
                size: 54,
                strokeWidth: 5,
                color: AppColors.modCentrales,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NextAction extends ConsumerWidget {
  const _NextAction({required this.next});

  final ({String moduleId, String kind, String label}) next;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StudyModule module = bundle.module(next.moduleId);
    final Color color = ModuleVisuals.color(module.colorKey);

    return AppCard(
      accent: color,
      onTap: () {
        switch (next.kind) {
          case 'lesson':
          case 'review':
            Navigator.pushNamed(context, AppRouter.module,
                arguments: module.id);
          case 'lab':
            Navigator.pushNamed(context, AppRouter.lab, arguments: module.id);
          case 'exercise':
            Navigator.pushNamed(context, AppRouter.exercises,
                arguments: module.id);
        }
      },
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Icon(Icons.play_arrow_rounded, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('CONTINÚA POR AQUÍ',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: color, letterSpacing: 0.7)),
                const SizedBox(height: 2),
                Text(next.label,
                    style: Theme.of(context).textTheme.titleSmall),
              ],
            ),
          ),
          Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.progress,
    required this.exerciseCount,
  });

  final StudyModule module;
  final ModuleProgress progress;
  final int exerciseCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = ModuleVisuals.color(module.colorKey);

    return AppCard(
      accent: color,
      onTap: () =>
          Navigator.pushNamed(context, AppRouter.module, arguments: module.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(ModuleVisuals.icon(module.iconKey),
                    color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('MÓDULO ${module.order}',
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: color, letterSpacing: 0.7)),
                    const SizedBox(height: 1),
                    Text(module.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(module.subtitle, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ProgressRing(
                fraction: progress.fraction,
                size: 46,
                strokeWidth: 4.5,
                color: color,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: 6,
            children: <Widget>[
              _Meta(
                icon: Icons.article_outlined,
                label:
                    '${progress.lessonsRead}/${progress.lessonsTotal} lecciones',
                done: progress.lessonsRead == progress.lessonsTotal,
              ),
              _Meta(
                icon: Icons.science_outlined,
                label: 'Laboratorio',
                done: progress.labDone,
              ),
              _Meta(
                icon: Icons.task_alt_outlined,
                label:
                    '${progress.exercisesAttempted}/$exerciseCount ejercicios',
                done: progress.exercisesAttempted == exerciseCount &&
                    exerciseCount > 0,
              ),
            ],
          ),
          if (progress.completed) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: <Widget>[
                const Icon(Icons.verified, size: 16, color: AppColors.success),
                const SizedBox(width: 5),
                Text(
                  'Módulo dominado · ${(progress.averageScore * 100).round()} %',
                  style: theme.textTheme.labelMedium
                      ?.copyWith(color: AppColors.success),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label, required this.done});

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final Color c = done
        ? AppColors.success
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(done ? Icons.check_circle : icon, size: 14, color: c),
        const SizedBox(width: 4),
        Text(label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(color: c)),
      ],
    );
  }
}
