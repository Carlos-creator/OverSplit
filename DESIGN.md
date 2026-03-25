# OverSplit — Diseño Roguelike

> Documento de diseño para la evolución del prototipo hacia un juego roguelike completo.
> Todas las mecánicas propuestas refuerzan el mensaje central: *"El que mucho abarca, poco aprieta."*

---

## Visión Roguelike

El roguelike es una elección natural para OverSplit porque **cada run fuerza decisiones de tradeoff**, exactamente lo que el juego quiere comunicar. No hay mejoras puramente positivas: cada elección sacrifica algo para ganar otra cosa. El jugador que quiera "tenerlo todo" siempre pagará un precio.

### Principios de diseño

- **Ninguna mejora es gratis** — toda ventaja tiene una contrapartida visible.
- **Las builds definen el estilo de juego** — runs minimalistas (1–2 clones eficientes) vs runs caóticas (6 clones descontrolados) deben ser igualmente válidas.
- **El caos es inevitable, pero manejable** — el juego no castiga perder el control; castiga no haber tomado una decisión consciente.

---

## Sistema de Elección Entre Olas

Al completar todas las tareas de una ola (o al expirar el timer de ola), aparece una **pantalla de elección** antes de que empiece la siguiente:

- Se muestran **3 cartas aleatorias** del pool de mejoras disponibles.
- El jugador elige **1**.
- Las cartas no elegidas se descartan (no vuelven en esa run).
- La pantalla dura máximo **10 segundos** — si no se elige, se descarta todo y la ola empieza sin mejora (presión de decisión).

Las mejoras se acumulan durante la run y se pierden al terminar (roguelike puro).

---

## Catálogo de Mejoras

### Velocidad

| Nombre | Efecto positivo | Efecto negativo |
|---|---|---|
| **Adrenalina** | +60% velocidad base | La eficiencia baja un 10% adicional por cada clon |
| **Enfoque** | +80% velocidad, pero solo con 1 clon activo | Con 2+ clones, velocidad cae al 50% |
| **Inercia** | Velocidad aumenta cuanto más tiempo llevas moviéndote sin parar | Al detenerte, tardas 1s en recuperar velocidad máxima |
| **Caravana** | Los clones se mueven un 30% más rápido cuando están cerca de otro | Solos se mueven 20% más lento |

---

### Interacción

| Nombre | Efecto positivo | Efecto negativo |
|---|---|---|
| **Especialista** | Interacción 2× más rápida | Solo podés interactuar con tareas de 1 color específico (elegido al tomar la mejora) |
| **Torrente** | Múltiples clones en la misma tarea acumulan progreso ×1.5 | Un solo clon sobre una tarea interactúa 30% más lento |
| **Impulso** | La primera interacción de cada ola es instantánea | Las siguientes interacciones de esa ola son 20% más lentas |
| **Esfuerzo Bruto** | Las tareas con `work_amount=3` se completan como si fueran `work_amount=2` | Las tareas con `work_amount=1` requieren el doble de tiempo |
| **Constancia** | Interactuar sin interrupciones aumenta la velocidad de progreso (stacking hasta ×2) | Cualquier interrupción reinicia el stack a 0 |

---

### Clones

| Nombre | Efecto positivo | Efecto negativo |
|---|---|---|
| **Ejército Mínimo** | La eficiencia con 1–2 clones es siempre 100% | El máximo de clones se reduce a 3 |
| **Proliferación** | El máximo de clones sube a 8 | La eficiencia mínima cae al 8% (aún más caótico) |
| **Sacrificio** | Eliminar un clon da un bonus de +300 pts | Crear un clon cuesta 200 pts del score |
| **Clonación Rápida** | Crear un clon no consume tiempo de animación | Eliminar el último clon causa un Colapso de 3s |
| **Independencia** | Los clones ignoran directivas manuales y son 40% más eficientes en IA | Perdés control total del sistema de click de asignación |

---

### Tareas

| Nombre | Efecto positivo | Efecto negativo |
|---|---|---|
| **Sobrecarga** | Cada tarea fallida da +150 pts de bonus | Las tareas fallidas spawnean 1 tarea nueva inmediatamente |
| **Clarividencia** | El badge ①②③ es 100% preciso y aparece antes | Las tareas sin badge tienen timeout 20% más corto |
| **Cadena** | Completar una tarea extiende el timeout de todas las demás en +3s | Al fallar una tarea, todas las activas pierden 5s de timeout |
| **Efecto Dominó** | Completar 2 tareas seguidas sin fallar da bonus ×2 al score | Fallar cualquier tarea resetea el multiplicador a 1 |
| **Caos Controlado** | Las tareas con urgencia activa (borde rojo) valen ×3 pts | Las tareas sin urgencia valen 0 pts extra |

---

### Eficiencia / Mecánica Central

