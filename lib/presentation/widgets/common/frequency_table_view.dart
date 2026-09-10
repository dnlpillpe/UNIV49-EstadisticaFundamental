import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/number_format.dart';
import '../../../domain/entities/frequency_table.dart';

/// Tabla de distribución de frecuencias.
///
/// Las seis columnas llevan el encabezado técnico (fᵢ, hᵢ, Fᵢ, Hᵢ) y, debajo,
/// la pregunta que responde cada una. Es el remedio directo al problema del
/// módulo 2: el estudiante que rellena la tabla sin saber para qué sirve cada
/// columna.
class FrequencyTableView extends StatelessWidget {
  const FrequencyTableView({
    super.key,
    required this.table,
    this.accent,
    this.highlightModal = true,
    this.showHelpRow = true,
  });

  final FrequencyTable table;
  final Color? accent;
  final bool highlightModal;
  final bool showHelpRow;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = accent ?? theme.colorScheme.primary;
    final FrequencyRow? modal = highlightModal ? table.modalClass : null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm + 2),
        border: Border.all(color: theme.colorScheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowHeight: showHelpRow ? 56 : 40,
          dataRowMinHeight: 38,
          dataRowMaxHeight: 44,
          horizontalMargin: AppSpacing.md,
          columnSpacing: AppSpacing.lg,
          headingRowColor: WidgetStatePropertyAll<Color>(
              color.withValues(alpha: 0.10)),
          columns: <DataColumn>[
            _col(context, table.isCategorical ? 'Categoría' : 'Clase',
                showHelpRow ? '¿qué grupo?' : null),
            _col(context, 'xᵢ', showHelpRow ? 'marca' : null,
                numeric: true, hide: table.isCategorical),
            _col(context, 'fᵢ', showHelpRow ? '¿cuántos aquí?' : null,
                numeric: true),
            _col(context, 'hᵢ', showHelpRow ? '¿qué parte?' : null,
                numeric: true),
            _col(context, 'Fᵢ', showHelpRow ? '¿cuántos hasta aquí?' : null,
                numeric: true),
            _col(context, 'Hᵢ', showHelpRow ? '¿qué parte hasta aquí?' : null,
                numeric: true),
          ],
          rows: <DataRow>[
            for (final FrequencyRow r in table.rows)
              DataRow(
                color: modal != null && identical(r, modal)
                    ? WidgetStatePropertyAll<Color>(
                        color.withValues(alpha: 0.13))
                    : null,
                cells: <DataCell>[
                  DataCell(Text(r.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: modal != null && identical(r, modal)
                              ? FontWeight.w700
                              : FontWeight.w500))),
                  DataCell(Text(
                      table.isCategorical ? '—' : Num.auto(r.midpoint),
                      style: theme.textTheme.bodySmall)),
                  DataCell(Text('${r.absolute}',
                      style: theme.textTheme.bodySmall)),
                  DataCell(Text(Num.percent(r.relative * 100),
                      style: theme.textTheme.bodySmall)),
                  DataCell(Text('${r.cumulativeAbsolute}',
                      style: theme.textTheme.bodySmall)),
                  DataCell(Text(Num.percent(r.cumulativeRelative * 100),
                      style: theme.textTheme.bodySmall)),
                ],
              ),
            DataRow(
              color: WidgetStatePropertyAll<Color>(
                  theme.colorScheme.surfaceContainerHighest),
              cells: <DataCell>[
                DataCell(Text('Total', style: theme.textTheme.titleSmall)),
                const DataCell(Text('')),
                DataCell(Text('${table.total}',
                    style: theme.textTheme.titleSmall)),
                DataCell(Text('100,0 %', style: theme.textTheme.titleSmall)),
                const DataCell(Text('')),
                const DataCell(Text('')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  DataColumn _col(BuildContext context, String title, String? help,
      {bool numeric = false, bool hide = false}) {
    final ThemeData theme = Theme.of(context);
    return DataColumn(
      numeric: numeric,
      label: Column(
        crossAxisAlignment:
            numeric ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(hide ? '' : title, style: theme.textTheme.titleSmall),
          if (help != null && !hide)
            Text(help,
                style: theme.textTheme.labelSmall?.copyWith(fontSize: 10)),
        ],
      ),
    );
  }
}
