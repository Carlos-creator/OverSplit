extends CanvasLayer

@onready var score_label = $Panel/VBoxContainer/ScoreLabel
@onready var btn_replay  = $Panel/VBoxContainer/ButtonReplay
@onready var btn_menu    = $Panel/VBoxContainer/ButtonMenu

func setup(score: int) -> void:
	score_label.text = "Score: %d" % score

func _ready() -> void:
	btn_replay.pressed.connect(_on_replay)
	btn_menu.pressed.connect(_on_menu)

func _on_replay() -> void:
	get_tree().paused = false
	queue_free()
	UpgradeManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu() -> void:
	get_tree().paused = false
	queue_free()
	UpgradeManager.reset_run()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
