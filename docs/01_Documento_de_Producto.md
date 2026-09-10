# 01 · Documento de producto

**Estadística Fundamental** · Área: Estadística universitaria · Versión 1.0.0 (MVP)

---

## 1. Fase 1 — Análisis educativo

### 1.1 El problema, formulado con precisión

El enunciado de partida era: *«los estudiantes conocen fórmulas, pero tienen
dificultad interpretando datos»*. Es correcto y demasiado ancho para construir
sobre él. Al descomponerlo aparecen cuatro fallos distintos, y solo tres son
tratables con una app:

| Fallo | Qué ocurre | ¿Lo ataca el MVP? |
|---|---|---|
| **Elección de medida** | Calcula la media siempre, porque es la que sabe calcular. No se pregunta si la distribución la admite. | Sí, es el núcleo |
| **Lectura del resultado** | Obtiene `s = 3,52` y no puede decir qué significa. Nunca lo ha comparado con nada. | Sí |
| **Conexión con la decisión** | No relaciona el número con la acción que habilita: presupuestar, intervenir, alertar. | Sí, vía casos de decisión |
| **Aritmética** | Se equivoca al sumar cuarenta números. | **No**, y a propósito |

La cuarta se descarta de forma deliberada. Si el problema es interpretar, evaluar
aritmética es evaluar lo que el estudiante ya sabe hacer, y consume el esfuerzo
que debería ir a la decisión. De ahí la primera decisión de producto: **la
calculadora está siempre disponible**.

### 1.2 El fallo invisible

Hay un quinto fallo que ninguna prueba de opción múltiple detecta: **acertar sin
entender**. En estadística descriptiva el repertorio de respuestas es pequeño
—media, mediana, moda, desviación, rango— y se puede acertar por eliminación o
por heurística aprendida («ante la duda, la mediana»). Un examen le da a ese
estudiante la misma nota que a quien razonó.

Este MVP lo hace visible mediante la **regla 60/40** y lo reporta como
indicador propio: la *tasa de acierto ciego*.

### 1.3 Usuario objetivo

Estudiante universitario de primer o segundo año, de **cualquier carrera**, que
cursa Estadística General o Bioestadística como asignatura de formación básica.

Perfil relevante para el diseño:

- No se dedicará a la estadística; la necesita como herramienta.
- Llega con aversión previa a la asignatura y con la creencia de que consiste en
  memorizar fórmulas.
- Estudia en el móvil, en ratos cortos, y con frecuencia **sin conexión**.
- Va a contrastar los resultados de la app con Excel o con su libro de curso.

Las dos últimas condicionan la arquitectura: contenido empaquetado en el APK, y
el método de cálculo declarado dentro de la app.

### 1.4 Dificultades frecuentes documentadas

Las 28 confusiones catalogadas en `assets/data/misconceptions.json` son el
inventario operativo del problema. Las más determinantes:

- Promediar una escala ordinal codificada como 1–5 sin declarar el supuesto.
- Tratar una escala de intervalo (notas, pH, °C) como de razón.
- Eliminar un valor atípico verificado porque «descuadra el promedio».
- Reportar un centro sin ninguna medida de dispersión al lado.
- Promediar promedios de grupos de distinto tamaño.
- Interpretar la varianza en las unidades originales del problema.
- Aplicar la regla 68–95–99,7 a distribuciones fuertemente asimétricas.
- Leer una correlación alta como una relación causal.
- No mirar dónde empieza el eje vertical de un gráfico.

### 1.5 Competencias desarrolladas

| Competencia | Qué significa aquí | Cómo se ejercita |
|---|---|---|
| **Análisis descriptivo** | Producir la medida correcta para el tipo de dato y la escala | Ejercicios numéricos y de clasificación |
| **Interpretación** | Traducir la cifra a una afirmación sobre el fenómeno | Preguntas de lectura + justificación |
| **Toma de decisiones** | Elegir la medida o el gráfico según la decisión que se va a tomar | Casos profesionales con justificación |

Cada ejercicio declara la suya, de modo que el progreso se reporta por
competencia y no solo por módulo. Un estudiante puede ir bien en «análisis
descriptivo» y mal en «toma de decisiones», y eso es información accionable que
el promedio general esconde.

