import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import '../../../domain/entities/descriptive_stats.dart';
import '../../../domain/entities/measurement.dart';
import 'callout.dart';
import 'stat_tile.dart';

/// Rejilla con el resumen descriptivo completo y su lectura.
///
/// Cada casilla lleva una nota que traduce el número. Es el núcleo de la
/// respuesta al problema del curso: la app calcula al instante para que el
/// esfuerzo del estudiante se gaste en decidir qué medida usar y qué significa,
/// no en la aritmética.
class StatsGrid extends StatelessWidget {
  const StatsGrid({
    super.key,
    required this.stats,
    required this.dataset,
    this.showInterpretation = true,
    this.compact = false,
  });

  final DescriptiveStats stats;
  final Dataset dataset;
  final bool showInterpretation;
  final bool compact;

  bool get _ratioScale => dataset.scale == MeasurementScale.ratio;

  @override
  Widget build(BuildContext context) {
    final String unit = dataset.unit;
    final int dec = dataset.decimals;

    final List<Widget> tiles = <Widget>[
      StatTile(
        label: 'Media',
        value: Num.fixed(stats.mean, dec + 1),
        unit: unit,
        color: AppColors.mean,
        emphasis: true,
        compact: compact,
        note: 'Reparto igualitario del total.',
      ),
      StatTile(
        label: 'Mediana',
        value: Num.fixed(stats.median, dec + 1),
        unit: unit,
        color: AppColors.median,
        emphasis: true,
        compact: compact,
        note: 'La mitad está por debajo.',
      ),
      StatTile(
        label: 'Moda',
        value: stats.modes.isEmpty
            ? 'amodal'
            : stats.modes
                .map((double m) => Num.fixed(m, dec))
                .join(' · '),
        unit: stats.modes.isEmpty ? '' : unit,
        color: AppColors.mode,
        compact: compact,
        note: stats.modes.isEmpty
            ? 'Ningún valor se repite.'
            : stats.isBimodalOrMore
                ? '${stats.modes.length} valores empatados.'
                : 'El valor más frecuente.',
      ),
      StatTile(
        label: 'n',
        value: '${stats.n}',
        compact: compact,
        note: 'Observaciones.',
      ),
      StatTile(
        label: 'Mínimo',
        value: Num.fixed(stats.min, dec),
        unit: unit,
        compact: compact,
      ),
      StatTile(
        label: 'Máximo',
        value: Num.fixed(stats.max, dec),
        unit: unit,
        compact: compact,
      ),
      StatTile(
        label: 'Rango',
        value: Num.fixed(stats.range, dec),
        unit: unit,
        compact: compact,
        note: 'Solo lo fijan dos datos.',
      ),
      StatTile(
        label: 'Q₁',
        value: Num.fixed(stats.q1, dec + 1),
        unit: unit,
        compact: compact,
        note: '25 % por debajo.',
      ),
      StatTile(
        label: 'Q₃',
        value: Num.fixed(stats.q3, dec + 1),
        unit: unit,
        compact: compact,
        note: '75 % por debajo.',
      ),
      StatTile(
        label: 'RIC',
        value: Num.fixed(stats.iqr, dec + 1),
        unit: unit,
        compact: compact,
        note: 'Ancho de la mitad central.',
      ),
      StatTile(
        label: 'Desv. estándar (s)',
        value: Num.fixed(stats.sampleStdDev, dec + 2),
        unit: unit,
        color: AppColors.modDispersion,
        emphasis: true,
        compact: compact,
        note: 'Distancia típica a la media.',
      ),
      StatTile(
        label: 'Varianza (s²)',
        value: Num.fixed(stats.sampleVariance, dec + 2),
        unit: unit.isEmpty ? '' : '$unit²',
        compact: compact,
        note: 'En unidades al cuadrado.',
      ),
      StatTile(
        label: 'Coef. de variación',
        value: _ratioScale
            ? Num.fixed(stats.coefficientOfVariation, 2)
            : 'no aplica',
        unit: _ratioScale ? '%' : '',
        color: AppColors.modDispersion,
        compact: compact,
        note: _ratioScale
            ? 'Dispersión relativa, sin unidades.'
            : 'Requiere escala de razón.',
      ),
      StatTile(
        label: 'Atípicos',
        value: stats.outliers.isEmpty
            ? 'ninguno'
            : '${stats.outliers.length}',
        color: stats.hasOutliers ? AppColors.outlier : null,
        compact: compact,
        note: stats.hasOutliers
            ? 'Fuera de [${Num.auto(stats.lowerFence)}, ${Num.auto(stats.upperFence)}].'
            : 'Todos dentro de las vallas.',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints c) {
            final int columns = c.maxWidth > 560 ? 4 : (c.maxWidth > 380 ? 3 : 2);
            final double spacing = AppSpacing.sm;
            final double width =
                (c.maxWidth - spacing * (columns - 1)) / columns;
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: tiles
                  .map((Widget w) => SizedBox(width: width, child: w))
                  .toList(growable: false),
            );
          },
        ),
        if (showInterpretation) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          Callout(
            title: 'Cómo se lee este conjunto',
            text: _interpretation(),
            kind: CalloutKind.insight,
          ),
        ],
      ],
    );
  }

  String _interpretation() {
    final StringBuffer b = StringBuffer();
    final String u = dataset.unit.isEmpty ? '' : ' ${dataset.unit}';

    b.write('Un caso típico ronda ');
    b.write(stats.skewnessSign == 0
        ? '${Num.auto(stats.mean)}$u (media y mediana casi coinciden). '
        : '${Num.auto(stats.median)}$u según la mediana, mientras la media es '
            '${Num.auto(stats.mean)}$u. ');

    if (stats.skewnessSign > 0) {
      b.write(
          'La media supera a la mediana: la distribución tiene cola hacia los '
          'valores altos, así que la mediana describe mejor el caso típico. ');
    } else if (stats.skewnessSign < 0) {
      b.write(
          'La media queda por debajo de la mediana: hay cola hacia los valores '
          'bajos. ');
    } else {
      b.write('La distribución es aproximadamente simétrica. ');
    }

    if (!stats.sampleStdDev.isNaN) {
      b.write(
          'Un dato se aleja típicamente ${Num.auto(stats.sampleStdDev)}$u de la '
          'media, es decir la mayoría cae entre '
          '${Num.auto(stats.mean - stats.sampleStdDev)} y '
          '${Num.auto(stats.mean + stats.sampleStdDev)}$u. ');
    }

    if (stats.hasOutliers) {
      b.write(
          'Hay ${stats.outliers.length} valor${stats.outliers.length == 1 ? '' : 'es'} '
          'atípico${stats.outliers.length == 1 ? '' : 's'} '
          '(${stats.outliers.map((double v) => Num.auto(v)).join(', ')}): '
          'revísalo${stats.outliers.length == 1 ? '' : 's'} antes de sacar '
          'conclusiones, y no lo${stats.outliers.length == 1 ? '' : 's'} '
          'elimines sin poder demostrar que es un error.');
    } else {
      b.write('Ningún dato queda fuera de las vallas de Tukey.');
    }
    return b.toString();
  }
}
