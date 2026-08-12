extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var center_container: VBoxContainer = $CenterContainer
@onready var continue_button: Button = $CenterContainer/ContinueButton
@onready var options_button: Button = $CenterContainer/OptionsButton
@onready var exit_button: Button = $CenterContainer/ExitButton

# Flag para evitar que el mismo ESC abra y cierre el menú
var just_opened: bool = false

func _ready() -> void:
	AudioManager.register_button_neutral(continue_button)
	AudioManager.register_button_neutral(options_button)
	AudioManager.register_button_back(exit_button)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide_menu()

func show_menu() -> void:
	background.visible = true
	center_container.visible = true
	just_opened = true
	# Después de un frame, ya puede recibir ESC para cerrar
	await get_tree().process_frame
	just_opened = false

func hide_menu() -> void:
	background.visible = false
	center_container.visible = false

func is_open() -> bool:
	return background.visible

func _unhandled_input(event: InputEvent) -> void:
	# Solo procesar si el menú está abierto Y no acaba de abrirse
	if not is_open():
		return
	if just_opened:
		return
	
	if event.is_action_pressed("ui_cancel"):
		_on_continue_pressed()
		get_viewport().set_input_as_handled()

func _on_continue_pressed() -> void:
	hide_menu()
	GameManager.hide_cursor()
	CountdownOverlay.start_countdown(3)
	await CountdownOverlay.countdown_finished

	# Si el menú volvió a abrirse durante el countdown (perder el foco lo cancela),
	# seguimos en pausa: no hay que despausar
	if is_open():
		return

	GameManager.restore_game_speed()
	get_tree().paused = false
	GameManager.refresh_cursor()

func _on_options_pressed() -> void:
	OptionsMenu.show_menu()

func _on_exit_pressed() -> void:
	# Si hay una transición en curso, return_to_main_menu() sería ignorada:
	# cerrar el menú aquí dejaría al jugador despausado y sin salida
	if IrisTransition.is_busy:
		return

	get_tree().paused = false
	hide_menu()
	GameManager.return_to_main_menu()
