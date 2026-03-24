extends CharacterBody2D

@export var player_index: int = 0
@export var color: Color = Color.WHITE

var _interact_target: Node = null
var _interacting: bool = false
var _next_target: Node = null
var _directed_to: Node = null
var _push_velocity: Vector2 = Vector2.ZERO

@onready var sprite: ColorRect = $Sprite
@onready var interact_bar: ProgressBar = $InteractBar
@onready var clone_label: Label = $CloneLabel

func _ready() -> void:
	add_to_group("players")
	sprite.color = color
	clone_label.text = "P" + str(player_index + 1) if player_index > 0 else "YOU"
	interact_bar.visible = false

func _physics_process(delta: float) -> void:
	if _interacting:
		_process_interaction(delta)
		if player_index != 0:
			_handle_ai_movement(delta)
		velocity = _push_velocity
		move_and_slide()
		_push_velocity = _push_velocity.lerp(Vector2.ZERO, 0.35)
		return
	_handle_movement(delta)
	_check_interact_input()

func _handle_movement(delta: float) -> void:
	var gm: Node = get_node("/root/GameManager")
	var speed: float = gm.get_speed()
	var dir := Vector2.ZERO

	if player_index == 0:
		if Input.is_action_pressed("ui_right"): dir.x += 1
		if Input.is_action_pressed("ui_left"):  dir.x -= 1
		if Input.is_action_pressed("ui_down"):  dir.y += 1
		if Input.is_action_pressed("ui_up"):    dir.y -= 1
	else:
		var target := _get_ai_target(gm)
		if target != null:
			var to_task: Vector2 = target.global_position - global_position
			if to_task.length() > 32.0:
				var sep := _get_separation_force()
				dir = (to_task.normalized() + sep * 0.75).normalized()
			else:
				_try_start_interaction(target)

	velocity = dir.normalized() * speed
	move_and_slide()
	for i in get_slide_collision_count():
		var col := get_slide_collision(i)
		var other := col.get_collider()
		if other != null and other.has_method("receive_push") and other._interacting:
			other.receive_push(velocity.normalized() * 28.0)

func _handle_ai_movement(delta: float) -> void:
	if _next_target == null or not is_instance_valid(_next_target):
		return
	var gm: Node = get_node("/root/GameManager")
	var speed: float = gm.get_speed()
	var to_next: Vector2 = _next_target.global_position - global_position
	if to_next.length() > 32.0:
		velocity = to_next.normalized() * speed * 0.5
		move_and_slide()

func _get_ai_target(gm: Node) -> Node:
	# Directive tiene prioridad máxima
	if _directed_to != null:
		if not is_instance_valid(_directed_to) or _directed_to.is_complete:
			_directed_to = null
		else:
			return _directed_to
	# Targeting normal
	if _next_target != null:
		if not is_instance_valid(_next_target) or _next_target.is_complete:
			gm.release_task(_next_target)
			_next_target = null
		else:
			return _next_target
	var claimed := _claim_best_task(gm, null)
	if claimed != null:
		_next_target = claimed
		return claimed
	return _find_nearest_any_task(gm)

func set_directive(task: Node) -> void:
	var gm := get_node("/root/GameManager")
	if _next_target != null and _next_target != task:
		gm.release_task(_next_target)
		_next_target = null
	_directed_to = task
	gm.reserve_task(task, self)

func clear_directive() -> void:
	if _directed_to != null and is_instance_valid(_directed_to):
		get_node("/root/GameManager").release_task(_directed_to)
	_directed_to = null

func _check_interact_input() -> void:
	if player_index != 0:
		return
	if Input.is_action_just_pressed("interact"):
		var nearest := _find_nearest_task_for_player()
		if nearest:
			_try_start_interaction(nearest)

func _try_start_interaction(task: Node) -> void:
	if task.is_complete:
		return
	if _next_target == task:
		_next_target = null
	_interact_target = task
	_interacting = true
	interact_bar.visible = true
	interact_bar.value = 0
	get_node("/root/AudioManager").play_interact_start()

func _process_interaction(delta: float) -> void:
	if _interact_target == null or not is_instance_valid(_interact_target) or _interact_target.is_complete:
		_cancel_interaction()
		return

	var gm: Node = get_node("/root/GameManager")
	var duration: float = gm.get_interact_duration()
	_interact_target.add_interact(delta / duration)
	interact_bar.value = _interact_target.interact_progress * 100.0

	if player_index != 0 and _interact_target.interact_progress >= 0.65 and _next_target == null and _directed_to == null:
		_next_target = _claim_best_task(gm, _interact_target)

func _cancel_interaction() -> void:
	if _interact_target != null and is_instance_valid(_interact_target):
		get_node("/root/GameManager").release_task(_interact_target)
	_interacting = false
	_interact_target = null
	interact_bar.visible = false

func _claim_best_task(gm: Node, exclude: Node) -> Node:
	var best: Node = null
	var best_dist := INF
	for task in gm.tasks_active:
		if task.is_complete or task == exclude:
			continue
		if not gm.is_task_available(task, self):
			continue
		var d := global_position.distance_to(task.global_position)
		if d < best_dist:
			best_dist = d
			best = task
	if best != null:
		gm.reserve_task(best, self)
	return best

func receive_push(push: Vector2) -> void:
	_push_velocity = (_push_velocity + push).limit_length(50.0)

func _get_separation_force() -> Vector2:
	var sep := Vector2.ZERO
	const RADIUS := 52.0
	for p in get_tree().get_nodes_in_group("players"):
		if p == self:
			continue
		if p._interacting:
			continue
		var diff: Vector2 = global_position - p.global_position
		var dist := diff.length()
		if dist < RADIUS and dist > 0.5:
			sep += diff.normalized() * (1.0 - dist / RADIUS)
	return sep

func _find_nearest_task_for_player() -> Node:
	var gm: Node = get_node("/root/GameManager")
	var best: Node = null
	var best_dist := INF
	for task in gm.tasks_active:
		if task.is_complete:
			continue
		var d := global_position.distance_to(task.global_position)
		if d < best_dist:
			best_dist = d
			best = task
	return best

func _find_nearest_any_task(gm: Node) -> Node:
	var best: Node = null
	var best_dist := INF
	for task in gm.tasks_active:
		if task.is_complete:
			continue
		var d := global_position.distance_to(task.global_position)
		if d < best_dist:
			best_dist = d
			best = task
	return best
