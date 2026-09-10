import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/number_format.dart';
import '../../domain/entities/exercise.dart';
import '../../domain/entities/misconception.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../../domain/services/grading_service.dart';
import '../../domain/services/tutor_engine.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/exercise_visual.dart';
import '../widgets/common/module_visuals.dart';

enum _Phase { answer, justify, feedback }

/// Ejecutor de ejercicios.
///
/// Un único ejecutor para los tres tipos. La diferencia entre ellos está en el
/// widget de respuesta; el resto —enunciado, apoyo visual, pista, corrección,
/// explicación y diagnóstico de la confusión— es común, y duplicarlo por tipo
/// habría triplicado el código sin añadir valor educativo.
class ExerciseScreen extends ConsumerStatefulWidget {
  const ExerciseScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  ConsumerState<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends ConsumerState<ExerciseScreen> {
  _Phase _phase = _Phase.answer;
  String? _selected;
  String? _justification;
  final TextEditingController _numeric = TextEditingController();
  final Map<String, String> _assignment = <String, String>{};
  GradedAttempt? _graded;
  bool _showHint = false;

  @override
  void dispose() {
    _numeric.dispose();
    super.dispose();
  }

  void _reset() {
    setState(() {
      _phase = _Phase.answer;
      _selected = null;
      _justification = null;
      _numeric.clear();
      _assignment.clear();
      _graded = null;
      _showHint = false;
    });
  }

  bool _canSubmit(Exercise e) {
    switch (e.type) {
      case ExerciseType.choice:
        return _phase == _Phase.answer
            ? _selected != null
            : _justification != null;
      case ExerciseType.numeric:
        return double.tryParse(_numeric.text.trim().replaceAll(',', '.')) !=
            null;
      case ExerciseType.classify:
        return _assignment.length == e.items.length;
    }
  }

  Future<void> _submit(Exercise e) async {
    final GradingService grading = ref.read(gradingServiceProvider);

    if (e.type == ExerciseType.choice &&
        _phase == _Phase.answer &&
        e.hasJustification) {
      setState(() => _phase = _Phase.justify);
      return;
    }

    late final GradedAttempt result;
    switch (e.type) {
      case ExerciseType.choice:
        result = grading.gradeChoice(
          e,
          selectedOptionId: _selected!,
          justificationOptionId: _justification,
        );
      case ExerciseType.numeric:
        result = grading.gradeNumeric(
          e,
          answer: double.parse(_numeric.text.trim().replaceAll(',', '.')),
        );
      case ExerciseType.classify:
        result = grading.gradeClassify(e, assignment: _assignment);
    }

    await ref.read(learnerProvider.notifier).recordAttempt(
          ExerciseAttempt(
            exerciseId: e.id,
            moduleId: e.moduleId,
            competencyKey: e.competency.key,
            score: result.score,
            choiceCorrect: result.choiceCorrect,
            justificationCorrect: result.justificationCorrect,
            errorTags: result.errorTags,
            timestampMs: DateTime.now().millisecondsSinceEpoch,
          ),
        );

    if (!mounted) return;
    setState(() {
      _graded = result;
      _phase = _Phase.feedback;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final Exercise e = bundle.exercise(widget.exerciseId);
    final StudyModule module = bundle.module(e.moduleId);
    final Color color = ModuleVisuals.color(module.colorKey);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(module.title),
        actions: <Widget>[
          if (e.hint.isNotEmpty && _phase != _Phase.feedback)
            IconButton(
              tooltip: 'Pista',
              icon: Icon(_showHint
                  ? Icons.lightbulb
                  : Icons.lightbulb_outline),
              onPressed: () => setState(() => _showHint = !_showHint),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Text(e.competency.label.toUpperCase(),
              style: theme.textTheme.labelSmall
                  ?.copyWith(color: color, letterSpacing: 0.7)),
          const SizedBox(height: 4),
          Text(e.title, style: theme.textTheme.headlineSmall),
          if (e.context.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(e.context, style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.lg),
          ExerciseVisualView(exercise: e),
          const SizedBox(height: AppSpacing.lg),
          Text(e.prompt, style: theme.textTheme.bodyLarge),
          if (_showHint && e.hint.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            Callout(
                text: e.hint, kind: CalloutKind.info, icon: Icons.lightbulb),
          ],
          const SizedBox(height: AppSpacing.lg),
          ..._answerArea(e, color),
          if (_phase == _Phase.feedback) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            ..._feedbackArea(e),
          ],
          const SizedBox(height: AppSpacing.xl),
          ..._actions(e, bundle, color),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Área de respuesta
  // -------------------------------------------------------------------------

  List<Widget> _answerArea(Exercise e, Color color) {
    switch (e.type) {
      case ExerciseType.choice:
        // La segunda rama solo es válida cuando el ejercicio tiene fase de
        // justificación. Sin esa condición, un ejercicio de elección simple
        // llegaría a la corrección desreferenciando una justificación nula.
        if (_phase == _Phase.answer || !e.hasJustification) {
          final bool revealed = _phase == _Phase.feedback;
          return <Widget>[
            for (final AnswerOption o in e.options)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: _OptionTile(
                  option: o,
                  selected: _selected == o.id,
                  revealed: revealed,
                  color: color,
                  onTap: revealed
                      ? null
                      : () => setState(() => _selected = o.id),
                ),
              ),
          ];
        }
        return <Widget>[
          _ChosenSummary(
            label: 'Tu respuesta',
            text: e.options
                .firstWhere((AnswerOption o) => o.id == _selected)
                .text,
            correct: _phase == _Phase.feedback
                ? _graded?.choiceCorrect
                : null,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(e.justification!.prompt,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: AppSpacing.md),
          for (final AnswerOption o in e.justification!.options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _OptionTile(
                option: o,
                selected: _justification == o.id,
                revealed: _phase == _Phase.feedback,
                color: color,
                onTap: _phase == _Phase.feedback
                    ? null
                    : () => setState(() => _justification = o.id),
              ),
            ),
        ];

      case ExerciseType.numeric:
        final NumericAnswer a = e.numericAnswer!;
        return <Widget>[
          TextField(
            controller: _numeric,
            enabled: _phase != _Phase.feedback,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true, signed: true),
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\-]')),
            ],
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Tu respuesta',
              suffixText: a.unit,
              helperText:
                  'Se acepta con una tolerancia de ±${Num.auto(a.tolerance)}'
                  '${a.unit.isEmpty ? '' : ' ${a.unit}'}. '
                  'Puedes usar coma o punto decimal.',
              helperMaxLines: 3,
            ),
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontFeatures: const <FontFeature>[
              FontFeature.tabularFigures()
            ]),
          ),
        ];

      case ExerciseType.classify:
        return <Widget>[
          for (final ClassifyItem item in e.items)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: _ClassifyRow(
                item: item,
                buckets: e.buckets,
                selected: _assignment[item.id],
                revealed: _phase == _Phase.feedback,
                correctBucket: item.bucketId,
                color: color,
                onSelect: _phase == _Phase.feedback
                    ? null
                    : (String b) => setState(() => _assignment[item.id] = b),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: e.buckets
                .where((ClassifyBucket b) => b.description.isNotEmpty)
                .map((ClassifyBucket b) => Chip(
                      label: Text('${b.label}: ${b.description}'),
                      visualDensity: VisualDensity.compact,
                    ))
                .toList(growable: false),
          ),
        ];
    }
  }

  // -------------------------------------------------------------------------
  // Corrección
  // -------------------------------------------------------------------------

  List<Widget> _feedbackArea(Exercise e) {
    final GradedAttempt g = _graded!;
    final TutorEngine engine = ref.read(tutorEngineProvider);
    final List<Misconception> found = g.errorTags
        .toSet()
        .map(engine.explain)
        .whereType<Misconception>()
        .toList(growable: false);

    return <Widget>[
      Callout(
        title: g.perfect
            ? 'Correcto · ${(g.score * 100).round()} %'
            : g.score > 0
                ? 'Parcialmente correcto · ${(g.score * 100).round()} %'
                : 'Incorrecto · 0 %',
        text: g.choiceFeedback,
        kind: g.perfect
            ? CalloutKind.success
            : g.score > 0
                ? CalloutKind.warning
                : CalloutKind.danger,
      ),
      if (g.justificationFeedback.isNotEmpty) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        Callout(
          title: g.justificationCorrect == true
              ? 'Justificación correcta (0,4)'
              : 'Justificación incorrecta',
          text: g.justificationFeedback,
          kind: g.justificationCorrect == true
              ? CalloutKind.success
              : CalloutKind.danger,
        ),
      ],
      if (g.choiceCorrect && g.justificationCorrect == false) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        const Callout(
          title: 'Acertaste sin entender',
          kind: CalloutKind.warning,
          icon: Icons.visibility_off_outlined,
          text:
              'Elegiste la alternativa correcta y fallaste el porqué. Es el '
              'patrón que esta app busca detectar: en un examen de opción '
              'múltiple habría contado como acierto pleno, y en un problema '
              'real habría fallado.',
        ),
      ],
      const SizedBox(height: AppSpacing.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('POR QUÉ',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(letterSpacing: 0.7)),
            const SizedBox(height: 6),
            Text(e.explanation,
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
      for (final Misconception m in found) ...<Widget>[
        const SizedBox(height: AppSpacing.md),
        _MisconceptionCard(misconception: m),
      ],
    ];
  }

  // -------------------------------------------------------------------------
  // Acciones
  // -------------------------------------------------------------------------

  List<Widget> _actions(Exercise e, ContentBundle bundle, Color color) {
    if (_phase == _Phase.feedback) {
      final List<Exercise> siblings = bundle.exercisesOf(e.moduleId);
      final int index = siblings.indexWhere((Exercise x) => x.id == e.id);
      final bool hasNext = index >= 0 && index < siblings.length - 1;

      return <Widget>[
        if (!(_graded?.perfect ?? false))
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: OutlinedButton.icon(
              onPressed: _reset,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Intentar de nuevo'),
            ),
          ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: color),
          onPressed: () {
            if (hasNext) {
              Navigator.pushReplacementNamed(
                context,
                AppRouter.exercise,
                arguments: ExerciseArgs(exerciseId: siblings[index + 1].id),
              );
            } else {
              Navigator.pop(context);
            }
          },
          child: Text(hasNext ? 'Siguiente ejercicio' : 'Terminar práctica'),
        ),
      ];
    }

