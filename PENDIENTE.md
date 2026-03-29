# OverSplit — Mecánicas Pendientes de Implementación

> Todo lo diseñado pero no implementado en v10.2.
> Fuente: DESIGN.md original vs código real.

---

## Mejoras no implementadas (del catálogo original)

Estas mejoras están en el diseño pero **no existen en `UpgradeManager.gd`**:

| Nombre | Categoría | Descripción |
|---|---|---|
| **Inercia** | Velocidad | Velocidad aumenta cuanto más tiempo llevas moviéndote; al detenerte, tardas 1s en recuperar velocidad máxima |
| **Especialista** | Interacción | Interacción 2× más rápida, pero solo podés interactuar con tareas de 1 color específico |
| **Esfuerzo Bruto** | Interacción | Tareas work_amount=3 se completan como si fueran 2; tareas work_amount=1 requieren el doble |
| **Clonación Rápida** | Clones | Crear clon sin animación de delay; eliminar el último clon causa Colapso de 3s |
| **Independencia** | Clones | Clones ignoran directivas manuales y son 40% más eficientes en IA; perdés el sistema de click |
| **Clarividencia** | Tareas | Badge ①②③ 100% preciso y aparece antes; tareas sin badge tienen timeout 20% más corto |
| **Sincronía** | Eficiencia | Si todos los clones interactúan simultáneamente, eficiencia sube al 100% temporalmente; clon idle > 3s = −50 pts |
| **Rendimientos Decrecientes** | Eficiencia | Curva de eficiencia más suave con 2–3 clones; con 5–6 la caída es mucho más abrupta |
| **Préstamo** | Meta | Empezás con +2000 pts; si terminás con menos de 2000, score final = 0 |
| **Veterano** | Meta | Clones recuerdan última tarea y van directo a la siguiente similar; clones nuevos tardan 2s en activarse |

---

## Sistema de Rasgos de Clon

Al crear un clon, aparece una elección rápida de **1 de 2 rasgos** para ese clon específico. No implementado en absoluto.

| Nombre | Efecto en ese clon | Contrapartida |
|---|---|---|
| **Veloz** | +40% velocidad | Interactúa 30% más lento |
| **Obstinado** | Nunca abandona su tarea aunque otra sea más urgente | Ignora directivas manuales |
| **Amplificador** | Estar cerca de una tarea acelera a los demás clones un 20% | No interactúa directamente |
| **Fantasma** | No colisiona con otros clones | No puede empujar ni ser empujado |
| **Eficiente** | No cuenta para el cálculo de eficiencia | Velocidad 20% más baja |
| **Kamikaze** | Al completar su tarea se elimina solo (+200 pts) | No puede eliminarse con Q |

**Dónde implementar:** `CloneManager._spawn_clone()` → mostrar UI de elección antes de añadir el clon → aplicar el rasgo al `PlayerController` instanciado.

---

## Tipos de Tareas Especiales

Solo existe `SwitchTask` (bomba genérica). Estos tipos están diseñados pero no implementados:

### Mantenimiento
- Debe interactuarse **periódicamente** o su progreso regresa a 0%
- Un clon asignado queda "atado" de forma semi-permanente
- Penaliza builds de pocos clones especializados

### Encadenada
- Al completarla, spawnea **2 tareas nuevas inmediatamente**
- Recompensa alta, pero genera avalanchas de trabajo

### Explosiva
- Si falla, **desactiva temporalmente todos los clones cercanos** (stun de 2s)
- Obliga a mantenerla vigilada aunque no sea la más urgente

### Crisis
- Aparece sin aviso en cualquier momento de la ola
- Timeout muy corto (3–5s), pero vale triple de puntos
- Testea reacción bajo caos

**Dónde implementar:** crear nuevos scripts heredando de `SwitchTask.gd` o añadir un `task_type` enum y ramificar la lógica en `_process`.

---

## Sistema de Colapso Parcial (diseño original)

El diseño original planteaba un colapso **más gradual** que el actual:

> Si la eficiencia cae por debajo del 20% durante más de 8 segundos, **un clon se desconecta automáticamente** (el de mayor índice), con aviso visual 2s antes.

Lo implementado actualmente es diferente: el Game Over ocurre cuando el **estrés se mantiene en 5** durante 10s (no por eficiencia baja). El sistema de colapso por eficiencia baja no está implementado.

**Dónde implementar:** `GameManager._process()` → detectar `efficiency < 0.20` por N segundos → emitir evento → `CloneManager` elimina el último clon.

---

## Meta-progresión entre Runs

No implementado en absoluto. El diseño planteaba **rasgos permanentes** que se desbloquean al terminar una run y persisten en las siguientes:

Ejemplos diseñados:
- *"Memoria de Grupo"*: clones más rápidos en targeting, pero pueden ignorar directivas ocasionalmente
- *"Cicatrices"*: eficiencia empieza al 80% (como si hubieras 2 clones), pero MAX_CLONES sube a 7
- *"Veteranía"*: jugador humano interactúa 50% más rápido, clones 20% más lento

**Principio de diseño a respetar:** la meta-progresión nunca debería hacer el juego más fácil en absoluto — solo cambia el estilo de la dificultad.

**Dónde implementar:** requiere sistema de guardado (`FileAccess` en Godot 4), nueva pantalla de selección de rasgo al terminar una run, y un nuevo Autoload `RunProgressManager`.

---

## Mejoras implementadas con lógica incompleta

Estas mejoras **existen** en el catálogo pero su lógica no está completamente conectada en el código:

| Mejora | Estado |
|---|---|
| **Caravana** | `apply_upgrade` registra la mejora pero no hay lógica en `PlayerController` que detecte proximidad a otros clones y modifique la velocidad |
| **Caos Controlado** | `notify_task_completed` tiene un `pass` donde debería verificar si la tarea estaba en urgencia y multiplicar el score |
| **Sobrecarga** | El +150 pts al fallar está implementado, pero el spawn de tarea extra no está conectado en `on_task_failed` |
| **Cadena** | `apply_upgrade` registra la mejora pero no hay lógica en `SwitchTask` o `GameManager` que extienda/reduzca timeouts de tareas activas |
| **Segunda Oportunidad** | La variable `segunda_oportunidad_used` existe pero no hay trigger en el juego para activarla |
| **Reloj de Arena** | `reloj_arena_active = true` se setea pero `GameManager` no verifica esta flag para bloquear el inicio de la siguiente ola |

---

## Otras funcionalidades pendientes menores

- **Música del menú distinta a la del juego:** implementado (`PaCarlosIntro.wav` / `PaCarlosFull.wav`), pero ambos archivos deben existir en `res://audio/`
- **Score negativo visible:** no hay límite inferior en el score, puede volverse negativo sin feedback especial al jugador
- **Highscore / persistencia:** no existe sistema de guardado; el score se pierde al volver al menú
- **`_check_wave_clear()`:** el método existe en `GameManager` y suma `wave × 500` al limpiar la ola, pero **nunca se llama** en ningún lugar del código
- **Notificación de cierre de ventana:** el `_notification` en `Main.gd` está comentado; `stop_game()` no se llama al cerrar la ventana
