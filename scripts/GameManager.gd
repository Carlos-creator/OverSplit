extends Node

signal efficiency_changed(value: float)
signal clone_count_changed(count: int)
signal wave_started(wave_number: int)
signal stress_changed(value: int, max_value: int)
signal zona_colapso_changed(active: bool)

var MAX_CLONES: int = 6
const BASE_SPEED := 180.0
const BASE_INTERACT_TIME := 2.5
const WAVE_INTERVAL := 20.0
const MIN_WAVE_INTERVAL := 7.0
const MAX_TASKS_PER_WAVE := 8
const MAX_STRESS := 5

const MAP_MIN := Vector2(140, 140)
const MAP_MAX := Vector2(860, 430)

# Mecanica para perder
const COLLAPSE_TIME := 10.0
var collapse_progress: float = 0.0
const GameOverScene = preload("res://scenes/ui/GameOver.tscn")

var clone_count: int = 1
var efficiency: float = 1.0
var score: int = 0
var wave: int = 0
var wave_timer: float = 0.0
var tasks_active: Array = []
var task_reservations: Dictionary = {}

var stress: int = 0
var consecutive_completes: int = 0
var reaction_delay: float = 0.0
var speed_penalty: float = 0.0
var timeout_penalty: float = 0.0
var efficiency_penalty: float = 0.0
var zona_colapso: bool = false

var _game_active: bool = false

func _ready() -> void:
	pass

func start_game() -> void:
	get_node("/root/AudioManager").play_game_music()
	_game_active = true
	MAX_CLONES = 6
	wave = 0
	wave_timer = 0.0
	score = 0
	stress = 0
	consecutive_completes = 0
	reaction_delay = 0.0
	speed_penalty = 0.0
	timeout_penalty = 0.0
	efficiency_penalty = 0.0
	zona_colapso = false
	clone_count = 1
	tasks_active.clear()
	task_reservations.clear()
	_recalculate_efficiency()
	_start_wave()

func stop_game() -> void:
	_game_active = false

func _game_over() -> void:
	if not _game_active:
		return
	get_node("/root/AudioManager").play_menu_music()
	_game_active = false
	get_tree().paused = true
	var go = GameOverScene.instantiate()
	go.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(go)
	go.setup(score)

func _process(delta: float) -> void:
	if not _game_active:
		return
	wave_timer += delta
	if wave_timer >= get_current_wave_interval():
		wave_timer = 0.0
		_start_wave()
		
	if stress == MAX_STRESS:
		collapse_progress += delta / COLLAPSE_TIME
	else:
		collapse_progress -= delta / COLLAPSE_TIME
	collapse_progress = clamp(collapse_progress, 0.0, 1.0)
	if collapse_progress >= 1.0:
		_game_over()

func add_clone() -> bool:
	if clone_count >= MAX_CLONES:
		return false
	clone_count += 1
	_recalculate_efficiency()
	return true

func remove_clone() -> void:
	if clone_count <= 1:
		return
	clone_count -= 1
	_recalculate_efficiency()

func _recalculate_efficiency() -> void:
	var base := maxf(0.1, 1.0 - float(clone_count - 1) * 0.156)
	var um: Node = get_node("/root/UpgradeManager")
	efficiency = um.get_efficiency(base, clone_count)
	emit_signal("efficiency_changed", efficiency)
	emit_signal("clone_count_changed", clone_count)

func get_speed() -> float:
	var um: Node = get_node("/root/UpgradeManager")
	var base := BASE_SPEED * maxf(0.1, efficiency - efficiency_penalty) * (1.0 - speed_penalty)
	return base * um.get_speed_multiplier(clone_count)

func get_interact_duration() -> float:
	return BASE_INTERACT_TIME

func get_current_wave_interval() -> float:
	return maxf(MIN_WAVE_INTERVAL, WAVE_INTERVAL - float(wave) * 1.3)

func get_task_count() -> int:
	return mini(wave + 1, MAX_TASKS_PER_WAVE)

func get_task_timeout() -> float:
	var t_min := maxf(3.0, 12.0 - float(wave) * 0.6 - timeout_penalty)
	var t_max := maxf(5.0, 22.0 - float(wave) * 1.0 - timeout_penalty)
	return randf_range(t_min, t_max)

func get_difficulty_label() -> String:
	if wave <= 2:   return "Facil"
	elif wave <= 5: return "Normal"
	elif wave <= 9: return "Dificil"
	else:           return "CAOS"

func register_task(task: Node) -> void:
	tasks_active.append(task)
	task.task_failed.connect(on_task_failed)

func unregister_task(task: Node) -> void:
	tasks_active.erase(task)
	task_reservations.erase(task)

func on_task_completed(task: Node) -> void:
	score += 100
	if stress > 0:
		stress -= 1
	consecutive_completes += 1
	_apply_debuffs()
	emit_signal("stress_changed", stress, MAX_STRESS)
	unregister_task(task)

func on_task_failed(_task: Node) -> void:
	score -= 200
	stress = mini(stress + 1, MAX_STRESS)
	consecutive_completes = 0
	get_node("/root/UpgradeManager").notify_task_failed()
	var was_colapso := zona_colapso
	_apply_debuffs()
	emit_signal("stress_changed", stress, MAX_STRESS)
	if zona_colapso != was_colapso:
		emit_signal("zona_colapso_changed", zona_colapso)

func _apply_debuffs() -> void:
	speed_penalty      = 0.05 if stress >= 1 else 0.0
	timeout_penalty    = 1.0  if stress >= 2 else 0.0
	reaction_delay     = 0.3  if stress >= 3 else 0.0
	efficiency_penalty = 0.10 if stress >= 4 else 0.0
	var new_zona := stress >= MAX_STRESS
	if new_zona != zona_colapso:
		zona_colapso = new_zona
		emit_signal("zona_colapso_changed", zona_colapso)
	elif stress < MAX_STRESS:
		zona_colapso = false

func reserve_task(task: Node, player: Node) -> void:
	task_reservations[task] = player

func release_task(task: Node) -> void:
	task_reservations.erase(task)

func is_task_available(task: Node, requester: Node) -> bool:
	if not task_reservations.has(task):
		return true
	return task_reservations[task] == requester

func _check_wave_clear() -> void:
	if tasks_active.is_empty():
		score += wave * 500

func _start_wave() -> void:
	wave += 1
	emit_signal("wave_started", wave)
	get_node("/root/AudioManager").play_wave_start()

func skip_wave() -> void:
	wave_timer = get_current_wave_interval()

func get_clone_count_for_task(task: Node) -> int:
	var count := 0
	for p in get_tree().get_nodes_in_group("players"):
		if p._interact_target == task or p._next_target == task or p._directed_to == task:
			count += 1
	return count
