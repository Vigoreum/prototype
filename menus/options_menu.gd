extends Control

@onready var fullscreen_check: CheckBox = $OptionsContainer/FullscreenCheck
@onready var back_button: Button = $BackButton

# Indica desde dónde se abrió OptionsMenu para saber a dónde volver
# Valores: "main_menu" o "pause_menu"
static var came_from: String = "main_menu"


func _ready() -> void:
	# Inicializar el checkbox con el estado actual de SettingsManager
	fullscreen_check.button_pressed = SettingsManager.is_fullscreen
	
	# Conectar señales
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	
	# Registrar sonidos UI
	AudioManager.register_button_back(back_button)
	# El checkbox no se "registra" como botón normal, le agregamos su propio sonido
	fullscreen_check.mouse_entered.connect(AudioManager.play_hover)
	fullscreen_check.toggled.connect(_play_check_sound)


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_back_pressed() -> void:
	_return_to_origin()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_click_back()
		_return_to_origin()


func _return_to_origin() -> void:
	if came_from == "pause_menu":
		# Si vinimos del menú de pausa, volver al menú de pausa
		# Como el pause_menu está como autoload, solo lo mostramos
		IrisTransition.transition_to_scene(GameManager.MAIN_MENU_SCENE)
		# Esperamos a que cargue el menú principal, luego pausamos otra vez
		await get_tree().process_frame
		await get_tree().process_frame
		# Hmm, esto es complicado. Lo arreglamos en la Etapa 5.
	else:
		# Vinimos del menú principal
		IrisTransition.transition_to_scene(GameManager.MAIN_MENU_SCENE)


# Sonido al togglear el checkbox (usamos neutral como "navegación/cambio")
func _play_check_sound(_pressed: bool) -> void:
	AudioManager.play_click_neutral()
