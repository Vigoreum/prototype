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
const SPEED_UP_SCENE: String = "res://ui/screens/speed_up.tscn"
const MAX_LIVES: int = 4

# Microjuegos que hay que jugar (se ganen o se pierdan) para subir de velocidad
const MICROGAMES_PER_SPEED_UP: int = 4
# Cuánto se acelera el juego en cada subida
const SPEED_STEP: float = 0.25
# Nivel 1 = x1.0, nivel 5 = x2.0 (tope). Más rápido que x2 los microjuegos
# dejan de ser legibles
const MAX_SPEED_LEVEL: int = 5


# ===== ESTADO =====

var lives: int = MAX_LIVES
var play_queue: Array[MicrogameData] = []
# Microjuegos jugados en la partida actual, para saber cuándo acelerar
var microgames_played: int = 0
# Microjuegos ganados en la partida actual: el puntaje que muestra el game over
var microgames_cleared: int = 0
var speed_level: int = 1
var is_in_play_mode: bool = false
var pending_intro_data: MicrogameData = null
var pending_microgame_data: MicrogameData = null
var current_microgame_data: MicrogameData = null
var is_transitioning: bool = false
# True mientras el game over se muestre superpuesto sobre otra escena
# (fundido encima de life_lost al perder la última vida)
var is_game_over_overlay: bool = false


# ===== READY =====

func _ready() -> void:
	microgame_won.connect(_on_microgame_won)
	microgame_lost.connect(_on_microgame_lost)
	microgame_timed_out.connect(_on_microgame_timed_out)


# ===== MODO PLAY =====

func start_play_mode() -> void:
	if IrisTransition.is_busy:
		return
	is_game_over_overlay = false
	is_in_play_mode = true
	lives = MAX_LIVES
	microgames_played = 0
	microgames_cleared = 0
	speed_level = 1
	reset_game_speed()
	play_queue = _load_all_microgame_data()
	play_queue.shuffle()
	_load_next_microgame()


func play_single_microgame(data_path: String) -> void:
	is_in_play_mode = false
	speed_level = 1
	reset_game_speed()
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
	microgames_cleared += 1
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
	reset_game_speed()

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


# Llamada por life_lost.gd al fundir el game over encima suyo. Como no hay
# cambio de escena, current_scene sigue siendo life_lost.tscn: hay que
# mostrar el cursor y bloquear la pausa a mano
func enter_game_over_overlay() -> void:
	is_game_over_overlay = true
	show_cursor()


# Llamada por speed_up.gd cuando termina de mostrarse la pantalla
func continue_after_speed_up() -> void:
	_load_next_microgame()


# ===== VELOCIDAD =====

# Multiplicador de tiempo del nivel de velocidad actual (nivel 1 = x1.0)
func get_speed_multiplier() -> float:
	return 1.0 + (speed_level - 1) * SPEED_STEP


# Acelerar el juego entero (animaciones, física y barra de tiempo a la vez) en
# vez de solo recortar la duración: si únicamente durara menos, los microjuegos
# con movimiento a velocidad fija se volverían imposibles en vez de más difíciles
func apply_game_speed() -> void:
	Engine.time_scale = get_speed_multiplier()


func reset_game_speed() -> void:
	Engine.time_scale = 1.0


# Vuelve a la velocidad que corresponda a la escena actual. La usa el menú de
# pausa al reanudar: solo los microjuegos van acelerados, los menús y pantallas
# intermedias siempre a x1.0
func restore_game_speed() -> void:
	if _is_microgame_scene():
		apply_game_speed()
	else:
		reset_game_speed()


# True si la escena actual es el microjuego en curso (y no una intro, menú o
# pantalla intermedia)
func _is_microgame_scene() -> bool:
	if current_microgame_data == null or current_microgame_data.scene == null:
		return false

	var scene: Node = get_tree().current_scene
	if scene == null:
		return false

	return scene.scene_file_path == current_microgame_data.scene.resource_path


# ===== REINTENTAR =====

