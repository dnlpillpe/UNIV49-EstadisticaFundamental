import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/module_visuals.dart';
import 'labs/dispersion_lab.dart';
import 'labs/frequency_lab.dart';
import 'labs/misleading_chart_lab.dart';
import 'labs/outlier_lab.dart';
import 'labs/variable_classifier_lab.dart';

/// Contenedor de los laboratorios.
///
/// La estructura es siempre la misma: instrucciones arriba, experimento en
/// medio y —solo al final, cuando el estudiante decide terminar— la conclusión
/// que debía descubrir. Mostrar la conclusión antes de experimentar anularía el
/// laboratorio, así que el texto del objetivo está deliberadamente oculto hasta
/// ese momento.
class LabScreen extends ConsumerStatefulWidget {
  const LabScreen({super.key, required this.moduleId});

  final String moduleId;

  @override
  ConsumerState<LabScreen> createState() => _LabScreenState();
}

class _LabScreenState extends ConsumerState<LabScreen> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StudyModule module = bundle.module(widget.moduleId);
    final LabInfo lab = module.lab;
    final Color color = ModuleVisuals.color(module.colorKey);
    final ThemeData theme = Theme.of(context);
    final bool done = ref.watch(learnerProvider).completedLabs.contains(lab.id);

    return Scaffold(
      appBar: AppBar(title: Text('Laboratorio · ${module.title}')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Text(lab.title, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(lab.subtitle, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.lg),
          _Steps(steps: lab.steps, color: color),
          const SizedBox(height: AppSpacing.xl),
          _build(lab, color),
          const SizedBox(height: AppSpacing.xl),
          if (_revealed || done) ...<Widget>[
            Callout(
              title: 'Qué deberías haber descubierto',
              text: lab.goal,
              kind: CalloutKind.insight,
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          if (!done)
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: color),
              onPressed: () async {
                setState(() => _revealed = true);
                await ref
                    .read(learnerProvider.notifier)
                    .markLabCompleted(lab.id);
              },
              icon: const Icon(Icons.check, size: 18),
              label: const Text('He terminado el laboratorio'),
            )
          else
            const Callout(
              text: 'Laboratorio completado. Puedes volver cuando quieras: '
                  'el experimento sigue disponible.',
              kind: CalloutKind.success,
            ),
        ],
      ),
    );
  }

  Widget _build(LabInfo lab, Color color) {
    switch (lab.kind) {
      case LabKind.variableClassifier:
        return VariableClassifierLab(color: color);
      case LabKind.frequencyBuilder:
        return FrequencyLab(datasetIds: lab.datasetIds, color: color);
      case LabKind.outlierSandbox:
        return OutlierLab(datasetIds: lab.datasetIds, color: color);
      case LabKind.dispersionComparator:
        return DispersionLab(datasetIds: lab.datasetIds, color: color);
      case LabKind.misleadingChart:
        return MisleadingChartLab(datasetIds: lab.datasetIds, color: color);
    }
  }
}

class _Steps extends StatelessWidget {
  const _Steps({required this.steps, required this.color});

  final List<String> steps;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Text('${i + 1}',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: color, fontSize: 11)),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(steps[i], style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
