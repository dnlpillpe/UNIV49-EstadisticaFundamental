import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/measurement.dart';
import '../../widgets/common/app_card.dart';
import '../../widgets/common/callout.dart';

class _Variable {
  const _Variable(this.name, this.scale, this.why);

  final String name;
  final MeasurementScale scale;
  final String why;
}

/// Laboratorio 1: clasificar variables por escala de medición.
///
/// Doce variables reales, sin fórmulas. Se corrige una a una y en el momento,
/// no al final: en una tarea de clasificación el aprendizaje se produce en el
/// instante del error, no en el recuento.
class VariableClassifierLab extends StatefulWidget {
  const VariableClassifierLab({super.key, required this.color});

  final Color color;

  @override
  State<VariableClassifierLab> createState() => _VariableClassifierLabState();
}

class _VariableClassifierLabState extends State<VariableClassifierLab> {
  static const List<_Variable> _variables = <_Variable>[
    _Variable('Carrera de procedencia', MeasurementScale.nominal,
        'Categorías sin orden. Solo admite moda.'),
    _Variable('Código de la carrera (01, 02, 03…)', MeasurementScale.nominal,
        'Etiqueta numérica: sumar dos códigos no significa nada.'),
    _Variable('Nivel de satisfacción (Muy insatisfecho → Muy satisfecho)',
        MeasurementScale.ordinal,
        'Hay orden, pero nada garantiza que los saltos sean iguales.'),
    _Variable('Puesto en el ranking de admisión', MeasurementScale.ordinal,
        'La diferencia entre el 1.º y el 2.º no equivale a la del 50.º y el 51.º.'),
    _Variable('Grado de severidad de un incidente (leve, grave, crítico)',
        MeasurementScale.ordinal, 'Ordena severidad sin cuantificar la distancia.'),
    _Variable('Temperatura del laboratorio en °C', MeasurementScale.interval,
        'El 0 °C es convencional: 20 °C no es el doble de calor que 10 °C.'),
    _Variable('Nota vigesimal del examen', MeasurementScale.interval,
        'Un 0 no es conocimiento nulo, así que un 16 no es el doble que un 8.'),
    _Variable('pH del agua', MeasurementScale.interval,
        'Escala logarítmica: las razones no tienen sentido.'),
    _Variable('Tiempo de traslado en minutos', MeasurementScale.ratio,
        'Cero minutos es ausencia de traslado; 60 sí es el doble de 30.'),
    _Variable('Gasto semanal en soles', MeasurementScale.ratio,
        'Cero soles es no gastar nada.'),
    _Variable('Ley de cobre en porcentaje', MeasurementScale.ratio,
        'Cero por ciento es ausencia de cobre.'),
    _Variable('Número de atenciones diarias en el tópico',
        MeasurementScale.ratio, 'Cero atenciones es ausencia de atenciones.'),
  ];

  final Map<int, MeasurementScale> _answers = <int, MeasurementScale>{};

  int get _correct => _answers.entries
      .where((MapEntry<int, MeasurementScale> e) =>
          _variables[e.key].scale == e.value)
      .length;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: LinearProgressIndicator(
                value: _answers.length / _variables.length,
                color: widget.color,
                minHeight: 6,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Text('$_correct / ${_answers.length}',
                style: theme.textTheme.labelLarge),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        for (int i = 0; i < _variables.length; i++) ...<Widget>[
          _VariableRow(
            variable: _variables[i],
            answer: _answers[i],
            color: widget.color,
            onSelect: (MeasurementScale s) =>
                setState(() => _answers[i] = s),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        if (_answers.length == _variables.length) ...<Widget>[
          const SizedBox(height: AppSpacing.md),
          Callout(
            title: 'Resultado: $_correct de ${_variables.length}',
            kind: _correct == _variables.length
                ? CalloutKind.success
                : CalloutKind.warning,
            text: _correct == _variables.length
                ? 'Las doce correctas. Fíjate en que cuatro de ellas se '
                    'escriben con números y ninguna de esas cuatro admite las '
                    'mismas operaciones.'
                : 'Revisa las que fallaste. El criterio no es si el dato lleva '
                    'números, sino qué operación conserva sentido: distinguir, '
                    'ordenar, restar o dividir.',
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: () => setState(_answers.clear),
            icon: const Icon(Icons.refresh, size: 17),
            label: const Text('Empezar de nuevo'),
          ),
        ],
      ],
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({
    required this.variable,
    required this.answer,
    required this.color,
    required this.onSelect,
  });

  final _Variable variable;
  final MeasurementScale? answer;
  final Color color;
  final void Function(MeasurementScale) onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool answered = answer != null;
    final bool ok = answer == variable.scale;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: answered
          ? (ok ? AppColors.success : AppColors.danger)
          : theme.colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (answered) ...<Widget>[
                Icon(ok ? Icons.check_circle : Icons.cancel,
                    size: 17,
                    color: ok ? AppColors.success : AppColors.danger),
                const SizedBox(width: 6),
              ],
              Expanded(
                  child: Text(variable.name,
                      style: theme.textTheme.titleSmall)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: MeasurementScale.values.map((MeasurementScale s) {
              final bool selected = answer == s;
              final bool isRight = answered && s == variable.scale;
              return ChoiceChip(
                label: Text(s.label),
                selected: selected,
                showCheckmark: false,
                onSelected: (_) => onSelect(s),
                selectedColor: (ok ? AppColors.success : AppColors.danger)
                    .withValues(alpha: 0.20),
                side: BorderSide(
                  color: isRight
                      ? AppColors.success
                      : (selected ? color : theme.colorScheme.outline),
                  width: isRight ? 1.6 : 1,
                ),
              );
            }).toList(growable: false),
          ),
          if (answered) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(variable.why, style: theme.textTheme.bodySmall),
            const SizedBox(height: 3),
            Text(
              'Medidas de centro admisibles: '
              '${variable.scale.allowedCentralMeasures.join(', ')}.',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ],
      ),
    );
  }
}
