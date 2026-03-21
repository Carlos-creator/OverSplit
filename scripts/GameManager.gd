extends Node

signal efficiency_changed(value: float)
signal clone_count_changed(count: int)
signal game_over()
signal wave_started(wave_number: int)

const MAX_CLONES := 6
const BASE_SPEED := 180.0
const BASE_INTERACT_TIME := 1.0
const WAVE_INTERVAL := 20.0

var clone_count: int = 1
var efficiency: float = 1.0
var score: int = 0
var wave: int = 0
var _wave_timer: float = 0.0
var tasks_active: Array = []

func _ready() -> void:
	_start_wave()

func _process(delta: float) -> void:
	_wave_timer += delta
	if _wave_timer >= WAVE_INTERVAL:
		_wave_timer = 0.0
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
	efficiency = 1.0 / float(clone_count)
	emit_signal("efficiency_changed", efficiency)
	emit_signal("clone_count_changed", clone_count)

func get_speed() -> float:
	return BASE_SPEED * efficiency

func get_interact_duration() -> float:
	return BASE_INTERACT_TIME / efficiency

func register_task(task: Node) -> void:
	tasks_active.append(task)

func unregister_task(task: Node) -> void:
	tasks_active.erase(task)
	score += 100
	_check_wave_clear()

func _check_wave_clear() -> void:
	if tasks_active.is_empty():
		score += wave * 500

func _start_wave() -> void:
	wave += 1
	emit_signal("wave_started", wave)
