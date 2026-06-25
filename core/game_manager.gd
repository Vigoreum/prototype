extends Node

# ===== SEÑALES =====

signal microgame_won
signal microgame_lost
signal microgame_timed_out


# ===== CONSTANTES =====

const MICROGAME_DATA_PATHS: Array[String] = [
	"res://microgames/usb/usb_data.tres",
	"res://microgames/delete/delete_data.tres",
	"res://microgames/draw/draw_data.tres",
	"res://microgames/wake_up/wake_up_data.tres"
]

const MAIN_MENU_SCENE: String = "res://menus/main_menu.tscn"
const MICROGAME_INTRO_SCENE: String = "res://menus/microgame_intro.tscn"
const GAME_OVER_SCENE: String = "res://menus/game_over.tscn"


# ===== ESTADO =====

var play_queue: Array[MicrogameData] = []
var is_in_play_mode: bool = false
var pending_intro_data: MicrogameData = null
var pending_microgame_data: MicrogameData = null
var current_microgame_data: MicrogameData = null
var is_transitioning: bool = false

# ===== READY =====

func _ready() -> void:
	microgame_won.connect(_on_microgame_won)
	microgame_lost.connect(_on_microgame_lost)
	microgame_timed_out.connect(_on_microgame_timed_out)


# ===== MODO PLAY =====

func start_play_mode() -> void:
	is_in_play_mode = true
	play_queue = _load_all_microgame_data()
	play_queue.shuffle()
	_load_next_microgame()


func play_single_microgame(data_path: String) -> void:
	is_in_play_mode = false
	var data: MicrogameData = load(data_path)
	if data == null:
		print("⚠️ No se pudo cargar el MicrogameData en: ", data_path)
		return_to_main_menu()
		return
	_start_microgame_with_intro(data)


# ===== FUNCIONES QUE LLAMAN LOS MICROJUEGOS =====

func notify_microgame_won() -> void:
	print("📡 notify_microgame_won emitida")
	microgame_won.emit()


func notify_microgame_lost() -> void:
	microgame_lost.emit()


func notify_microgame_timed_out() -> void:
	microgame_timed_out.emit()


# ===== RESPUESTAS A LAS SEÑALES =====

func _on_microgame_won() -> void:
	if is_transitioning:
		print("⚠️ Ignorando microgame_won duplicado (ya en transición)")
		return
	is_transitioning = true
	_advance_or_finish()


func _on_microgame_lost() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_show_game_over()


func _on_microgame_timed_out() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_show_game_over()


# ===== REINTENTAR =====

func retry_after_loss() -> void:
	if is_in_play_mode:
		start_play_mode()
	else:
		if current_microgame_data != null:
			var data: MicrogameData = current_microgame_data
			_start_microgame_with_intro(data)
		else:
			return_to_main_menu()


# ===== VOLVER AL MENÚ =====

func return_to_main_menu() -> void:
	is_in_play_mode = false
	play_queue.clear()
	pending_intro_data = null
	pending_microgame_data = null
	current_microgame_data = null
	is_transitioning = false  # ← reset
	IrisTransition.transition_to_scene(MAIN_MENU_SCENE)


# ===== INTRO Y CARGA DE MICROJUEGOS =====

func start_pending_microgame() -> void:
	if pending_microgame_data == null:
		print("⚠️ start_pending_microgame: no hay datos pendientes")
		return_to_main_menu()
		return
	
	current_microgame_data = pending_microgame_data
	var scene: PackedScene = pending_microgame_data.scene
	pending_microgame_data = null
	is_transitioning = false  # ← reset cuando arranca el siguiente microjuego
	IrisTransition.transition_to_packed_scene(scene)


func get_microgame_duration() -> float:
	if current_microgame_data != null:
		return current_microgame_data.duration
	return 5.0


# ===== LÓGICA INTERNA =====

func _advance_or_finish() -> void:
	if is_in_play_mode and not play_queue.is_empty():
		_load_next_microgame()
	else:
		return_to_main_menu()


func _show_game_over() -> void:
	IrisTransition.transition_to_scene(GAME_OVER_SCENE)


func _load_next_microgame() -> void:
	if play_queue.is_empty():
		return_to_main_menu()
		return
	
	var next_data: MicrogameData = play_queue.pop_front()
	_start_microgame_with_intro(next_data)


func _start_microgame_with_intro(data: MicrogameData) -> void:
	pending_intro_data = data
	pending_microgame_data = data
	IrisTransition.transition_to_scene(MICROGAME_INTRO_SCENE)


func _load_all_microgame_data() -> Array[MicrogameData]:
	var result: Array[MicrogameData] = []
	for path in MICROGAME_DATA_PATHS:
		var data: MicrogameData = load(path)
		if data != null:
			result.append(data)
		else:
			print("⚠️ No se pudo cargar: ", path)
	return result
