# OverSplit — Documento de Diseño

> Estado actual del juego: lo que está implementado y funcionando en v10.2.
> Mensaje central: *"El que mucho abarca, poco aprieta."*

---

## Visión

OverSplit es un roguelite de gestión donde **cada decisión tiene un tradeoff**. No hay mejoras puramente positivas: cada ventaja sacrifica algo. El jugador que quiera "tenerlo todo" siempre pagará un precio.

### Principios de diseño

- **Ninguna mejora es gratis** — toda ventaja tiene una contrapartida visible.
- **Las builds definen el estilo** — runs minimalistas (1–2 clones eficientes) vs runs caóticas (6 clones descontrolados) son igualmente válidas.
- **El caos es inevitable, pero manejable** — el juego castiga no haber tomado una decisión consciente, no perder el control.

---

## Flujo de juego

```
MainMenu → [Jugar] → Main (start_game)
    → Ola 1: spawn de tareas gradual (0.4s entre c/u)
    → Jugador interactúa / gestiona clones
    → Tareas completadas o fallidas → estrés sube/baja
    → Timer de ola se agota → Ola N+1
    → Cada 3 olas: UpgradeScreen (pausa + 3 cartas, 10s)
    → Estrés = 5 por 10s consecutivos → Game Over
    → Game Over: Volver a jugar / Menú principal
```

---

## Mecánicas implementadas

### Clones y eficiencia

El jugador empieza solo. Puede crear hasta **6 clones** (SPACE) y eliminarlos (Q). Cada clon adicional reduce la eficiencia global:

```
eficiencia_base = 1.0 - (clones - 1) × 0.156
```

| Clones | Eficiencia |
|---|---|
| 1 | 100% |
| 2 | 84% |
| 3 | 69% |
| 4 | 53% |
| 5 | 38% |
| 6 | 22% |

La eficiencia afecta directamente la **velocidad de movimiento** de todos los jugadores. El alpha visual de los sprites también se reduce con la eficiencia (0.3 mín → 1.0 máx).

`MAX_CLONES` es una variable mutable (default 6), modificable por upgrades en runtime.

### Tareas (SwitchTask)

Las tareas son "bombas" con timer. El jugador las completa acercándose y presionando E (o los clones van automáticamente). Tienen 3 capas de feedback visual:

**Capa base:** el tamaño de la bomba escala con el trabajo restante (más grande = más trabajo pendiente).

**Capa de estado (urgencia):** cuando queda menos del 35% del tiempo, la bomba entra en modo urgency — animación pulsante acelerada, borde naranja/rojo parpadeante.

**Capa de decisión (badge):** si los clones asignados son insuficientes para completar la tarea a tiempo, aparece un badge dorado ①②③ con el número recomendado. Desaparece si hay suficientes clones.

Al **completarse**: la bomba se encoge y desaparece (animación shrink + fade).  
Al **fallar**: explota con animación de 4 frames, luego desaparece.

### Sistema de prioridad por click

- **Click izquierdo** en tarea → asigna el clon más cercano disponible a ella. Clicks adicionales asignan más clones. La tarea muestra borde cyan pulsante y el indicador `>> N`.
- **Click derecho** en tarea → cancela todas las asignaciones de esa tarea.

Los clones asignados van directamente a la tarea y tienen prioridad sobre la IA automática.

### IA de clones

Los clones (player_index > 0) tienen IA automática que:
- Busca la tarea más cercana disponible
- Respeta el sistema de reservas (evita que todos vayan al mismo objetivo)
- Mantiene separación entre clones (radio 52px)
- Cuando lleva el 65% de una tarea, empieza a buscar la siguiente
- En Zona de Colapso: 0.2% de chance por frame de ignorar directivas e ir a tarea aleatoria

### Sistema de estrés y colapso

Fallar tareas sube el estrés. Completar tareas lo baja (mín 0). Cada nivel aplica debuffs acumulativos:

| Nivel | Efecto |
|---|---|
| 1 | −5% velocidad |
| 2 | −1s al timeout de tareas nuevas |
| 3 | +0.3s delay de activación en clones nuevos |
| 4 | −10% eficiencia global adicional |
| 5 | **Zona de Colapso** |

**Zona de Colapso (estrés = 5):** la IA de clones se vuelve caótica (chance de ignorar directivas). El HUD entra en shake continuo. Si el estrés se mantiene en 5 durante **10 segundos**, la barra de colapso llega al máximo y es **Game Over**.

El colapso es emergente: el jugador puede recuperarse bajando el estrés antes de que se llene la barra. Si baja del 5, la barra retrocede.

### Puntuación

- Completar tarea: **+100 pts**
- Fallar tarea: **−200 pts**
- Limpiar toda la ola sin fallos: **+ola × 500 pts**

Upgrades pueden modificar estos valores.

### Oleadas

- Intervalo inicial: 20s. Se reduce 1.3s por ola, mínimo 7s.
- Tareas por ola: `min(ola + 1, 8)`.
- Timeout de tarea: decrece con las olas (rango inicial ~12–22s, mínimo 3–5s).
- Work amount (cuánto tarda en completarse): olas 1–3 → 1, olas 4–6 → 1 o 2, ola 7+ → 1, 2 o 3.
- En Zona de Colapso: work amount mínimo forzado a 2.

