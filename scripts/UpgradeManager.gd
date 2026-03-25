extends Node

signal upgrade_chosen(upgrade: Dictionary)

const UPGRADE_INTERVAL := 3

const CATALOGUE: Array = [
	{
		"id": "adrenalina", "name": "Adrenalina", "icon": "⚡", "category": "Velocidad",
		"desc_short": "+60% vel. base | −10% efic. extra por clon",
		"desc_long": "Aumenta la velocidad base un 60%. Sin embargo, cada clon activo reduce la eficiencia un 10% adicional sobre la penalización normal."
	},
	{
		"id": "enfoque", "name": "Enfoque", "icon": "🎯", "category": "Velocidad",
		"desc_short": "+80% vel. con 1 clon | −50% vel. con 2+",
		"desc_long": "Con 1 clon activo, la velocidad aumenta un 80%. Con 2 o más clones, la velocidad cae al 50% de la base. Ideal para runs minimalistas."
	},
	{
		"id": "caravana", "name": "Caravana", "icon": "🚶", "category": "Velocidad",
		"desc_short": "+30% vel. en grupo | −20% vel. en solitario",
		"desc_long": "Los clones cerca de otro se mueven un 30% más rápido. Los clones solos (sin vecino a menos de 80px) se mueven un 20% más lento."
	},
	{
		"id": "torrente", "name": "Torrente", "icon": "💧", "category": "Interacción",
		"desc_short": "x1.5 progreso con 2+ clones | −30% solo",
		"desc_long": "Cuando 2 o más clones interactúan con la misma tarea, el progreso acumulado es x1.5. Un solo clon interactúa un 30% más lento."
	},
	{
		"id": "impulso", "name": "Impulso", "icon": "💨", "category": "Interacción",
		"desc_short": "1ra interacción de cada ola instantánea | −20% las siguientes",
		"desc_long": "La primera interacción completada de cada ola es instantánea. Todas las interacciones siguientes de esa ola tienen un 20% de penalización."
	},
	{
		"id": "constancia", "name": "Constancia", "icon": "🔥", "category": "Interacción",
		"desc_short": "Interacción sin cortes sube hasta x2 | reset al interrumpir",
		"desc_long": "Interactuar sin interrupciones acumula un multiplicador de velocidad de interacción hasta x2. Cualquier interrupción lo resetea a x1."
	},
	{
		"id": "ejercito_minimo", "name": "Ejército Mínimo", "icon": "🛡", "category": "Clones",
		"desc_short": "100% efic. con 1–2 clones | máx clones = 3",
		"desc_long": "Con 1 o 2 clones activos, la eficiencia es siempre 100%. El máximo de clones se reduce permanentemente a 3."
	},
	{
		"id": "proliferacion", "name": "Proliferación", "icon": "👥", "category": "Clones",
		"desc_short": "Máx clones = 8 | efic. mínima = 8%",
		"desc_long": "El máximo de clones sube a 8. La eficiencia mínima cae al 8%, haciendo el caos más extremo. Para jugadores que abrazan el descontrol."
	},
	{
		"id": "sacrificio", "name": "Sacrificio", "icon": "💀", "category": "Clones",
		"desc_short": "+300 pts al eliminar clon | −200 pts al crear",
		"desc_long": "Eliminar un clon da un bonus de +300 puntos. Crear un clon cuesta 200 puntos del score. Incentiva rotar clones estratégicamente."
	},
	{
		"id": "sobrecarga", "name": "Sobrecarga", "icon": "💥", "category": "Tareas",
		"desc_short": "+150 pts por fallo | fallo spawnea 1 tarea extra",
		"desc_long": "Cada tarea fallida otorga +150 puntos de bonus. Pero cada tarea fallida también spawnea 1 tarea nueva inmediatamente. Alto riesgo, alta recompensa."
	},
	{
		"id": "cadena", "name": "Cadena", "icon": "⛓", "category": "Tareas",
		"desc_short": "+3s a todas al completar | −5s a todas al fallar",
		"desc_long": "Completar una tarea extiende el timeout de todas las demás en +3 segundos. Fallar una tarea resta 5 segundos a todas las activas."
	},
	{
		"id": "efecto_domino", "name": "Efecto Dominó", "icon": "🎲", "category": "Tareas",
		"desc_short": "x2 score con racha de 2 | reset al fallar",
		"desc_long": "Completar 2 tareas seguidas sin fallar dobla el score de las siguientes. Fallar cualquier tarea resetea el multiplicador a x1."
	},
	{
		"id": "caos_controlado", "name": "Caos Controlado", "icon": "🌀", "category": "Eficiencia",
		"desc_short": "Tareas urgentes x3 pts | sin urgencia = 0 pts extra",
		"desc_long": "Las tareas con urgencia activa (borde rojo) valen x3 puntos al completarse. Las tareas sin urgencia no otorgan puntos extra."
	},
	{
		"id": "zona_confort", "name": "Zona de Confort", "icon": "😌", "category": "Eficiencia",
		"desc_short": "Sin penaliz. hasta 4 clones | caída x2 con 5–6",
		"desc_long": "Con 1 a 4 clones, no hay penalización de eficiencia. A partir del 5° clon, la caída es el doble de pronunciada que la fórmula base."
	},
	{
		"id": "caos_productivo", "name": "Caos Productivo", "icon": "🔀", "category": "Eficiencia",
		"desc_short": "+500 pts cada 10s con efic.<30% | clones desobedecen 20%",
		"desc_long": "Cada 10 segundos con eficiencia menor al 30% se acumulan +500 puntos automáticamente. Los clones tienen 20% de chance de ignorar directivas."
	},
	{
		"id": "umbral", "name": "Umbral", "icon": "📊", "category": "Eficiencia",
		"desc_short": "Efic. nunca baja del 40% | máximo = 80%",
		"desc_long": "La eficiencia nunca cae por debajo del 40%, sin importar cuántos clones tengas. Pero la eficiencia máxima es 80% aunque tengas 1 solo clon."
	},
	{
		"id": "segunda_oportunidad", "name": "Segunda Oportunidad", "icon": "🔄", "category": "Meta",
		"desc_short": "Recupera 1 tarea fallida (1 vez) | elimina todos los clones",
		"desc_long": "Una vez por run, podés recuperar una tarea fallida que regresa al 50% de progreso. Al usarla, todos los clones se eliminan instantáneamente."
	},
	{
		"id": "reloj_arena", "name": "Reloj de Arena", "icon": "⌛", "category": "Meta",
		"desc_short": "Ola no inicia hasta limpiar todo | −4s timeout próxima ola",
		"desc_long": "La siguiente ola nunca empieza hasta que completás todas las tareas actuales. El timeout de todas las tareas de la próxima ola se reduce en 4 segundos."
	},
]

