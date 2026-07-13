extends Area2D

const DRAG_SMOOTHNESS: float = 0.15
const VARIANTS: Array[String] = ["A", "B", "C"]

var is_malware: bool = false
var variant: String = "A"
var is_being_dragged: bool = false
var drag_offset: Vector2 = Vector2.ZERO
var trash_can_ref: Area2D = null
var has_been_disposed: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var microgame: Node2D = get_tree().current_scene

func _ready() -> void:
	input_pickable = true

func setup(malware: bool, trash_can: Area2D) -> void:
	is_malware = malware
	trash_can_ref = trash_can
	variant = VARIANTS[randi() % VARIANTS.size()]
	_update_animation()

func _update_animation() -> void:
	var suffix: String = "_corrupt" if is_malware else "_good"
	sprite.play(variant + suffix)

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if has_been_disposed:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_start_drag()

func _start_drag() -> void:
	if not microgame.try_grab_file():
		return
	is_being_dragged = true
	drag_offset = position - get_parent().to_local(get_global_mouse_position())
	get_parent().move_child(self, -1)  # traer al frente

func _process(delta: float) -> void:
	if is_being_dragged:
		var target_local: Vector2 = get_parent().to_local(get_global_mouse_position()) + drag_offset
		position = position.lerp(target_local, DRAG_SMOOTHNESS * delta * 60.0)
		if not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
			_end_drag()

func _end_drag() -> void:
	is_being_dragged = false
	microgame.release_grabbed_file()
	if _is_over_trash_can():
		_dispose()

func _is_over_trash_can() -> bool:
	if trash_can_ref == null:
		return false
	return trash_can_ref in get_overlapping_areas()

func _dispose() -> void:
	has_been_disposed = true
	if is_malware:
		if microgame.has_method("on_malware_disposed"):
			microgame.on_malware_disposed()
	else:
		if microgame.has_method("on_innocent_disposed"):
			microgame.on_innocent_disposed()
	
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(queue_free)
