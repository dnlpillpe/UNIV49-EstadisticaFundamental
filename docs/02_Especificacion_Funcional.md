# 02 · Especificación funcional

---

## 1. Mapa de navegación

```
Arranque (carga contenido + progreso)
└── Contenedor con 4 destinos
    ├── Ruta       → Módulo → Lección
    │                       → Laboratorio
    │                       → Práctica → Ejercicio
    ├── Datos      (laboratorio libre sobre los 16 conjuntos)
    ├── Tutor      (consulta + diagnóstico)
    └── Progreso   (avance, competencias, confusiones)

Accesibles desde la barra superior de «Ruta»:
    ├── Glosario
    └── Acerca de  (incluye «Cómo calcula esta app»)
```

**Por qué cuatro destinos y no tres.** El laboratorio de datos está en la barra
principal, no dentro de un módulo. Es una decisión de producto derivada del
diagnóstico: si el problema es interpretar, consultar un cálculo tiene que ser
trivial, no requerir navegar tres niveles.

---

## 2. Pantallas

### 2.1 Arranque

Carga el contenido y el progreso persistido antes de construir cualquier otra
pantalla. A cambio de un segundo de espera, ninguna pantalla posterior maneja
estados de carga y el contenido se accede de forma síncrona.

Ante un fallo de carga muestra el mensaje y un botón de reintento; no deja la
app en blanco.

### 2.2 Ruta (inicio)

- Cabecera con la marca y el anillo de avance global.
- **Tarjeta «Continúa por aquí»**: una única acción concreta, calculada por
  `ProgressService.nextAction`. Prioridad: terminar lo empezado antes de abrir
  algo nuevo (teoría → laboratorio → práctica → repaso si la puntuación está
  bajo el umbral).
- Cinco tarjetas de módulo con anillo de avance y tres indicadores
  (lecciones, laboratorio, ejercicios). El módulo dominado se marca con su
  puntuación.

### 2.3 Módulo

Orden intencionado: primero **el error que este módulo corrige**, después la
**idea central**, y solo entonces el contenido. El estudiante debe saber contra
qué está trabajando antes de empezar.

Secciones: Teoría (lista de lecciones con estado de lectura) · Laboratorio ·
Práctica (con la puntuación media y el aviso si está bajo el umbral) ·
Competencias.

### 2.4 Lección

Tarjetas a pantalla completa que se pasan deslizando. Estructura fija:

```
intro → tarjeta 1 … tarjeta n → idea clave
```

Cinco tipos de tarjeta con tratamiento visual propio: concepto, **aviso**
(errores frecuentes), ejemplo, fórmula y clave. Barra de progreso en la parte
superior. Al terminar, la lección se marca como leída y se encadena la
siguiente del módulo.

### 2.5 Laboratorio

Estructura común: instrucciones numeradas → experimento → botón «He terminado».

El **objetivo del laboratorio permanece oculto** hasta pulsar ese botón. No es
un detalle de interfaz: adelantar la conclusión convierte el experimento en una
ilustración de algo ya dicho.

### 2.6 Práctica y ejercicio

Lista con la mejor puntuación de cada ejercicio, su dificultad (1–3), su
competencia y una marca si pide justificación.

El ejecutor es único para los tres tipos de ejercicio. Estructura:

```
competencia · título · contexto
apoyo visual (conjunto de datos + gráfico o tabla)
enunciado
[pista, bajo demanda]
área de respuesta
[corrección]
acciones
```

### 2.7 Laboratorio de datos

Selector de los 16 conjuntos y, según el tipo:

- **Numérico**: rejilla con las 14 medidas y su lectura, histograma con media y
  mediana marcadas y control de número de clases, diagrama de puntos, diagrama
  de caja, tabla de frecuencias y contraste entre media exacta y agrupada.
- **Categórico**: barras ordenadas, tabla de frecuencias y el mismo dato en
  circular, para que la comparación entre ambos sea del propio estudiante.
- **Bivariado**: dispersión con recta de ajuste, `r`, `r²` y la advertencia
  explícita sobre causalidad.

### 2.8 Tutor

Dos zonas:

- **Diagnóstico proactivo** (sin preguntar nada): las tres confusiones más
  frecuentes del historial, con su corrección y la pregunta de autocomprobación.
  Si la tasa de acierto ciego supera el 25 %, se avisa.
- **Consulta**: entrada de texto y chips de preguntas frecuentes. Las respuestas
  incluyen sugerencias de seguimiento que mantienen la conversación dentro del
  corpus, que es donde el tutor es fiable.

### 2.9 Progreso