var active_upgrades: Array = []
var discarded_ids: Array = []
var _upgrade_screen: Node = null

var speed_bonus: float = 0.0
var efficiency_extra_per_clone: float = 0.0
var interact_multi_bonus: float = 0.0
var interact_solo_penalty: float = 0.0
var score_multiplier: float = 1.0
var caos_productivo_timer: float = 0.0
var caos_productivo_bonus_scored: bool = false
var segunda_oportunidad_used: bool = false
var reloj_arena_active: bool = false
var constancia_stack: float = 1.0
var constancia_timer: float = 0.0
var domino_streak: int = 0
var domino_active: bool = false
var primera_interaccion_ola: bool = false
var impulso_penalized: bool = false

func _ready() -> void:
	get_node("/root/GameManager").wave_started.connect(_on_wave_started)
	get_node("/root/GameManager").efficiency_changed.connect(_on_efficiency_changed)

func _process(delta: float) -> void:
	if has_upgrade("caos_productivo"):
		var gm := get_node("/root/GameManager")
		if gm.efficiency < 0.30:
			caos_productivo_timer += delta
			if caos_productivo_timer >= 10.0:
				caos_productivo_timer = 0.0
				gm.score += 500
		else:
			caos_productivo_timer = 0.0
	if has_upgrade("constancia") and constancia_stack > 1.0:
		constancia_timer += delta
		if constancia_timer > 1.5:
			constancia_stack = maxf(1.0, constancia_stack - 0.1)

func _on_wave_started(wave: int) -> void:
	primera_interaccion_ola = true
	impulso_penalized = false
	if wave > 0 and wave % UPGRADE_INTERVAL == 0:
		call_deferred("_show_upgrade_screen")

func _on_efficiency_changed(_eff: float) -> void:
	pass

func _show_upgrade_screen() -> void:
	if _upgrade_screen == null or not is_instance_valid(_upgrade_screen):
		var scene := load("res://scenes/UpgradeScreen.tscn") as PackedScene
		if scene == null:
			return
		_upgrade_screen = scene.instantiate()
		get_tree().get_root().add_child(_upgrade_screen)
	_upgrade_screen.show_cards(_pick_three())

func _pick_three() -> Array:
	var pool: Array = []
	for u in CATALOGUE:
		if u["id"] not in discarded_ids and not has_upgrade(u["id"]):
			pool.append(u)
	pool.shuffle()
	return pool.slice(0, mini(3, pool.size()))

