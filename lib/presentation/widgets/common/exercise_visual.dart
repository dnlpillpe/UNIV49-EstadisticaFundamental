import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/entities/descriptive_stats.dart';
import '../../../domain/entities/exercise.dart';
import '../../../domain/entities/frequency_table.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../../domain/services/statistics_service.dart';
import '../../providers/app_providers.dart';
import '../charts/bar_chart.dart';
import '../charts/box_plot_chart.dart';
import '../charts/dot_plot_chart.dart';
import '../charts/histogram_chart.dart';
import '../charts/line_chart.dart';
import '../charts/pie_chart.dart';
import '../charts/scatter_chart.dart';
import 'dataset_panel.dart';
import 'frequency_table_view.dart';

/// Renderiza el apoyo visual que declara un ejercicio.
///
/// El ejercicio no dice "dibuja un histograma con estos parámetros": dice
/// `"visual": "histograma"`, y esta capa decide cómo se dibuja. Así el
/// contenido sigue siendo editable por alguien que no programa.
class ExerciseVisualView extends ConsumerWidget {
  const ExerciseVisualView({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (exercise.visual == ExerciseVisual.none && exercise.datasetId == null) {
      return const SizedBox.shrink();
    }

    final ContentBundle bundle = ref.watch(bundleProvider);
    final StatisticsService stats = ref.watch(statisticsServiceProvider);
    final Dataset? primary = bundle.datasetOrNull(exercise.datasetId);
    final Dataset? secondary = bundle.datasetOrNull(exercise.secondaryDatasetId);

    if (primary == null) return const SizedBox.shrink();

    final Widget? chart = _buildChart(primary, secondary, stats);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DatasetPanel(
          dataset: primary,
          initiallyExpanded: exercise.visual == ExerciseVisual.dataList,
          showValues: primary.kind != DatasetKind.bivariate,
        ),
        if (secondary != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          DatasetPanel(dataset: secondary),
        ],
        if (chart != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          chart,
        ],
      ],
    );
  }

  Widget? _buildChart(
      Dataset primary, Dataset? secondary, StatisticsService service) {
    switch (exercise.visual) {
      case ExerciseVisual.none:
      case ExerciseVisual.dataList:
        return null;

      case ExerciseVisual.table:
        final FrequencyTable table = primary.kind == DatasetKind.categorical
            ? service.buildCategoricalTable(primary.categories)
            : service.buildFrequencyTable(primary.values,
                classCount: exercise.classCount);
        return FrequencyTableView(table: table);

      case ExerciseVisual.histogram:
        if (primary.values.isEmpty) return null;
        final DescriptiveStats st = service.describe(primary.values);
        return HistogramChart(
          table: service.buildFrequencyTable(primary.values,
              classCount: exercise.classCount),
          stats: st,
          showMean: true,
          showMedian: true,
          color: AppColors.modDatos,
          title: primary.variableName,
          subtitle: primary.unit.isEmpty ? null : 'En ${primary.unit}',
        );

      case ExerciseVisual.bar:
        if (primary.kind == DatasetKind.categorical) {
          return BarChart(
            entries: (List<CategoryCount>.of(primary.categories)
                  ..sort((CategoryCount a, CategoryCount b) =>
                      b.count.compareTo(a.count)))
                .map((CategoryCount c) =>
                    BarEntry(c.label, c.count.toDouble()))
                .toList(growable: false),
            total: primary.size,
            showPercent: true,
            height: 40.0 * primary.categories.length + 50,
            title: primary.variableName,
          );
        }
        return null;

      case ExerciseVisual.pie:
        if (primary.kind != DatasetKind.categorical) return null;
        return PieChart(
          entries: primary.categories
              .map((CategoryCount c) => PieEntry(c.label, c.count.toDouble()))
              .toList(growable: false),
          title: primary.variableName,
          height: 240,
        );

      case ExerciseVisual.boxPlot:
        if (primary.values.isEmpty) return null;
        return BoxPlotChart(
          series: <BoxSeries>[
            BoxSeries(primary.name, service.describe(primary.values),
                AppColors.modDispersion),
            if (secondary != null && secondary.values.isNotEmpty)
              BoxSeries(secondary.name, service.describe(secondary.values),
                  AppColors.modCentrales),
          ],
          height: secondary == null ? 150 : 190,
          title: 'Diagrama de caja',
          unit: primary.unit,
        );

      case ExerciseVisual.scatter:
        if (primary.pairs.isEmpty) return null;
        return ScatterChart(
          pairs: primary.pairs,
          fit: service.linearFit(primary.pairs),
          xName: primary.xName,
          yName: primary.yName,
          title: primary.variableName,
        );

      case ExerciseVisual.dotPlot:
        if (primary.values.isEmpty) return null;
        return DotPlotChart(
          values: primary.values,
          stats: service.describe(primary.values),
          title: primary.variableName,
          subtitle: 'Un punto por observación',
        );

      case ExerciseVisual.line:
        if (primary.values.isEmpty) return null;
        return LineChart(
          values: primary.values,
          labels: List<String>.generate(
              primary.values.length, (int i) => 'S${i + 1}'),
          title: primary.variableName,
          subtitle: 'Eje vertical desde cero',
          xTitle: 'Semana',
        );

      case ExerciseVisual.comparison:
        if (secondary == null) return null;
        final DescriptiveStats a = service.describe(primary.values);
        final DescriptiveStats b = service.describe(secondary.values);
        return Column(
          children: <Widget>[
            DotPlotChart(
              values: primary.values,
              stats: a,
              color: AppColors.modCentrales,
              title: primary.name,
              height: 165,
            ),
            const SizedBox(height: AppSpacing.lg),
            DotPlotChart(
              values: secondary.values,
              stats: b,
              color: AppColors.modDispersion,
              title: secondary.name,
              height: 165,
            ),
          ],
        );
    }
  }
}
