import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../domain/entities/glossary_term.dart';
import '../../domain/entities/study_module.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/formula_block.dart';
import '../widgets/common/module_visuals.dart';

/// Glosario.
///
/// Cada término lleva dos redacciones: la formal, que es la que aparecerá en el
/// examen, y la de andar por casa, que es la que hace que se entienda. Se
/// muestran juntas a propósito; separarlas obligaría al estudiante a elegir
/// entre entender y aprobar.
class GlossaryScreen extends ConsumerStatefulWidget {
  const GlossaryScreen({super.key});

  @override
  ConsumerState<GlossaryScreen> createState() => _GlossaryScreenState();
}

class _GlossaryScreenState extends ConsumerState<GlossaryScreen> {
  String _query = '';
  String? _moduleFilter;

  @override
  Widget build(BuildContext context) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final String needle = _query.trim().toLowerCase();

    final List<GlossaryTerm> terms = bundle.glossary.where((GlossaryTerm t) {
      final bool matchesModule =
          _moduleFilter == null || t.moduleId == _moduleFilter;
      final bool matchesText = needle.isEmpty ||
          t.term.toLowerCase().contains(needle) ||
          t.plainDefinition.toLowerCase().contains(needle) ||
          t.formalDefinition.toLowerCase().contains(needle);
      return matchesModule && matchesText;
    }).toList()
      ..sort((GlossaryTerm a, GlossaryTerm b) => a.term.compareTo(b.term));

    return Scaffold(
      appBar: AppBar(title: const Text('Glosario')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, AppSpacing.sm),
            child: TextField(
              onChanged: (String v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Buscar un término',
                prefixIcon: Icon(Icons.search, size: 20),
                isDense: true,
              ),
            ),
          ),
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: const Text('Todos'),
                    selected: _moduleFilter == null,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _moduleFilter = null),
                  ),
                ),
                for (final StudyModule m in bundle.modules)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(m.title),
                      selected: _moduleFilter == m.id,
                      showCheckmark: false,
                      selectedColor: ModuleVisuals.color(m.colorKey)
                          .withValues(alpha: 0.18),
                      onSelected: (_) =>
                          setState(() => _moduleFilter = m.id),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: terms.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Callout(
                      text: 'Ningún término coincide con esa búsqueda.',
                      kind: CalloutKind.info,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.lg,
                        AppSpacing.md, AppSpacing.lg, AppSpacing.xxl),
                    itemCount: terms.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (BuildContext context, int i) =>
                        _TermCard(term: terms[i], bundle: bundle),
                  ),
          ),
        ],
      ),
    );
  }
}

class _TermCard extends StatelessWidget {
  const _TermCard({required this.term, required this.bundle});

  final GlossaryTerm term;
  final ContentBundle bundle;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final StudyModule module = bundle.module(term.moduleId);
    final Color color = ModuleVisuals.color(module.colorKey);

    return AppCard(
      accent: color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                  child: Text(term.term, style: theme.textTheme.titleMedium)),
              Text(module.title,
                  style: theme.textTheme.labelSmall?.copyWith(color: color)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(term.formalDefinition, style: theme.textTheme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm + 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Icon(Icons.chat_bubble_outline,
                    size: 15, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 7),
                Expanded(
                  child: Text('En corto: ${term.plainDefinition}',
                      style: theme.textTheme.bodySmall),
                ),
              ],
            ),
          ),
          if (term.formula != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            FormulaBlock(formula: term.formula!),
          ],
          if (term.caution != null) ...<Widget>[
            const SizedBox(height: AppSpacing.sm),
            Callout(text: term.caution!, kind: CalloutKind.warning),
          ],
        ],
      ),
    );
  }
}
