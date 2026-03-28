extends Node2D

signal task_completed(task: Node)
signal task_failed(task: Node)

@export var timeout: float = 15.0
@export var task_color: Color = Color.RED
@export var work_amount: int = 1

var is_complete: bool = false
var interact_progress: float = 0.0
var _timer: float = 0.0
var has_directive: bool = false
var _urgency_active: bool = false
var _urgency_tween: Tween = null
var _badge_tween: Tween = null

@onready var border_rect: ColorRect = $BorderRect
@onready var body: ColorRect = $Body
@onready var timer_bar: ProgressBar = $TimerBar
@onready var interact_bar: ProgressBar = $InteractBar
@onready var directive_label: Label = $DirectiveLabel
@onready var badge_label: Label = $BadgeLabel

const BADGE_SYMBOLS: Array[String] = ["①", "②", "③"]

func _ready() -> void:
	get_node("/root/GameManager").register_task(self)
	body.color = task_color
	timer_bar.max_value = timeout
	timer_bar.value = timeout
	interact_bar.value = 0
	directive_label.visible = false
	badge_label.visible = false
	badge_label.scale = Vector2.ZERO
	border_rect.color = Color(0, 0, 0, 0)

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
		return

	var work_left: float = 1.0 - interact_progress
	var time_left: float = timeout - _timer
	var time_ratio: float = time_left / timeout

	_update_base_layer(work_left)
	_update_state_layer(time_ratio, work_left)
	_update_decision_layer(work_left, time_left)

func _update_base_layer(work_left: float) -> void:
	var scale_max: float = 1.0 + float(work_amount - 1) * 0.35
	var scale_val: float = lerp(0.75, scale_max, work_left)
	self.scale = Vector2(scale_val, scale_val)

	if not has_directive:
		var glow_alpha: float = work_left * (float(work_amount) / 3.0) * 0.65
		var glow_color: Color = task_color.lightened(0.3)
		glow_color.a = glow_alpha
		border_rect.color = glow_color

func _update_state_layer(time_ratio: float, _work_left: float) -> void:
	if time_ratio > 0.35 or has_directive:
		if _urgency_active:
			_deactivate_urgency()
		return

	if not _urgency_active:
		_activate_urgency()

	if not has_directive:
		if time_ratio > 0.15:
			border_rect.color = Color(1.0, 0.5, 0.0, 0.7)
		else:
			var pulse_alpha: float = 0.5 + abs(sin(_timer * 8.0)) * 0.5
			border_rect.color = Color(1.0, 0.1, 0.1, pulse_alpha)

func _activate_urgency() -> void:
	_urgency_active = true
	if _urgency_tween:
		_urgency_tween.kill()
	_urgency_tween = create_tween().set_loops()
	_urgency_tween.tween_property(self, "scale", Vector2(1.12, 1.12), 0.18)
	_urgency_tween.tween_property(self, "scale", Vector2(0.95, 0.95), 0.18)

func _deactivate_urgency() -> void:
	_urgency_active = false
	if _urgency_tween:
		_urgency_tween.kill()
		_urgency_tween = null

func _update_decision_layer(work_left: float, time_left: float) -> void:
	if has_directive:
		_hide_badge()
		return

	var gm: Node = get_node("/root/GameManager")
	var base_interact: float = gm.BASE_INTERACT_TIME
	var time_safe: float = maxf(time_left, 0.1)
	var recommended: int = ceili(float(work_amount) * work_left * base_interact / time_safe)
	recommended = clampi(recommended, 1, 3)
	var assigned: int = gm.get_clone_count_for_task(self)

	if assigned < recommended:
		_show_badge(recommended)
	else:
		_hide_badge()

func _show_badge(count: int) -> void:
	badge_label.text = BADGE_SYMBOLS[clampi(count - 1, 0, 2)]
	if badge_label.visible and badge_label.scale.x > 0.5:
		return
	badge_label.visible = true
	badge_label.scale = Vector2.ZERO
	if _badge_tween:
		_badge_tween.kill()
	_badge_tween = create_tween()
	_badge_tween.tween_property(badge_label, "scale", Vector2(1.1, 1.1), 0.12)
	_badge_tween.tween_property(badge_label, "scale", Vector2(1.0, 1.0), 0.08)
	var loop_tween := create_tween().set_loops()
	loop_tween.tween_property(badge_label, "scale", Vector2(1.1, 1.1), 0.6)
	loop_tween.tween_property(badge_label, "scale", Vector2(1.0, 1.0), 0.6)
	badge_label.set_meta("loop_tween", loop_tween)

func _hide_badge() -> void:
	if not badge_label.visible:
		return
	if _badge_tween:
		_badge_tween.kill()
		_badge_tween = null
	if badge_label.has_meta("loop_tween"):
		var lt: Tween = badge_label.get_meta("loop_tween")
		if lt:
			lt.kill()
	var t := create_tween()
	t.tween_property(badge_label, "scale", Vector2.ZERO, 0.1)
	t.tween_callback(func(): badge_label.visible = false)

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
	_deactivate_urgency()
	emit_signal("task_completed", self)
	get_node("/root/GameManager").on_task_completed(self)
	get_node("/root/AudioManager").play_task_complete()
	_play_complete_animation()

func _on_timeout() -> void:
	if is_complete:
		return
	is_complete = true
	_deactivate_urgency()
	get_node("/root/GameManager").unregister_task(self)
	get_node("/root/AudioManager").play_task_fail()
	emit_signal("task_failed", self)
	_play_fail_animation()

func _play_complete_animation() -> void:
	body.color = Color.LIME_GREEN
	var t := create_tween()
	t.tween_property(self, "scale", Vector2(1.4, 1.4), 0.15)
	t.tween_property(self, "modulate:a", 0.0, 0.3)
	t.tween_callback(queue_free)

func _play_fail_animation() -> void:
	body.color = Color.DARK_RED
	var t := create_tween()
	t.tween_property(self, "modulate:a", 0.0, 0.25)
	t.tween_callback(queue_free)
