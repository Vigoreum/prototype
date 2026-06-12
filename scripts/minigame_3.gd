extends Node2D

# --- Configuration ---
const FILE_COUNT_GOOD: int = 3
const FILE_COUNT_BAD: int = 3
const SPAWN_AREA_MIN: Vector2 = Vector2(80, 100)
const SPAWN_AREA_MAX: Vector2 = Vector2(900, 480)
const MIN_DISTANCE_BETWEEN_FILES: float = 110.0

# --- Node references ---
@onready var trash_can: Area2D = $TrashCan
@onready var files_container: Node2D = $FilesContainer

const FileItemScene: PackedScene = preload("res://scenes/file_item.tscn")


func _ready() -> void:
	randomize()
	_spawn_files()


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
		var is_valid: bool = true
		for pos in existing:
			if candidate.distance_to(pos) < MIN_DISTANCE_BETWEEN_FILES:
				is_valid = false
				break
		if is_valid:
			return candidate
	return Vector2(
		randf_range(SPAWN_AREA_MIN.x, SPAWN_AREA_MAX.x),
		randf_range(SPAWN_AREA_MIN.y, SPAWN_AREA_MAX.y)
	)


func _spawn_file(spawn_position: Vector2, is_malware: bool) -> void:
	var file_instance: Node2D = FileItemScene.instantiate()
	files_container.add_child(file_instance)
	file_instance.position = spawn_position
	file_instance.setup(is_malware, trash_can)
