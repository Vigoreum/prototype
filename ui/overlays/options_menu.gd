extends CanvasLayer

@onready var background: ColorRect = $Background
@onready var title_label: Label = $Title
@onready var options_container: VBoxContainer = $OptionsContainer
@onready var fullscreen_check: CheckBox = $OptionsContainer/FullscreenCheck
@onready var back_button: Button = $BackButton


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Inicializar el checkbox con el estado actual
	fullscreen_check.button_pressed = SettingsManager.is_fullscreen
	
	# Conectar señales
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_button.pressed.connect(_on_back_pressed)
	SettingsManager.fullscreen_changed.connect(_on_settings_fullscreen_changed)  # ← nueva
	
	# Registrar sonidos UI
	AudioManager.register_button_back(back_button)
	fullscreen_check.mouse_entered.connect(AudioManager.play_hover)
	fullscreen_check.toggled.connect(_play_check_sound)
	
	hide_menu()


# Muestra el menú de opciones
func show_menu() -> void:
	background.visible = true
	title_label.visible = true
	options_container.visible = true
	back_button.visible = true
	# Refrescar el estado del checkbox por si cambió desde otro lado (ej: F11)
	fullscreen_check.button_pressed = SettingsManager.is_fullscreen


# Oculta el menú de opciones
func hide_menu() -> void:
	background.visible = false
	title_label.visible = false
	options_container.visible = false
	back_button.visible = false


# Verifica si el menú está abierto
func is_open() -> bool:
	return background.visible


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


func _on_back_pressed() -> void:
	AudioManager.play_click_back()
	hide_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	
	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_click_back()
		hide_menu()
		get_viewport().set_input_as_handled()


func _play_check_sound(_pressed: bool) -> void:
	AudioManager.play_click_neutral()

# Se ejecuta cuando el fullscreen cambia desde fuera (ej: tecla F11)
func _on_settings_fullscreen_changed(enabled: bool) -> void:
	# Actualizamos el checkbox sin disparar la señal toggled
	# (set_pressed_no_signal evita el loop infinito)
	fullscreen_check.set_pressed_no_signal(enabled)
