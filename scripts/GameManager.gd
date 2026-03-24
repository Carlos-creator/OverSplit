extends Node

signal efficiency_changed(value: float)
signal clone_count_changed(count: int)
signal game_over()
signal wave_started(wave_number: int)

const MAX_CLONES := 6
const BASE_SPEED := 180.0
const BASE_INTERACT_TIME := 2.5
const WAVE_INTERVAL := 20.0
const MIN_WAVE_INTERVAL := 7.0
const MAX_TASKS_PER_WAVE := 8

var clone_count: int = 1
var efficiency: float = 1.0
var score: int = 0
var wave: int = 0
var wave_timer: float = 0.0
var tasks_active: Array = []
var task_reservations: Dictionary = {}

func _ready() -> void:
	_start_wave()

func _process(delta: float) -> void:
	wave_timer += delta
	if wave_timer >= get_current_wave_interval():
		wave_timer = 0.0
		_start_wave()

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
	efficiency = maxf(0.1, 1.0 - float(clone_count - 1) * 0.156)
	emit_signal("efficiency_changed", efficiency)
	emit_signal("clone_count_changed", clone_count)

func get_speed() -> float:
	return BASE_SPEED * efficiency

func get_interact_duration() -> float:
	return BASE_INTERACT_TIME

func get_current_wave_interval() -> float:
	return maxf(MIN_WAVE_INTERVAL, WAVE_INTERVAL - float(wave) * 1.3)

func get_task_count() -> int:
	return mini(wave + 1, MAX_TASKS_PER_WAVE)

func get_task_timeout() -> float:
	var t_min := maxf(5.0, 12.0 - float(wave) * 0.6)
	var t_max := maxf(8.0, 22.0 - float(wave) * 1.0)
	return randf_range(t_min, t_max)

func get_difficulty_label() -> String:
	if wave <= 2:   return "Facil"
	elif wave <= 5: return "Normal"
	elif wave <= 9: return "Dificil"
	else:           return "CAOS"

func register_task(task: Node) -> void:
	tasks_active.append(task)

func unregister_task(task: Node) -> void:
	tasks_active.erase(task)
	task_reservations.erase(task)
	score += 100
	_check_wave_clear()

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
