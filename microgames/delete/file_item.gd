extends Area2D

@warning_ignore("unused_signal")
signal dropped_in_trash(was_malware: bool)

const DRAG_SMOOTHNESS: float = 0.15

var is_malware: bool = false
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var trash_can_ref: Area2D = null
var has_been_disposed: bool = false

@onready var visual: ColorRect = $Visual
@onready var icon: Label = $Icon
@onready var microgame: Node2D = get_tree().current_scene


func _ready() -> void:
	print("FileItem ready at position: ", position)
	input_pickable = true


func setup(malware: bool, trash_can: Area2D) -> void:
	is_malware = malware
	trash_can_ref = trash_can
	_update_appearance()


func _update_appearance() -> void:
	if is_malware:
		visual.color = Color(0.9, 0.25, 0.25)
		icon.text = "💀"
	else:
		visual.color = Color(0.35, 0.55, 0.9)
		icon.text = "📄"


func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if has_been_disposed:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("CLICK DETECTED on file (malware: ", is_malware, ")")
			_start_drag()


func _start_drag() -> void:
	if not microgame.try_grab_file():
		print("Otro archivo ya está siendo arrastrado, ignorando clic")
		return
	
	is_being_dragged = true
	drag_offset = global_position - get_global_mouse_position()
	get_parent().move_child(self, -1)
	print("Drag started. Offset: ", drag_offset)


func _process(delta: float) -> void:
	if is_being_dragged:
		var target_position: Vector2 = get_global_mouse_position() + drag_offset
		global_position = global_position.lerp(target_position, DRAG_SMOOTHNESS * delta * 60.0)
		
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			print("Mouse released, ending drag")
			_end_drag()


func _end_drag() -> void:
	is_being_dragged = false
	microgame.release_grabbed_file()
	print("Drag ended. Over trash: ", _is_over_trash_can())
	if _is_over_trash_can():
		_dispose()


func _is_over_trash_can() -> bool:
	if not trash_can_ref:
		print("No trash_can_ref!")
		return false
	var overlapping_areas: Array[Area2D] = get_overlapping_areas()
	print("Overlapping areas: ", overlapping_areas)
	return trash_can_ref in overlapping_areas


func _dispose() -> void:
	has_been_disposed = true
	
	# Avisar al microjuego según el tipo de archivo
	var microgame = get_tree().current_scene
	if is_malware:
		print("Malware deleted ✓")
		if microgame.has_method("on_malware_disposed"):
			microgame.on_malware_disposed()
	else:
		print("Important file deleted ✗")
		if microgame.has_method("on_innocent_disposed"):
			microgame.on_innocent_disposed()
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
