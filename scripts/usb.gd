extends Node2D

# Referencias a nodos hijos
@onready var front_face: ColorRect = $FrontFace
@onready var connector: ColorRect = $Connector
@onready var area: Area2D = $Area
@onready var notebook: Node2D = get_parent().get_node("Notebook")

# Constantes
const DRAG_SMOOTHNESS: float = 0.15
const COLOR_FRONT: Color = Color("0066FF")
const COLOR_BACK: Color = Color("FF3333")

# Constantes para la posición inicial aleatoria
const SCREEN_WIDTH: float = 1152.0
const SCREEN_HEIGHT: float = 648.0
const NOTEBOOK_CENTER: Vector2 = Vector2(576, 324)
const NOTEBOOK_HALF_WIDTH: float = 200.0
const NOTEBOOK_HALF_HEIGHT: float = 150.0
const SCREEN_MARGIN: float = 80.0

# Estado del USB
var is_grabbed: bool = false
var is_flipped: bool = false
var connector_on_right: bool = true
var drag_offset: Vector2 = Vector2.ZERO


func _ready() -> void:
	area.input_event.connect(_on_area_input_event)
	randomize_orientation()
	randomize_position()
	update_visuals()


func _process(delta: float) -> void:
	if is_grabbed:
		var target_position = get_global_mouse_position() - drag_offset
		global_position = global_position.lerp(target_position, DRAG_SMOOTHNESS * delta * 60.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_grabbed = false
	
	if is_grabbed and event.is_action_pressed("space_bar"):
		flip()


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_grabbed = true
			drag_offset = get_global_mouse_position() - global_position


func randomize_orientation() -> void:
	is_flipped = randi() % 2 == 0
	# Conector siempre en el lado opuesto al puerto del notebook
	connector_on_right = not notebook.is_port_on_right()


func randomize_position() -> void:
	var zone: int = randi() % 4
	var new_pos: Vector2 = Vector2.ZERO
	
	match zone:
		0:
			new_pos.x = randf_range(SCREEN_MARGIN, NOTEBOOK_CENTER.x - NOTEBOOK_HALF_WIDTH)
			new_pos.y = randf_range(SCREEN_MARGIN, SCREEN_HEIGHT - SCREEN_MARGIN)
		1:
			new_pos.x = randf_range(NOTEBOOK_CENTER.x + NOTEBOOK_HALF_WIDTH, SCREEN_WIDTH - SCREEN_MARGIN)
			new_pos.y = randf_range(SCREEN_MARGIN, SCREEN_HEIGHT - SCREEN_MARGIN)
		2:
			new_pos.x = randf_range(SCREEN_MARGIN, SCREEN_WIDTH - SCREEN_MARGIN)
			new_pos.y = randf_range(SCREEN_MARGIN, NOTEBOOK_CENTER.y - NOTEBOOK_HALF_HEIGHT)
		3:
			new_pos.x = randf_range(SCREEN_MARGIN, SCREEN_WIDTH - SCREEN_MARGIN)
			new_pos.y = randf_range(NOTEBOOK_CENTER.y + NOTEBOOK_HALF_HEIGHT, SCREEN_HEIGHT - SCREEN_MARGIN)
	
	global_position = new_pos


func flip() -> void:
	is_flipped = not is_flipped
	update_visuals()


func update_visuals() -> void:
	if is_flipped:
		front_face.color = COLOR_BACK
	else:
		front_face.color = COLOR_FRONT
	
	if connector_on_right:
		connector.position.x = 60
	else:
		connector.position.x = -90
