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
	"res://microgames/wake_up/wake_up_data.tres",
	"res://microgames/correct_password/correct_password_data.tres"
]

const MAIN_MENU_SCENE: String = "res://ui/screens/main_menu.tscn"
const MICROGAME_INTRO_SCENE: String = "res://ui/screens/microgame_intro.tscn"
const GAME_OVER_SCENE: String = "res://ui/screens/game_over.tscn"
const LIFE_LOST_SCENE: String = "res://ui/screens/life_lost.tscn"
const MAX_LIVES: int = 4


# ===== ESTADO =====

var lives: int = MAX_LIVES
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
	if IrisTransition.is_busy:
		return
	is_in_play_mode = true
	lives = MAX_LIVES
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
	microgame_won.emit()


func notify_microgame_lost() -> void:
	microgame_lost.emit()


func notify_microgame_timed_out() -> void:
	microgame_timed_out.emit()


# ===== RESPUESTAS A LAS SEÑALES =====

func _on_microgame_won() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_advance_or_finish()


func _on_microgame_lost() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_handle_life_loss()


func _on_microgame_timed_out() -> void:
	if is_transitioning:
		return
	is_transitioning = true
	_handle_life_loss()


func _handle_life_loss() -> void:
	# En single mode no hay vidas: perder va directo a game over
	if not is_in_play_mode:
		_show_game_over()
		return
	
	lives -= 1
	IrisTransition.transition_to_scene(LIFE_LOST_SCENE)


# Llamada por life_lost.gd cuando termina la animación
func continue_after_life_lost() -> void:
	if lives <= 0:
		_show_game_over()
	else:
		is_transitioning = false
		_advance_or_finish()


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
	is_transitioning = false
	IrisTransition.transition_to_scene(MAIN_MENU_SCENE)


# ===== CURSOR =====

func show_cursor() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	# Fuerza el redibujado inmediato del cursor
	var vp: Viewport = get_viewport()
	if vp != null:
		vp.warp_mouse(vp.get_mouse_position())


func hide_cursor() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN


# Aplica el cursor según el MicrogameData del microjuego actual
func restore_microgame_cursor() -> void:
	if current_microgame_data != null and current_microgame_data.show_cursor:
		show_cursor()
	else:
		hide_cursor()


# Decide el estado correcto del cursor según la escena actual.
# La llama IrisTransition al terminar una transición, y pause_menu al reanudar.
func refresh_cursor() -> void:
	var scene: Node = get_tree().current_scene
	if scene == null:
		hide_cursor()
		return
	
	var path: String = scene.scene_file_path
	
	# Menús con botones: cursor visible
	if path.ends_with("main_menu.tscn") \
	or path.ends_with("microgame_select.tscn") \
	or path.ends_with("game_over.tscn"):
		show_cursor()
		return
	
	# Intro y pantalla de vidas: sin cursor
	if path.ends_with("microgame_intro.tscn") \
	or path.ends_with("life_lost.tscn"):
		hide_cursor()
		return
	
	# Microjuego: según su MicrogameData
	restore_microgame_cursor()


# ===== INTRO Y CARGA DE MICROJUEGOS =====

func start_pending_microgame() -> void:
	if pending_microgame_data == null:
		print("⚠️ start_pending_microgame: no hay datos pendientes")
		return_to_main_menu()
		return
	
	current_microgame_data = pending_microgame_data
	var scene: PackedScene = pending_microgame_data.scene
	pending_microgame_data = null
	is_transitioning = false
	IrisTransition.transition_to_packed_scene(scene)


func get_microgame_duration() -> float:
	if current_microgame_data != null:
		return current_microgame_data.duration
	return 5.0


# ===== PAUSA =====

# Llamada por el jugador (ESC) o por pérdida de foco
# Nota: la transición iris sigue corriendo aunque el juego esté pausado
# porque IrisTransition tiene process_mode = ALWAYS
func try_open_pause_menu() -> void:
	if get_tree().paused:
		return
	
	if not _is_pausable_scene():
		return
	
	show_cursor()
	get_tree().paused = true
	PauseMenu.show_menu()


# True si la escena actual permite pausa
func _is_pausable_scene() -> bool:
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return false
	
	var scene_name: String = current_scene.scene_file_path
	
	# Escenas que NO permiten pausa
	if scene_name.ends_with("main_menu.tscn"):
		return false
	if scene_name.ends_with("microgame_select.tscn"):
		return false
	if scene_name.ends_with("game_over.tscn"):
		return false
	
	# Todo lo demás (microjuegos, intro, life_lost) sí permite pausa
	return true


# Detección de pérdida de foco (alt-tab, minimizar)
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		try_open_pause_menu()


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
