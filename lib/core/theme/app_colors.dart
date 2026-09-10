import 'package:flutter/material.dart';

/// Paleta de la aplicación.
///
/// La identidad visual es deliberadamente "de datos": azul profundo de fondo
/// institucional y una escala categórica de cinco acentos, uno por módulo, que
/// se reutiliza literalmente como paleta de series en los gráficos. Así el
/// color deja de ser decoración: el naranja de Dispersión en el menú es el
/// mismo naranja de la barra de dispersión en un histograma comparativo.
class AppColors {
  const AppColors._();

  // --- Marca -------------------------------------------------------------
  static const Color navy = Color(0xFF0E2A47);
  static const Color navyDeep = Color(0xFF081B2E);
  static const Color primary = Color(0xFF1B5E8C);
  static const Color primaryLight = Color(0xFF3E86B8);
  static const Color primaryContainer = Color(0xFFD6E7F3);

  // --- Escala categórica (una por módulo, reutilizada en gráficos) --------
  static const Color modDatos = Color(0xFF1B5E8C); // 1. Datos
  static const Color modTablas = Color(0xFF7B5EA7); // 2. Tablas
  static const Color modCentrales = Color(0xFF2A9D8F); // 3. Medidas centrales
  static const Color modDispersion = Color(0xFFE76F51); // 4. Dispersión
  static const Color modGraficos = Color(0xFFD64550); // 5. Gráficos

  /// Paleta categórica para series de datos. El orden importa: está pensada
  /// para leerse bien en secuencia y mantiene contraste en tema oscuro.
  static const List<Color> series = <Color>[
    modDatos,
    modCentrales,
    modDispersion,
    modTablas,
    modGraficos,
    Color(0xFFE9C46A),
    Color(0xFF4C6EF5),
    Color(0xFF9C6644),
  ];

  // --- Semánticos --------------------------------------------------------
  static const Color success = Color(0xFF2A9D8F);
  static const Color successBg = Color(0xFFE3F3F1);
  static const Color warning = Color(0xFFE9A23B);
  static const Color warningBg = Color(0xFFFDF3E3);
  static const Color danger = Color(0xFFD64550);
  static const Color dangerBg = Color(0xFFFBE7E8);
  static const Color info = Color(0xFF3E86B8);
  static const Color infoBg = Color(0xFFE6F0F7);

  /// Color con el que se marcan los valores atípicos en todos los gráficos.
  static const Color outlier = Color(0xFFD64550);

  /// Colores fijos de las tres medidas de tendencia central. Son constantes en
  /// toda la app para que el estudiante asocie color y concepto.
  static const Color mean = Color(0xFF1B5E8C);
  static const Color median = Color(0xFF2A9D8F);
  static const Color mode = Color(0xFFE76F51);

  // --- Superficies claras ------------------------------------------------
  static const Color lightBg = Color(0xFFF4F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFEDF2F7);
  static const Color lightBorder = Color(0xFFD9E2EC);
  static const Color lightText = Color(0xFF102A43);
  static const Color lightTextMuted = Color(0xFF627D98);

  // --- Superficies oscuras ----------------------------------------------
  static const Color darkBg = Color(0xFF0B1C2C);
  static const Color darkSurface = Color(0xFF122A40);
  static const Color darkSurfaceAlt = Color(0xFF19374F);
  static const Color darkBorder = Color(0xFF23455F);
  static const Color darkText = Color(0xFFE6EEF5);
  static const Color darkTextMuted = Color(0xFF9AB3C6);
}
