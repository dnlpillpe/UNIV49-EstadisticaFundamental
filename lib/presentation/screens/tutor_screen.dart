import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/entities/misconception.dart';
import '../../domain/entities/progress.dart';
import '../../domain/entities/tutor.dart';
import '../../domain/repositories/tutor_repository.dart';
import '../../domain/services/tutor_engine.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';

/// Tutor estadístico.
///
/// Hace dos cosas distintas y las dos importan:
///
/// - **Responde** preguntas sobre un corpus curado, y dice claramente cuándo no
///   sabe. Un tutor que responde siempre es un tutor en el que no se puede
///   confiar nunca.
/// - **Diagnostica** sin que le pregunten. Lee el historial de etiquetas de
///   error y señala qué confusión concreta está repitiendo este estudiante. Es
///   la parte más útil, porque quien más lo necesita es justamente quien no
///   sabe qué preguntar.
class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final TextEditingController _input = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final List<TutorMessage> _messages = <TutorMessage>[];
  bool _busy = false;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _ask(String raw) async {
    final String query = raw.trim();
    if (query.isEmpty || _busy) return;

    setState(() {
      _messages.add(TutorMessage(role: TutorRole.student, text: query));
      _busy = true;
      _input.clear();
    });
    _scrollToEnd();

    final TutorRepository repo = ref.read(tutorRepositoryProvider);
    final TutorAnswer answer = await repo.ask(query);

    if (!mounted) return;
    setState(() {
      _messages.add(TutorMessage(
        role: TutorRole.tutor,
        text: answer.text,
        topicId: answer.topicId,
        suggestions: answer.suggestions,
        isFallback: answer.isFallback,
        example: answer.example,
      ));
      _busy = false;
    });
    if (answer.topicId != null) {
      await ref
          .read(learnerProvider.notifier)
          .markTutorTopicAsked(answer.topicId!);
    }
    _scrollToEnd();
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final TutorEngine engine = ref.watch(tutorEngineProvider);
    final List<MisconceptionTally> tallies =
        ref.watch(misconceptionRankingProvider);
    final List<({Misconception misconception, int count})> diagnosis =
        engine.diagnose(tallies);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tutor estadístico'),
        // Es un destino de la barra inferior: sin flecha de retroceso.
        automaticallyImplyLeading: !widget.embedded,
        actions: <Widget>[
          if (_messages.isNotEmpty)
            IconButton(
              tooltip: 'Limpiar conversación',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => setState(_messages.clear),
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView(
              controller: _scroll,
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.lg),
              children: <Widget>[
                if (_messages.isEmpty) ...<Widget>[
                  _Intro(diagnosis: diagnosis, onAsk: _ask),
                ],
                for (final TutorMessage m in _messages) ...<Widget>[
                  _Bubble(message: m, onSuggestion: _ask),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (_busy)
                  const Padding(
                    padding: EdgeInsets.only(top: AppSpacing.sm),
                    child: LinearProgressIndicator(minHeight: 3),
                  ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      controller: _input,
                      textInputAction: TextInputAction.send,
                      onSubmitted: _ask,
                      decoration: const InputDecoration(
                        hintText: '¿Cuándo uso la mediana en vez de la media?',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    onPressed: () => _ask(_input.text),
                    icon: const Icon(Icons.send_rounded, size: 20),
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

class _Intro extends ConsumerWidget {
  const _Intro({required this.diagnosis, required this.onAsk});

  final List<({Misconception misconception, int count})> diagnosis;
  final void Function(String) onAsk;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final List<TutorTopic> topics = ref.watch(bundleProvider).tutorTopics;
    final double blind = ref.watch(blindHitRateProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (diagnosis.isNotEmpty) ...<Widget>[
          Text('LO QUE TU HISTORIAL DICE',
              style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.7)),
          const SizedBox(height: AppSpacing.sm),
          for (final ({Misconception misconception, int count}) d
              in diagnosis) ...<Widget>[
            _DiagnosisCard(misconception: d.misconception, count: d.count),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (blind > 0.25) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Callout(
              title: 'Aciertas más de lo que entiendes',
              kind: CalloutKind.warning,
              text: 'En el ${(blind * 100).round()} % de los ejercicios con '
                  'justificación elegiste bien la alternativa y fallaste el '
                  'porqué. Vuelve a la teoría de esos módulos aunque tu '
                  'puntuación parezca aceptable: en un problema real, la '
                  'justificación es lo que decide.',
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
        ] else ...<Widget>[
          const Callout(
            title: 'Cómo funciona este tutor',
            kind: CalloutKind.info,
            text:
                'Responde sobre un corpus de temas revisados, no genera texto '
                'libre. Si no tiene una respuesta contrastada te lo dirá en '
                'lugar de improvisar una. A medida que resuelvas ejercicios, '
                'aquí aparecerá también un diagnóstico de las confusiones '
                'concretas que estés repitiendo.',
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
        Text('PREGUNTAS FRECUENTES',
            style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 0.7)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: topics
              .take(10)
              .map((TutorTopic t) => ActionChip(
                    label: Text(t.title),
                    onPressed: () => onAsk(t.title),
                  ))
              .toList(growable: false),
        ),
      ],
    );
  }
}

class _DiagnosisCard extends StatelessWidget {
  const _DiagnosisCard({required this.misconception, required this.count});

  final Misconception misconception;
  final int count;

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
              Expanded(
                child: Text(misconception.label,
                    style: theme.textTheme.titleSmall),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.16),
                  borderRadius:
                      BorderRadius.circular(AppSpacing.radiusPill),
                ),
                child: Text('$count ${count == 1 ? 'vez' : 'veces'}',
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.warning)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(misconception.correction,
              style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text('Pregúntate: ${misconception.checkYourself}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.onSuggestion});

  final TutorMessage message;
  final void Function(String) onSuggestion;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isStudent = message.role == TutorRole.student;

    if (isStudent) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 320),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md + 2, vertical: AppSpacing.sm + 2),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Text(message.text,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onPrimary)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        AppCard(
          accent: message.isFallback ? AppColors.warning : AppColors.primary,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _RichAnswer(text: message.text),
              if (message.example != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.radiusSm),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(Icons.dataset_outlined,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(message.example!,
                            style: theme.textTheme.bodySmall),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (message.suggestions.isNotEmpty) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: message.suggestions
                .map((String s) => ActionChip(
                      label: Text(s),
                      onPressed: () => onSuggestion(s),
                    ))
                .toList(growable: false),
          ),
        ],
      ],
    );
  }
}

/// Renderiza el texto del corpus con un subconjunto mínimo de Markdown:
/// negrita con `**` y viñetas con `-`.
///
/// Un renderizador completo de Markdown sería otra dependencia; el corpus está
/// escrito sabiendo qué se soporta, así que basta con esto.
class _RichAnswer extends StatelessWidget {
  const _RichAnswer({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<Widget> blocks = <Widget>[];

    for (final String rawLine in text.split('\n')) {
      final String line = rawLine.trimRight();
      if (line.trim().isEmpty) {
        blocks.add(const SizedBox(height: AppSpacing.sm));
        continue;
      }
      final bool bullet = line.trimLeft().startsWith('- ');
      final String content =
          bullet ? line.trimLeft().substring(2) : line;
      blocks.add(
        Padding(
          padding: EdgeInsets.only(left: bullet ? 12 : 0, bottom: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (bullet) ...<Widget>[
                Padding(
                  padding: const EdgeInsets.only(top: 7, right: 7),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.onSurfaceVariant,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: RichText(
                  text: TextSpan(
                    style: theme.textTheme.bodyMedium,
                    children: _spans(content, theme),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }

  List<TextSpan> _spans(String line, ThemeData theme) {
    final List<TextSpan> spans = <TextSpan>[];
    final RegExp bold = RegExp(r'\*\*(.+?)\*\*');
    int cursor = 0;
    for (final RegExpMatch m in bold.allMatches(line)) {
      if (m.start > cursor) {
        spans.add(TextSpan(text: line.substring(cursor, m.start)));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ));
      cursor = m.end;
    }
    if (cursor < line.length) {
      spans.add(TextSpan(text: line.substring(cursor)));
    }
    return spans;
  }
}
