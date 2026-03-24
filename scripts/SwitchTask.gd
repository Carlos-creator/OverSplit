extends Node2D

signal task_completed(task: Node)

@export var timeout: float = 15.0
@export var task_color: Color = Color.RED

var is_complete: bool = false
var interact_progress: float = 0.0
var _timer: float = 0.0
var has_directive: bool = false

@onready var border_rect: ColorRect = $BorderRect
@onready var body: ColorRect = $Body
@onready var timer_bar: ProgressBar = $TimerBar
@onready var interact_bar: ProgressBar = $InteractBar
@onready var directive_label: Label = $DirectiveLabel
@onready var pulse_tween: Tween = null

func _ready() -> void:
	get_node("/root/GameManager").register_task(self)
	body.color = task_color
	timer_bar.max_value = timeout
	timer_bar.value = timeout
	interact_bar.value = 0
	directive_label.visible = false
	border_rect.color = Color(0, 0, 0, 0)
	_start_pulse()

func get_time_remaining() -> float:
	return timeout - _timer

func set_directive(count: int) -> void:
	has_directive = count > 0
	directive_label.visible = has_directive
	directive_label.text = ">> " + str(count)
	if has_directive:
		_start_border_pulse()
	else:
		_stop_border_pulse()

func _start_border_pulse() -> void:
	border_rect.color = Color(0, 1, 1, 1)
	var t := create_tween().set_loops()
	t.tween_property(border_rect, "color:a", 0.2, 0.4)
	t.tween_property(border_rect, "color:a", 1.0, 0.4)
	border_rect.set_meta("pulse_tween", t)

func _stop_border_pulse() -> void:
	if border_rect.has_meta("pulse_tween"):
		var t: Tween = border_rect.get_meta("pulse_tween")
		if t:
			t.kill()
	border_rect.color = Color(0, 0, 0, 0)

func _process(delta: float) -> void:
	if is_complete:
		return
	_timer += delta
	timer_bar.value = timeout - _timer
	if _timer >= timeout:
		_on_timeout()

func add_interact(amount: float) -> void:
	if is_complete:
		return
	interact_progress = minf(1.0, interact_progress + amount)
	interact_bar.value = interact_progress * 100.0
	if interact_progress >= 1.0:
		complete()

func complete() -> void:
	if is_complete:
		return
	is_complete = true
	get_node("/root/GameManager").unregister_task(self)
	get_node("/root/AudioManager").play_task_complete()
	emit_signal("task_completed", self)
	_play_complete_animation()

func _on_timeout() -> void:
	if is_complete:
		return
	is_complete = true
	get_node("/root/GameManager").unregister_task(self)
	get_node("/root/AudioManager").play_task_fail()
	_play_fail_animation()

func _start_pulse() -> void:
	pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.4)
	pulse_tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.4)

func _play_complete_animation() -> void:
	if pulse_tween:
		pulse_tween.kill()
	body.color = Color.LIME_GREEN
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)

func _play_fail_animation() -> void:
	if pulse_tween:
		pulse_tween.kill()
	body.color = Color.DARK_RED
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