### 1.6 Por qué existe la necesidad

Estadística General es asignatura obligatoria en prácticamente todas las
carreras del catálogo del proyecto (Minas, Sistemas, Electrónica, Ambiental,
Administración, Economía, Contabilidad, Psicología, Humanidades). Es, por tanto,
la única app del catálogo con **audiencia transversal**: los mismos cinco
módulos sirven al estudiante de minas que analiza leyes de mineral y al de
psicología que interpreta una escala de satisfacción.

Esa transversalidad es también un riesgo —una app para todos puede no ser de
nadie— y se mitiga con los datos: de los 16 conjuntos, siete provienen de
contextos de carrera específicos (ley de cobre, pH de un río, tiempo de
respuesta de un servidor, residuos del campus) y el resto son de vida
universitaria común.

---

## 2. Fase 2 — Validación académica

### 2.1 Cursos relacionados

Estadística General, Estadística Descriptiva, Bioestadística, Métodos
Cuantitativos, Estadística Aplicada a la Investigación.

### 2.2 Tópicos fundamentales cubiertos

Población y muestra · unidad de análisis · tipos de variable · escalas de
medición · calidad del dato · distribución de frecuencias · marca de clase ·
frecuencias relativas y acumuladas · media, mediana y moda · media ponderada ·
asimetría · rango · cuartiles y RIC · vallas de Tukey · varianza y desviación
estándar · coeficiente de variación · regla empírica y Chebyshev · puntuación z ·
elección de gráfico · histograma y diagrama de caja · correlación de Pearson ·
coeficiente de determinación · correlación frente a causalidad · distorsión
gráfica.

### 2.3 Conceptos que el análisis identificó como difíciles

Cuatro, y los cuatro tienen contenido dedicado:

1. **La escala de intervalo.** Que un 0 en un examen no sea «conocimiento nulo»
   es contraintuitivo. Se trata en la lección 1.3, en el laboratorio 1 y en dos
   ejercicios.
2. **Por qué `n − 1`.** Se suele memorizar sin entender. La lección 4.3 explica
   el sesgo que corrige y el ejercicio `ex_m4_12` obliga a decidir según el
   problema, no según la tecla de la calculadora.
3. **Que la varianza no se interpreta.** Está en unidades al cuadrado, y casi
   nadie lo dice en voz alta. Ejercicio `ex_m4_06`.
4. **Que `r = 0` no significa «sin relación».** Ejercicio `ex_m5_07`, con el
   contraejemplo de la parábola, que además está verificado en la suite de
   pruebas.

### 2.4 Aplicación profesional

Cada módulo cierra con una situación de trabajo real: presupuestar un subsidio
de transporte (módulo 3), decidir la intervención docente en dos secciones con
el mismo promedio (módulo 4), y preparar la exposición de cinco minutos ante un
decano (módulo 5).

---

## 3. Fase 3 — Diseño de la experiencia educativa

### 3.1 Cómo aprende el estudiante

Secuencia por módulo, deliberadamente en este orden:

```
teoría corta  →  laboratorio  →  práctica con justificación
```

- **Teoría**: 4 lecciones de 3–7 minutos, en tarjetas que se pasan de una en
  una. Una tarjeta por idea; el formato hace visible que la lección es corta,
  que es lo que evita el abandono. Cada lección cierra con una única frase que
  retener.
- **Laboratorio**: el estudiante manipula y observa. Es la parte que más enseña
  y la que da más tentación de saltarse, por eso pesa **un tercio completo** del
  avance del módulo. El objetivo del laboratorio permanece oculto hasta que el
  estudiante declara haber terminado: adelantar la conclusión anula el
  experimento.
- **Práctica**: 8–12 ejercicios, con justificación en los de mayor dificultad.

### 3.2 Interacción principal

**Decidir y justificar sobre datos con contexto.** No hay ni un solo ejercicio
del tipo «calcula la media de esta lista» sin una pregunta de interpretación
detrás. Los cinco ejercicios estrictamente numéricos existen para anclar el
procedimiento, y todos llevan una explicación que conecta el número con su
lectura.

### 3.3 Los cinco laboratorios