### Sistema de mejoras

Cada 3 olas aparece `UpgradeScreen` con 3 cartas aleatorias del pool disponible. El jugador tiene **10 segundos** para elegir. Las no elegidas se descartan para esa run. Si el pool se agota, no aparece pantalla.

Al elegir: se aplica la mejora y las otras 2 se descartan.  
Si no elige en 10s: se descartan las 3 sin aplicar ninguna.

---

## Catálogo de mejoras implementadas (17 total)

### Velocidad

| Nombre | Efecto positivo | Contrapartida |
|---|---|---|
| **⚡ Adrenalina** | +60% velocidad base | La eficiencia baja un 10% adicional por cada clon |
| **🎯 Enfoque** | +80% velocidad con 1 clon activo | Con 2+ clones, velocidad cae al 50% |
| **🚶 Caravana** | +30% velocidad cerca de otro clon (< 80px) | Solo: −20% velocidad |

### Interacción

| Nombre | Efecto positivo | Contrapartida |
|---|---|---|
| **💧 Torrente** | x1.5 progreso con 2+ clones en la misma tarea | Solo: −30% progreso |
| **💨 Impulso** | 1ra interacción de cada ola es instantánea | Las siguientes tienen −20% velocidad |
| **🔥 Constancia** | Interactuar sin cortes acumula multiplicador hasta x2 | Cualquier interrupción resetea el stack a x1 |

### Clones

| Nombre | Efecto positivo | Contrapartida |
|---|---|---|
| **🛡 Ejército Mínimo** | Eficiencia = 100% con 1–2 clones | MAX_CLONES se reduce a 3 |
| **👥 Proliferación** | MAX_CLONES sube a 8 | Eficiencia mínima cae al 8% |
| **💀 Sacrificio** | +300 pts al eliminar clon | −200 pts al crear clon |

### Tareas

| Nombre | Efecto positivo | Contrapartida |
|---|---|---|
| **💥 Sobrecarga** | +150 pts por cada tarea fallida | Cada fallo spawnea 1 tarea nueva inmediatamente |
| **⛓ Cadena** | Completar tarea: +3s a todas las activas | Fallar tarea: −5s a todas las activas |
| **🎲 Efecto Dominó** | Racha de 2 completadas sin fallo → x2 score | Cualquier fallo resetea el multiplicador |

### Eficiencia

| Nombre | Efecto positivo | Contrapartida |
|---|---|---|
| **🌀 Caos Controlado** | Tareas urgentes (borde rojo) valen x3 pts | Tareas sin urgencia no dan puntos extra |
| **😌 Zona de Confort** | Sin penalización de eficiencia hasta 4 clones | Con 5–6 clones, la caída es el doble de pronunciada |
| **🔀 Caos Productivo** | +500 pts cada 10s con eficiencia < 30% | Clones tienen 20% de chance de ignorar directivas |
| **📊 Umbral** | Eficiencia nunca baja del 40% | Eficiencia máxima = 80% aunque tengas 1 clon |

### Meta

| Nombre | Efecto positivo | Contrapartida |
|---|---|---|
| **🔄 Segunda Oportunidad** | Recupera 1 tarea fallida (1 vez por run, vuelve al 50% de progreso) | Al activarse, elimina todos los clones instantáneamente |
| **⌛ Reloj de Arena** | La siguiente ola nunca empieza hasta limpiar todas las tareas | El timeout de todas las tareas de la próxima ola −4s |

---

## Arquitectura técnica

### Autoloads (singletons)

| Nombre | Responsabilidad |
|---|---|
| `AudioManager` | Pool de 10 AudioStreamPlayers, generación procedural de SFX, música WAV en loop |
| `GameManager` | Estado global: olas, eficiencia, score, estrés, colapso, reservas de tareas |
| `UpgradeManager` | Catálogo, upgrades activos, descartados, modificadores de gameplay |

### Señales principales (GameManager)

| Señal | Cuándo se emite |
|---|---|
| `efficiency_changed(value)` | Al cambiar el número de clones o aplicar un upgrade |
| `clone_count_changed(count)` | Al crear o eliminar un clon |
| `wave_started(wave_number)` | Al iniciar cada nueva ola |
| `stress_changed(value, max)` | Al completar o fallar una tarea |
| `zona_colapso_changed(active)` | Al entrar o salir de la Zona de Colapso |

### Resolución y render

- Viewport: **960×540**, ventana fija (no redimensionable)
- Renderer: **GL Compatibility** (Godot 4.6)
- Área de juego: `MAP_MIN = (140, 140)` / `MAP_MAX = (860, 430)`

---

## Menú principal

Pantallas accesibles desde el menú:

- **Catálogo de mejoras** — todas las 17 mejoras organizadas por categoría con colores por categoría, descripción expandible al click.
- **Tutorial** — 6 pasos navegables: ¿Qué es OverSplit?, Controles, Clones y eficiencia, Asignar prioridad, Estrés y colapso, Mejoras.

Colores por categoría en el catálogo:

| Categoría | Color |
|---|---|
| Velocidad | Azul claro |
| Interacción | Verde |
| Clones | Violeta |
| Tareas | Amarillo |
| Eficiencia | Rojo |
| Meta | Amarillo pálido |