Avance global · puntuación media · **tasa de acierto ciego** · número de
intentos · avance por módulo · puntuación por competencia · confusiones
detectadas ordenadas por frecuencia · reinicio con confirmación.

### 2.10 Glosario

46 términos con buscador y filtro por módulo. Cada entrada: definición formal,
definición en lenguaje llano («En corto:»), fórmula si la tiene y el error más
frecuente asociado.

### 2.11 Acerca de

Incluye **«Cómo calcula esta app»**, con el método de cuantiles y las
convenciones de varianza, atípicos, clases e intervalos. Existe porque el
estudiante contrastará los resultados con Excel o con su libro, y una
discrepancia sin explicación destruye la confianza en la herramienta.

También declara que los datos son realistas pero no institucionales, y explica
la naturaleza determinista del tutor.

---

## 3. Tipos de ejercicio

| Tipo | Interacción | Corrección |
|---|---|---|
| **Elección** | Una alternativa entre 3–4 | 1,0 o 0; con justificación, 0,6 + 0,4 |
| **Numérico** | Campo numérico | Tolerancia absoluta declarada por ejercicio |
| **Clasificación** | Asignar cada elemento a una categoría | Proporcional a los aciertos |

**Por qué tres y no diez.** El valor educativo lo aporta la pregunta, no el
mecanismo de respuesta. Multiplicar mecanismos habría multiplicado el código de
interfaz sin enseñar nada nuevo.

**Por qué la clasificación no es todo o nada.** Colocar 7 de 8 escalas
correctamente no es el mismo estado de conocimiento que colocar 2 de 8.

**Sobre la tolerancia numérica.** Se declara por ejercicio y no globalmente:
redondear a un decimal es aceptable en minutos y no lo es en una proporción. Se
aceptan coma y punto decimal, porque el teclado del estudiante puede producir
cualquiera de los dos.

---

## 4. Reglas de puntuación y avance

### 4.1 Corrección

```
sin justificación:   acierto → 1,0        fallo → 0
con justificación:   elección 0,6  +  justificación 0,4
clasificación:       aciertos / total
```

### 4.2 Avance de módulo

Tres tercios iguales: teoría leída, laboratorio completado y ejercicios
intentados.

Que el laboratorio pese un tercio entero es deliberado: es la parte que más
enseña y la que un estudiante saltaría.

### 4.3 Dominio de módulo

Se exige **todo** lo siguiente:

- todas las lecciones leídas,
- laboratorio completado,
- todos los ejercicios intentados,
- puntuación media ≥ **0,70**.

El umbral es 0,70 y no 0,60 por una razón concreta: con justificaciones que
valen 0,4, un 0,60 se alcanza acertando siempre la alternativa y fallando
siempre el porqué. Ese es exactamente el perfil que la app existe para detectar,
y no puede pasar por dominio.

### 4.4 Persistencia

- Se guarda **la mejor** puntuación de cada ejercicio, nunca la última.
- El historial conserva todos los intentos, acotado a los 500 más recientes.
- Todo el estado es un único documento JSON en almacenamiento local, lo que
  elimina la posibilidad de un progreso escrito a medias.
- Si el documento persistido está corrupto o es de una versión incompatible, se
  descarta y se empieza de cero: perder el progreso es malo, dejar la app sin
  arrancar es peor.

---

## 5. Reglas del tutor

1. Responde **solo** desde el corpus curado de 33 temas.
2. Si ninguna coincidencia supera el umbral, **lo dice** y ofrece los temas que
   sí conoce. El fallback es un estado de primera clase, no un error.
3. **No calcula.** Cualquier cifra de sus respuestas procede del mismo motor
   estadístico que el resto de la app.
4. El diagnóstico proactivo se construye del historial de etiquetas de error,
   ordenado por frecuencia y, a igualdad, por recencia.
5. Las sugerencias de seguimiento están verificadas por la suite de pruebas: si
   una sugerencia no encontrara respuesta, el test falla. Un chip que lleva a un
   callejón sin salida es peor que no ofrecer chips.

---

## 6. Requisitos no funcionales

| Requisito | Cómo se cumple |
|---|---|
| **Sin conexión** | Todo el contenido va empaquetado en el APK |
| **Arranque rápido** | Una sola carga inicial; el resto de accesos son síncronos |
| **Legibilidad** | Escala de texto acotada a [0,85 · 1,4]: por encima, gráficos y tablas dejan de leerse en pantallas pequeñas |
| **Tema oscuro** | Diseñado, no derivado: paleta propia con contraste verificado |
| **Sin permisos** | La app no pide ninguno |
| **Sin datos personales** | No hay cuentas, ni analítica, ni red |
| **Orientación** | Vertical: los gráficos están dimensionados para esa proporción |
