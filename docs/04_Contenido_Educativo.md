# 04 · Contenido educativo

---

## 1. Los cinco módulos

### Módulo 1 · Datos
> *Qué tienes delante antes de calcular nada*

**El error que corrige.** El estudiante empieza a calcular antes de preguntarse
qué clase de dato tiene. De ahí salen promedios de códigos de carrera, medianas
de colores y conclusiones sobre una población que nunca se midió.

**Idea central.** La escala de medición decide qué operaciones tienen sentido.
No es el preámbulo del curso: es la primera decisión estadística que se toma, y
la que hace inútil todo lo demás si se falla.

| Lección | Contenido |
|---|---|
| 1.1 De la pregunta al dato | Población, muestra, unidad de análisis, sesgo de selección |
| 1.2 Tipos de variable | Cualitativa, discreta, continua; números que no son cantidades |
| 1.3 Escalas de medición | Nominal, ordinal, intervalo, razón; el caso del pH |
| 1.4 Calidad del dato | Faltantes, duplicados, imposibles; el atípico incómodo |

**Laboratorio: Clasificador de variables.** Doce variables reales, cuatro
escalas, corrección inmediata una a una. Cuatro de las doce se escriben con
números y ninguna de esas cuatro admite las mismas operaciones.

---

### Módulo 2 · Tablas
> *Convertir 40 datos sueltos en una forma*

**El error que corrige.** La tabla de frecuencias se construye como un trámite
—Sturges, ancho, límites— y luego no se lee. El estudiante rellena seis columnas
y sigue sin poder decir qué les pasa a esos datos.

**Idea central.** Agrupar es un intercambio: se gana una forma reconocible y se
pierden los valores individuales. Solo vale la pena si se sabe qué se compró y
qué se pagó.

| Lección | Contenido |
|---|---|
| 2.1 Por qué agrupar | De la lista al patrón; fᵢ, hᵢ, Fᵢ, Hᵢ |
| 2.2 Cómo se construye | Sturges, ancho, la convención `[Lᵢ, Lₛ)`, marca de clase |
| 2.3 Cómo se lee | Las cuatro preguntas que responde una tabla |
| 2.4 Lo que se pierde al agrupar | Media agrupada frente a media exacta |

**Laboratorio: Constructor de tablas.** El control de número de clases mueve a
la vez la tabla, el histograma y el error de la media agrupada. Con 2 clases
cualquier distribución parece uniforme; con 15 y 40 datos, el histograma muestra
el azar del muestreo.

La lección 2.4 es el contenido que casi ningún curso hace explícito y el que
separa rellenar una tabla de entenderla.

---

### Módulo 3 · Medidas centrales
> *Tres formas de decir «el centro», y ninguna es intercambiable*

**El error que corrige.** El estudiante calcula la media siempre, porque es la
que sabe calcular. Cuando los datos tienen cola o atípicos, entrega un número
correcto que describe a nadie.

**Idea central.** Media, mediana y moda no son tres formas de aproximar lo
mismo: responden a tres preguntas distintas. Elegir mal no es un error de
cálculo, es un error de interpretación.

| Lección | Contenido |
|---|---|
| 3.1 Tres preguntas distintas | Qué responde cada medida; el caso de los sueldos |
| 3.2 Cuándo cada una | Filtro por escala, después por forma; la señal media–mediana |
| 3.3 La media ponderada | El promedio con créditos; promediar promedios |
| 3.4 El centro no basta | Dos secciones idénticas en el centro |

**Laboratorio: Valor atípico.** Se arrastra el dato más alto y se ve, en
directo, cuánto se mueve la media, cuánto la mediana y cuánto la moda. El
argumento de la robustez convertido en gesto.

Contiene además el caso que la mayoría de cursos omite: **cuándo la mediana es
la equivocada**. Para presupuestar un subsidio de transporte hace falta el
total, y solo la media lo reconstruye.

---

### Módulo 4 · Dispersión
> *La mitad de la respuesta que casi nadie da*

**El error que corrige.** El estudiante calcula la desviación estándar y no sabe
decir qué significa el número. «3,5 puntos» no le dice nada porque nunca lo ha
comparado con nada.

**Idea central.** La dispersión no es un complemento del promedio: es la
variable que decide qué hacer. Dos grupos con el mismo centro y distinta
dispersión exigen intervenciones opuestas.

