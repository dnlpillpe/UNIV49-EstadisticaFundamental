import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../providers/app_providers.dart';
import '../../widgets/charts/bar_chart.dart';
import '../../widgets/charts/line_chart.dart';
import '../../widgets/charts/pie_chart.dart';
import '../../widgets/common/callout.dart';
import '../../widgets/common/dataset_selector.dart';

/// Laboratorio 5: producir la distorsión con las propias manos.
///
/// El estudiante mueve el origen del eje y ve la misma serie convertirse en
/// catástrofe o en línea plana. Que sea él quien fabrica el engaño —y no un
/// ejemplo ya hecho— es lo que deja el recuerdo: la próxima vez que vea un
/// gráfico alarmante, mirará el eje.
class MisleadingChartLab extends ConsumerStatefulWidget {
  const MisleadingChartLab({
    super.key,
    required this.datasetIds,
    required this.color,
  });

  final List<String> datasetIds;
  final Color color;

  @override
  ConsumerState<MisleadingChartLab> createState() =>
      _MisleadingChartLabState();
}

class _MisleadingChartLabState extends ConsumerState<MisleadingChartLab> {
  late String _datasetId = widget.datasetIds.first;
  double? _axisMin;
  bool _asBars = false;
  bool _asPie = false;

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final Dataset dataset = bundle.dataset(_datasetId);
    final ThemeData theme = Theme.of(context);

    if (dataset.kind == DatasetKind.categorical) {
      return _categoricalSection(dataset, theme);
    }

    final List<double> values = dataset.values;
    final double dataMin = values.reduce(math.min);
    final double dataMax = values.reduce(math.max);
    final double drop = values.first - values.last;
    final double dropPercent =
        values.first == 0 ? 0 : drop / values.first * 100;

