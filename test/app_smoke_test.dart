import 'package:estadistica_fundamental/app.dart';
import 'package:estadistica_fundamental/domain/repositories/content_repository.dart';
import 'package:estadistica_fundamental/presentation/providers/app_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/file_content_repository.dart';

/// Prueba de humo de la interfaz.
///
/// No intenta cubrir cada pantalla: comprueba que la app arranca, que el
/// contenido llega a la primera pantalla y que la navegación básica funciona.
/// El contenido se inyecta desde el sistema de archivos para que la prueba no
/// dependa del bundle de assets.
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          contentRepositoryProvider.overrideWithValue(
            const FileContentRepository(),
          ),
        ],
        child: const EstadisticaFundamentalApp(),
      ),
    );
    // El arranque dispara la carga en un `postFrameCallback`: hace falta un
    // pump para que se ejecute y otro para que el estado resultante se pinte.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpAndSettle();
  }

  testWidgets('arranca y muestra los cinco módulos', (WidgetTester tester) async {
    await pumpApp(tester);

    expect(find.text('Estadística Fundamental'), findsWidgets);
    expect(find.text('Datos'), findsWidgets);
    expect(find.text('Tablas'), findsWidgets);
    expect(find.text('Medidas centrales'), findsWidgets);
    expect(find.text('Dispersión'), findsWidgets);
    expect(find.text('Gráficos'), findsWidgets);
  });

  testWidgets('propone una primera acción concreta', (WidgetTester tester) async {
    await pumpApp(tester);
    expect(find.text('CONTINÚA POR AQUÍ'), findsOneWidget);
  });

  testWidgets('se entra a un módulo y se ve su problema educativo',
      (WidgetTester tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('Tablas').first);
    await tester.pumpAndSettle();

    expect(find.text('El error que este módulo corrige'), findsOneWidget);
    expect(find.text('Idea central'), findsOneWidget);
    expect(find.text('Teoría'), findsOneWidget);
    expect(find.text('Laboratorio'), findsOneWidget);
  });

  testWidgets('el contenido cargado es coherente con lo que se muestra',
      (WidgetTester tester) async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        contentRepositoryProvider
            .overrideWithValue(const FileContentRepository()),
      ],
    );
    addTearDown(container.dispose);

    final ContentBundle bundle = await container.read(contentProvider.future);
    expect(bundle.modules.length, 5);
    expect(bundle.exercises.length, greaterThanOrEqualTo(45));
    expect(bundle.datasets.length, greaterThanOrEqualTo(15));
    expect(bundle.tutorTopics.length, greaterThanOrEqualTo(30));
  });

  testWidgets('la navegación inferior cambia de sección',
      (WidgetTester tester) async {
    await pumpApp(tester);

    // Los destinos se buscan dentro de la barra de navegación: `IndexedStack`
    // mantiene las cuatro pantallas en el árbol, así que los mismos iconos
    // aparecen también dentro de ellas y una búsqueda global sería ambigua.
    Finder destination(IconData icon) => find.descendant(
          of: find.byType(NavigationBar),
          matching: find.byIcon(icon),
        );

    await tester.tap(destination(Icons.psychology_alt_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Tutor estadístico'), findsWidgets);

    await tester.tap(destination(Icons.insights_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Tu progreso'), findsWidgets);
  });
}
