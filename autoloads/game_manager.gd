extends Node

# Lista de microjuegos disponibles
const MICROGAME_SCENES: Array[String] = [
	"res://microgames/usb/usb.tscn",
	"res://microgames/delete/delete.tscn",
	"res://microgames/draw/draw.tscn",
	"res://microgames/wake_up/wake_up_microgame.tscn"
	
]

const MAIN_MENU_SCENE: String = "res://menus/main_menu.tscn"

# Duración de cada microjuego en segundos
const MICROGAME_DURATION: float = 5.0

# Estado del modo PLAY
var play_queue: Array[String] = []
var is_in_play_mode: bool = false


# Llamada desde el menú principal cuando se pulsa PLAY
func start_play_mode() -> void:
	is_in_play_mode = true
	play_queue = MICROGAME_SCENES.duplicate()
	play_queue.shuffle()
	_load_next_microgame()


# Llamada desde el menú selector cuando se elige un microjuego específico
func play_single_microgame(scene_path: String) -> void:
	is_in_play_mode = false
	get_tree().change_scene_to_file(scene_path)


# Llamada por cada microjuego cuando termina (timer agotado o jugador gana)
func microgame_finished() -> void:
	if is_in_play_mode and not play_queue.is_empty():
		_load_next_microgame()
	else:
		return_to_main_menu()


# Llamada cuando se vuelve al menú manualmente (ESC)
func return_to_main_menu() -> void:
	is_in_play_mode = false
	play_queue.clear()
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


# Devuelve la duración configurada para los microjuegos
func get_microgame_duration() -> float:
	return MICROGAME_DURATION


func _load_next_microgame() -> void:
	if play_queue.is_empty():
		return_to_main_menu()
		return
	
	var next_scene: String = play_queue.pop_front()
	get_tree().change_scene_to_file(next_scene)
