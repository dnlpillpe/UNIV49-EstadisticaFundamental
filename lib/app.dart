import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_info.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'presentation/screens/bootstrap_screen.dart';

class EstadisticaFundamentalApp extends ConsumerWidget {
  const EstadisticaFundamentalApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      // Se respeta el ajuste del sistema. Muchos estudiantes usan el móvil en
      // aulas con poca luz y el tema oscuro está diseñado, no derivado.
      themeMode: ThemeMode.system,
      onGenerateRoute: AppRouter.onGenerateRoute,
      home: const BootstrapScreen(),
      builder: (BuildContext context, Widget? child) {
        // El factor de escala de texto se acota: por encima de 1,4 los
        // gráficos y las tablas dejan de ser legibles en pantallas pequeñas.
        final MediaQueryData mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(minScaleFactor: 0.85, maxScaleFactor: 1.4),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
