import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/entities/dataset.dart';
import '../../../domain/repositories/content_repository.dart';
import '../../providers/app_providers.dart';

/// Selector horizontal de conjuntos de datos, compartido por los laboratorios.
class DatasetSelector extends ConsumerWidget {
  const DatasetSelector({
    super.key,
    required this.ids,
    required this.selected,
    required this.color,
    required this.onChanged,
  });

  final List<String> ids;
  final String selected;
  final Color color;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: ids.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (BuildContext context, int i) {
          final Dataset d = bundle.dataset(ids[i]);
          final bool isSelected = selected == ids[i];
          return ChoiceChip(
            label: Text(d.name),
            selected: isSelected,
            showCheckmark: false,
            onSelected: (_) => onChanged(ids[i]),
            selectedColor: color.withValues(alpha: 0.18),
            side: BorderSide(
              color:
                  isSelected ? color : Theme.of(context).colorScheme.outline,
            ),
          );
        },
      ),
    );
  }
}
