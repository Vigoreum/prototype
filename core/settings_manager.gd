extends Node

# Ruta donde se guardan las configuraciones del usuario
const CONFIG_PATH: String = "user://settings.cfg"

# Sección y claves del archivo de configuración
const SECTION_DISPLAY: String = "display"
const KEY_FULLSCREEN: String = "fullscreen"

# Estado actual de los settings
var is_fullscreen: bool = false

signal fullscreen_changed(enabled: bool)

func _ready() -> void:
	# Funciona aunque el juego esté pausado (F11 debe responder siempre)
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Cargar y aplicar la configuración guardada
	_load_settings()
	_apply_fullscreen(is_fullscreen)


# Activa o desactiva fullscreen, lo aplica y lo guarda
func set_fullscreen(enabled: bool) -> void:
	is_fullscreen = enabled
	_apply_fullscreen(enabled)
	_save_settings()
	fullscreen_changed.emit(enabled)  # ← nuevo


# Alterna entre fullscreen y ventana
func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen)


# Detecta F11 globalmente
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F11:
			toggle_fullscreen()


# Aplica el modo de ventana al sistema
func _apply_fullscreen(enabled: bool) -> void:
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


# Carga la configuración desde el archivo (si existe)
func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(CONFIG_PATH)
	
	if err != OK:
		# El archivo no existe (primera vez que se ejecuta el juego)
		# Usamos los valores por defecto
		return
	
	is_fullscreen = config.get_value(SECTION_DISPLAY, KEY_FULLSCREEN, false)


# Guarda la configuración al archivo
func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_DISPLAY, KEY_FULLSCREEN, is_fullscreen)
	config.save(CONFIG_PATH)
