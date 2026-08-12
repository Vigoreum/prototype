extends Node

# Ruta donde se guardan las configuraciones del usuario
const CONFIG_PATH: String = "user://settings.cfg"

# Sección y claves del archivo de configuración
const SECTION_DISPLAY: String = "display"
const KEY_FULLSCREEN: String = "fullscreen"
const KEY_WINDOW_SCALE: String = "window_scale"

const SECTION_AUDIO: String = "audio"

# Buses de audio (ver default_bus_layout.tres). Music y SFX envían a Master.
const BUS_MASTER: StringName = &"Master"
const BUS_MUSIC: StringName = &"Music"
const BUS_SFX: StringName = &"SFX"

# Clave en el .cfg de cada bus
const VOLUME_KEYS: Dictionary[StringName, String] = {
	BUS_MASTER: "master_volume",
	BUS_MUSIC: "music_volume",
	BUS_SFX: "sfx_volume",
}

const DEFAULT_VOLUME: float = 0.8
# Por debajo de esto silenciamos el bus: linear_to_db(0.0) da -inf
const SILENCE_THRESHOLD: float = 0.001

# Guardar en cada frame del slider destrozaría el disco: se agrupan los cambios
const SAVE_DEBOUNCE_SECONDS: float = 0.5

# Resolución base del juego. La ventana siempre es un múltiplo entero de esto,
# así los píxeles quedan perfectos (sin filas/columnas de distinto grosor).
const BASE_RESOLUTION: Vector2i = Vector2i(640, 360)
const MIN_WINDOW_SCALE: int = 1
# 3x (1920x1080) es el tope: 4x serían 2560x1440, más que la mayoría de monitores
const MAX_WINDOW_SCALE: int = 3

# Valores por defecto cuando no hay .cfg (primera vez que se abre el juego)
const DEFAULT_FULLSCREEN: bool = true
const DEFAULT_WINDOW_SCALE: int = 2

# Estado actual de los settings
var is_fullscreen: bool = DEFAULT_FULLSCREEN
var window_scale: int = DEFAULT_WINDOW_SCALE

# Volumen 0.0..1.0 por bus
var volumes: Dictionary[StringName, float] = {
	BUS_MASTER: DEFAULT_VOLUME,
	BUS_MUSIC: DEFAULT_VOLUME,
	BUS_SFX: DEFAULT_VOLUME,
}

var _save_timer: Timer = null

signal fullscreen_changed(enabled: bool)
signal window_scale_changed(scale: int)
signal volume_changed(bus: StringName, value: float)

func _ready() -> void:
	# Funciona aunque el juego esté pausado (F11 debe responder siempre)
	process_mode = Node.PROCESS_MODE_ALWAYS

	# El timer debe existir antes de cargar: _load_settings puede pedir un guardado
	_setup_save_timer()

	# Cargar y aplicar la configuración guardada
	_load_settings()
	_apply_fullscreen(is_fullscreen)
	_apply_all_volumes()

# Si el juego se cierra con un guardado pendiente, lo escribimos antes de salir
func _exit_tree() -> void:
	if _save_timer != null and _save_timer.time_left > 0.0:
		_save_settings()

# Activa o desactiva fullscreen, lo aplica y lo guarda
func set_fullscreen(enabled: bool) -> void:
	is_fullscreen = enabled
	_apply_fullscreen(enabled)
	_save_settings()
	fullscreen_changed.emit(enabled)

# Alterna entre fullscreen y ventana
func toggle_fullscreen() -> void:
	set_fullscreen(not is_fullscreen)


# Cambia la escala de la ventana (1x..3x sobre BASE_RESOLUTION).
# Si estamos en fullscreen solo se guarda: se aplicará al volver a ventana.
func set_window_scale(scale: int) -> void:
	window_scale = clampi(scale, MIN_WINDOW_SCALE, MAX_WINDOW_SCALE)
	if not is_fullscreen:
		_apply_window_scale(window_scale)
	_save_settings()
	window_scale_changed.emit(window_scale)


# Cambia el volumen de un bus (0.0..1.0). Se aplica al instante y se guarda
# con retardo, porque el slider dispara esto muchas veces por segundo.
func set_bus_volume(bus: StringName, value: float) -> void:
	if not volumes.has(bus):
		return
	var clamped: float = clampf(value, 0.0, 1.0)
	volumes[bus] = clamped
	_apply_bus_volume(bus, clamped)
	_request_save()
	volume_changed.emit(bus, clamped)


func get_bus_volume(bus: StringName) -> float:
	return volumes.get(bus, DEFAULT_VOLUME)


