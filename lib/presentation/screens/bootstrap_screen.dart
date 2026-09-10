import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_info.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../providers/app_providers.dart';
import '../widgets/common/brand_mark.dart';
import 'home_shell.dart';

/// Pantalla de arranque.
///
/// Carga el contenido y el progreso persistido antes de construir ninguna otra
/// pantalla. A cambio de un segundo de espera, el resto de la app accede al
/// contenido de forma síncrona y ninguna pantalla tiene que manejar estados de
/// carga.
class BootstrapScreen extends ConsumerStatefulWidget {
  const BootstrapScreen({super.key});

  @override
  ConsumerState<BootstrapScreen> createState() => _BootstrapScreenState();
}

class _BootstrapScreenState extends ConsumerState<BootstrapScreen> {
  Object? _error;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    try {
      await ref.read(contentProvider.future);
      await ref.read(learnerProvider.notifier).hydrate();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  Future<void> _retry() async {
    setState(() {
      _error = null;
      _ready = false;
    });
    ref.invalidate(contentProvider);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) return const HomeShell();

    return Scaffold(
      backgroundColor: AppColors.navy,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const BrandMark(size: 108),
                const SizedBox(height: AppSpacing.xl),
                const Text(
                  AppInfo.name,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  AppInfo.tagline,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxxl),
                if (_error == null)
                  SizedBox(
                    width: 160,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.white.withValues(alpha: 0.16),
                      color: AppColors.modCentrales,
                      minHeight: 4,
                    ),
                  )
                else ...<Widget>[
                  Text(
                    _errorMessage(_error!),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, height: 1.5),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FilledButton.tonal(
                    onPressed: _retry,
                    child: const Text('Reintentar'),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _errorMessage(Object error) {
    if (error is StateError) return error.message;
    return 'No se pudo cargar el contenido de la aplicación.\n'
        'Si el problema persiste, reinstala la app.\n\n$error';
  }
}
