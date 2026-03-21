extends Node2D

signal task_completed(task: Node)

@export var timeout: float = 15.0
@export var task_color: Color = Color.RED

var is_complete: bool = false
var _timer: float = 0.0
var _activated: bool = false

@onready var body: ColorRect = $Body
@onready var timer_bar: ProgressBar = $TimerBar
@onready var pulse_tween: Tween = null

func _ready() -> void:
	get_node("/root/GameManager").register_task(self)
	body.color = task_color
	timer_bar.max_value = timeout
	timer_bar.value = timeout
	_start_pulse()

func _process(delta: float) -> void:
	if is_complete:
		return
	_timer += delta
	timer_bar.value = timeout - _timer
	if _timer >= timeout:
		_on_timeout()

func complete() -> void:
	if is_complete:
		return
	is_complete = true
	get_node("/root/GameManager").unregister_task(self)
	emit_signal("task_completed", self)
	_play_complete_animation()

func _on_timeout() -> void:
	if is_complete:
		return
	is_complete = true
	get_node("/root/GameManager").unregister_task(self)
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
