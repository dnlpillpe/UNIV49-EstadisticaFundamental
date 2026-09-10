# 06 · Decisión sobre inteligencia artificial

**Conclusión: el tutor del MVP es determinista. No usa un modelo de lenguaje.**

No es una limitación técnica ni una carencia pendiente de resolver. Es el
resultado del análisis, y este documento lo justifica y fija las condiciones
bajo las cuales cambiaría.

---

## 1. Qué se pedía

El planteamiento inicial pedía un «tutor estadístico». La pregunta que hay que
responder antes de construirlo no es *cómo* sino **qué problema resuelve la IA
que no resuelve el contenido bien escrito**.

---

## 2. Qué personalización importa aquí

El hallazgo del análisis es que en este dominio hay dos tipos de personalización
y solo uno cambia el aprendizaje:

| Tipo | Ejemplo | ¿Necesita un LLM? |
|---|---|---|
| **De redacción** | Explicar la mediana con otras palabras, o con una analogía de fútbol | Sí, y aporta poco |
| **De contenido** | «Estás confundiendo rango con desviación estándar: te ha pasado 4 veces» | **No**, la produce el historial de errores |

La segunda es la que importa, y para producirla hace falta que **cada distractor
declare qué confusión representa** —lo que este proyecto hace con 28 etiquetas
conceptuales— y no un modelo generativo.

Dicho de otro modo: el trabajo duro de la personalización educativa está en el
diseño del contenido, no en el motor que lo entrega.

---

## 3. Los tres riesgos, en este dominio concreto

Un LLM en un tutor de estadística descriptiva introduce riesgos que en otros
dominios serían tolerables y aquí no:

**1 · Inventar una fórmula.** Un error en el denominador de la varianza, o una
regla de cuartiles distinta de la que usa la app, se propaga a todo lo que el
estudiante calcule después. En una asignatura donde el estudiante ya desconfía
de su propio criterio, no tiene forma de detectarlo.

**2 · Afirmar causalidad.** El módulo 5 dedica una lección entera a que
correlación no implica causa. Un tutor que, ante «¿por qué suben juntas las
ventas de bebidas y los golpes de calor?», responda con una explicación causal
plausible enseñaría exactamente lo contrario que el curso.

**3 · Dar un número distinto al del motor.** La app calcula la mediana de los
sueldos como 1 825. Si el tutor dice 1 850 porque redondeó de otra forma, el
estudiante pierde la confianza en la herramienta entera. Y la confianza es el
activo con el que se paga la aversión previa a la asignatura.

---

## 4. Qué se construyó en su lugar

Un motor determinista con dos funciones distintas:

### 4.1 Responder

Corpus curado de 33 temas, cada uno con la formulación canónica de la duda, una
respuesta revisada y palabras clave. El motor normaliza la consulta (minúsculas,
sin tildes, subíndices convertidos a su base), descarta las palabras sin valor
discriminante y puntúa contra las claves y contra el título del tema.

**Umbral de honestidad.** Si ninguna coincidencia supera el umbral, el tutor
responde:

> «No tengo una respuesta revisada para esa pregunta, y prefiero decírtelo antes
> que improvisar una.»

y ofrece los temas que sí cubre. El fallback es un estado de primera clase del
sistema, no un error. **Un tutor que responde siempre es un tutor en el que no
se puede confiar nunca.**

### 4.2 Diagnosticar

Esta es la parte que un LLM no haría mejor. El motor lee el historial de
etiquetas de error, las ordena por frecuencia y, a igualdad, por recencia, y
muestra las tres principales con su corrección y una pregunta de
autocomprobación. Sin que el estudiante pregunte nada.

Es lo más útil del tutor precisamente porque **quien más lo necesita es quien no
sabe qué preguntar**.

A eso se suma el indicador de **acierto ciego**: si en más del 25 % de los
ejercicios con justificación el estudiante eligió bien y falló el porqué, el
tutor lo señala explícitamente, aunque su puntuación parezca aceptable.

---

## 5. Dónde sí aportaría un modelo generativo

Siendo honestos con el análisis, hay tres usos donde sí añadiría valor real:

