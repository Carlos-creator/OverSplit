extends CanvasLayer

@onready var efficiency_bar: ProgressBar = $Panel/VBox/EfficiencyBar
@onready var efficiency_label: Label = $Panel/VBox/EfficiencyLabel
@onready var clone_label: Label = $Panel/VBox/CloneLabel
@onready var score_label: Label = $Panel/VBox/ScoreLabel
@onready var wave_label: Label = $Panel/VBox/WaveLabel
@onready var difficulty_label: Label = $Panel/VBox/DifficultyLabel
@onready var wave_timer_label: Label = $Panel/VBox/WaveTimerLabel
@onready var wave_timer_bar: ProgressBar = $Panel/VBox/WaveTimerBar
@onready var hint_label: Label = $Panel/VBox/HintLabel

const COLOR_GOOD := Color(0.2, 0.9, 0.4)
const COLOR_MID  := Color(1.0, 0.8, 0.1)
const COLOR_BAD  := Color(0.9, 0.2, 0.2)

func _ready() -> void:
	var gm := get_node("/root/GameManager")
	gm.efficiency_changed.connect(_on_efficiency_changed)
	gm.clone_count_changed.connect(_on_clone_count_changed)
	gm.wave_started.connect(_on_wave_started)
	_on_efficiency_changed(1.0)
	_on_clone_count_changed(1)
	hint_label.text = "[SPACE] Clonar  [Q] Eliminar clon  [E] Interactuar"

func _process(_delta: float) -> void:
	var gm := get_node("/root/GameManager")
	score_label.text = "Score: %d" % gm.score
	var interval: float = gm.get_current_wave_interval()
	var remaining: float = interval - gm.wave_timer
	wave_timer_label.text = "Proxima ola: %ds" % int(ceil(remaining))
	wave_timer_bar.max_value = interval
	wave_timer_bar.value = remaining
	_update_difficulty_label(gm)

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
	_shake_if_low(value)

func _on_clone_count_changed(count: int) -> void:
	clone_label.text = "Clones: %d / %d" % [count, get_node("/root/GameManager").MAX_CLONES]

func _on_wave_started(wave_number: int) -> void:
	wave_label.text = "Ola: %d" % wave_number
	_flash_wave_label()

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

func _update_difficulty_label(gm: Node) -> void:
	var label: String = gm.get_difficulty_label()
	difficulty_label.text = "Dificultad: " + label
	match label:
		"Facil":   difficulty_label.modulate = Color(0.4, 1.0, 0.4, 1)
		"Normal":  difficulty_label.modulate = Color(1.0, 0.85, 0.2, 1)
		"Dificil": difficulty_label.modulate = Color(1.0, 0.4, 0.1, 1)
		"CAOS":    difficulty_label.modulate = Color(1.0, 0.1, 0.1, 1)
