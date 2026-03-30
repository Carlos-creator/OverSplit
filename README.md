# OverSplit

**Versión:** v11.0  
**Motor:** Godot 4.6 (GDScript)  
**Género:** Puzzle / Gestión / Roguelite  
**Jugar en itch.io:** https://unifroxt.itch.io/oversplit

---

## Temática

> *"El que mucho abarca, poco aprieta."*


## Concepto

> *"Cuantas más cosas haces al mismo tiempo, peor las haces."*

OverSplit es un prototipo de game jam donde el jugador puede clonarse para atender múltiples tareas simultáneas, pero cada clon reduce la eficiencia global. La clave está en decidir cuándo vale la pena dividirse y cuándo concentrarse.

---

## Cómo jugar

### Controles

| Acción | Tecla |
|---|---|
| Mover | Flechas / WASD |
| Crear clon | SPACE |
| Eliminar clon | Q |
| Desactivar bomba | E (en rango) |
| Asignar prioridad a clon | Click izquierdo en bomba |
| Cancelar prioridad | Click derecho en bomba |
| Pausar | ESC / Botón Pausa |
| Velocidad del juego | Botón x1 / x1.5 / x2 |
| Saltar oleada | Botón Skip (solo si no hay tareas activas) |

### Loop principal

1. Aparecen bombas con un temporizador — hay que desactivarlas antes de que exploten
2. Desactivar una bomba requiere presencia; varios clones en la misma bomba la desactivan más rápido
3. Cada ola es más difícil: más bombas, menos tiempo, más trabajo por bomba
4. Cada 3 olas se puede elegir una mejora (upgrade) de 3 opciones aleatorias
5. Las mejoras no elegidas se descartan para siempre en esa run

---

## Sistema de eficiencia

La eficiencia base se calcula según el número de clones activos:

```
eficiencia = 1 - (clones - 1) × 0.156
```

| Clones | Eficiencia base |
|---|---|
| 1 | 100% |
| 2 | 84% |
| 3 | 69% |
| 4 | 53% |
| 5 | 38% |
| 6 | 22% |

La eficiencia afecta la **velocidad de movimiento** de todos los clones.  
Los upgrades pueden modificar este comportamiento (ver catálogo de mejoras).

---

## Sistema de estrés y colapso

Dejar explotar bombas acumula **estrés** (máx. 5). Cada nivel aplica un debuff acumulativo:

| Estrés | Efecto |
|---|---|
| 1 | −5% velocidad |
| 2 | −1s timeout de tareas |
| 3 | +0.3s delay de reacción de clones al crearse |
| 4 | −10% eficiencia global |
| 5 | **Zona de Colapso** — efectos caóticos activos |

Desactivar una bomba reduce el estrés en 1 (si es mayor a 0).

### Zona de Colapso
Cuando el estrés llega al máximo (5), se activa la Zona de Colapso: la pantalla lo señaliza con efectos visuales y los clones tienen un 0.2% de chance por frame de ignorar sus directivas e ir a tareas aleatorias. Si el estrés se mantiene en 5 durante **10 segundos consecutivos**, es **Game Over**.

El jugador puede recuperarse completando tareas para bajar el estrés antes de que se llene la barra de colapso.

---

## Sistema de oleadas

- Las oleadas inician automáticamente cada **20s** (se reduce 1.3s por ola, mínimo 7s)
- Las tareas se spawnean de a una cada 0.4s (gradualmente, no todas de golpe)
- La dificultad sube con cada oleada: más tareas, menos tiempo, más trabajo por tarea
- Las tareas tienen **tamaño variable** según su cantidad de trabajo restante
- Si la tarea está urgente (queda menos del 35% del tiempo), **pulsa** visualmente y cambia animación
- Si la tarea requiere más clones de los asignados, aparece un **badge dorado** ①②③ con el número recomendado

| Oleada | Dificultad | Tareas máx | Work amount |
|---|---|---|---|
| 1–2 | Fácil | 2 | 1 |
| 3–5 | Normal | 4–6 | 1–2 |
| 6–9 | Difícil | 7–8 | 1–2 |
| 10+ | CAOS | 8 | 1–3 |

---

## Sistema de mejoras (Roguelite)

Cada **3 oleadas** se pausa el juego y se presentan **3 cartas aleatorias** del catálogo.  
El jugador tiene **10 segundos** para elegir una; si no elige, se descartan todas y la ola empieza sin mejora.  
Las cartas no elegidas se descartan permanentemente para esa run.

Cada carta muestra icono, nombre, categoría y descripción corta.  
Un botón **"Ver detalle"** expande la descripción completa.

### Catálogo completo

#### Velocidad
| Icono | Nombre | Efecto |
|---|---|---|
| ⚡ | Adrenalina | +60% vel. base, −10% efic. extra por clon |
| 🎯 | Enfoque | +80% vel. con 1 clon, −50% con 2+ |
| 🚶 | Caravana | +30% vel. en grupo, −20% en solitario |

