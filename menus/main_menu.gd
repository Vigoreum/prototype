extends Control

@onready var play_button: Button = $ButtonsContainer/PlayButton
@onready var select_button: Button = $ButtonsContainer/SelectButton
@onready var options_button: Button = $ButtonsContainer/OptionsButton
@onready var exit_button: Button = $ButtonsContainer/ExitButton

@onready var exit_confirm_panel: Control = $ExitConfirmPanel
@onready var yes_button: Button = $ExitConfirmPanel/YesButton
@onready var no_button: Button = $ExitConfirmPanel/NoButton

func _ready() -> void:
	AudioManager.register_button_positive(play_button)
	AudioManager.register_button_neutral(select_button)
	AudioManager.register_button_neutral(options_button)
	AudioManager.register_button_back(exit_button)
	
	# Botones del panel de confirmación
	AudioManager.register_button_back(yes_button)
	AudioManager.register_button_neutral(no_button)
	
	# El panel arranca oculto
	exit_confirm_panel.visible = false

func _on_play_pressed() -> void:
	GameManager.start_play_mode()

func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://menus/microgame_select.tscn")

func _on_options_pressed() -> void:
	OptionsMenu.show_menu()

func _on_exit_pressed() -> void:
	exit_confirm_panel.visible = true

func _on_yes_pressed() -> void:
	get_tree().quit()

func _on_no_pressed() -> void:
	exit_confirm_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if exit_confirm_panel.visible and event.is_action_pressed("ui_cancel"):
		exit_confirm_panel.visible = false
		get_viewport().set_input_as_handled()
