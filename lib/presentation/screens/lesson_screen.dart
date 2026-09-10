import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/router/app_router.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/formula_block.dart';
import '../widgets/common/module_visuals.dart';

/// Lectura de una lección: tarjeta a tarjeta, con la idea clave al final.
///
/// Las tarjetas se recorren deslizando en horizontal, no en una lista vertical
/// larga. El motivo es de atención: una tarjeta a la vez obliga a terminar una
/// idea antes de pasar a la siguiente, y el indicador de posición hace visible
/// que la lección es corta, que es lo que evita el abandono.
class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.moduleId, required this.lessonId});

  final String moduleId;
  final String lessonId;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final StudyModule module = bundle.module(widget.moduleId);
    final Lesson lesson =
        module.lessons.firstWhere((Lesson l) => l.id == widget.lessonId);
    final Color color = ModuleVisuals.color(module.colorKey);
    final ThemeData theme = Theme.of(context);

    // Páginas: intro + tarjetas + cierre.
    final int total = lesson.cards.length + 2;
    final bool last = _page == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(lesson.title, overflow: TextOverflow.ellipsis),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(3),
          child: LinearProgressIndicator(
            value: (_page + 1) / total,
            color: color,
            minHeight: 3,
          ),
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: total,
              onPageChanged: (int i) => setState(() => _page = i),
              itemBuilder: (BuildContext context, int index) {
                if (index == 0) {
                  return _Page(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('MÓDULO ${module.order} · ${module.title}',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: color, letterSpacing: 0.7)),
                        const SizedBox(height: AppSpacing.sm),
                        Text(lesson.title,
                            style: theme.textTheme.displaySmall),
                        const SizedBox(height: AppSpacing.lg),
                        Text(lesson.intro,
                            style: theme.textTheme.bodyLarge),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          children: <Widget>[
                            Icon(Icons.schedule,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant),
                            const SizedBox(width: 6),
                            Text(
                                '${lesson.readingMinutes} min · ${lesson.cards.length} tarjetas',
                                style: theme.textTheme.bodySmall),
                          ],
                        ),
                      ],
                    ),
                  );
                }
                if (index == total - 1) {
                  return _Page(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('LO QUE HAY QUE RETENER',
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: color, letterSpacing: 0.7)),
                        const SizedBox(height: AppSpacing.md),
                        Text(lesson.keyIdea,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(height: 1.4)),
                        const SizedBox(height: AppSpacing.xl),
                        Callout(
                          text:
                              'Si dentro de una semana solo recuerdas una frase '
                              'de esta lección, que sea esa.',
                          kind: CalloutKind.insight,
                        ),
                      ],
                    ),
                  );
                }
                return _Page(
                  child: _CardView(card: lesson.cards[index - 1], color: color),
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, 0,
                  AppSpacing.lg, AppSpacing.md),
              child: Row(
                children: <Widget>[
                  Text('${_page + 1} / $total',
                      style: theme.textTheme.labelMedium),
                  const Spacer(),
                  if (_page > 0)
                    TextButton(
                      onPressed: () => _controller.previousPage(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                      ),
                      child: const Text('Anterior'),
                    ),
                  const SizedBox(width: AppSpacing.sm),
                  FilledButton(
                    style: FilledButton.styleFrom(backgroundColor: color),
                    onPressed: () async {
                      if (!last) {
                        await _controller.nextPage(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut,
                        );
                        return;
                      }
                      await ref
                          .read(learnerProvider.notifier)
                          .markLessonRead(lesson.id);
                      if (!context.mounted) return;
                      final int i = module.lessons
                          .indexWhere((Lesson l) => l.id == lesson.id);
                      if (i >= 0 && i < module.lessons.length - 1) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRouter.lesson,
                          arguments: LessonArgs(
                            moduleId: module.id,
                            lessonId: module.lessons[i + 1].id,
                          ),
                        );
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Text(last ? 'Terminar lección' : 'Siguiente'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl),
      child: child,
    );
  }
}

class _CardView extends StatelessWidget {
  const _CardView({required this.card, required this.color});

  final ConceptCard card;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    final (IconData icon, String label, Color tint) = switch (card.kind) {
      CardKind.concept => (Icons.lightbulb_outline, 'CONCEPTO', color),
      CardKind.warning => (
          Icons.report_problem_outlined,
          'CUIDADO AQUÍ',
          const Color(0xFFE9A23B)
        ),
      CardKind.example => (Icons.dataset_outlined, 'EJEMPLO', color),
      CardKind.formula => (Icons.functions, 'FÓRMULA', color),
      CardKind.insight => (Icons.key_outlined, 'CLAVE', const Color(0xFF2A9D8F)),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Icon(icon, size: 17, color: tint),
            const SizedBox(width: 6),
            Text(label,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tint, letterSpacing: 0.8)),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Text(card.heading, style: theme.textTheme.headlineSmall),
        const SizedBox(height: AppSpacing.md),
        Text(card.body, style: theme.textTheme.bodyLarge),
        if (card.formula != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          FormulaBlock(formula: card.formula!),
        ],
        if (card.caption != null) ...<Widget>[
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            color: theme.colorScheme.surfaceContainerHighest,
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.arrow_right_alt,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(card.caption!,
                      style: theme.textTheme.bodyMedium),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
