extends CharacterBody2D

# Referencias a nodos hijos
@onready var front_face: ColorRect = $FrontFace
@onready var connector: ColorRect = $Connector
@onready var area: Area2D = $Area
@onready var notebook: Node2D = get_parent().get_node("Notebook")

# Constantes
const DRAG_SMOOTHNESS: float = 0.15
const COLOR_FRONT: Color = Color("0066FF")  # azul (cara correcta)
const COLOR_BACK: Color = Color("FF3333")   # rojo (cara incorrecta)

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
var is_connected: bool = false


func _ready() -> void:
	area.input_event.connect(_on_area_input_event)
	randomize_orientation()
	randomize_position()
	update_visuals()


func _process(delta: float) -> void:
	if is_connected:
		return
	if is_grabbed:
		var target_position = get_global_mouse_position() - drag_offset
		var new_position = global_position.lerp(target_position, DRAG_SMOOTHNESS * delta * 60.0)
		var motion = new_position - global_position
		velocity = motion / delta
		move_and_slide()
	else:
		velocity = Vector2.ZERO


func _input(event: InputEvent) -> void:
	if is_connected:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_grabbed = false
	if is_grabbed and event.is_action_pressed("space_bar"):
		flip()


func _on_area_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if is_connected:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			is_grabbed = true
			drag_offset = get_global_mouse_position() - global_position


func randomize_orientation() -> void:
	is_flipped = randi() % 2 == 0
	connector_on_right = not notebook.is_port_on_right()


func randomize_position() -> void:
	var zone: int = randi() % 4
	var new_pos: Vector2 = Vector2.ZERO
	
	match zone:
		0:  # Izquierda del notebook
			new_pos.x = randf_range(SCREEN_MARGIN, NOTEBOOK_CENTER.x - NOTEBOOK_HALF_WIDTH)
			new_pos.y = randf_range(SCREEN_MARGIN, SCREEN_HEIGHT - SCREEN_MARGIN)
		1:  # Derecha del notebook
			new_pos.x = randf_range(NOTEBOOK_CENTER.x + NOTEBOOK_HALF_WIDTH, SCREEN_WIDTH - SCREEN_MARGIN)
			new_pos.y = randf_range(SCREEN_MARGIN, SCREEN_HEIGHT - SCREEN_MARGIN)
		2:  # Arriba del notebook
			new_pos.x = randf_range(SCREEN_MARGIN, SCREEN_WIDTH - SCREEN_MARGIN)
			new_pos.y = randf_range(SCREEN_MARGIN, NOTEBOOK_CENTER.y - NOTEBOOK_HALF_HEIGHT)
		3:  # Abajo del notebook
			new_pos.x = randf_range(SCREEN_MARGIN, SCREEN_WIDTH - SCREEN_MARGIN)
			new_pos.y = randf_range(NOTEBOOK_CENTER.y + NOTEBOOK_HALF_HEIGHT, SCREEN_HEIGHT - SCREEN_MARGIN)
	
	global_position = new_pos


func flip() -> void:
	is_flipped = not is_flipped
	update_visuals()
	check_connection_after_flip()


func check_connection_after_flip() -> void:
	# Si tras rotar la orientación no es correcta, no hay nada que hacer
	if not is_correctly_oriented():
		return
	
	# Obtener el PortArea desde el notebook
	var port_area: Area2D = notebook.get_node("PortArea")
	
	# Verificar si este USB está actualmente dentro del área del puerto
	var overlapping_bodies: Array = port_area.get_overlapping_bodies()
	if self in overlapping_bodies:
		connect_to_port(notebook.get_port_global_position())


func update_visuals() -> void:
	# Actualizar color de la cara
	if is_flipped:
		front_face.color = COLOR_BACK
	else:
		front_face.color = COLOR_FRONT
	
	# Actualizar posición del conector según el lado (fija desde el inicio)
	if connector_on_right:
		connector.position.x = 60
	else:
		connector.position.x = -90


func is_correctly_oriented() -> bool:
	# Cara debe ser azul
	if is_flipped:
		return false
	
	# El conector debe estar en el lado opuesto al puerto del notebook
	var port_is_on_right: bool = notebook.is_port_on_right()
	if port_is_on_right and connector_on_right:
		return false
	if not port_is_on_right and not connector_on_right:
		return false
	
	return true


func connect_to_port(port_global_pos: Vector2) -> void:
	if is_connected:
		return
	is_connected = true
	is_grabbed = false
	
	# Calcular la posición final del USB para que el conector quede centrado en el puerto.
	# El centro del conector está a 75 px del centro del USB (en eje X).
	var target: Vector2 = port_global_pos
	if connector_on_right:
		# Conector a la derecha del USB → el centro del USB queda 75 px a la izquierda del puerto
		target.x -= 75
	else:
		# Conector a la izquierda del USB → el centro del USB queda 75 px a la derecha del puerto
		target.x += 75
	
	# Animar la entrada con una pausa breve seguida de la introducción completa
	var tween = create_tween()
	tween.tween_interval(0.1)
	tween.tween_property(self, "global_position", target, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_connected_complete)


func _on_connected_complete() -> void:
	print("USB conectado correctamente! 🎉")
	GameManager.notify_microgame_won()  
