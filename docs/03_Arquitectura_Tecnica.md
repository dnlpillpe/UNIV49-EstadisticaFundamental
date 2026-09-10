# 03 · Arquitectura técnica

---

## 1. Stack

| Elemento | Elección | Motivo |
|---|---|---|
| Framework | Flutter (stable) | Un código para Android e iOS; requisito del proyecto |
| Lenguaje | Dart 3.3+ | Registros y `switch` exhaustivo sobre `enum`, que el dominio usa |
| Estado | `flutter_riverpod` ^2.5 | Sin generación de código, testeable sin widgets, y `ProviderScope` permite sustituir repositorios en las pruebas |
| Persistencia | `shared_preferences` ^2.2 | Clave-valor basta: volumen pequeño y sin consultas relacionales |
| Gráficos | `CustomPainter` propio | Ver §4 |
| Enrutado | `Navigator` con rutas nombradas | Ocho destinos, sin enlaces profundos |
| Backend | Ninguno | Ver §5 |

**Dependencias de producción: dos.** Cada dependencia no añadida es una versión
menos que puede romper el build dentro de un año, y este proyecto forma parte de
una biblioteca de apps que debe seguir compilando sin mantenimiento continuo.

---

## 2. Capas

```
presentation  →  domain  ←  data
```

- **domain** — Dart puro. No importa Flutter en ningún archivo de
  `domain/services`. Contiene las entidades, las cuatro reglas de negocio
  (cálculo, corrección, avance, tutor) y las interfaces de repositorio.
- **data** — implementa esas interfaces: contenido desde assets, progreso en
  `SharedPreferences`, tutor local y adaptador remoto.
- **presentation** — Riverpod, pantallas y widgets. No conoce `data`: recibe las
  implementaciones por inyección.

La consecuencia práctica: **toda la lógica educativa se prueba sin arrancar
Flutter**. La suite de dominio corre en milisegundos y es utilizable como puerta
de CI.

### Estructura

```
lib/
├── core/
│   ├── theme/          app_colors · app_theme · app_spacing
│   ├── router/         app_router
│   ├── utils/          number_format
│   └── constants/      app_info
├── domain/
│   ├── entities/       measurement · dataset · descriptive_stats ·
│   │                   frequency_table · exercise · study_module ·
│   │                   glossary_term · misconception · tutor · progress
│   ├── services/       statistics_service · grading_service ·
│   │                   progress_service · tutor_engine
│   └── repositories/   content · progress · tutor  (interfaces)
├── data/
│   └── repositories/   asset_content · prefs_progress ·
│                       local_tutor · remote_tutor
├── presentation/
│   ├── providers/      app_providers
│   ├── screens/        11 pantallas + labs/ (5)
│   └── widgets/        charts/ (8) · common/ (12)
├── app.dart
└── main.dart
```

---

## 3. Modelo de datos

El contenido educativo vive en `assets/data/` como JSON, para que lo pueda
editar el equipo docente sin tocar código.

| Archivo | Contenido | Entidad |
|---|---|---|
| `modules.json` | 5 módulos con lecciones, tarjetas y laboratorio | `StudyModule` |
| `datasets.json` | 16 conjuntos con contexto | `Dataset` |
| `exercises.json` | 50 ejercicios | `Exercise` |
| `glossary.json` | 46 términos | `GlossaryTerm` |
| `misconceptions.json` | 28 confusiones | `Misconception` |
| `tutor_corpus.json` | 33 temas | `TutorTopic` |

**Total: 232 kB.** Se cargan una sola vez al arrancar y se mantienen en memoria.
La alternativa —consultar en cada pantalla— habría añadido asincronía a toda la
interfaz sin ahorrar nada relevante.

### El acoplamiento intencionado

`Exercise.options[].tags` → `Misconception.id`

Es lo que convierte un fallo en un diagnóstico. No hay comprobación en tiempo de
compilación que lo garantice, así que lo garantiza el test de integridad: si un
distractor apunta a una etiqueta inexistente, o si una confusión catalogada no
la produce ningún distractor, la suite falla.

### Estado del estudiante

`LearnerState` se serializa entero como un único JSON:

```
readLessons · completedLabs · bestScores · attempts · tutorAskedTopics
```

Guardar el documento completo, y no una tabla por entidad, elimina la clase de
error más molesta: un progreso escrito a medias tras cerrar la app. Con un
historial de 500 intentos el documento ronda las decenas de kB, muy por debajo
de lo que ralentiza este almacenamiento.

---

## 4. Por qué los gráficos son propios

Siete tipos —histograma, barras, caja, dispersión, puntos, líneas y circular—
dibujados con `CustomPainter`, unas mil líneas de Dart.

**1 · Control pedagógico.** El histograma necesita marcar la media y la mediana
con colores fijos y constantes en toda la app. El diagrama de caja necesita que
los bigotes lleguen al dato más extremo *dentro* de las vallas de Tukey, no al
mínimo absoluto, para que los atípicos aparezcan como puntos sueltos. El
laboratorio del módulo 5 necesita mover el origen del eje en vivo. Las librerías
generalistas hacen difícil exactamente eso.

