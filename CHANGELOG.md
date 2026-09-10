# Changelog

## 1.0.0 — MVP

Primera versión de **Estadística Fundamental**.

### Contenido
- 5 módulos: Datos, Tablas, Medidas centrales, Dispersión y Gráficos.
- 20 lecciones con 93 tarjetas conceptuales.
- 5 laboratorios interactivos, uno por módulo.
- 50 ejercicios, 15 con fase de justificación, 181 alternativas con
  retroalimentación propia.
- 16 conjuntos de datos con contexto declarado (1 974 observaciones).
- 28 confusiones conceptuales catalogadas y enlazadas a sus distractores.
- Glosario de 46 términos con doble redacción.
- Corpus del tutor con 33 temas.

### Producto
- Regla de puntuación 60/40 (elección/justificación) y umbral de dominio 0,70.
- Indicador de **acierto ciego**: porcentaje de aciertos sin justificación
  correcta.
- Diagnóstico proactivo de confusiones a partir del historial de errores.
- Laboratorio de datos libre en la navegación principal.
- Pantalla «Cómo calcula esta app» con el método de cuantiles declarado.

### Técnico
- Arquitectura por capas con dominio en Dart puro.
- Dos dependencias de producción: `flutter_riverpod` y `shared_preferences`.
- Siete tipos de gráfico dibujados con `CustomPainter` propio.
- Funcionamiento íntegro sin conexión.
- Temas claro y oscuro diseñados.
- 8 suites de prueba, incluidas integridad de contenido y verificación de las
  cifras que aparecen en los enunciados.
- Workflows de CI y de compilación de APK con release automática por etiqueta.

### Limitaciones conocidas
- El proyecto no se ha compilado ni ejecutado en un dispositivo: se construyó
  sin SDK de Flutter en el entorno. La primera puerta es el workflow de CI.
- El APK de release se firma con la clave de depuración: no es publicable en
  Google Play.
- Los conjuntos de datos son realistas pero no proceden de registros
  institucionales reales; la app lo declara.
