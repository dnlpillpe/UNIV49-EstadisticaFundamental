import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../domain/repositories/content_repository.dart';
import '../providers/app_providers.dart';
import '../widgets/common/app_card.dart';
import '../widgets/common/brand_mark.dart';
import '../widgets/common/callout.dart';
import '../widgets/common/section_header.dart';

/// Acerca de, y —más importante— «cómo calcula».
///
/// La pantalla declara el método de cuantiles que usa la app. No es un detalle
/// menor: el estudiante va a contrastar los resultados con una hoja de cálculo
/// o con su libro de curso, y una discrepancia sin explicación destruye la
/// confianza en la herramienta.
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ContentBundle bundle = ref.watch(bundleProvider);
    final ThemeData theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Acerca de')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xxl),
        children: <Widget>[
          Center(
            child: Column(
              children: <Widget>[
                const BrandMark(size: 92),
                const SizedBox(height: AppSpacing.lg),
                Text(AppInfo.name, style: theme.textTheme.headlineSmall),
                const SizedBox(height: 4),
                Text(AppInfo.tagline,
                    style: theme.textTheme.bodySmall,
                    textAlign: TextAlign.center),
                const SizedBox(height: 4),
                Text('Versión ${AppInfo.version}',
                    style: theme.textTheme.labelSmall),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Cómo calcula esta app',
            icon: Icons.functions,
          ),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Cuantiles y cuartiles',
                    style: theme.textTheme.titleSmall),
                const SizedBox(height: 5),
                Text(AppInfo.quantileMethod,
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: AppSpacing.md),
                const Callout(
                  kind: CalloutKind.warning,
                  text:
                      'Existen otras convenciones. Si tu libro de curso usa la '
                      'regla (n + 1)·p, obtendrás valores ligeramente distintos '
                      'en Q₁ y Q₃. Ninguno de los dos está mal: son métodos '
                      'diferentes, y lo correcto es declarar cuál se usa.',
                ),
                const SizedBox(height: AppSpacing.md),
                _Item(
                  title: 'Varianza y desviación estándar',
                  body:
                      'Se reporta la versión muestral, dividiendo entre n − 1. '
                      'La poblacional (entre n) se usa solo cuando el conjunto '
                      'es la población completa.',
                ),
                _Item(
                  title: 'Valores atípicos',
                  body:
                      'Regla de Tukey: fuera de Q₁ − 1,5·RIC o Q₃ + 1,5·RIC. '
                      'El 1,5 es una convención, no una verdad matemática.',
                ),
                _Item(
                  title: 'Número de clases',
                  body:
                      'Regla de Sturges, k = 1 + 3,322·log₁₀(n), redondeado. '
                      'Es una sugerencia: puedes cambiarla en los laboratorios.',
                ),
                _Item(
                  title: 'Intervalos de clase',
                  body:
                      'Cerrados por la izquierda y abiertos por la derecha, '
                      '[Lᵢ, Lₛ), salvo el último, que incluye el máximo.',
                ),
                _Item(
                  title: 'Asimetría',
                  body:
                      'Se deriva de la relación entre media y mediana, no de un '
                      'coeficiente de tercer momento. Es la comparación que el '
                      'estudiante puede hacer a ojo y justificar.',
                  last: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
              title: 'El tutor', icon: Icons.psychology_alt_outlined),
          const Callout(
            kind: CalloutKind.info,
            text:
                'El tutor responde sobre un corpus de temas revisados. No genera '
                'texto libre y no calcula: cualquier cifra que aparezca en sus '
                'respuestas procede del mismo motor estadístico que el resto de '
                'la app. Cuando no tiene una respuesta contrastada, lo dice.\n\n'
                'Fue una decisión, no una limitación técnica: en estadística, un '
                'tutor que inventa una fórmula o que afirma causalidad a partir '
                'de una correlación enseña justamente lo contrario de lo que '
                'este curso corrige.',
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(
              title: 'Los datos', icon: Icons.folder_open_outlined),
          Callout(
            kind: CalloutKind.warning,
            text:
                'Los ${bundle.datasets.length} conjuntos de datos son realistas '
                'y están construidos para el curso: reproducen situaciones y '
                'órdenes de magnitud verosímiles del ámbito universitario '
                'peruano, pero no proceden de un registro institucional real. '
                'Se indican con su contexto completo —población, unidad, '
                'origen— porque interpretar sin contexto es imposible.',
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionHeader(title: 'Contenido', icon: Icons.inventory_2_outlined),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _Stat(label: 'Módulos', value: '${bundle.modules.length}'),
                _Stat(
                    label: 'Lecciones',
                    value:
                        '${bundle.modules.fold<int>(0, (int a, m) => a + m.lessons.length)}'),
                _Stat(
                    label: 'Tarjetas conceptuales',
                    value:
                        '${bundle.modules.fold<int>(0, (int a, m) => a + m.lessons.fold<int>(0, (int b, l) => b + l.cards.length))}'),
                _Stat(
                    label: 'Laboratorios interactivos',
                    value: '${bundle.modules.length}'),
                _Stat(label: 'Ejercicios', value: '${bundle.exercises.length}'),
                _Stat(
                    label: 'Conjuntos de datos',
                    value: '${bundle.datasets.length}'),
                _Stat(
                    label: 'Términos del glosario',
                    value: '${bundle.glossary.length}'),
                _Stat(
                    label: 'Confusiones catalogadas',
                    value: '${bundle.misconceptions.length}'),
                _Stat(
                    label: 'Temas del tutor',
                    value: '${bundle.tutorTopics.length}',
                    last: true),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            '${AppInfo.area} · ${AppInfo.audience}\n'
            'Educational Mobile Apps Factory',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.successBg,
                borderRadius: BorderRadius.circular(AppSpacing.radiusPill),
              ),
              child: const Text(
                'Funciona sin conexión',
                style: TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.title, required this.body, this.last = false});

  final String title;
  final String body;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: theme.textTheme.titleSmall),
          const SizedBox(height: 3),
          Text(body, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.last = false});

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Container(
      padding: EdgeInsets.only(bottom: last ? 0 : 7),
      decoration: last
          ? null
          : BoxDecoration(
              border: Border(
                bottom: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.5)),
              ),
            ),
      margin: EdgeInsets.only(bottom: last ? 0 : 7),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(value,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        ],
      ),
    );
  }
}
