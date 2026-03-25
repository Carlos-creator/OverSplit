extends Node2D

func _ready() -> void:
	var original := $Player/OriginalPlayer
	$CloneManager.register_original(original)
	get_node("/root/GameManager").start_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_PREDELETE:
		get_node("/root/GameManager").stop_game()
