import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/entities/descriptive_stats.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/services/statistics_service.dart';
import '../../providers/app_providers.dart';
import '../../widgets/charts/box_plot_chart.dart';
import '../../widgets/charts/dot_plot_chart.dart';
import '../../widgets/common/callout.dart';
import '../../widgets/common/dataset_selector.dart';
import '../../widgets/common/stat_tile.dart';

/// Laboratorio 3: mover un dato y ver a qué medida le importa.
///
/// El estudiante arrastra el valor más alto del conjunto y observa, en directo,
/// cuánto se mueve la media, cuánto la mediana y cuánto la moda. Es el
/// argumento de la robustez convertido en gesto: mucho más eficaz que
/// enunciarlo, porque el desplazamiento diferencial se ve en la misma pantalla.
class OutlierLab extends ConsumerStatefulWidget {
  const OutlierLab({super.key, required this.datasetIds, required this.color});

  final List<String> datasetIds;
  final Color color;

  @override
  ConsumerState<OutlierLab> createState() => _OutlierLabState();
}

class _OutlierLabState extends ConsumerState<OutlierLab> {
  late String _datasetId = widget.datasetIds.first;
  double? _movedValue;

  /// Estadísticas del conjunto original, para poder mostrar la diferencia.
  DescriptiveStats? _baseline;

  List<double> _currentValues(Dataset dataset) {
    final List<double> values = List<double>.of(dataset.values)..sort();
    if (_movedValue == null || values.isEmpty) return values;
    values[values.length - 1] = _movedValue!;
    values.sort();
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StatisticsService service = ref.watch(statisticsServiceProvider);
    final Dataset dataset = bundle.dataset(_datasetId);
    final ThemeData theme = Theme.of(context);

    _baseline ??= service.describe(dataset.values);
    final List<double> values = _currentValues(dataset);
    final DescriptiveStats stats = service.describe(values);
    final DescriptiveStats base = _baseline!;

    final double originalMax =
        (List<double>.of(dataset.values)..sort()).last;
    final double originalMin =
        (List<double>.of(dataset.values)..sort()).first;
    final double sliderMin = originalMin;
    // Si todos los valores fueran iguales, mínimo y máximo coincidirían y el
    // control lanzaría una aserción. El margen mínimo evita ese caso límite.
    final double rawMax = originalMax + (originalMax - originalMin) * 2.5;
    final double sliderMax =
        rawMax > sliderMin ? rawMax : sliderMin + 1;
    final double sliderValue =
        (_movedValue ?? originalMax).clamp(sliderMin, sliderMax);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DatasetSelector(
          ids: widget.datasetIds,
          selected: _datasetId,
          color: widget.color,
          onChanged: (String id) => setState(() {
            _datasetId = id;
            _movedValue = null;
            _baseline = null;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        DotPlotChart(
          values: values,
          stats: stats,
          color: widget.color,
          highlightValue: _movedValue,
          height: 200,
          title: dataset.variableName,
          subtitle:
              'Un punto por observación · el punto naranja es el que estás moviendo',
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Text('Valor más alto', style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(
              '${Num.fixed(sliderValue, dataset.decimals)} ${dataset.unit}',
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: AppColors.warning),
            ),
          ],
        ),
        Slider(
          value: sliderValue,
          min: sliderMin,
          max: sliderMax,
          activeColor: AppColors.warning,
          onChanged: (double v) => setState(() => _movedValue = v),
        ),
        if (_movedValue != null)
          TextButton.icon(
            onPressed: () => setState(() => _movedValue = null),
            icon: const Icon(Icons.restart_alt, size: 17),
            label: const Text('Devolver el dato a su valor original'),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: <Widget>[
            Expanded(
              child: _MeasureTile(
                label: 'Media',
                value: Num.fixed(stats.mean, 2),
                delta: stats.mean - base.mean,
                color: AppColors.mean,
                unit: dataset.unit,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MeasureTile(
                label: 'Mediana',
                value: Num.fixed(stats.median, 2),
                delta: stats.median - base.median,
                color: AppColors.median,
                unit: dataset.unit,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: _MeasureTile(
                label: 'Moda',
                value: stats.modes.isEmpty
                    ? 'amodal'
                    : Num.fixed(stats.modes.first, dataset.decimals),
                delta: 0,
                color: AppColors.mode,
                unit: stats.modes.isEmpty ? '' : dataset.unit,
                showDelta: false,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            Expanded(
              child: StatTile(
                label: 'Desv. estándar',
                value: Num.fixed(stats.sampleStdDev, 2),
                unit: dataset.unit,
                compact: true,
                note: 'También se mueve.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                label: 'RIC',
                value: Num.fixed(stats.iqr, 2),
                unit: dataset.unit,
                compact: true,
                note: 'No se inmuta.',
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: StatTile(
                label: 'Atípicos',
                value: stats.outliers.isEmpty
                    ? '0'
                    : '${stats.outliers.length}',
                compact: true,
                color: stats.hasOutliers ? AppColors.outlier : null,
                note: 'Regla de Tukey.',
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        BoxPlotChart(
          series: <BoxSeries>[
            BoxSeries('Actual', stats, widget.color),
            BoxSeries('Original', base, AppColors.lightTextMuted),
          ],
          height: 175,
          title: 'Antes y después',
          unit: dataset.unit,
        ),
        const SizedBox(height: AppSpacing.lg),
        Callout(
          kind: _movedValue == null
              ? CalloutKind.info
              : (stats.median == base.median
                  ? CalloutKind.insight
                  : CalloutKind.warning),
          text: _movedValue == null
              ? 'Mueve el control y observa cuál de las tres medidas se '
                  'desplaza y cuál no.'
              : stats.median == base.median
                  ? 'Has movido ese dato ${Num.auto((sliderValue - _originalMaxOf(dataset)).abs())} '
                      '${dataset.unit} y la mediana no se ha movido ni una '
                      'décima, mientras la media cambió '
                      '${Num.signed(stats.mean - base.mean)}. La media usa el '
                      'valor de cada dato; la mediana solo cuenta posiciones.'
                  : 'Al mover tanto el dato has cambiado también qué valor '
                      'ocupa la posición central, así que esta vez sí se movió '
                      'la mediana.',
        ),
      ],
    );
  }

  double _originalMaxOf(Dataset dataset) =>
      dataset.values.reduce((double a, double b) => math.max(a, b));
}

class _MeasureTile extends StatelessWidget {
  const _MeasureTile({
    required this.label,
    required this.value,
    required this.delta,
    required this.color,
    required this.unit,
    this.showDelta = true,
  });

  final String label;
  final String value;
  final double delta;
  final Color color;
  final String unit;
  final bool showDelta;

  @override
  Widget build(BuildContext context) {
    final bool moved = delta.abs() > 0.005;
    return StatTile(
      label: label,
      value: value,
      unit: unit,
      color: color,
      emphasis: true,
      compact: true,
      note: !showDelta
          ? null
          : moved
              ? 'Se movió ${Num.signed(delta)}'
              : 'Sin cambio',
    );
  }
}
