import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/entities/descriptive_stats.dart';
import '../../../domain/entities/frequency_table.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/services/statistics_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/charts/histogram_chart.dart';
import '../../widgets/common/callout.dart';
import '../../widgets/common/dataset_panel.dart';
import '../../widgets/common/dataset_selector.dart';
import '../../widgets/common/frequency_table_view.dart';
import '../../widgets/common/stat_tile.dart';

/// Laboratorio 2: construir la tabla de frecuencias moviendo el número de
/// clases y ver, a la vez, el histograma y el error de la media agrupada.
///
/// Poner las tres cosas en la misma pantalla es la decisión de diseño: el
/// estudiante que mueve el control ve simultáneamente cómo cambia la forma
/// percibida y cuánta precisión pierde. Separarlas en pestañas habría roto
/// justamente la relación que el laboratorio enseña.
class FrequencyLab extends ConsumerStatefulWidget {
  const FrequencyLab({super.key, required this.datasetIds, required this.color});

  final List<String> datasetIds;
  final Color color;

  @override
  ConsumerState<FrequencyLab> createState() => _FrequencyLabState();
}

class _FrequencyLabState extends ConsumerState<FrequencyLab> {
  late String _datasetId = widget.datasetIds.first;
  int? _classCount;

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StatisticsService service = ref.watch(statisticsServiceProvider);
    final Dataset dataset = bundle.dataset(_datasetId);
    final int suggested = service.sturgesClassCount(dataset.values.length);
    final int k = _classCount ?? suggested;

    final FrequencyTable table =
        service.buildFrequencyTable(dataset.values, classCount: k);
    final DescriptiveStats stats = service.describe(dataset.values);
    final double grouped = table.groupedMean;
    final double error = (grouped - stats.mean).abs();
    final double errorPercent =
        stats.mean == 0 ? 0 : error / stats.mean.abs() * 100;
    final ThemeData theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DatasetSelector(
          ids: widget.datasetIds,
          selected: _datasetId,
          color: widget.color,
          onChanged: (String id) => setState(() {
            _datasetId = id;
            _classCount = null;
          }),
        ),
        const SizedBox(height: AppSpacing.md),
        DatasetPanel(dataset: dataset),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Text('Clases: $k', style: theme.textTheme.titleSmall),
            const SizedBox(width: AppSpacing.sm),
            if (k == suggested)
              Chip(
                label: Text('Sturges', style: theme.textTheme.labelSmall),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            const Spacer(),
            Text('Ancho: ${Num.auto(table.classWidth)} ${dataset.unit}',
                style: theme.textTheme.bodySmall),
          ],
        ),
        Slider(
          value: k.toDouble(),
          min: 2,
          max: 15,
          divisions: 13,
          label: '$k',
          activeColor: widget.color,
          onChanged: (double v) => setState(() => _classCount = v.round()),
        ),
        if (k != suggested)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => setState(() => _classCount = null),
              icon: const Icon(Icons.restart_alt, size: 17),
              label: Text('Volver a las $suggested clases de Sturges'),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        HistogramChart(
          table: table,
          stats: stats,
          showMean: true,
          showMedian: true,
          color: widget.color,
          height: 240,
          title: dataset.variableName,
          subtitle: 'n = ${stats.n} · ${dataset.unit}',
        ),
        const SizedBox(height: AppSpacing.lg),
        FrequencyTableView(table: table, accent: widget.color),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Media exacta',
                value: Num.fixed(stats.mean, 2),
                unit: dataset.unit,
                compact: true,
                note: 'Con los datos originales.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                label: 'Media agrupada',
                value: Num.fixed(grouped, 2),
                unit: dataset.unit,
                compact: true,
                note: 'Con las marcas de clase.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                label: 'Error',
                value: Num.fixed(errorPercent, 2),
                unit: '%',
                compact: true,
                emphasis: errorPercent > 2,
                note: 'Lo que cuesta agrupar.',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Callout(
          kind: k <= 3
              ? CalloutKind.warning
              : (k >= 12 ? CalloutKind.warning : CalloutKind.info),
          text: k <= 3
              ? 'Con $k clases casi cualquier distribución parece uniforme: has '
                  'comprimido tanto que la forma desaparece.'
              : k >= 12
                  ? 'Con $k clases y ${stats.n} datos, la mayoría de clases '
                      'tiene uno o dos casos. Eso ya no es detalle, es ruido: '
                      'el histograma empieza a mostrar el azar del muestreo.'
                  : 'Con $k clases se distingue el pico y las colas. Compara el '
                      'error de la media agrupada al mover el control: no baja '
                      'de forma monótona, depende de dónde caigan los límites.',
        ),
      ],
    );
  }
}
