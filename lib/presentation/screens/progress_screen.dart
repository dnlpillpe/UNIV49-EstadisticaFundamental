import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/measurement.dart';
import '../../domain/entities/misconception.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/services/progress_service.dart';
import '../../domain/services/tutor_engine.dart';
import '../providers/app_providers.dart';
import '../widgets/charts/bar_chart.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/module_visuals.dart';
import '../widgets/common/progress_ring.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/stat_tile.dart';

/// Progreso.
///
/// Muestra tres cosas y la tercera es la que distingue a esta app: el avance
/// por módulo, la puntuación por competencia y la **tasa de acierto ciego**,
/// es decir el porcentaje de veces que el estudiante eligió la alternativa
/// correcta y falló la justificación. Ese indicador es la medida directa del
/// problema que la app existe para resolver.
class ProgressScreen extends ConsumerWidget {
  const ProgressScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final LearnerState learner = ref.watch(learnerProvider);
    final List<ModuleProgress> progresses =
        ref.watch(allModuleProgressProvider);
    final double overall = ref.watch(overallProgressProvider);
    final Map<Competency, double> competencies =
        ref.watch(competencyScoresProvider);
    final double blind = ref.watch(blindHitRateProvider);
    final TutorEngine engine = ref.watch(tutorEngineProvider);
    final List<({Misconception misconception, int count})> diagnosis =
        engine.diagnose(ref.watch(misconceptionRankingProvider), limit: 5);
    final ThemeData theme = Theme.of(context);

    final int attempted = learner.bestScores.length;
    final double averageScore = learner.bestScores.isEmpty
        ? 0
        : learner.bestScores.values.reduce((double a, double b) => a + b) /
            learner.bestScores.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu progreso'),
        // Es un destino de la barra inferior: sin flecha de retroceso.
        automaticallyImplyLeading: !embedded,
        actions: <Widget>[
          IconButton(
            tooltip: 'Reiniciar progreso',
            icon: const Icon(Icons.restart_alt),
            onPressed: () => _confirmReset(context, ref),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Row(
            children: <Widget>[
              ProgressRing(fraction: overall, size: 78, strokeWidth: 7),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('Avance del curso',
                        style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      '${progresses.where((ModuleProgress p) => p.completed).length} '
                      'de ${progresses.length} módulos dominados · '
                      '$attempted de ${bundle.exercises.length} ejercicios intentados',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: <Widget>[
              Expanded(
                child: StatTile(
                  label: 'Puntuación media',
                  value: attempted == 0
                      ? '—'
                      : '${(averageScore * 100).round()}',
                  unit: attempted == 0 ? '' : '%',
                  compact: true,
                  emphasis: true,
                  color: averageScore >= ProgressService.masteryThreshold
                      ? AppColors.success
                      : AppColors.warning,
                  note: 'Umbral de dominio: 70 %.',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'Acierto ciego',
                  value: learner.attempts.isEmpty
                      ? '—'
                      : '${(blind * 100).round()}',
                  unit: learner.attempts.isEmpty ? '' : '%',
                  compact: true,
                  emphasis: blind > 0.25,
                  color: blind > 0.25 ? AppColors.danger : null,
                  note: 'Elegiste bien y fallaste el porqué.',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: StatTile(
                  label: 'Intentos',
                  value: '${learner.attempts.length}',
                  compact: true,
                  note: 'Reintentar no penaliza.',
                ),
              ),
            ],
          ),
          if (blind > 0.25) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            Callout(
              title: 'Qué significa el acierto ciego',
              kind: CalloutKind.warning,
              text:
                  'En el ${(blind * 100).round()} % de los ejercicios con dos '
                  'fases elegiste la alternativa correcta y no supiste '
                  'justificarla. En un examen de opción múltiple eso habría '
                  'contado como acierto pleno; en un informe real, no. Es '
                  'exactamente el patrón que esta app está construida para '
                  'hacer visible.',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Por módulo',
            icon: Icons.route_outlined,
          ),
          for (int i = 0; i < bundle.modules.length; i++) ...<Widget>[
            _ModuleRow(
              module: bundle.modules[i],
              progress: progresses[i],
            ),
            const SizedBox(height: AppSpacing.sm),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Por competencia',
            subtitle: 'Media de tus mejores intentos en cada tipo de tarea',
            icon: Icons.workspace_premium_outlined,
          ),
          if (competencies.isEmpty)
            const Callout(
              text: 'Resuelve algunos ejercicios y aquí verás en qué '
                  'competencia estás más flojo, que no siempre coincide con '
                  'el módulo que peor llevas.',
              kind: CalloutKind.info,
            )
          else
            BarChart(
              entries: Competency.values
                  .where((Competency c) => competencies.containsKey(c))
                  .map((Competency c) => BarEntry(
                        c.label,
                        (competencies[c] ?? 0) * 100,
                        color: (competencies[c] ?? 0) >=
                                ProgressService.masteryThreshold
                            ? AppColors.success
                            : AppColors.warning,
                      ))
                  .toList(growable: false),
              unit: '%',
              height: 42.0 * competencies.length + 46,
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
            title: 'Confusiones detectadas',
            subtitle: 'Ordenadas por frecuencia en tu historial',
            icon: Icons.psychology_alt_outlined,
          ),
          if (diagnosis.isEmpty)
            const Callout(
              text: 'Todavía no hay suficientes errores registrados para '
                  'detectar un patrón. Eso no es malo.',
              kind: CalloutKind.success,
            )
          else
            for (final ({Misconception misconception, int count}) d
                in diagnosis) ...<Widget>[
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.md),
                accent: AppColors.warning,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(d.misconception.label,
                              style: theme.textTheme.titleSmall),
                          const SizedBox(height: 2),
                          Text(d.misconception.checkYourself,
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('${d.count}×',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(color: AppColors.warning)),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
        ],
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('¿Reiniciar tu progreso?'),
        content: const Text(
            'Se borrarán las lecciones leídas, los laboratorios completados y '
            'todo el historial de intentos. El contenido del curso no cambia. '
            'Esta acción no se puede deshacer.'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reiniciar'),
          ),
        ],
      ),
    );
    if (ok ?? false) {
      await ref.read(learnerProvider.notifier).reset();
    }
  }
}

class _ModuleRow extends StatelessWidget {
  const _ModuleRow({required this.module, required this.progress});

  final StudyModule module;
  final ModuleProgress progress;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = ModuleVisuals.color(module.colorKey);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: () =>
          Navigator.pushNamed(context, AppRouter.module, arguments: module.id),
      child: Row(
        children: <Widget>[
          Icon(ModuleVisuals.icon(module.iconKey), size: 20, color: color),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(module.title, style: theme.textTheme.titleSmall),
                const SizedBox(height: 5),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    color: color,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${progress.lessonsRead}/${progress.lessonsTotal} lecciones · '
                  '${progress.labDone ? 'laboratorio hecho' : 'laboratorio pendiente'} · '
                  '${progress.exercisesAttempted}/${progress.exercisesTotal} ejercicios',
                  style: theme.textTheme.labelSmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (progress.exercisesAttempted > 0)
            Text('${(progress.averageScore * 100).round()} %',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: progress.averageScore >=
                          ProgressService.masteryThreshold
                      ? AppColors.success
                      : AppColors.warning,
                )),
        ],
      ),
    );
  }
}
