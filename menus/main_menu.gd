extends Control

@onready var play_button: Button = $ButtonsContainer/PlayButton
@onready var select_button: Button = $ButtonsContainer/SelectButton
@onready var options_button: Button = $ButtonsContainer/OptionsButton

func _ready() -> void:
	AudioManager.register_button_positive(play_button)
	AudioManager.register_button_neutral(select_button)
	AudioManager.register_button_neutral(options_button)

func _on_play_pressed() -> void:
	GameManager.start_play_mode()


func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/microgame_select.tscn")


func _on_options_pressed() -> void:
	OptionsMenu.show_menu()