#### Interacción
| Icono | Nombre | Efecto |
|---|---|---|
| 💧 | Torrente | x1.5 progreso con 2+ clones en misma tarea, −30% solo |
| 💨 | Impulso | 1ra interacción de cada ola instantánea, −20% las siguientes |
| 🔥 | Constancia | Interacción sin cortes sube hasta x2, reset al interrumpir |

#### Clones
| Icono | Nombre | Efecto |
|---|---|---|
| 🛡 | Ejército Mínimo | 100% efic. con 1–2 clones, máx clones = 3 |
| 👥 | Proliferación | Máx clones = 8, efic. mínima = 8% |
| 💀 | Sacrificio | +300 pts al eliminar clon, −200 pts al crear |

#### Tareas
| Icono | Nombre | Efecto |
|---|---|---|
| 💥 | Sobrecarga | +150 pts por fallo, pero spawnea 1 tarea extra |
| ⛓ | Cadena | +3s a todas al completar, −5s a todas al fallar |
| 🎲 | Efecto Dominó | x2 score con racha de 2 completadas, reset al fallar |

#### Eficiencia
| Icono | Nombre | Efecto |
|---|---|---|
| 🌀 | Caos Controlado | Tareas urgentes x3 pts, sin urgencia = 0 pts extra |
| 😌 | Zona de Confort | Sin penaliz. hasta 4 clones, caída x2 con 5–6 |
| 🔀 | Caos Productivo | +500 pts cada 10s con efic.<30%, clones desobedecen 20% |
| 📊 | Umbral | Efic. nunca baja del 40%, máximo = 80% |

#### Meta
| Icono | Nombre | Efecto |
|---|---|---|
| 🔄 | Segunda Oportunidad | Recupera 1 tarea fallida (1 vez por run), elimina todos los clones |
| ⌛ | Reloj de Arena | Ola no inicia hasta limpiar todo, −4s timeout próxima ola |

---

## HUD en pantalla

- **Ola** — número actual y dificultad (color reactivo, visible en todo momento)
- **Próxima ola** — countdown + barra de progreso
- **Eficiencia** — porcentaje actual con barra de color (verde/amarillo/rojo)
- **Clones** — cantidad actual / máximo
- **Score** — puntuación acumulada
- **Estrés** — barra de 0 a 5 con indicador de Zona Crítica
- **Botones** — Pausa, Velocidad (x1/x1.5/x2), Saltar oleada
- **Iconos de mejoras activas** — esquina inferior derecha; hover muestra descripción breve, click muestra detalle completo

---

## Menú de pausa

Accesible con **ESC** o el botón de pausa en pantalla.

- Botón **Continuar**
- Botón **Opciones** — idioma, volumen música y SFX
- Botón **Menú principal**
- Sección **Mejoras activas**: lista con icono, nombre y descripción corta de cada upgrade elegido; click en una fila expande la descripción completa

---

## Menú principal

- **Jugar** — inicia una nueva run (resetea mejoras)
- **Ver Mejoras** — catálogo completo de upgrades organizado por categoría, con descripción expandible al hacer click
- **Cómo Jugar** — tutorial de 6 pasos navegable (← →)
- **Opciones** — idioma (🇪🇸 🇬🇧 🇧🇷), volumen música y SFX
- **Salir** — cierra el juego

---

## Arquitectura del proyecto

```
OverSplit/
├── scenes/
│   ├── Main.tscn               # Escena principal de juego
│   ├── MainMenu.tscn           # Menú principal
│   ├── Player.tscn             # Jugador base (original + clones)
│   ├── SwitchTask.tscn         # Tarea interactuable (bomba animada)
│   ├── UpgradeScreen.tscn      # Pantalla de elección de mejoras (3 cartas)
│   └── ui/
│       ├── EfficiencyUI.tscn   # HUD principal (eficiencia, score, oleada, estrés)
│       ├── GameOver.tscn       # Pantalla de Game Over
│       ├── PauseMenu.tscn      # Menú de pausa con lista de mejoras activas
│       ├── UpgradeIconsHUD.tscn # Iconos de upgrades activos (esquina inferior derecha)
│       └── OptionsMenu.tscn    # Menú de opciones (idioma + volumen)
│
├── scripts/
│   ├── GameManager.gd          # Autoload — estado global, oleadas, estrés, colapso
│   ├── UpgradeManager.gd       # Autoload — catálogo, upgrades activos, efectos
│   ├── AudioManager.gd         # Autoload — audio procedural + música WAV
│   ├── CloneManager.gd         # Spawn/eliminación de clones, directivas por click
│   ├── PlayerController.gd     # Movimiento jugador, IA de clones, interacción
│   ├── SwitchTask.gd           # Lógica de tarea (progreso, timeout, urgencia, badge)
│   ├── TaskSpawner.gd          # Spawner de tareas por oleada con cola delta
│   ├── Main.gd                 # Inicialización de la escena de juego
│   ├── MainMenu.gd             # Menú principal, catálogo y tutorial
│   ├── PauseMenu.gd            # Lógica del menú de pausa
│   ├── GameOver.gd             # Pantalla de Game Over
│   ├── EfficiencyUI.gd         # Actualización del HUD
│   ├── UpgradeScreen.gd        # Lógica de cartas de mejora con timer
│   ├── UpgradeIconsHUD.gd      # Iconos HUD con tooltip y panel de detalle
│   └── OptionsMenu.gd          # Lógica de opciones: idioma y control de volumen
│
├── sprites/
│   ├── Bomba/                  # 21 frames de animación de la bomba
│   ├── sprite_pj.png           # Frame idle del personaje
│   ├── sprite_walk_pj.png      # Frame walk 1
│   ├── sprite_walk_pj2.png     # Frame walk 2
│   ├── sprite_frames_pj.tres   # SpriteFrames (idle 1f + walk 4f a 8fps)
│   ├── OVERSPLIT.png           # Logo pixel-art
│   └── fondo_menu.jpeg         # Ilustración del menú principal
│
├── backgrounds/
│   └── fondo_oversplit.png     # Fondo top-down del área de juego (steampunk)
│
├── translations/
│   ├── translations.csv        # Fuente de traducciones ES/EN/PT
│   ├── translations.es.translation
│   ├── translations.en.translation
│   └── translations.pt.translation
│
└── audio/
    ├── PaCarlosIntro.wav       # Música del menú (loop)
    └── PaCarlosFull.wav        # Música del juego (loop)
```

