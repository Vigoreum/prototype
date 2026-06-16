extends Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ui_cancel = tecla ESC por defecto
		GameManager.return_to_main_menu()
