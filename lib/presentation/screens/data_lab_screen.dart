import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/number_format.dart';
import '../../domain/entities/dataset.dart';
import '../../domain/entities/descriptive_stats.dart';
import '../../domain/entities/frequency_table.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/services/statistics_service.dart';
import '../providers/app_providers.dart';
import '../widgets/charts/bar_chart.dart';
import '../widgets/charts/box_plot_chart.dart';
import '../widgets/charts/dot_plot_chart.dart';
import '../widgets/charts/histogram_chart.dart';
import '../widgets/charts/line_chart.dart';
import '../widgets/charts/pie_chart.dart';
import '../widgets/charts/scatter_chart.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/dataset_panel.dart';
import '../widgets/common/frequency_table_view.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/stats_grid.dart';

/// Laboratorio de datos: los 16 conjuntos del curso, con todas las medidas y
/// todos los gráficos calculados al instante.
///
/// Está en la barra de navegación principal a propósito. Si el problema que la
/// app ataca es la interpretación, la aritmética no debe costar esfuerzo: el
/// estudiante gasta su atención en decidir qué medida usar y qué significa, no
/// en sumar cuarenta números. Es la consecuencia práctica del diagnóstico.
class DataLabScreen extends ConsumerStatefulWidget {
  const DataLabScreen({
    super.key,
    this.embedded = false,
    this.initialDatasetId,
  });

  final bool embedded;
  final String? initialDatasetId;

  @override
  ConsumerState<DataLabScreen> createState() => _DataLabScreenState();
}

class _DataLabScreenState extends ConsumerState<DataLabScreen> {
  String? _datasetId;
  int? _classCount;

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StatisticsService service = ref.watch(statisticsServiceProvider);
    final ThemeData theme = Theme.of(context);

    _datasetId ??= widget.initialDatasetId ?? bundle.datasets.first.id;
    final Dataset dataset = bundle.dataset(_datasetId!);

