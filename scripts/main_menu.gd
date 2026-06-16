extends Control

@onready var play_button: Button = $PlayButton
@onready var select_button: Button = $SelectButton

func _on_play_pressed() -> void:
	GameManager.start_play_mode()


func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/microgame_select.tscn")
