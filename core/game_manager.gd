extends Node

# Lista de paths a los Resources de microjuegos.
# Cada uno apunta a un .tres que contiene los datos del microjuego.
const MICROGAME_DATA_PATHS: Array[String] = [
	"res://microgames/usb/usb_data.tres",
	"res://microgames/delete/delete_data.tres",
	"res://microgames/draw/draw_data.tres",
	"res://microgames/wake_up/wake_up_data.tres"
]

const MAIN_MENU_SCENE: String = "res://menus/main_menu.tscn"
const MICROGAME_INTRO_SCENE: String = "res://menus/microgame_intro.tscn"

# Estado del modo PLAY
var play_queue: Array[MicrogameData] = []
var is_in_play_mode: bool = false

# Sistema de "buzón" para pasar datos entre escenas
# La escena de intro lee estos datos en su _ready()
var pending_intro_data: MicrogameData = null

# Microjuego que se va a cargar después de la intro
var pending_microgame_data: MicrogameData = null

# Resource del microjuego que se está jugando actualmente
var current_microgame_data: MicrogameData = null

# ===== Modo PLAY (secuencia aleatoria) =====

func start_play_mode() -> void:
	is_in_play_mode = true
	play_queue = _load_all_microgame_data()
	play_queue.shuffle()
	_load_next_microgame()


# ===== Modo "Escoger Microjuego" (uno solo) =====

func play_single_microgame(data_path: String) -> void:
	is_in_play_mode = false
	var data: MicrogameData = load(data_path)
	if data == null:
		print("⚠️ No se pudo cargar el MicrogameData en: ", data_path)
		return_to_main_menu()
		return
	_start_microgame_with_intro(data)


# ===== Cuando termina un microjuego =====

func microgame_finished() -> void:
	if is_in_play_mode and not play_queue.is_empty():
		_load_next_microgame()
	else:
		return_to_main_menu()


# ===== Volver al menú principal =====

func return_to_main_menu() -> void:
	is_in_play_mode = false
	play_queue.clear()
	pending_intro_data = null
	pending_microgame_data = null
	current_microgame_data = null  # limpiar también esto
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func start_pending_microgame() -> void:
	if pending_microgame_data == null:
		print("⚠️ start_pending_microgame: no hay datos pendientes")
		return_to_main_menu()
		return
	
	# Guardar el dato del microjuego en curso (para que el microjuego lo lea)
	current_microgame_data = pending_microgame_data
	
	var scene: PackedScene = pending_microgame_data.scene
	pending_microgame_data = null
	get_tree().change_scene_to_packed(scene)

func get_microgame_duration() -> float:
	if current_microgame_data != null:
		return current_microgame_data.duration
	return 5.0  # fallback por si el microjuego se ejecuta solo con F6

# ===== Funciones internas =====

func _load_next_microgame() -> void:
	if play_queue.is_empty():
		return_to_main_menu()
		return
	
	var next_data: MicrogameData = play_queue.pop_front()
	_start_microgame_with_intro(next_data)


func _start_microgame_with_intro(data: MicrogameData) -> void:
	# Llenar los "buzones" antes de cambiar de escena
	pending_intro_data = data
	pending_microgame_data = data
	# Cargar la escena de intro
	get_tree().change_scene_to_file(MICROGAME_INTRO_SCENE)


func _load_all_microgame_data() -> Array[MicrogameData]:
	var result: Array[MicrogameData] = []
	for path in MICROGAME_DATA_PATHS:
		var data: MicrogameData = load(path)
		if data != null:
			result.append(data)
		else:
			print("⚠️ No se pudo cargar: ", path)
	return result
