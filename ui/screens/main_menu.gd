extends Control

const FADE_DURATION: float = 0.6  # que coincida con el de la pantalla de título
const EXIT_FADE_DURATION: float = 0.25  # corto: esperar a que cierre se siente raro

@onready var play_button: Button = $ButtonsContainer/PlayButton
@onready var select_button: Button = $ButtonsContainer/SelectButton
@onready var options_button: Button = $ButtonsContainer/OptionsButton
@onready var exit_button: Button = $ButtonsContainer/ExitButton

@onready var exit_confirm_panel: Control = $ExitConfirmPanel
@onready var yes_button: Button = $ExitConfirmPanel/Panel/Margin/Content/ButtonsRow/YesButton
@onready var no_button: Button = $ExitConfirmPanel/Panel/Margin/Content/ButtonsRow/NoButton

@onready var fade_overlay: ColorRect = $FadeOverlay

var _is_quitting: bool = false

func _ready() -> void:
	GameManager.show_cursor()
	AudioManager.register_button_positive(play_button)
	AudioManager.register_button_neutral(select_button)
	AudioManager.register_button_neutral(options_button)
	AudioManager.register_button_back(exit_button)
	
	# Botones del panel de confirmación
	AudioManager.register_button_back(yes_button)
	AudioManager.register_button_neutral(no_button)
	
	# El panel arranca oculto
	exit_confirm_panel.visible = false
	_fade_in()


func _fade_in() -> void:
	fade_overlay.modulate.a = 1.0  # asegurar que arranca tapado
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)

func _on_play_pressed() -> void:
	GameManager.start_play_mode()

func _on_select_pressed() -> void:
	get_tree().change_scene_to_file("res://ui/screens/microgame_select.tscn")

func _on_options_pressed() -> void:
	OptionsMenu.show_menu()

func _on_exit_pressed() -> void:
	exit_confirm_panel.visible = true

func _on_yes_pressed() -> void:
	if _is_quitting:
		return
	_is_quitting = true
	# Fundido corto a negro antes de cerrar
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, EXIT_FADE_DURATION).set_ease(Tween.EASE_IN)
	await tween.finished
	get_tree().quit()

func _on_no_pressed() -> void:
	if _is_quitting:
		return
	exit_confirm_panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _is_quitting:
		return
	if exit_confirm_panel.visible and event.is_action_pressed("ui_cancel"):
		exit_confirm_panel.visible = false
		get_viewport().set_input_as_handled()
