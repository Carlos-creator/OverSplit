extends Node2D

func _ready() -> void:
	$CanvasLayer/Panel/VBox/PlayButton.pressed.connect(_on_play)
	$CanvasLayer/Panel/VBox/QuitButton.pressed.connect(_on_quit)

func _on_play() -> void:
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_quit() -> void:
	get_tree().quit()
