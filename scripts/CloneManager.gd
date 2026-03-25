extends Node

@export var player_scene: PackedScene

var _clones: Array[Node] = []
var _original: Node = null

const CLONE_COLORS: Array[Color] = [
	Color.CYAN,
	Color.YELLOW,
	Color.GREEN,
	Color.ORANGE,
	Color.MAGENTA,
]
const CLICK_RADIUS := 65.0

func _ready() -> void:
	get_node("/root/GameManager").efficiency_changed.connect(_on_efficiency_changed)

func register_original(player: Node) -> void:
	_original = player

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("create_clone"):
		_spawn_clone()
	if event.is_action_pressed("remove_clone"):
		_remove_last_clone()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if not mb.pressed:
			return
		var world_pos: Vector2 = get_viewport().get_canvas_transform().affine_inverse() * mb.position
		var task := _find_task_at(world_pos)
		if task == null:
			return
		get_viewport().set_input_as_handled()
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_add_directive_to_task(task)
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			_clear_directive_from_task(task)

func _add_directive_to_task(task: Node) -> void:
	if _clones.is_empty():
		task.set_directive(0)
		return
	var sorted := _clones_sorted_by_distance(task)
	for clone in sorted:
		if clone._directed_to == task:
			continue
		clone.set_directive(task)
		break
	task.set_directive(_count_directed_to(task))

func _clear_directive_from_task(task: Node) -> void:
	for clone in _clones:
		if clone._directed_to == task:
			clone.clear_directive()
	task.set_directive(0)

func _count_directed_to(task: Node) -> int:
	var count := 0
	for clone in _clones:
		if clone._directed_to == task:
			count += 1
	return count

func _find_task_at(pos: Vector2) -> Node:
	var gm := get_node("/root/GameManager")
	var best: Node = null
	var best_dist := CLICK_RADIUS
	for task in gm.tasks_active:
		if task.is_complete:
			continue
		var d := pos.distance_to(task.global_position)
		if d < best_dist:
			best_dist = d
			best = task
	return best

func _calc_needed_clones(task: Node) -> int:
	var gm := get_node("/root/GameManager")
	var time_left: float = task.get_time_remaining()
	if time_left <= 0.2:
		return _clones.size()
	var progress_left: float = 1.0 - task.interact_progress
	if progress_left <= 0.0:
		return 0
	var duration: float = gm.get_interact_duration()
	var needed := ceili(progress_left * duration / time_left)
	return clampi(needed, 1, _clones.size())

func _clones_sorted_by_distance(task: Node) -> Array:
	var sorted := _clones.duplicate()
	sorted.sort_custom(func(a, b):
		return a.global_position.distance_to(task.global_position) < b.global_position.distance_to(task.global_position)
	)
	return sorted

func _spawn_clone() -> void:
	var gm := get_node("/root/GameManager")
	if not gm.add_clone():
		return

	var clone: Node = player_scene.instantiate()
	var index: int = gm.clone_count - 1
	clone.player_index = index
	clone.color = CLONE_COLORS[(index - 1) % CLONE_COLORS.size()]
	get_parent().add_child(clone)
	clone.global_position = _original.global_position + Vector2(randf_range(-40, 40), randf_range(-40, 40))
	_clones.append(clone)
	if gm.reaction_delay > 0.0:
		clone.activate_with_delay(gm.reaction_delay)
	get_node("/root/UpgradeManager").notify_clone_created()
	get_node("/root/AudioManager").play_clone_create()
	_flash_all_clones()

func _remove_last_clone() -> void:
	if _clones.is_empty():
		return
	var last: Node = _clones.pop_back()
	last.queue_free()
	get_node("/root/UpgradeManager").notify_clone_removed()
	get_node("/root/AudioManager").play_clone_remove()
	get_node("/root/GameManager").remove_clone()

func _on_efficiency_changed(value: float) -> void:
	_apply_visual_efficiency(value)

func _apply_visual_efficiency(eff: float) -> void:
	var all_players := [_original] + _clones
	for p in all_players:
		if not is_instance_valid(p):
			continue
		var alpha := lerpf(0.3, 1.0, eff)
		p.modulate.a = alpha

func _flash_all_clones() -> void:
	var all_players := [_original] + _clones
	for p in all_players:
		if not is_instance_valid(p):
			continue
		var tween := create_tween()
		tween.tween_property(p, "modulate:a", 0.1, 0.08)
		tween.tween_property(p, "modulate:a", 1.0, 0.12)