| Laboratorio | Manipulación | Qué debe descubrirse |
|---|---|---|
| Clasificador de variables | Asignar 12 variables reales a su escala | La escala no depende de que el dato lleve números |
| Constructor de tablas | Mover el número de clases entre 2 y 15 | Pocas clases ocultan la forma; muchas la convierten en ruido |
| Valor atípico | Arrastrar el dato más alto | La media se mueve; la mediana y el RIC, no |
| Dos secciones | Comparar dos grupos con el mismo centro | El promedio idéntico llevaría a la misma decisión en dos casos opuestos |
| Gráficos engañosos | Mover el origen del eje vertical | Se puede mentir sin falsear un solo dato |

### 3.4 Evaluación

- **Elección 0,6 + justificación 0,4.** El umbral de dominio de módulo es 0,7 y
  no 0,6, precisamente porque 0,6 es lo que saca quien acierta siempre la
  alternativa y falla siempre el porqué.
- **Se guarda la mejor puntuación de cada ejercicio, no la última.** Reintentar
  nunca debe penalizar. El historial completo sí conserva todos los intentos,
  porque es lo que alimenta el diagnóstico del tutor.
- **Cada alternativa tiene retroalimentación propia**, no un genérico
  «incorrecto». Son 181 textos de retroalimentación.
- **Cada distractor declara la confusión que representa.** De ahí sale el
  diagnóstico.

### 3.5 Lo que se decidió NO hacer

- **Sin gamificación con puntos, rachas ni insignias.** El indicador que la app
  quiere que el estudiante mire es incómodo —el acierto ciego—, y una capa de
  recompensas empujaría exactamente en la dirección contraria: maximizar
  aciertos rápidos.
- **Sin ranking ni comparación entre estudiantes.** La app se usa en un contexto
  con ansiedad previa hacia la asignatura.
- **Sin temporizador.** Interpretar bien y responder rápido no son lo mismo.

---

## 4. Fase 4 — Definición del MVP

### 4.1 Dentro

- 5 módulos completos: teoría, laboratorio y práctica.
- 16 conjuntos de datos con contexto declarado.
- Motor estadístico completo y laboratorio de datos libre.
- Tutor determinista con diagnóstico por historial de errores.
- Progreso local con desglose por módulo y por competencia.
- Glosario de 46 términos con doble redacción, formal y llana.
- Funcionamiento íntegro sin conexión.

### 4.2 Fuera del MVP, y por qué

| Descartado | Motivo |
|---|---|
| Importar datos propios (CSV) | Multiplica los casos límite —codificaciones, separadores, columnas mixtas— y el valor educativo del MVP está en datos con contexto ya interpretado |
| Cuentas, sincronización, panel docente | Exige backend y política de datos de menores; el MVP debe validar primero el valor educativo |
| Estadística inferencial | Es otro curso. Meterlo aquí diluiría el foco: este MVP existe para la descriptiva |
| Exportar informes en PDF | Útil, no esencial para validar el aprendizaje |
| Tutor con modelo de lenguaje | Ver `06_Decision_de_IA.md` |

### 4.3 Cómo se validaría

Tres señales, en orden de importancia:

1. **Caída de la tasa de acierto ciego** entre el módulo 1 y el módulo 5 del
   mismo estudiante. Es la medida directa del objetivo.
2. **Finalización de laboratorios**, no solo de lecciones. Si los estudiantes
   leen y saltan el laboratorio, la hipótesis central del diseño está mal.
3. **Contraste con la nota del curso** en un grupo piloto frente a un grupo de
   control.

---

## 5. Riesgos reconocidos

| Riesgo | Mitigación adoptada |
|---|---|
| Discrepancia de cuartiles con el libro del curso | Se declara el método dentro de la app y se explica que existen otras convenciones |
| El estudiante salta el laboratorio | Pesa un tercio del avance y el módulo no se marca como dominado sin él |
| Los datos no son institucionales reales | Se declara explícitamente en «Acerca de»; el contexto de cada conjunto es verosímil y completo |
| Una app transversal puede no servir a nadie | 7 de 16 conjuntos son de carreras concretas; el resto, de vida universitaria común |
| El contenido en JSON puede romperse al editarlo | Suite de integridad que valida referencias, unicidad y completitud antes de compilar |
