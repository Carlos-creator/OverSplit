extends CanvasLayer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	$Panel/VBox/ResumeButton.pressed.connect(_on_resume)
	$Panel/VBox/MenuButton.pressed.connect(_on_menu)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("ui_cancel"):
		if get_tree().paused:
			_on_resume()
		else:
			_pause()

func _pause() -> void:
	get_tree().paused = true
	visible = true

func toggle_pause() -> void:
	if get_tree().paused:
		_on_resume()
	else:
		_pause()

func _on_resume() -> void:
	get_tree().paused = false
	visible = false

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