**2 · Coherencia semántica.** La paleta categórica de módulos es la misma que la
de series de datos: el naranja de «Dispersión» en el menú es el naranja de la
barra de dispersión en un histograma comparativo. El color deja de ser
decoración.

**3 · Cero riesgo de versión.** Una dependencia de gráficos es la que más
probabilidades tiene de romper el build a medio plazo.

Un detalle que ilustra el punto 1: el widget de histograma **no ofrece opción de
separar las barras**. Las barras separadas significan «variable categórica», y
permitir dibujar un histograma con huecos sería ofrecer una herramienta para
cometer el error que el módulo 5 corrige.

---

## 5. Decisiones deliberadas de "no"

| No se hizo | Motivo |
|---|---|
| **Backend / Firebase** | Nada del MVP lo necesita. Sin backend no hay servidor caído, ni política de datos de menores, ni estudiante bloqueado por falta de conexión |
| **Cuentas de usuario** | El progreso es local. Añadir identidad exigiría tratamiento de datos personales de menores de edad |
| **`go_router`** | Ocho destinos sin enlaces profundos ni URL compartibles |
| **`intl`** | El formato en español —coma decimal, espacio fino de millares— cabe en cuarenta líneas. La app está en un solo idioma |
| **`google_fonts`** | Descarga tipografías en tiempo de ejecución: rompería la app sin conexión, que es el escenario habitual en aula |
| **LaTeX** | Dependencia pesada para fórmulas que se leen bien en Unicode (x̄, Σ, √) y que así son accesibles a un lector de pantalla |
| **`build_runner`** | Ninguna generación de código; el proyecto se compila sin pasos previos |
| **`cardTheme` en el tema** | El tipo de ese campo cambió de `CardTheme` a `CardThemeData` entre versiones de Flutter. Se usa un widget `AppCard` propio para no atarse a un rango del SDK |
| **`DropdownButtonFormField`** | Mismo motivo: el nombre de su parámetro de valor cambió entre versiones |

---

## 6. Plataformas nativas

**`android/` e `ios/` no se versionan.** Se regeneran con
`flutter create --platforms=android,ios .`, en local y en CI.

El motivo es de mantenimiento: el scaffolding nativo congelado en un repositorio
es la causa más habitual de que un proyecto Flutter deje de compilar meses
después, por desajustes entre la versión de Gradle, el Android Gradle Plugin y
el SDK. Regenerarlo elimina esa clase entera de fallos.

El precio es que cualquier personalización nativa debe declararse fuera de esas
carpetas. En este proyecto la única es el icono, que se genera con
`flutter_launcher_icons` a partir de `assets/icon/`, en un paso del workflow.

El workflow incluye además un `git checkout -- lib pubspec.yaml test assets`
inmediatamente después de `flutter create`, como red de seguridad por si alguna
versión de la herramienta tocara archivos del proyecto.

---

## 7. El icono

`tool/generate_icon.py` genera los PNG de 1024×1024 reproduciendo en Pillow el
mismo dibujo que `BrandMarkPainter` pinta dentro de la app: un histograma
acampanado, la curva de distribución encima y la línea de la media punteada en
ámbar.

Que el icono y la marca salgan del mismo diseño no es casualidad: el usuario
debe reconocer la app por el símbolo. Y el símbolo elegido es exactamente lo que
la app enseña —los datos brutos, la curva que se lee sobre ellos y la marca del
centro— y no un gráfico genérico.

Se generan dos variantes: la completa con fondo, y una con más margen y fondo
transparente para el icono adaptativo de Android, que recorta hasta un 25 % del
borde.

---

## 8. Pruebas

| Suite | Qué cubre |
|---|---|
| `statistics_service_test` | Motor completo **y las cifras que aparecen en los enunciados** |
| `content_integrity_test` | Ids, referencias cruzadas, etiquetas, alternativas correctas, completitud |
| `grading_service_test` | Regla 60/40, tolerancia numérica, clasificación parcial |
| `progress_service_test` | Avance, dominio, ranking de confusiones, acierto ciego, siguiente acción |
| `tutor_engine_test` | Normalización, coincidencia, fallback honesto y diagnóstico |
| `number_format_test` | Coma decimal, millares, signo tipográfico, NaN |
| `app_smoke_test` | Arranque, contenido en pantalla y navegación básica |

Dos merecen comentario:

**El test de integridad de contenido** es la pieza más reutilizable del
proyecto. Sirve igual para cualquier otra app de la fábrica que guarde su
contenido en JSON, y es la red que impide que un error de edición llegue al APK.

**El test de cifras del contenido** es menos obvio y igual de importante: el
enunciado de `ex_m3_03` afirma que la mediana de los sueldos es 1 825, y el
enunciado de `ex_m4_11` afirma que 26 de 38 estudiantes caen a ±1 desviación.
Esas afirmaciones están en texto plano dentro del JSON y nada impediría que una
edición de los datos las dejara falsas. La suite las verifica contra el motor.

Las pruebas de dominio cargan el contenido con `FileContentRepository`, que lee
del sistema de archivos en lugar del bundle: corren como Dart puro, sin binding
de Flutter.
