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
///
/// El contenido se lee del sistema de archivos **una sola vez, antes de los
/// tests**, y dentro de ellos se sirve ya cargado. `testWidgets` corre con un
/// reloj simulado en el que una lectura real de disco no llega a completarse
/// nunca: si la app esperase ese `Future` dentro del test, la pantalla de
/// arranque se quedaría cargando y el test agotaría su tiempo.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ContentBundle bundle;

  setUpAll(() async {
    bundle = await const FileContentRepository().load();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  Future<void> pumpApp(WidgetTester tester) async {
    // La ventana por defecto de los tests (800x600) deja fuera de pantalla la
    // mitad de la ruta de módulos, y lo que no se pinta no se puede encontrar
    // ni pulsar. Se usa una pantalla alta, del orden de un móvil real.
    tester.view.physicalSize = const Size(1000, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          contentRepositoryProvider.overrideWithValue(
            _PreloadedContentRepository(bundle),
          ),
        ],
        child: const EstadisticaFundamentalApp(),
      ),
    );

    // El arranque encadena tres pasos asíncronos: el `postFrameCallback` que
    // lanza la carga, el contenido y la hidratación del progreso desde
    // SharedPreferences. Se bombea hasta que la barra de navegación está en
    // pantalla, que es la señal de que el arranque terminó. No se usa
    // `pumpAndSettle` aquí: mientras carga hay una barra de progreso
    // indeterminada, es decir, una animación que no se detiene nunca.
    for (int i = 0;
        i < 20 && find.byType(NavigationBar).evaluate().isEmpty;
        i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.byType(NavigationBar), findsOneWidget,
        reason: 'La app no pasó de la pantalla de arranque');
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

    final Finder tablas = find.text('Tablas').first;
    await tester.ensureVisible(tablas);
    await tester.pumpAndSettle();
    await tester.tap(tablas);
    await tester.pumpAndSettle();

    expect(find.text('El error que este módulo corrige'), findsOneWidget);
    expect(find.text('Idea central'), findsOneWidget);
    expect(find.text('Teoría'), findsOneWidget);
    expect(find.text('Laboratorio'), findsOneWidget);
  });

  // Sin `testWidgets`: aquí sí se lee del disco de verdad, y eso necesita el
  // reloj real.
  test('el contenido cargado es coherente con lo que se muestra', () async {
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        contentRepositoryProvider
            .overrideWithValue(const FileContentRepository()),
      ],
    );
    addTearDown(container.dispose);

    final ContentBundle loaded = await container.read(contentProvider.future);
    expect(loaded.modules.length, 5);
    expect(loaded.exercises.length, greaterThanOrEqualTo(45));
    expect(loaded.datasets.length, greaterThanOrEqualTo(15));
    expect(loaded.tutorTopics.length, greaterThanOrEqualTo(30));
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

/// Sirve un contenido ya cargado en memoria: dentro de un test de widgets no
/// puede haber lectura de disco (ver la nota de arriba).
class _PreloadedContentRepository implements ContentRepository {
  const _PreloadedContentRepository(this.bundle);

  final ContentBundle bundle;

  @override
  Future<ContentBundle> load() async => bundle;
}