    final bool ready = _canSubmit(e);
    final bool goingToJustify = e.type == ExerciseType.choice &&
        _phase == _Phase.answer &&
        e.hasJustification;

    return <Widget>[
      FilledButton(
        style: FilledButton.styleFrom(backgroundColor: color),
        onPressed: ready ? () => _submit(e) : null,
        child: Text(goingToJustify ? 'Continuar' : 'Comprobar'),
      ),
      if (goingToJustify)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.sm),
          child: Text(
            'Después tendrás que explicar por qué. La elección vale 0,6 y el '
            'porqué 0,4.',
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Piezas de la interfaz
// ---------------------------------------------------------------------------

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.revealed,
    required this.color,
    required this.onTap,
  });

  final AnswerOption option;
  final bool selected;
  final bool revealed;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    Color border = theme.colorScheme.outline;
    Color? bg;
    IconData icon = selected
        ? Icons.radio_button_checked
        : Icons.radio_button_unchecked;
    Color iconColor = selected ? color : theme.colorScheme.onSurfaceVariant;

    if (revealed) {
      if (option.correct) {
        border = AppColors.success;
        bg = AppColors.success.withValues(alpha: 0.10);
        icon = Icons.check_circle;
        iconColor = AppColors.success;
      } else if (selected) {
        border = AppColors.danger;
        bg = AppColors.danger.withValues(alpha: 0.10);
        icon = Icons.cancel;
        iconColor = AppColors.danger;
      }
    } else if (selected) {
      border = color;
      bg = color.withValues(alpha: 0.08);
    }

    return AppCard(
      onTap: onTap,
      color: bg,
      borderColor: border,
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(option.text, style: theme.textTheme.bodyMedium),
                if (revealed && (selected || option.correct)) ...<Widget>[
                  const SizedBox(height: 6),
                  Text(
                    option.feedback,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: option.correct
                            ? AppColors.success
                            : AppColors.danger),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChosenSummary extends StatelessWidget {
  const _ChosenSummary({
    required this.label,
    required this.text,
    required this.correct,
  });

  final String label;
  final String text;
  final bool? correct;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color c = correct == null
        ? theme.colorScheme.onSurfaceVariant
        : (correct! ? AppColors.success : AppColors.danger);
    return AppCard(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(
            correct == null
                ? Icons.check_circle_outline
                : (correct! ? Icons.check_circle : Icons.cancel),
            size: 18,
            color: c,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(label.toUpperCase(),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(letterSpacing: 0.6)),
                Text(text, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassifyRow extends StatelessWidget {
  const _ClassifyRow({
    required this.item,
    required this.buckets,
    required this.selected,
    required this.revealed,
    required this.correctBucket,
    required this.color,
    required this.onSelect,
  });

  final ClassifyItem item;
  final List<ClassifyBucket> buckets;
  final String? selected;
  final bool revealed;
  final String correctBucket;
  final Color color;
  final void Function(String)? onSelect;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool ok = selected == correctBucket;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: revealed
          ? (ok ? AppColors.success : AppColors.danger)
          : theme.colorScheme.outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (revealed) ...<Widget>[
                Icon(ok ? Icons.check_circle : Icons.cancel,
                    size: 17,
                    color: ok ? AppColors.success : AppColors.danger),
                const SizedBox(width: 6),
              ],
              Expanded(
                child: Text(item.text, style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: buckets.map((ClassifyBucket b) {
              final bool isSelected = selected == b.id;
              final bool isCorrect = revealed && b.id == correctBucket;
              return ChoiceChip(
                label: Text(b.label),
                selected: isSelected,
                showCheckmark: false,
                onSelected:
                    onSelect == null ? null : (_) => onSelect!(b.id),
                selectedColor: revealed
                    ? (ok ? AppColors.success : AppColors.danger)
                        .withValues(alpha: 0.20)
                    : color.withValues(alpha: 0.18),
                side: BorderSide(
                  color: isCorrect
                      ? AppColors.success
                      : (isSelected ? color : theme.colorScheme.outline),
                  width: isCorrect ? 1.6 : 1,
                ),
              );
            }).toList(growable: false),
          ),
          if (revealed && !ok && item.feedback.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Text(item.feedback,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.danger)),
          ],
        ],
      ),
    );
  }
}

class _MisconceptionCard extends StatelessWidget {
  const _MisconceptionCard({required this.misconception});

  final Misconception misconception;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return AppCard(
      accent: AppColors.warning,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Icon(Icons.psychology_alt_outlined,
                  size: 18, color: AppColors.warning),
              const SizedBox(width: 6),
              Expanded(
                child: Text(misconception.label,
                    style: theme.textTheme.titleSmall),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _Line(label: 'Lo que se suele pensar', text: misconception.whatStudentsThink),
          _Line(label: 'Por qué no funciona', text: misconception.whyItIsWrong),
          _Line(label: 'Cómo se hace', text: misconception.correction),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.help_outline,
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Pregúntate: ${misconception.checkYourself}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line({required this.label, required this.text});

  final String label;
  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.6)),
          Text(text, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
