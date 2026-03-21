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

func _ready() -> void:
	get_node("/root/GameManager").efficiency_changed.connect(_on_efficiency_changed)

func register_original(player: Node) -> void:
	_original = player

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("create_clone"):
		_spawn_clone()
	if event.is_action_pressed("remove_clone"):
		_remove_last_clone()

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
	_flash_all_clones()

func _remove_last_clone() -> void:
	if _clones.is_empty():
		return
	var last: Node = _clones.pop_back()
	last.queue_free()
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