func retry_after_loss() -> void:
	is_game_over_overlay = false
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
	reset_game_speed()
	is_in_play_mode = false
	speed_level = 1
	microgames_played = 0
	microgames_cleared = 0
	play_queue.clear()
	pending_intro_data = null
	pending_microgame_data = null
	current_microgame_data = null
	is_transitioning = false
	is_game_over_overlay = false
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
	# Si una transición termina con el juego pausado, el menú de pausa sigue
	# abierto y necesita el cursor visible para poder usar sus botones
	if get_tree().paused:
		show_cursor()
		return

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
	
	# Intro y pantallas intermedias: sin cursor
	if path.ends_with("microgame_intro.tscn") \
	or path.ends_with("life_lost.tscn") \
	or path.ends_with("speed_up.tscn"):
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
	apply_game_speed()
	IrisTransition.transition_to_packed_scene(scene)


func get_microgame_duration() -> float:
	if current_microgame_data != null:
		return current_microgame_data.duration
	return 5.0


# ===== PAUSA =====

# Llamada por el jugador (ESC) o por pérdida de foco
# Nota: la transición iris sigue corriendo aunque el juego esté pausado
# porque IrisTransition tiene process_mode = ALWAYS. La escena siguiente se
# carga ya pausada, así que su timer no empieza a correr
func try_open_pause_menu() -> void:
	if not _is_pausable_scene():
		return

	# El countdown de reanudación corre aunque el juego esté pausado, así que
	# con el juego acelerado contaría más rápido
	reset_game_speed()

	# Perder el foco durante el countdown de reanudación tiene que volver a pausar:
	# el countdown corre aunque el juego esté pausado, y al terminar despausaría
	# el microjuego con el jugador fuera de la ventana
	if CountdownOverlay.is_counting():
		CountdownOverlay.cancel_countdown()
		show_cursor()
		PauseMenu.show_menu()
		return

	if get_tree().paused:
		return

	show_cursor()
	get_tree().paused = true
	PauseMenu.show_menu()


# True si la escena actual permite pausa
func _is_pausable_scene() -> bool:
	# El game over superpuesto tampoco permite pausa, aunque la escena de
	# abajo (life_lost) sí lo haría
	if is_game_over_overlay:
		return false

	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return false

	var scene_name: String = current_scene.scene_file_path
	
	# Escenas que NO permiten pausa
	if scene_name.ends_with("splash_screen.tscn"):
		return false
	if scene_name.ends_with("title_screen.tscn"):
		return false
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

# Se llama al terminar un microjuego, se haya ganado o perdido (en ese caso
# después de la pantalla de vidas). En play mode la partida es infinita: solo
# termina al quedarse sin vidas
func _advance_or_finish() -> void:
	# Las intros y pantallas intermedias van siempre a velocidad normal
	reset_game_speed()

	if not is_in_play_mode:
		return_to_main_menu()
		return

	microgames_played += 1

	if _should_speed_up():
		speed_level += 1
		IrisTransition.transition_to_scene(SPEED_UP_SCENE)
		return

	_load_next_microgame()


# True si toca subir de velocidad después del microjuego recién jugado
func _should_speed_up() -> bool:
	if speed_level >= MAX_SPEED_LEVEL:
		return false
	return microgames_played % MICROGAMES_PER_SPEED_UP == 0


func _show_game_over() -> void:
	reset_game_speed()
	IrisTransition.transition_to_scene(GAME_OVER_SCENE)


func _load_next_microgame() -> void:
	if play_queue.is_empty():
		_refill_play_queue()

	# La cola solo puede seguir vacía si no se pudo cargar ningún microjuego
	if play_queue.is_empty():
		print("⚠️ No hay microjuegos para jugar")
		return_to_main_menu()
		return

	var next_data: MicrogameData = play_queue.pop_front()
	_start_microgame_with_intro(next_data)


# Vuelve a llenar la cola con todos los microjuegos barajados. Si el primero de
# la nueva tanda es el que se acaba de jugar, lo cambia de lugar para que no
# salga dos veces seguidas
func _refill_play_queue() -> void:
	play_queue = _load_all_microgame_data()
	play_queue.shuffle()

	if play_queue.size() > 1 and play_queue[0] == current_microgame_data:
		play_queue.push_back(play_queue.pop_front())


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
