extends Node2D

const FILE_COUNT_GOOD: int = 3
const FILE_COUNT_BAD: int = 3
const MIN_DISTANCE_BETWEEN_FILES: float = 60.0

const FileScene: PackedScene = preload("res://microgames/delete/file.tscn")
const TimerBarScene: PackedScene = preload("res://menus/timer_bar.tscn")

@onready var trash_can: Area2D = $TrashCan
@onready var files_container: Node2D = $FilesContainer
@onready var playable_area: Area2D = $PlayableArea
@onready var exclusion_zone: Area2D = $ExclusionZone

var any_file_grabbed: bool = false
var timer_bar: Control = null
var malware_remaining: int = 0
var has_finished: bool = false
var file_half_size: Vector2 = Vector2(20, 20)

func _ready() -> void:
	randomize()
	_measure_file_size()
	_spawn_files()
	if GameManager.is_in_play_mode:
		_setup_timer_bar()

func _measure_file_size() -> void:
	var probe: Node2D = FileScene.instantiate()
	var collision: CollisionShape2D = probe.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	if shape != null:
		file_half_size = (shape.size * probe.scale) / 2
	probe.queue_free()

func _setup_timer_bar() -> void:
	timer_bar = TimerBarScene.instantiate()
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(timer_bar)
	timer_bar.time_up.connect(_on_time_up)
	timer_bar.start(GameManager.get_microgame_duration())

func _on_time_up() -> void:
	if has_finished:
		return
	has_finished = true
	GameManager.notify_microgame_timed_out()

func get_playable_rect() -> Rect2:
	var collision: CollisionShape2D = playable_area.get_node("CollisionShape2D")
	var shape: RectangleShape2D = collision.shape as RectangleShape2D
	var center: Vector2 = playable_area.position + collision.position
	return Rect2(center - shape.size / 2, shape.size)

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
	malware_remaining = FILE_COUNT_BAD

func _get_valid_spawn_position(existing: Array[Vector2]) -> Vector2:
	var rect: Rect2 = get_playable_rect()
	rect = Rect2(rect.position + file_half_size, rect.size - file_half_size * 2)
	
	for attempt in 30:
		var candidate: Vector2 = Vector2(
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		if _is_position_in_area(candidate, exclusion_zone):
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
			randf_range(rect.position.x, rect.end.x),
			randf_range(rect.position.y, rect.end.y)
		)
		if not _is_position_in_area(fallback, exclusion_zone):
			return fallback
	return fallback

func _is_position_in_area(pos: Vector2, area: Area2D) -> bool:
	for child in area.get_children():
		if child is CollisionShape2D:
			var shape: RectangleShape2D = child.shape as RectangleShape2D
			if shape == null:
				continue
			var center: Vector2 = area.position + child.position
			var half_size: Vector2 = (shape.size * area.scale) / 2
			var min_x: float = center.x - half_size.x - file_half_size.x
			var max_x: float = center.x + half_size.x + file_half_size.x
			var min_y: float = center.y - half_size.y - file_half_size.y
			var max_y: float = center.y + half_size.y + file_half_size.y
			if pos.x > min_x and pos.x < max_x and pos.y > min_y and pos.y < max_y:
				return true
	return false

func _spawn_file(spawn_position: Vector2, is_malware: bool) -> void:
	var file_instance: Node2D = FileScene.instantiate()
	files_container.add_child(file_instance)
	file_instance.position = spawn_position
	file_instance.setup(is_malware, trash_can)

func try_grab_file() -> bool:
	if has_finished:
		return false
	if any_file_grabbed:
		return false
	any_file_grabbed = true
	return true

func release_grabbed_file() -> void:
	any_file_grabbed = false

func _unhandled_input(event: InputEvent) -> void:
	if has_finished:
		return
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()

func on_malware_disposed() -> void:
	if has_finished:
		return
	malware_remaining -= 1
	if malware_remaining <= 0:
		_on_win()

func on_innocent_disposed() -> void:
	if has_finished:
		return
	_on_lose()

func _on_win() -> void:
	has_finished = true
	if timer_bar != null:
		timer_bar.stop()
	GameManager.notify_microgame_won()

func _on_lose() -> void:
	has_finished = true
	if timer_bar != null:
		timer_bar.stop()
	GameManager.notify_microgame_lost()