    final double axisMin = _axisMin ?? 0;
    final double exaggeration = _exaggeration(dataMin, dataMax, axisMin);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DatasetSelector(
          ids: widget.datasetIds,
          selected: _datasetId,
          color: widget.color,
          onChanged: (String id) => setState(() {
            _datasetId = id;
            _axisMin = null;
            _asBars = false;
            _asPie = false;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_asBars)
          BarChart(
            entries: <BarEntry>[
              for (int i = 0; i < values.length; i++)
                BarEntry('Semana ${i + 1}', values[i]),
            ],
            color: widget.color,
            zeroBased: false,
            axisMin: axisMin,
            unit: dataset.unit,
            height: 34.0 * values.length + 46,
            title: dataset.variableName,
            subtitle: 'Barras · eje desde ${Num.auto(axisMin)}',
          )
        else
          LineChart(
            values: values,
            labels: List<String>.generate(
                values.length, (int i) => 'S${i + 1}'),
            color: widget.color,
            axisMin: axisMin,
            axisMax: dataMax + (dataMax - dataMin) * 0.08,
            fill: true,
            height: 240,
            title: dataset.variableName,
            subtitle: 'Líneas · eje desde ${Num.auto(axisMin)}',
            xTitle: 'Semana del ciclo',
          ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: <Widget>[
            Text('Origen del eje vertical',
                style: theme.textTheme.titleSmall),
            const Spacer(),
            Text(Num.auto(axisMin),
                style: theme.textTheme.titleSmall
                    ?.copyWith(color: AppColors.danger)),
          ],
        ),
        Slider(
          value: axisMin.clamp(0, dataMin),
          min: 0,
          max: math.max(dataMin, 0.001),
          activeColor: AppColors.danger,
          onChanged: (double v) => setState(() => _axisMin = v),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: SegmentedButton<bool>(
                segments: const <ButtonSegment<bool>>[
                  ButtonSegment<bool>(
                      value: false,
                      label: Text('Líneas'),
                      icon: Icon(Icons.show_chart, size: 16)),
                  ButtonSegment<bool>(
                      value: true,
                      label: Text('Barras'),
                      icon: Icon(Icons.bar_chart, size: 16)),
                ],
                selected: <bool>{_asBars},
                showSelectedIcon: false,
                onSelectionChanged: (Set<bool> s) =>
                    setState(() => _asBars = s.first),
              ),
            ),
          ],
        ),
        if (_axisMin != null && _axisMin! > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: TextButton.icon(
              onPressed: () => setState(() => _axisMin = null),
              icon: const Icon(Icons.restart_alt, size: 17),
              label: const Text('Devolver el eje a cero'),
            ),
          ),
        const SizedBox(height: AppSpacing.lg),
        Callout(
          title: 'Los datos no han cambiado',
          kind: exaggeration > 2.5
              ? CalloutKind.danger
              : (exaggeration > 1.4 ? CalloutKind.warning : CalloutKind.info),
          text: 'La caída real es de ${Num.auto(drop)} ${dataset.unit} sobre '
              '${Num.auto(values.first)}, es decir un '
              '${Num.fixed(dropPercent, 1)} %. '
              'Con el eje empezando en ${Num.auto(axisMin)}, esa misma caída '
              'ocupa ${Num.fixed(exaggeration, 1)} veces más alto del gráfico '
              'que con el eje desde cero.'
              '${_asBars && axisMin > 0 ? '\n\nY en barras esto es directamente inadmisible: el lector compara longitudes, y una barra recortada miente sobre la proporción entre valores.' : ''}',
        ),
        const SizedBox(height: AppSpacing.md),
        const Callout(
          title: 'La rutina de defensa',
          kind: CalloutKind.insight,
          text: '1. ¿Dónde empieza cada eje?\n'
              '2. ¿Qué unidades tiene?\n'
              '3. ¿De cuántos casos sale?\n'
              '4. ¿Qué no se está mostrando?',
        ),
      ],
    );
  }

  /// Cuántas veces se amplifica visualmente el recorrido de los datos al mover
  /// el origen del eje.
  double _exaggeration(double dataMin, double dataMax, double axisMin) {
    final double fullSpan = dataMax - 0;
    final double truncatedSpan = dataMax - axisMin;
    if (truncatedSpan <= 0 || fullSpan <= 0) return 1;
    return fullSpan / truncatedSpan;
  }

  Widget _categoricalSection(Dataset dataset, ThemeData theme) {
    final List<CategoryCount> sorted = List<CategoryCount>.of(dataset.categories)
      ..sort((CategoryCount a, CategoryCount b) => b.count.compareTo(a.count));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DatasetSelector(
          ids: widget.datasetIds,
          selected: _datasetId,
          color: widget.color,
          onChanged: (String id) => setState(() {
            _datasetId = id;
            _axisMin = null;
            _asPie = false;
          }),
        ),
        const SizedBox(height: AppSpacing.lg),
        SegmentedButton<bool>(
          segments: const <ButtonSegment<bool>>[
            ButtonSegment<bool>(
                value: false,
                label: Text('Barras'),
                icon: Icon(Icons.bar_chart, size: 16)),
            ButtonSegment<bool>(
                value: true,
                label: Text('Circular'),
                icon: Icon(Icons.pie_chart_outline, size: 16)),
          ],
          selected: <bool>{_asPie},
          showSelectedIcon: false,
          onSelectionChanged: (Set<bool> s) => setState(() => _asPie = s.first),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_asPie)
          PieChart(
            entries: sorted
                .map((CategoryCount c) =>
                    PieEntry(c.label, c.count.toDouble()))
                .toList(growable: false),
            title: dataset.variableName,
            height: 250,
          )
        else
          BarChart(
            entries: sorted
                .map((CategoryCount c) =>
                    BarEntry(c.label, c.count.toDouble()))
                .toList(growable: false),
            color: widget.color,
            total: dataset.size,
            showPercent: true,
            height: 38.0 * sorted.length + 46,
            title: dataset.variableName,
          ),
        const SizedBox(height: AppSpacing.lg),
        Callout(
          title: _asPie ? 'Intenta ordenarlas a ojo' : 'Ahora prueba el circular',
          kind: _asPie ? CalloutKind.warning : CalloutKind.info,
          text: _asPie
              ? 'Sin mirar la leyenda, ordena de mayor a menor las porciones '
                  'que se parecen. Con ${sorted.length} categorías y varias de '
                  'tamaño similar, el ojo compara ángulos mucho peor que '
                  'longitudes. El circular funciona con dos o tres porciones y '
                  'cuando la pregunta es "¿qué parte del total es esto?".'
              : 'Las barras ordenadas responden de un vistazo a "¿cuál es la '
                  'mayor?" y "¿cuánto más grande es que la siguiente?". '
                  'Cambia al circular y comprueba cuánto cuesta responder a lo '
                  'mismo.',
        ),
      ],
    );
  }
}
