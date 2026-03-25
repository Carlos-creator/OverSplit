extends CanvasLayer

@onready var efficiency_bar: ProgressBar = $Panel/VBox/EfficiencyBar
@onready var efficiency_label: Label = $Panel/VBox/EfficiencyLabel
@onready var clone_label: Label = $Panel/VBox/CloneLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var difficulty_label: Label = $Panel/VBox/DifficultyLabel
@onready var wave_timer_label: Label = $Panel/VBox/WaveTimerLabel
@onready var wave_timer_bar: ProgressBar = $Panel/VBox/WaveTimerBar
@onready var stress_label: Label = $Panel/VBox/StressLabel
@onready var stress_bar: ProgressBar = $Panel/VBox/StressBar
@onready var hint_label: Label = $Panel/VBox/HintLabel
@onready var pause_button: Button = $Panel/VBox/PauseButton
@onready var speed_button: Button = $Panel/VBox/SpeedButton
@onready var skip_button: Button = $Panel/VBox/SkipButton

const COLOR_GOOD := Color(0.2, 0.9, 0.4)
const COLOR_MID  := Color(1.0, 0.8, 0.1)
const COLOR_BAD  := Color(0.9, 0.2, 0.2)

const SPEED_STEPS: Array[float] = [1.0, 1.5, 2.0]
const SPEED_LABELS: Array[String] = ["x1", "x1.5", "x2"]
var _speed_index: int = 0
var _zona_colapso: bool = false
var _shake_tween: Tween = null

func _ready() -> void:
	var gm := get_node("/root/GameManager")
	gm.efficiency_changed.connect(_on_efficiency_changed)
	gm.clone_count_changed.connect(_on_clone_count_changed)
	gm.wave_started.connect(_on_wave_started)
	gm.stress_changed.connect(_on_stress_changed)
	gm.zona_colapso_changed.connect(_on_zona_colapso_changed)
	_on_efficiency_changed(1.0)
	_on_clone_count_changed(1)
	_on_stress_changed(0, gm.MAX_STRESS)
	hint_label.text = "[SPACE] Clonar  [Q] Eliminar clon  [E] Interactuar"
	pause_button.pressed.connect(_on_pause_button)
	speed_button.pressed.connect(_on_speed_button)
	skip_button.pressed.connect(_on_skip_button)
	_update_speed_button()

func _process(_delta: float) -> void:
	var gm := get_node("/root/GameManager")
	score_label.text = "Score: %d" % gm.score
	var interval: float = gm.get_current_wave_interval()
	var remaining: float = interval - gm.wave_timer
	wave_timer_label.text = "Proxima ola: %ds" % int(ceil(remaining))
	wave_timer_bar.max_value = interval
	wave_timer_bar.value = remaining
	_update_difficulty_label(gm)
	skip_button.disabled = not gm.tasks_active.is_empty()

func _on_efficiency_changed(value: float) -> void:
	efficiency_bar.value = value * 100.0
	var pct := int(value * 100)
	efficiency_label.text = "Eficiencia: %d%%" % pct
	var bar_color: Color
	if value > 0.6:
		bar_color = COLOR_GOOD
	elif value > 0.35:
		bar_color = COLOR_MID
	else:
		bar_color = COLOR_BAD
	efficiency_bar.add_theme_stylebox_override("fill", _make_fill_style(bar_color))
	if not _zona_colapso:
		_shake_if_low(value)

func _on_clone_count_changed(count: int) -> void:
	clone_label.text = "Clones: %d / %d" % [count, get_node("/root/GameManager").MAX_CLONES]

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Ola: %d" % wave_number
	_flash_wave_label()

