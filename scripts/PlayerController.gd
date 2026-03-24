extends CharacterBody2D

@export var player_index: int = 0
@export var color: Color = Color.WHITE

var _interact_target: Node = null
var _interact_progress: float = 0.0
var _interacting: bool = false

@onready var sprite: ColorRect = $Sprite
@onready var interact_bar: ProgressBar = $InteractBar
@onready var clone_label: Label = $CloneLabel

func _ready() -> void:
	sprite.color = color
	clone_label.text = "P" + str(player_index + 1) if player_index > 0 else "YOU"
	interact_bar.visible = false

func _physics_process(delta: float) -> void:
	if _interacting:
		_process_interaction(delta)
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
		var assigned_task := _find_nearest_incomplete_task()
		if assigned_task:
			var to_task: Vector2 = (assigned_task.global_position - global_position)
			if to_task.length() > 32.0:
				dir = to_task.normalized()
			else:
				_try_start_interaction(assigned_task)

	velocity = dir.normalized() * speed
	move_and_slide()

func _check_interact_input() -> void:
	if player_index != 0:
		return
	if Input.is_action_just_pressed("interact"):
		var nearest := _find_nearest_incomplete_task()
		if nearest:
			_try_start_interaction(nearest)

func _try_start_interaction(task: Node) -> void:
	if task.is_complete:
		return
	_interact_target = task
	_interacting = true
	_interact_progress = 0.0
	interact_bar.visible = true
	interact_bar.value = 0
	get_node("/root/AudioManager").play_interact_start()

func _process_interaction(delta: float) -> void:
	if _interact_target == null or _interact_target.is_complete:
		_cancel_interaction()
		return

	var gm: Node = get_node("/root/GameManager")
	var duration: float = gm.get_interact_duration()
	_interact_progress += delta / duration
	interact_bar.value = _interact_progress * 100.0

	if _interact_progress >= 1.0:
		_interact_target.complete()
		_cancel_interaction()

func _cancel_interaction() -> void:
	_interacting = false
	_interact_target = null
	_interact_progress = 0.0
	interact_bar.visible = false

func _find_nearest_incomplete_task() -> Node:
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