func apply_upgrade(upgrade: Dictionary) -> void:
	active_upgrades.append(upgrade)
	var id: String = upgrade["id"]
	var gm := get_node("/root/GameManager")
	match id:
		"adrenalina":
			speed_bonus += 0.6
			efficiency_extra_per_clone += 0.10
		"enfoque":
			pass
		"caravana":
			pass
		"torrente":
			interact_multi_bonus = 0.5
			interact_solo_penalty = 0.3
		"impulso":
			pass
		"constancia":
			pass
		"ejercito_minimo":
			gm.MAX_CLONES = 3
		"proliferacion":
			gm.MAX_CLONES = 8
		"sacrificio":
			pass
		"sobrecarga":
			pass
		"cadena":
			pass
		"efecto_domino":
			domino_active = true
		"caos_controlado":
			pass
		"zona_confort":
			pass
		"caos_productivo":
			pass
		"umbral":
			pass
		"segunda_oportunidad":
			pass
		"reloj_arena":
			reloj_arena_active = true
	emit_signal("upgrade_chosen", upgrade)

func discard_upgrade(upgrade: Dictionary) -> void:
	discarded_ids.append(upgrade["id"])

func has_upgrade(id: String) -> bool:
	for u in active_upgrades:
		if u["id"] == id:
			return true
	return false

func get_efficiency(base_efficiency: float, clone_count: int) -> float:
	var eff := base_efficiency
	if has_upgrade("umbral"):
		eff = clampf(eff, 0.40, 0.80)
	if has_upgrade("zona_confort"):
		if clone_count <= 4:
			eff = 1.0
		else:
			var extra_clones := clone_count - 4
			eff = maxf(0.10, 1.0 - float(extra_clones) * 0.156 * 2.0)
	if has_upgrade("ejercito_minimo"):
		if clone_count <= 2:
			eff = 1.0
	if has_upgrade("proliferacion"):
		eff = maxf(0.08, eff)
	return eff

func get_speed_multiplier(clone_count: int) -> float:
	var mult := 1.0 + speed_bonus
	if has_upgrade("enfoque"):
		mult = 1.8 if clone_count <= 1 else 0.5
	return mult

func get_interact_multiplier(contributors: int, is_first_this_wave: bool) -> float:
	var mult := 1.0
	if has_upgrade("impulso") and is_first_this_wave and not impulso_penalized:
		return 999.0
	if has_upgrade("impulso") and impulso_penalized:
		mult *= 0.8
	if has_upgrade("torrente"):
		mult = mult * 1.5 if contributors > 1 else mult * 0.7
	if has_upgrade("constancia"):
		mult *= constancia_stack
	return mult

func notify_interact_progress() -> void:
	if has_upgrade("constancia"):
		constancia_stack = minf(2.0, constancia_stack + 0.02)
		constancia_timer = 0.0

func notify_interact_interrupted() -> void:
	if has_upgrade("constancia"):
		constancia_stack = 1.0
		constancia_timer = 0.0

func notify_first_interact_used() -> void:
	if has_upgrade("impulso") and primera_interaccion_ola:
		primera_interaccion_ola = false
		impulso_penalized = true

func notify_task_completed(score_value: int) -> int:
	var _gm := get_node("/root/GameManager")
	var final_score := score_value
	if has_upgrade("efecto_domino") and domino_active:
		domino_streak += 1
		if domino_streak >= 2:
			final_score = score_value * 2
	if has_upgrade("caos_controlado"):
		pass
	return final_score

func notify_task_failed() -> void:
	if has_upgrade("efecto_domino"):
		domino_streak = 0
	if has_upgrade("sobrecarga"):
		get_node("/root/GameManager").score += 150

func notify_clone_created() -> void:
	if has_upgrade("sacrificio"):
		get_node("/root/GameManager").score -= 200

func notify_clone_removed() -> void:
	if has_upgrade("sacrificio"):
		get_node("/root/GameManager").score += 300

func reset_run() -> void:
	active_upgrades.clear()
	discarded_ids.clear()
	speed_bonus = 0.0
	efficiency_extra_per_clone = 0.0
	interact_multi_bonus = 0.0
	interact_solo_penalty = 0.0
	score_multiplier = 1.0
	caos_productivo_timer = 0.0
	segunda_oportunidad_used = false
	reloj_arena_active = false
	constancia_stack = 1.0
	domino_streak = 0
	domino_active = false
	primera_interaccion_ola = false
	impulso_penalized = false