# ¿Cabe esta escala en el área utilizable de la pantalla actual?
# (área utilizable = pantalla menos barra de tareas)
func scale_fits_screen(scale: int) -> bool:
	var usable: Rect2i = _get_usable_rect()
	var size: Vector2i = BASE_RESOLUTION * scale
	return size.x <= usable.size.x and size.y <= usable.size.y


# La escala más grande que entra en la pantalla (mínimo 1x)
func largest_fitting_scale() -> int:
	for scale: int in range(MAX_WINDOW_SCALE, MIN_WINDOW_SCALE, -1):
		if scale_fits_screen(scale):
			return scale
	return MIN_WINDOW_SCALE

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
		# Al salir de fullscreen la ventana recupera la escala elegida
		_apply_window_scale(window_scale)


# Redimensiona la ventana a un múltiplo entero de BASE_RESOLUTION y la centra
func _apply_window_scale(scale: int) -> void:
	DisplayServer.window_set_size(BASE_RESOLUTION * scale)
	_center_window()


func _center_window() -> void:
	var usable: Rect2i = _get_usable_rect()
	var window_size: Vector2i = DisplayServer.window_get_size()
	# La división entera es intencional: la posición de la ventana son píxeles enteros
	@warning_ignore("integer_division")
	var offset: Vector2i = (usable.size - window_size) / 2
	DisplayServer.window_set_position(usable.position + offset)


func _get_usable_rect() -> Rect2i:
	return DisplayServer.screen_get_usable_rect(DisplayServer.window_get_current_screen())


func _apply_all_volumes() -> void:
	for bus: StringName in volumes:
		_apply_bus_volume(bus, volumes[bus])


# Traduce el 0..1 del slider a decibelios y silencia el bus en el mínimo
func _apply_bus_volume(bus: StringName, value: float) -> void:
	var bus_index: int = AudioServer.get_bus_index(bus)
	if bus_index < 0:
		push_warning("Bus de audio inexistente: %s" % bus)
		return
	AudioServer.set_bus_mute(bus_index, value < SILENCE_THRESHOLD)
	AudioServer.set_bus_volume_db(bus_index, linear_to_db(maxf(value, SILENCE_THRESHOLD)))

# Carga la configuración desde el archivo (si existe)
func _load_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	var err: int = config.load(CONFIG_PATH)
	
	if err != OK:
		# El archivo no existe (primera vez que se ejecuta el juego).
		# Dejamos los defaults y creamos el .cfg para que a partir de ahora exista.
		window_scale = _sanitize_scale(DEFAULT_WINDOW_SCALE)
		_save_settings()
		return

	is_fullscreen = config.get_value(SECTION_DISPLAY, KEY_FULLSCREEN, DEFAULT_FULLSCREEN)
	window_scale = _sanitize_scale(config.get_value(SECTION_DISPLAY, KEY_WINDOW_SCALE, DEFAULT_WINDOW_SCALE))

	for bus: StringName in volumes:
		var stored: float = config.get_value(SECTION_AUDIO, VOLUME_KEYS[bus], DEFAULT_VOLUME)
		volumes[bus] = clampf(stored, 0.0, 1.0)

# Ajusta la escala al rango válido y a lo que realmente entra en el monitor
# (el usuario pudo cambiar de monitor desde la última vez que jugó)
func _sanitize_scale(scale: int) -> int:
	var clamped: int = clampi(scale, MIN_WINDOW_SCALE, MAX_WINDOW_SCALE)
	if scale_fits_screen(clamped):
		return clamped
	return largest_fitting_scale()

# Guarda la configuración al archivo
func _save_settings() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.set_value(SECTION_DISPLAY, KEY_FULLSCREEN, is_fullscreen)
	config.set_value(SECTION_DISPLAY, KEY_WINDOW_SCALE, window_scale)
	for bus: StringName in volumes:
		config.set_value(SECTION_AUDIO, VOLUME_KEYS[bus], volumes[bus])
	config.save(CONFIG_PATH)


func _setup_save_timer() -> void:
	_save_timer = Timer.new()
	_save_timer.one_shot = true
	_save_timer.wait_time = SAVE_DEBOUNCE_SECONDS
	_save_timer.process_mode = Node.PROCESS_MODE_ALWAYS
	_save_timer.timeout.connect(_save_settings)
	add_child(_save_timer)


# Reinicia la cuenta atrás: solo se escribe cuando el usuario deja de mover el slider
func _request_save() -> void:
	_save_timer.start()