1. **Reformular una explicación** cuando el estudiante dice «sigo sin
   entenderlo». El corpus tiene una redacción por tema; un modelo podría dar la
   segunda.
2. **Evaluar una justificación escrita en texto libre**, en lugar de elegida
   entre opciones. Es un salto cualitativo sobre la regla 60/40 actual: pasaría
   de reconocer el razonamiento correcto a producirlo.
3. **Generar variantes de ejercicios** con los mismos datos y distinta pregunta,
   para practicar sin memorizar respuestas.

Ninguno de los tres es necesario para validar la hipótesis educativa del MVP, y
los tres son costosos de hacer bien. Por eso quedan fuera de la primera versión,
no porque no sirvan.

---

## 6. Condiciones para activarlo

`RemoteTutorRepository` implementa la misma interfaz que el tutor local.
Activarlo es sustituir una línea en `presentation/providers/app_providers.dart`:

```dart
final Provider<TutorRepository> tutorRepositoryProvider =
    Provider<TutorRepository>((Ref ref) {
  return LocalTutorRepository(ref.watch(tutorEngineProvider));
  // → RemoteTutorRepository(fallbackEngine: ..., endpoint: ...)
});
```

Antes de hacerlo deben cumplirse **cuatro condiciones**, y ninguna es
negociable:

**1 · Anclaje al corpus.** El modelo responde *con* los temas del corpus como
contexto, no de memoria. Si la pregunta no está cubierta, degrada al motor local
en lugar de improvisar.

**2 · Un único origen para los números.** El modelo nunca calcula. Cualquier
cifra que aparezca en una respuesta procede de `StatisticsService`. Dos fuentes
de cálculo discrepando es la forma más rápida de perder al estudiante.

**3 · Guardarraíl de causalidad.** Filtro previo que impide afirmar que una
variable causa otra a partir de una correlación. Es el error que la app enseña a
evitar; sería absurdo que el tutor lo cometiera.

**4 · Degradación garantizada.** Sin red, con error o con tiempo agotado, se
responde con el motor local. La app funciona sin conexión y eso no se negocia.

Además:

- Sin datos personales del estudiante en la petición.
- Evaluación previa sobre **100 consultas reales de aula**, revisadas por un
  docente de la asignatura, antes de publicar.
- Coste por consulta acotado y medido: una app educativa gratuita con coste
  variable por uso es un problema de sostenibilidad, no de tecnología.

---

## 7. Otras tecnologías evaluadas y descartadas

| Tecnología | Veredicto |
|---|---|
| **Realidad aumentada** | Descartada. No hay ningún objeto físico que visualizar; la estadística descriptiva es abstracción sobre datos, y una capa de RA sería decoración cara |
| **Visión artificial** (fotografiar una tabla del libro) | Descartada del MVP. Es atractiva y su valor educativo es bajo: el problema no es teclear datos, es interpretarlos. Reconsiderar si el análisis de uso muestra que los estudiantes quieren trabajar con datos propios |
| **Voz** | Descartada. El contenido es visual y numérico |
| **Recomendador basado en aprendizaje automático** | Descartado. Con 50 ejercicios y 5 módulos, una regla de prioridad explícita —terminar lo empezado— es más predecible, más explicable y no necesita datos de entrenamiento |
| **Gamificación con puntos y rachas** | Descartada, y por una razón de fondo. El indicador que la app quiere que el estudiante mire es incómodo: el acierto ciego. Una capa de recompensas empujaría a maximizar aciertos rápidos, que es exactamente el comportamiento que el diseño intenta desincentivar |

---

## 8. Resumen

| | |
|---|---|
| **Dentro del MVP** | Motor determinista sobre corpus curado, con umbral de honestidad, y diagnóstico proactivo por historial de etiquetas conceptuales |
| **Fuera** | LLM en la nube (riesgo de fórmulas inventadas, de deriva causal y de cifras discrepantes) y generación automática de ejercicios |
| **Preparado** | `RemoteTutorRepository` con la misma interfaz; activación de una línea, bajo cuatro condiciones documentadas |