| Lección | Contenido |
|---|---|
| 4.1 Por qué la media sola miente | Las dos secciones; por qué las desviaciones suman cero |
| 4.2 Rango, cuartiles y RIC | Vallas de Tukey; qué significa «atípico» |
| 4.3 Varianza y desviación estándar | Unidades al cuadrado; por qué `n − 1`; regla empírica y Chebyshev |
| 4.4 Coeficiente de variación | Comparar variables con unidades distintas |

**Laboratorio: Dos secciones.** Tabla comparativa que marca en verde lo que
coincide y en naranja lo que difiere: las tres medidas de centro en verde, las
cuatro de dispersión en naranja. Ese contraste es todo el argumento del módulo.

---

### Módulo 5 · Gráficos
> *Ver los datos y detectar cuándo un gráfico te está mintiendo*

**El error que corrige.** El estudiante elige el gráfico por costumbre y lee el
que le ponen delante sin mirar los ejes. Es exactamente el perfil sobre el que
funciona un gráfico manipulado.

**Idea central.** Un gráfico es un argumento, no una ilustración. Quien lo hizo
tomó decisiones —ejes, escala, agrupación— y esas decisiones pueden cambiar la
conclusión sin cambiar un solo dato.

| Lección | Contenido |
|---|---|
| 5.1 Elegir el gráfico | Por tipo de variable y por pregunta |
| 5.2 Leer histograma y caja | Centro, dispersión, forma y rarezas; qué esconde la caja |
| 5.3 Correlación no es causalidad | Confusión, inversión, azar; `r = 0` no es «sin relación» |
| 5.4 Gráficos que engañan | Eje truncado, área que exagera, eje doble |

**Laboratorio: Detector de gráficos engañosos.** El estudiante mueve el origen
del eje y ve la misma serie convertirse en catástrofe. Que sea él quien fabrica
el engaño —y no un ejemplo ya hecho— es lo que deja el recuerdo.

---

## 2. Los conjuntos de datos

16 conjuntos, 1 974 observaciones. Cada uno declara población, unidad, escala,
procedencia y, cuando corresponde, una advertencia.

| ID | Nombre | n | Papel didáctico |
|---|---|---|---|
| `ds_traslado` | Tiempo de traslado | 40 | Asimetría a la derecha; media 50,75 frente a mediana 40 |
| `ds_notas_parcial` | Notas del parcial | 45 | Escala de intervalo; cero convencional |
| `ds_gasto_transporte` | Gasto semanal | 36 | El caso donde la media es la correcta (presupuesto) |
| `ds_horas_sueno` | Horas de sueño | 38 | Simétrico: cumple la regla empírica al 68,4 % |
| `ds_sueldos_egresados` | Sueldo del primer empleo | 30 | Atípicos verificados; media 2 556,67 frente a mediana 1 825 |
| `ds_seccion_a` | Sección A | 20 | Media 13,15 · s = 0,67 |
| `ds_seccion_b` | Sección B | 20 | Media 13,15 · s = 4,43 |
| `ds_tiempo_respuesta` | Tiempo de respuesta | 40 | Cola extrema; CV del 124 % |
| `ds_ley_cobre` | Ley de cobre | 32 | Ingeniería de Minas; CV del 10 % |
| `ds_ph_rio` | pH del agua | 30 | Ambiental; escala logarítmica |
| `ds_carreras` | Carrera de procedencia | 180 | Nominal; solo admite moda |
| `ds_satisfaccion` | Satisfacción | 160 | Ordinal; la trampa de promediar |
| `ds_residuos` | Residuos del campus | 1 250 kg | Nominal; barras frente a circular |
| `ds_estudio_nota` | Estudio y nota | 25 | Correlación real, `r = 0,93` |
| `ds_bebidas_insolacion` | Bebidas y golpes de calor | 12 | Correlación espuria, `r = 0,98` |
| `ds_asistencia_semanal` | Asistencia semanal | 16 | Serie temporal para el eje truncado |

**Las secciones A y B son el corazón del contenido.** Comparten media (13,15),
mediana (13) y moda (13), y su desviación estándar difiere en un factor de 6,6.
Sostienen el laboratorio del módulo 4 y cuatro ejercicios. La suite de pruebas
verifica que esa coincidencia se mantiene: si alguien edita un valor, el test
falla antes de que el contenido pierda su sentido.

