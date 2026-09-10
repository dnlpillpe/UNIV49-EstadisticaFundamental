import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/entities/descriptive_stats.dart';
import '../../../domain/entities/measurement.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/services/statistics_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/charts/box_plot_chart.dart';
import '../../widgets/charts/dot_plot_chart.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/callout.dart';
import '../../widgets/common/dataset_panel.dart';

/// Laboratorio 4: comparar dos conjuntos con el mismo centro.
///
/// La tabla comparativa marca en verde las medidas que coinciden y en naranja
/// las que difieren. Ese contraste visual es todo el argumento del módulo: las
/// tres medidas de centro en verde y las cuatro de dispersión en naranja.
class DispersionLab extends ConsumerStatefulWidget {
  const DispersionLab({
    super.key,
    required this.datasetIds,
    required this.color,
  });

  final List<String> datasetIds;
  final Color color;

  @override
  ConsumerState<DispersionLab> createState() => _DispersionLabState();
}

class _DispersionLabState extends ConsumerState<DispersionLab> {
  late String _leftId = widget.datasetIds.first;
  late String _rightId = widget.datasetIds.length > 1
      ? widget.datasetIds[1]
      : widget.datasetIds.first;

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StatisticsService service = ref.watch(statisticsServiceProvider);
    final Dataset a = bundle.dataset(_leftId);
    final Dataset b = bundle.dataset(_rightId);
    final DescriptiveStats sa = service.describe(a.values);
    final DescriptiveStats sb = service.describe(b.values);
    final ThemeData theme = Theme.of(context);

    final bool ratioScale = a.scale == MeasurementScale.ratio &&
        b.scale == MeasurementScale.ratio;

    final List<_Row> rows = <_Row>[
      _Row('Media', sa.mean, sb.mean, a.unit, true),
      _Row('Mediana', sa.median, sb.median, a.unit, true),
      _Row('Moda',
          sa.modes.isEmpty ? double.nan : sa.modes.first,
          sb.modes.isEmpty ? double.nan : sb.modes.first,
          a.unit, true),
      _Row('Mínimo', sa.min, sb.min, a.unit, false),
      _Row('Máximo', sa.max, sb.max, a.unit, false),
      _Row('Rango', sa.range, sb.range, a.unit, false),
      _Row('RIC', sa.iqr, sb.iqr, a.unit, false),
      _Row('Desv. estándar', sa.sampleStdDev, sb.sampleStdDev, a.unit, false),
      _Row('Varianza', sa.sampleVariance, sb.sampleVariance,
          a.unit.isEmpty ? '' : '${a.unit}²', false),
      if (ratioScale)
        _Row('Coef. de variación', sa.coefficientOfVariation,
            sb.coefficientOfVariation, '%', false),
    ];

    final int matching = rows
        .where((_Row r) => (r.left - r.right).abs() < 0.005)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _Picker(
          label: 'Grupo A',
          ids: widget.datasetIds,
          selected: _leftId,
          color: AppColors.modCentrales,
          onChanged: (String id) => setState(() => _leftId = id),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Picker(
          label: 'Grupo B',
          ids: widget.datasetIds,
          selected: _rightId,
          color: AppColors.modDispersion,
          onChanged: (String id) => setState(() => _rightId = id),
        ),
        const SizedBox(height: AppSpacing.lg),
        DotPlotChart(
          values: a.values,
          stats: sa,
          color: AppColors.modCentrales,
          height: 165,
          title: 'A · ${a.name}',
        ),
        const SizedBox(height: AppSpacing.md),
        DotPlotChart(
          values: b.values,
          stats: sb,
          color: AppColors.modDispersion,
          height: 165,
          title: 'B · ${b.name}',
        ),
        const SizedBox(height: AppSpacing.lg),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                color: theme.colorScheme.surfaceContainerHighest,
                child: Row(
                  children: <Widget>[
                    Expanded(flex: 4, child: Text('Medida', style: theme.textTheme.labelMedium)),
                    Expanded(
                        flex: 3,
                        child: Text('A',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: AppColors.modCentrales))),
                    Expanded(
                        flex: 3,
                        child: Text('B',
                            textAlign: TextAlign.right,
                            style: theme.textTheme.labelMedium
                                ?.copyWith(color: AppColors.modDispersion))),
                  ],
                ),
              ),
              for (final _Row r in rows) _RowView(row: r),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        BoxPlotChart(
          series: <BoxSeries>[
            BoxSeries('A', sa, AppColors.modCentrales),
            BoxSeries('B', sb, AppColors.modDispersion),
          ],
          height: 175,
          title: 'Comparación lado a lado',
          unit: a.unit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Callout(
          title: _leftId == _rightId
              ? 'Estás comparando un grupo consigo mismo'
              : '$matching de ${rows.length} medidas coinciden',
          kind: matching >= 3 && _leftId != _rightId
              ? CalloutKind.insight
              : CalloutKind.info,
          text: _leftId == _rightId
              ? 'Elige dos conjuntos distintos en los selectores de arriba.'
              : matching >= 3
                  ? 'Las medidas de centro coinciden y las de dispersión no. '
                      'Si tuvieras que decidir una intervención para cada grupo, '
                      'el promedio idéntico te habría llevado a la misma '
                      'decisión para dos situaciones opuestas.'
                  : 'Estos dos grupos difieren también en el centro. Prueba con '
                      'las secciones A y B: ahí las tres medidas de tendencia '
                      'central son idénticas.',
        ),
        const SizedBox(height: AppSpacing.lg),
        DatasetPanel(dataset: a),
        const SizedBox(height: AppSpacing.sm),
        DatasetPanel(dataset: b),
      ],
    );
  }
}

class _Row {
  const _Row(this.label, this.left, this.right, this.unit, this.isCentral);

  final String label;
  final double left;
  final double right;
  final String unit;
  final bool isCentral;
}

class _RowView extends StatelessWidget {
  const _RowView({required this.row});

  final _Row row;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool same = (row.left - row.right).abs() < 0.005;
    final Color tint = same ? AppColors.success : AppColors.warning;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 1),
      decoration: BoxDecoration(
        border: Border(
            top: BorderSide(color: theme.colorScheme.outline, width: 0.6)),
        color: tint.withValues(alpha: 0.07),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 4,
            child: Row(
              children: <Widget>[
                Icon(same ? Icons.drag_handle : Icons.compare_arrows,
                    size: 14, color: tint),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(row.label,
                      style: theme.textTheme.bodySmall,
                      overflow: TextOverflow.ellipsis),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.left.isNaN ? '—' : Num.fixed(row.left, 2),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ]),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              row.right.isNaN ? '—' : Num.fixed(row.right, 2),
              textAlign: TextAlign.right,
              style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures()
                  ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _Picker extends ConsumerWidget {
  const _Picker({
    required this.label,
    required this.ids,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final String label;
  final List<String> ids;
  final String selected;
  final Color color;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    return Row(
      children: <Widget>[
        SizedBox(
          width: 62,
          child: Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: color)),
        ),
        Expanded(
          // Se usa `DropdownButton` y no `DropdownButtonFormField`: el nombre
          // del parámetro de valor de este último cambió entre versiones de
          // Flutter y no compensa atarse a un rango del SDK por un desplegable.
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              border:
                  Border.all(color: Theme.of(context).colorScheme.outline),
            ),
            child: DropdownButton<String>(
              value: selected,
              isExpanded: true,
              underline: const SizedBox.shrink(),
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              items: ids
                  .map((String id) => DropdownMenuItem<String>(
                        value: id,
                        child: Text(bundle.dataset(id).name,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ))
                  .toList(growable: false),
              onChanged: (String? v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
