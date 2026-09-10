import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Traduce las claves de color e icono del contenido JSON a valores de Flutter.
///
/// El contenido no conoce Flutter: guarda `"colorKey": "dispersion"` y esta
/// capa decide qué naranja concreto es. Así el equipo docente puede editar el
/// JSON sin tocar código.
class ModuleVisuals {
  const ModuleVisuals._();

  static Color color(String key) {
    switch (key) {
      case 'datos':
        return AppColors.modDatos;
      case 'tablas':
        return AppColors.modTablas;
      case 'centrales':
        return AppColors.modCentrales;
      case 'dispersion':
        return AppColors.modDispersion;
      case 'graficos':
        return AppColors.modGraficos;
      default:
        return AppColors.primary;
    }
  }

  static IconData icon(String key) {
    switch (key) {
      case 'datos':
        return Icons.dataset_outlined;
      case 'tablas':
        return Icons.table_chart_outlined;
      case 'centrales':
        return Icons.center_focus_strong_outlined;
      case 'dispersion':
        return Icons.unfold_more_outlined;
      case 'graficos':
        return Icons.insights_outlined;
      default:
        return Icons.school_outlined;
    }
  }
}