func _on_stress_changed(value: int, max_value: int) -> void:
	stress_bar.max_value = max_value
	stress_bar.value = value
	if value == 0:
		stress_label.text = "Estres: 0/%d" % max_value
		stress_label.modulate = Color(0.8, 0.8, 0.8, 1)
		stress_bar.add_theme_stylebox_override("fill", _make_fill_style(Color(0.3, 0.8, 0.3)))
	elif value <= 2:
		stress_label.text = "Estres: %d/%d" % [value, max_value]
		stress_label.modulate = Color(1.0, 0.85, 0.2, 1)
		stress_bar.add_theme_stylebox_override("fill", _make_fill_style(Color(0.9, 0.7, 0.1)))
	elif value <= 4:
		stress_label.text = "Estres: %d/%d  !" % [value, max_value]
		stress_label.modulate = Color(1.0, 0.4, 0.1, 1)
		stress_bar.add_theme_stylebox_override("fill", _make_fill_style(Color(0.9, 0.3, 0.1)))
	else:
		stress_label.text = "!! ZONA CRITICA !!"
		stress_label.modulate = Color(1.0, 0.1, 0.1, 1)
		stress_bar.add_theme_stylebox_override("fill", _make_fill_style(Color(1.0, 0.05, 0.05)))

func _on_zona_colapso_changed(active: bool) -> void:
	_zona_colapso = active
	if active:
		_start_continuous_shake()
	else:
		_stop_continuous_shake()

func _start_continuous_shake() -> void:
	if _shake_tween and _shake_tween.is_running():
		return
	_shake_tween = create_tween().set_loops()
	_shake_tween.tween_property($Panel, "position:x", 5.0, 0.05)
	_shake_tween.tween_property($Panel, "position:x", -5.0, 0.05)
	_shake_tween.tween_property($Panel, "position:x", 3.0, 0.04)
	_shake_tween.tween_property($Panel, "position:x", -3.0, 0.04)
	_shake_tween.tween_property($Panel, "position:x", 0.0, 0.04)

func _stop_continuous_shake() -> void:
	if _shake_tween:
		_shake_tween.kill()
		_shake_tween = null
	$Panel.position.x = 0.0

func _flash_wave_label() -> void:
	var t := create_tween()
	t.tween_property(wave_label, "modulate:a", 0.0, 0.0)
	t.tween_property(wave_label, "modulate:a", 1.0, 0.3)
	t.tween_interval(1.5)
	t.tween_property(wave_label, "modulate:a", 0.0, 0.5)

func _shake_if_low(eff: float) -> void:
	if eff > 0.25:
		return
	var t := create_tween()
	for i in 4:
		t.tween_property($Panel, "position:x", 4.0 * (1 if i % 2 == 0 else -1), 0.04)
	t.tween_property($Panel, "position:x", 0.0, 0.04)

func _make_fill_style(color: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = color
	return s

func _on_pause_button() -> void:
	var pause_menu := get_tree().get_root().find_child("PauseMenu", true, false)
	if pause_menu:
		pause_menu.toggle_pause()

func _on_speed_button() -> void:
	_speed_index = (_speed_index + 1) % SPEED_STEPS.size()
	Engine.time_scale = SPEED_STEPS[_speed_index]
	_update_speed_button()

func _update_speed_button() -> void:
	speed_button.text = "Vel: " + SPEED_LABELS[_speed_index]
	match _speed_index:
		0: speed_button.modulate = Color(0.85, 0.85, 0.85, 1.0)
		1: speed_button.modulate = Color(1.0, 0.85, 0.3, 1.0)
		2: speed_button.modulate = Color(1.0, 0.35, 0.1, 1.0)

func _on_skip_button() -> void:
	get_node("/root/GameManager").skip_wave()

func _update_difficulty_label(gm: Node) -> void:
	var label: String = gm.get_difficulty_label()
	difficulty_label.text = "Dificultad: " + label
	match label:
		"Facil":   difficulty_label.modulate = Color(0.4, 1.0, 0.4, 1)
		"Normal":  difficulty_label.modulate = Color(1.0, 0.85, 0.2, 1)
		"Dificil": difficulty_label.modulate = Color(1.0, 0.4, 0.1, 1)
		"CAOS":    difficulty_label.modulate = Color(1.0, 0.1, 0.1, 1)
