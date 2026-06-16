extends Node2D

const FILE_COUNT_GOOD: int = 3
const FILE_COUNT_BAD: int = 3
const SPAWN_AREA_MIN: Vector2 = Vector2(80, 100)
const SPAWN_AREA_MAX: Vector2 = Vector2(900, 480)
const MIN_DISTANCE_BETWEEN_FILES: float = 110.0
const TRASH_SPAWN_MARGIN: float = 80.0
const TimerBarScene: PackedScene = preload("res://menus/timer_bar.tscn")

@onready var trash_can: Area2D = $TrashCan
@onready var files_container: Node2D = $FilesContainer

const FileItemScene: PackedScene = preload("res://microgames/delete/file_item.tscn")

# Estado global: indica si hay algún archivo siendo arrastrado
var any_file_grabbed: bool = false
var timer_bar: Control = null

func _ready() -> void:
	randomize()
	_spawn_files()
	if GameManager.is_in_play_mode:
		_setup_timer_bar()


func _setup_timer_bar() -> void:
	timer_bar = TimerBarScene.instantiate()
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(timer_bar)
	timer_bar.time_up.connect(_on_time_up)
	timer_bar.start(GameManager.get_microgame_duration())

func _on_time_up() -> void:
	GameManager.microgame_finished()

func _spawn_files() -> void:
	var spawned_positions: Array[Vector2] = []
	
	for i in FILE_COUNT_GOOD:
		var pos: Vector2 = _get_valid_spawn_position(spawned_positions)
		spawned_positions.append(pos)
		_spawn_file(pos, false)
	
	for i in FILE_COUNT_BAD:
		var pos: Vector2 = _get_valid_spawn_position(spawned_positions)
		spawned_positions.append(pos)
		_spawn_file(pos, true)


func _get_valid_spawn_position(existing: Array[Vector2]) -> Vector2:
	for attempt in 30:
		var candidate: Vector2 = Vector2(
			randf_range(SPAWN_AREA_MIN.x, SPAWN_AREA_MAX.x),
			randf_range(SPAWN_AREA_MIN.y, SPAWN_AREA_MAX.y)
		)
		
		if _is_position_over_trash(candidate):
			continue
		
		var is_valid: bool = true
		for pos in existing:
			if candidate.distance_to(pos) < MIN_DISTANCE_BETWEEN_FILES:
				is_valid = false
				break
		
		if is_valid:
			return candidate
	
	var fallback: Vector2
	for attempt in 10:
		fallback = Vector2(
			randf_range(SPAWN_AREA_MIN.x, SPAWN_AREA_MAX.x),
			randf_range(SPAWN_AREA_MIN.y, SPAWN_AREA_MAX.y)
		)
		if not _is_position_over_trash(fallback):
			return fallback
	
	return fallback


func _is_position_over_trash(pos: Vector2) -> bool:
	var collision: CollisionShape2D = trash_can.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	
	if shape == null:
		return false
	
	var trash_center: Vector2 = trash_can.position + collision.position
	var half_size: Vector2 = shape.size / 2
	
	var min_x: float = trash_center.x - half_size.x - TRASH_SPAWN_MARGIN
	var max_x: float = trash_center.x + half_size.x + TRASH_SPAWN_MARGIN
	var min_y: float = trash_center.y - half_size.y - TRASH_SPAWN_MARGIN
	var max_y: float = trash_center.y + half_size.y + TRASH_SPAWN_MARGIN
	
	return pos.x > min_x and pos.x < max_x and pos.y > min_y and pos.y < max_y


func _spawn_file(spawn_position: Vector2, is_malware: bool) -> void:
	var file_instance: Node2D = FileItemScene.instantiate()
	files_container.add_child(file_instance)
	file_instance.position = spawn_position
	file_instance.setup(is_malware, trash_can)


# ===== Control global de arrastre =====

func try_grab_file() -> bool:
	# Devuelve true si el archivo puede agarrarse, false si ya hay uno agarrado
	if any_file_grabbed:
		return false
	any_file_grabbed = true
	return true


func release_grabbed_file() -> void:
	any_file_grabbed = false
	
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):  # ui_cancel = tecla ESC por defecto
		GameManager.return_to_main_menu()