**Los datos son realistas, no institucionales.** Reproducen situaciones y
órdenes de magnitud verosímiles del ámbito universitario peruano, pero no
proceden de un registro real. La app lo declara en «Acerca de».

---

## 3. Las 28 confusiones catalogadas

Son el inventario operativo del problema educativo. Cada una tiene cuatro
campos: qué se suele pensar, por qué no funciona, cómo se hace, y una pregunta
de autocomprobación.

| Módulo | Confusiones |
|---|---|
| 1 · Datos | `escala_numerica` · `ordinal_promediado` · `poblacion_vs_muestra` · `atipico_borrado` · `intervalo_vs_razon` |
| 2 · Tablas | `limite_doble_conteo` · `absoluta_vs_relativa` · `clase_modal_vs_moda` · `media_agrupada` · `acumulada_mal_leida` |
| 3 · Centrales | `media_siempre` · `media_vs_mediana` · `moda_inexistente` · `media_de_medias` · `centro_sin_dispersion` |
| 4 · Dispersión | `rango_vs_desviacion` · `varianza_unidades` · `n_vs_n1` · `regla_empirica_mal_aplicada` · `cv_mal_usado` · `desviacion_comparada_entre_unidades` |
| 5 · Gráficos | `correlacion_causalidad` · `eje_truncado` · `grafico_mal_elegido` · `histograma_vs_barras` · `r_cero_sin_relacion` · `caja_bimodal` · `lectura_caja` |

Cada una está enlazada a los distractores que la producen. El test de integridad
verifica las dos direcciones: que ninguna etiqueta apunte al vacío y que ninguna
confusión catalogada quede sin ejercicio que la genere.

---

## 4. Los ejercicios

50 ejercicios, 15 con justificación, 181 alternativas con retroalimentación
propia.

| Módulo | Ejercicios | Con justificación |
|---|---|---|
| 1 · Datos | 9 | 3 |
| 2 · Tablas | 9 | 2 |
| 3 · Centrales | 10 | 3 |
| 4 · Dispersión | 12 | 4 |
| 5 · Gráficos | 10 | 3 |

Por competencia: análisis descriptivo, interpretación y toma de decisiones,
declarada en cada ejercicio para poder reportar el progreso por competencia.

### Ejercicios representativos

- **`ex_m3_03`** — «¿Cuánto voy a ganar?». Media 2 556,67 frente a mediana
  1 825. La justificación distingue entre «la mediana es más robusta» (correcta)
  y «la mediana siempre es mejor» (incorrecta, y es el atajo más común).
- **`ex_m3_04`** — El caso inverso: presupuestar transporte. Aquí la mediana
  falla, porque no reconstruye el total. Sin este ejercicio, el módulo enseñaría
  una heurística nueva y equivocada.
- **`ex_m4_09`** — La regla empírica aplicada a los sueldos predice un intervalo
  que incluye sueldos negativos y un 68 % donde el dato real es 93,3 %.
- **`ex_m5_03`** — `r = 0,98` entre bebidas frías y golpes de calor. La opción
  incorrecta más tentadora no es «la correlación prueba causa» sino «con más
  datos sí se podría concluir».
- **`ex_m5_06`** — Formulado en negativo: qué **no** se puede concluir de un
  diagrama de caja.

---

## 5. El corpus del tutor

33 temas. Cada uno con título, respuesta revisada, palabras clave, tema
relacionado y, cuando aporta, un ejemplo con datos del propio curso.

Los títulos son la formulación canónica de cada duda y el motor los usa como
claves: eso garantiza que las preguntas sugeridas siempre lleven a una
respuesta, en vez de a un callejón sin salida. La suite de pruebas lo verifica
tema por tema.

Temas más consultados por diseño: cuándo usar media o mediana · qué significa la
desviación estándar · por qué `n − 1` · correlación y causalidad · cómo detectar
un gráfico engañoso · qué gráfico usar · con qué método calcula la app los
cuartiles.

---

## 6. El glosario

46 términos, cada uno con:

- **definición formal** — la que aparecerá en el examen,
- **definición llana** — la que hace que se entienda,
- **fórmula** cuando la tiene, en Unicode legible,
- **advertencia** con el error más frecuente asociado.

Las dos redacciones se muestran juntas a propósito. Separarlas obligaría al
estudiante a elegir entre entender y aprobar.