---

## Sistemas técnicos destacados

### Spawn con cola delta (TaskSpawner)
Las tareas se spawnean de a una cada 0.4s usando `_process(delta)` con un contador interno. Esto asegura que al reanudar después de una pausa (ej: pantalla de mejoras) las tareas aparezcan gradualmente.

### Eficiencia con modificadores por upgrade
`GameManager._recalculate_efficiency()` calcula la base y la pasa por `UpgradeManager.get_efficiency()`, que aplica modificadores de Umbral, Zona de Confort, Ejército Mínimo y Proliferación antes de emitir la señal al HUD.

### MAX_CLONES como variable mutable
`MAX_CLONES` es una variable (no constante) en `GameManager`, permitiendo que upgrades como Ejército Mínimo (3) y Proliferación (8) la modifiquen en runtime. Se resetea a 6 en cada `start_game()`.

### IA de clones con anti-stacking y reservas
Los clones evalúan tareas disponibles con un sistema de reservas (`task_reservations`) para evitar que todos vayan al mismo objetivo. Cuando un clon lleva el 65% de progreso de una tarea, ya empieza a buscar la siguiente.

### Sistema de prioridad por click
Click izquierdo asigna el clon más cercano disponible a la tarea (indicador numérico ①②③ sobre ella). Click derecho cancela todas las asignaciones. Los clones asignados muestran borde cyan pulsante.

### Audio 100% procedural (SFX)
Todos los efectos de sonido se generan en tiempo real con `AudioStreamGenerator` usando ondas sine, square y noise. Solo la música usa archivos WAV.

### Fix de orientación de sprite al salir de interacción
Al terminar de desactivar una bomba, el sprite del clon ahora se orienta inmediatamente hacia el siguiente destino en vez de girar con lerp desde la posición anterior, eliminando el efecto de "caminar hacia atrás".

### Colapso emergente (no inmediato)
Estrés máximo (5) activa Zona de Colapso, pero el Game Over solo ocurre si el estrés se mantiene en 5 durante 10 segundos consecutivos. La barra de colapso sube y baja según el estrés actual, dando margen de recuperación.

---

## Instalación y ejecución

> **Juega directamente en el navegador:** [unifroxt.itch.io/oversplit](https://unifroxt.itch.io/oversplit)

O para ejecutar localmente desde el código fuente:

1. Tener **Godot 4.6** instalado
2. Clonar o descargar el repositorio
3. Abrir Godot → **Import** → seleccionar `project.godot`
4. Ejecutar con **F5** o el botón Play

> No se requieren plugins ni assets externos. Los SFX usan solo primitivas de Godot. Los iconos de mejoras usan emojis Unicode.

---

## Historial de versiones resumido

| Versión | Cambios principales |
|---|---|
| v1.0 | Prototipo base: clones, eficiencia, tareas, UI |
| v2.0 | Sistema de dificultad progresiva |
| v3.0 | Sistema de sonido procedural |
| v4.0 | Ajustes de balance, menú básico |
| v5.0 | IA de clones mejorada, interacción compartida |
| v6.0 | Sistema de pausa, velocidad de juego, skip oleada |
| v7.0 | Feedback visual jerárquico en tareas (tamaño, glow, pulso, badge) |
| v8.0 | Sistema de estrés, colapso progresivo, círculo de reacción en clones |
| v9.0 | Sistema de upgrades roguelite, HUD de iconos, WASD |
| v10.0 | Fixes: spawn acumulado en pausa, upgrades de eficiencia, MAX_CLONES mutable |
| v10.2 | Tutorial integrado en menú, catálogo de mejoras en menú, GameOver dinámico, fixes generales |
| v11.0 | Sistema de localización ES/EN/PT, menú de opciones (idioma + volumen), fix orientación sprite, oleada visible en todo momento |