    final Widget body = ListView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
      children: <Widget>[
        const SectionHeader(
          title: 'Elige un conjunto',
          subtitle:
              'Dieciséis conjuntos con contexto real. Todas las medidas se '
              'calculan al instante: tu trabajo es decidir cuál usar.',
          icon: Icons.folder_open_outlined,
        ),
        _DatasetGrid(
          datasets: bundle.datasets,
          selected: _datasetId!,
          onSelect: (String id) => setState(() {
            _datasetId = id;
            _classCount = null;
          }),
        ),
        const SizedBox(height: AppSpacing.xl),
        DatasetPanel(dataset: dataset, initiallyExpanded: true),
        const SizedBox(height: AppSpacing.xl),
        ..._analysis(dataset, service, theme),
      ],
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Laboratorio de datos'),
        // Dentro del contenedor principal la pantalla es un destino de la barra
        // inferior y no debe mostrar flecha de retroceso.
        automaticallyImplyLeading: !widget.embedded,
      ),
      body: body,
    );
  }

  List<Widget> _analysis(
      Dataset dataset, StatisticsService service, ThemeData theme) {
    switch (dataset.kind) {
      case DatasetKind.categorical:
        final FrequencyTable table =
            service.buildCategoricalTable(dataset.categories);
        return <Widget>[
          const SectionHeader(
            title: 'Distribución',
            subtitle: 'Variable cualitativa: solo admite conteos y moda',
            icon: Icons.bar_chart,
          ),
          BarChart(
            entries: table.rows
                .map((FrequencyRow r) =>
                    BarEntry(r.label, r.absolute.toDouble()))
                .toList(growable: false),
            total: table.total,
            showPercent: true,
            height: 38.0 * table.rows.length + 46,
            title: dataset.variableName,
          ),
          const SizedBox(height: AppSpacing.lg),
          FrequencyTableView(table: table),
          const SizedBox(height: AppSpacing.lg),
          PieChart(
            entries: table.rows
                .map((FrequencyRow r) =>
                    PieEntry(r.label, r.absolute.toDouble()))
                .toList(growable: false),
            title: 'El mismo dato en circular',
            subtitle: 'Compara qué gráfico te deja ordenar las categorías antes',
            height: 250,
          ),
          const SizedBox(height: AppSpacing.lg),
          Callout(
            title: 'Qué puedes calcular con esta variable',
            kind: CalloutKind.info,
            text: 'Escala ${dataset.scale.label.toLowerCase()}. '
                'Medidas de centro admisibles: '
                '${dataset.scale.allowedCentralMeasures.join(', ')}. '
                'La categoría más frecuente es «${table.modalClass?.label ?? '—'}» '
                'con ${table.modalClass?.absolute ?? 0} casos '
                '(${Num.percent((table.modalClass?.relative ?? 0) * 100)}).',
          ),
        ];

      case DatasetKind.bivariate:
        final LinearFit fit = service.linearFit(dataset.pairs);
        return <Widget>[
          const SectionHeader(
            title: 'Relación entre dos variables',
            icon: Icons.scatter_plot_outlined,
          ),
          ScatterChart(
            pairs: dataset.pairs,
            fit: fit,
            xName: '${dataset.xName} (${dataset.xUnit})',
            yName: '${dataset.yName} (${dataset.yUnit})',
            height: 280,
          ),
          const SizedBox(height: AppSpacing.lg),
          Callout(
            title: 'r = ${Num.fixed(fit.correlation, 3)} · '
                'r² = ${Num.percent(fit.rSquared * 100)}',
            kind: CalloutKind.warning,
            text:
                'Relación lineal ${fit.strengthLabel} y ${fit.directionLabel}. '
                'La recta explica el ${Num.percent(fit.rSquared * 100)} de la '
                'variabilidad de ${dataset.yName.toLowerCase()}.\n\n'
                'Y nada de esto prueba causa. Antes de afirmarla habría que '
                'descartar una tercera variable que mueva a las dos, la '
                'posibilidad de que la causalidad vaya al revés, y el azar.',
          ),
        ];

      case DatasetKind.numeric:
        final DescriptiveStats stats = service.describe(dataset.values);
        final int suggested = service.sturgesClassCount(stats.n);
        final int k = _classCount ?? suggested;
        final FrequencyTable table =
            service.buildFrequencyTable(dataset.values, classCount: k);

        return <Widget>[
          const SectionHeader(
            title: 'Resumen descriptivo',
            subtitle: 'Todas las medidas, con su lectura al lado',
            icon: Icons.calculate_outlined,
          ),
          StatsGrid(stats: stats, dataset: dataset),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
              title: 'Forma de la distribución',
              icon: Icons.area_chart_outlined),
          HistogramChart(
            table: table,
            stats: stats,
            showMean: true,
            showMedian: true,
            color: AppColors.modDatos,
            height: 240,
            title: dataset.variableName,
            subtitle: '$k clases · ancho ${Num.auto(table.classWidth)} '
                '${dataset.unit}',
          ),
          Row(
            children: <Widget>[
              Text('Clases', style: theme.textTheme.labelMedium),
              Expanded(
                child: Slider(
                  value: k.toDouble(),
                  min: 2,
                  max: 15,
                  divisions: 13,
                  label: '$k',
                  onChanged: (double v) =>
                      setState(() => _classCount = v.round()),
                ),
              ),
              Text('$k', style: theme.textTheme.labelMedium),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          DotPlotChart(
            values: dataset.values,
            stats: stats,
            title: 'Los datos sin agrupar',
            subtitle: 'Un punto por observación: nada se resume',
            height: 185,
          ),
          const SizedBox(height: AppSpacing.lg),
          BoxPlotChart(
            series: <BoxSeries>[
              BoxSeries(dataset.name, stats, AppColors.modDispersion)
            ],
            height: 150,
            title: 'Diagrama de caja',
            unit: dataset.unit,
          ),
          if (dataset.tags.contains('serie')) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            LineChart(
              values: dataset.values,
              labels: List<String>.generate(
                  dataset.values.length, (int i) => 'S${i + 1}'),
              title: 'Evolución',
              subtitle: 'Eje vertical desde cero',
              height: 220,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
              title: 'Tabla de frecuencias', icon: Icons.table_rows_outlined),
          FrequencyTableView(table: table),
          const SizedBox(height: AppSpacing.md),
          Callout(
            kind: CalloutKind.info,
            text: 'Media exacta ${Num.fixed(stats.mean, 3)} frente a media '
                'agrupada ${Num.fixed(table.groupedMean, 3)}. La diferencia es '
                'lo que cuesta sustituir cada dato por la marca de su clase.',
          ),
        ];
    }
  }
}

class _DatasetGrid extends StatelessWidget {
  const _DatasetGrid({
    required this.datasets,
    required this.selected,
    required this.onSelect,
  });

  final List<Dataset> datasets;
  final String selected;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: datasets.map((Dataset d) {
        final bool isSelected = d.id == selected;
        final IconData icon = switch (d.kind) {
          DatasetKind.numeric => Icons.timeline,
          DatasetKind.categorical => Icons.category_outlined,
          DatasetKind.bivariate => Icons.scatter_plot_outlined,
        };
        return ChoiceChip(
          label: Text(d.name),
          avatar: Icon(icon,
              size: 15,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant),
          selected: isSelected,
          showCheckmark: false,
          onSelected: (_) => onSelect(d.id),
          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          side: BorderSide(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline,
          ),
        );
      }).toList(growable: false),
    );
  }
}
