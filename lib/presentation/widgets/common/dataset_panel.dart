import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/dataset.dart';
import 'app_card.dart';
import 'callout.dart';

/// Panel de contexto de un conjunto de datos.
///
/// Aparece plegado por defecto y siempre disponible. Es una decisión de
/// producto: si el problema que la app ataca es la interpretación, el contexto
/// —población, unidad, procedencia— tiene que estar a un toque en cualquier
/// pantalla donde haya números, no en la lección donde se presentó.
class DatasetPanel extends StatefulWidget {
  const DatasetPanel({
    super.key,
    required this.dataset,
    this.initiallyExpanded = false,
    this.showValues = true,
  });

  final Dataset dataset;
  final bool initiallyExpanded;
  final bool showValues;

  @override
  State<DatasetPanel> createState() => _DatasetPanelState();
}

class _DatasetPanelState extends State<DatasetPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final Dataset d = widget.dataset;
    final ThemeData theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: <Widget>[
                Icon(Icons.folder_open_outlined,
                    size: 18, color: theme.colorScheme.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(d.name, style: theme.textTheme.titleSmall),
                      Text(
                        'n = ${d.size}'
                        '${d.unit.isEmpty ? '' : ' · ${d.unit}'}'
                        ' · ${d.variableKind.label} · escala ${d.scale.label.toLowerCase()}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Icon(_expanded ? Icons.expand_less : Icons.expand_more,
                    size: 20, color: theme.colorScheme.onSurfaceVariant),
              ],
            ),
          ),
          if (_expanded) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _Row(label: 'Contexto', value: d.context),
            if (d.population.isNotEmpty)
              _Row(label: 'Población', value: d.population),
            if (d.source.isNotEmpty) _Row(label: 'Origen', value: d.source),
            if (d.note != null) ...<Widget>[
              const SizedBox(height: AppSpacing.sm),
              Callout(text: d.note!, kind: CalloutKind.warning),
            ],
            if (widget.showValues) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _Values(dataset: d),
            ],
          ],
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6)),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Values extends StatelessWidget {
  const _Values({required this.dataset});

  final Dataset dataset;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<String> chips;
    switch (dataset.kind) {
      case DatasetKind.numeric:
        final List<double> sorted = List<double>.of(dataset.values)..sort();
        chips = sorted
            .map((double v) => Num.fixed(v, dataset.decimals))
            .toList(growable: false);
      case DatasetKind.categorical:
        chips = dataset.categories
            .map((CategoryCount c) => '${c.label}: ${c.count}')
            .toList(growable: false);
      case DatasetKind.bivariate:
        chips = dataset.pairs
            .map((DataPair p) =>
                '(${Num.auto(p.x)}; ${Num.auto(p.y)})')
            .toList(growable: false);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          dataset.kind == DatasetKind.numeric
              ? 'DATOS ORDENADOS'
              : 'DATOS',
          style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: chips
              .map((String c) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(5),
                      border: Border.all(color: theme.colorScheme.outline),
                    ),
                    child: Text(c,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures()
                          ],
                        )),
                  ))
              .toList(growable: false),
        ),
      ],
    );
  }
}
