extends Node

# Sonidos UI
const HOVER_SOUND: AudioStream = preload("res://assets/audio/UI/hover.wav")
const CLICK_POSITIVE_SOUND: AudioStream = preload("res://assets/audio/UI/click_positive.mp3")
const CLICK_BACK_SOUND: AudioStream = preload("res://assets/audio/UI/click_back.wav")
const CLICK_NEUTRAL_SOUND: AudioStream = preload("res://assets/audio/UI/click_neutral.wav")

var ui_player: AudioStreamPlayer = null


func _ready() -> void:
	ui_player = AudioStreamPlayer.new()
	add_child(ui_player)
	ui_player.process_mode = Node.PROCESS_MODE_ALWAYS


func play_hover() -> void:
	_play_sound(HOVER_SOUND)


# Sonido positivo: para acciones afirmativas (jugar, elegir microjuego, reintentar)
func play_click_positive() -> void:
	_play_sound(CLICK_POSITIVE_SOUND)


# Sonido de retroceso: para volver/salir (botón VOLVER, SALIR)
func play_click_back() -> void:
	_play_sound(CLICK_BACK_SOUND)


# Sonido neutro: para navegación (continuar, opciones, etc.)
# Mientras no haya archivo, simplemente no suena (sin error)
func play_click_neutral() -> void:
	_play_sound(CLICK_NEUTRAL_SOUND)


# Función interna: reproduce un sonido si existe, ignora si es null
func _play_sound(sound: AudioStream) -> void:
	if sound == null:
		return
	ui_player.stream = sound
	ui_player.play()


# Registra un botón con sonido positivo de clic
func register_button_positive(button: Button) -> void:
	button.mouse_entered.connect(play_hover)
	button.pressed.connect(play_click_positive)


# Registra un botón con sonido de retroceso (volver, salir)
func register_button_back(button: Button) -> void:
	button.mouse_entered.connect(play_hover)
	button.pressed.connect(play_click_back)


# Registra un botón con sonido neutro
func register_button_neutral(button: Button) -> void:
	button.mouse_entered.connect(play_hover)
	button.pressed.connect(play_click_neutral)