| Nombre | Efecto positivo | Efecto negativo |
|---|---|---|
| **Zona de Confort** | Con 1–4 clones no hay penalización de eficiencia | A partir del 5° clon la caída es el doble de pronunciada |
| **Caos Productivo** | Cada 10s con eficiencia <30% suma +500 pts automáticamente | Con eficiencia <30% los clones tienen 20% de chance de ignorar directivas |
| **Sincronía** | Si todos los clones interactúan simultáneamente, la eficiencia sube al 100% temporalmente | Si algún clon está idle más de 3s, perdés 50 pts |
| **Umbral** | La eficiencia nunca baja del 40% | La eficiencia máxima es 80% aunque tengas 1 solo clon |
| **Rendimientos Decrecientes** | La curva de eficiencia es más suave al principio (2–3 clones) | Con 5–6 clones la caída es mucho más abrupta que la fórmula base |

---

### Meta / Run

| Nombre | Efecto positivo | Efecto negativo |
|---|---|---|
| **Segunda Oportunidad** | Una vez por run, podés recuperar una tarea fallida | Al usarla, todos los clones se eliminan instantáneamente |
| **Préstamo** | Empezás la run con +2000 pts de score | Si terminás la run con menos de 2000 pts, el score final es 0 |
| **Veterano** | Los clones recuerdan la última tarea completada y van directo a la siguiente similar | Los clones nuevos tardan 2s en "activarse" al ser creados |
| **Reloj de Arena** | La ola nunca empieza hasta que completás todas las tareas actuales | El timeout de todas las tareas de la próxima ola se reduce en 4s |

---

## Rasgos de Clon (al crearlo)

Al crear un clon aparece una elección rápida de **1 de 2 rasgos** para ese clon específico. Aplica solo a él, no a todos.

| Nombre | Efecto en ese clon | Contrapartida |
|---|---|---|
| **Veloz** | +40% velocidad | Interactúa 30% más lento |
| **Obstinado** | Nunca abandona su tarea aunque otra sea más urgente | Ignora directivas manuales |
| **Amplificador** | Estar cerca de una tarea acelera a los demás clones en esa tarea un 20% | No interactúa directamente |
| **Fantasma** | No colisiona con otros clones | No puede empujar ni ser empujado |
| **Eficiente** | Este clon no cuenta para el cálculo de eficiencia | Velocidad 20% más baja que el resto |
| **Kamikaze** | Al completar su tarea, se elimina solo (+200 pts) | No puede ser eliminado manualmente con Q |

---

## Tipos de Tareas Especiales

Más allá del `SwitchTask` base, estos tipos introducen variedad y presión distinta:

### Mantenimiento
- Debe ser interactuada **periódicamente** o su progreso regresa a 0%.
- Un clon asignado queda "atado" a ella de forma semi-permanente.
- Penaliza builds de pocos clones muy especializados.

### Encadenada
- Completarla spawnea **2 tareas nuevas inmediatamente**, sin esperar la ola.
- Recompensa alta, pero genera avalanchas de trabajo si no se gestiona bien.

### Explosiva
- Si falla (timeout), **desactiva temporalmente todos los clones cercanos** (stun de 2s).
- Obliga a mantenerla vigilada aunque no sea la más urgente.

### Crisis
- Aparece sin aviso en cualquier momento de la ola.
- Timeout muy corto (3–5s), pero vale triple de puntos.
- Testea la capacidad de reacción del jugador bajo caos.

---

## Sistema de Colapso

Si la **eficiencia cae por debajo del 20% durante más de 8 segundos consecutivos**, se dispara un evento de Colapso parcial:

- Uno de los clones (el de mayor índice) se **desconecta automáticamente**.
- Hay un aviso visual 2s antes (flash rojo en todos los clones).
- El jugador pierde control de ese clon por 3s antes de que desaparezca.

**Objetivo**: penalizar activamente el abuso de clones sin decisión consciente. Si tenés 6 clones pero no los estás aprovechando, el sistema te los quita.

---

## Meta-progresión Entre Runs

Al terminar una run (por tiempo límite o por colapso total), se desbloquean **rasgos permanentes de run** para la siguiente partida. Ninguno es puramente positivo:

Ejemplos:
- *"Memoria de Grupo"*: los clones aprenden de tareas anteriores (más rápidos en targeting), pero tienen opinión propia y pueden ignorar directivas ocasionalmente.
- *"Cicatrices"*: empezás con la eficiencia ya al 80% (como si tuvieras 2 clones), pero el máximo sube a 7.
- *"Veteranía"*: el jugador humano interactúa un 50% más rápido, pero los clones un 20% más lento.

La meta-progresión nunca debería hacer el juego "más fácil" en términos absolutos — solo cambia el estilo de la dificultad.

---

## Orden de Implementación Sugerido

| Prioridad | Mecánica | Impacto temático | Esfuerzo estimado |
|:---:|---|:---:|:---:|
| 1 | Sistema de elección entre olas (pantalla de cartas) | Alto | Medio |
| 2 | Mejoras de Eficiencia y Velocidad (las más simples de implementar) | Alto | Bajo |
| 3 | Tipos de tareas especiales (Crisis y Encadenada primero) | Alto | Medio |
| 4 | Rasgos de Clon al crearlo | Muy alto | Alto |
| 5 | Sistema de Colapso | Alto | Bajo |
| 6 | Mejoras de Meta / Run complejas | Medio | Alto |
| 7 | Meta-progresión entre runs | Medio | Alto |
