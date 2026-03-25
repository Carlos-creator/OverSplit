extends Node2D

@export var switch_task_scene: PackedScene
@export var spawn_area: Rect2 = Rect2(80, 80, 800, 480)

const TASK_COLORS: Array[Color] = [
	Color.RED,
	Color.ORANGE,
	Color.DEEP_PINK,
	Color.DODGER_BLUE,
	Color.MEDIUM_PURPLE,
]

func _ready() -> void:
	get_node("/root/GameManager").wave_started.connect(_on_wave_started)

func _on_wave_started(_wave_number: int) -> void:
	var gm := get_node("/root/GameManager")
	var count: int = gm.get_task_count()
	for i in count:
		await get_tree().create_timer(float(i) * 0.4).timeout
		_spawn_task()

func _spawn_task() -> void:
	var gm := get_node("/root/GameManager")
	var task: Node = switch_task_scene.instantiate()
	task.global_position = Vector2(
		randf_range(spawn_area.position.x, spawn_area.position.x + spawn_area.size.x),
		randf_range(spawn_area.position.y, spawn_area.position.y + spawn_area.size.y)
	)
	task.task_color = TASK_COLORS[randi() % TASK_COLORS.size()]
	task.timeout = gm.get_task_timeout()
	task.work_amount = _get_work_amount(gm.wave)
	if gm.zona_colapso:
		task.work_amount = maxi(task.work_amount, 2)
	add_child(task)

func _get_work_amount(wave: int) -> int:
	if wave <= 3:
		return 1
	elif wave <= 6:
		return 1 + randi() % 2
	else:
		return 1 + randi() % 3
