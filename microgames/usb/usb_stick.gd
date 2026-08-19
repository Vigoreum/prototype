extends CharacterBody2D

# Referencias a nodos hijos
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var area: Area2D = $Area
@onready var body_collision: CollisionShape2D = $BodyCollision
@onready var connector_collision: CollisionShape2D = $ConnectorCollision
@onready var laptop: Node2D = get_parent().get_node("Laptop")

# Nombres de las animaciones del SpriteFrames.
# Las estáticas son de un solo frame y loopean; las de giro no loopean, así
# que al terminar emiten animation_finished y volvemos a la cara que toca
const ANIM_FRONT: StringName = &"front"
const ANIM_BACK: StringName = &"back"
const ANIM_FLIP_TO_BACK: StringName = &"flip_to_back"
const ANIM_FLIP_TO_FRONT: StringName = &"flip_to_front"

# Constantes
const DRAG_SMOOTHNESS: float = 0.15

# Geometría del sprite, medida sobre la spritesheet y relativa a su centro.
# El cuerpo va de -48 a 28 en x; el conector sobresale de 29 a 48
const BODY_SIZE: Vector2 = Vector2(76, 36)
const BODY_CENTER_X: float = -10.0
const CONNECTOR_SIZE: Vector2 = Vector2(20, 24)
const CONNECTOR_CENTER_X: float = 38.5
const CONNECTOR_TIP: float = 48.0
# Distancia del centro del USB a la cara del cuerpo por donde sale el
# conector. Es el borde de BodyCollision, que es donde la laptop lo frena: el
# asentado final tiene que caer justo ahí. El collar metálico (la columna 28,
# de 32 de alto) queda del lado de adentro y lo tapa la laptop
const BODY_FRONT: float = 28.0
# El dibujo no está centrado en vertical por medio pixel
const SPRITE_CENTER_Y: float = 0.5

# Tiempo del acomodado final una vez que la ranura lo dio por insertado
const SEAT_DURATION: float = 0.12

# Zona jugable en pixeles de pantalla. La barra de tiempo tapa los últimos 40
const SCREEN_WIDTH: float = 640.0
const PLAYABLE_HEIGHT: float = 320.0
const SCREEN_MARGIN: float = 4.0
const SPAWN_CLEARANCE: float = 4.0
const LAPTOP_CENTER: Vector2 = Vector2(320, 160)
const LAPTOP_HALF_WIDTH: float = 139.5

# Estado del USB
var is_grabbed: bool = false
var is_flipped: bool = false
var connector_on_right: bool = true
var drag_offset: Vector2 = Vector2.ZERO
var is_connected: bool = false


func _ready() -> void:
	area.input_event.connect(_on_area_input_event)
	sprite.animation_finished.connect(_on_flip_animation_finished)
	randomize_orientation()
	randomize_position()
	update_visuals()


func _process(delta: float) -> void:
	if is_connected:
		return
	if is_grabbed:
		var target_position: Vector2 = get_global_mouse_position() - drag_offset
		var new_position: Vector2 = global_position.lerp(target_position, DRAG_SMOOTHNESS * delta * 60.0)
		var motion: Vector2 = new_position - global_position
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


# La cara arranca al azar (es lo único que el jugador puede corregir); el lado
# del conector se fija hacia la laptop, porque la barra espaciadora no lo gira
func randomize_orientation() -> void:
	is_flipped = randi() % 2 == 0
	connector_on_right = not laptop.is_port_on_right()


func randomize_position() -> void:
	# El USB nace SIEMPRE del lado del logo. Su conector ya apunta a la laptop,
	# así que el jugador sólo tiene que acercarlo y, si hace falta, girarlo;
	# no hay que rodear la laptop con el conector mirando para afuera.
	# La altura sigue siendo libre, que es de donde sale la variedad.
	# Se ubica por su CENTRO, así que los márgenes y la caja de la laptop se
	# agrandan con su media extensión: si no, nace pisando la laptop o
	# asomándose fuera de la pantalla
	var half: Vector2 = Vector2(CONNECTOR_TIP, BODY_SIZE.y / 2.0)
	var min_x: float = SCREEN_MARGIN + half.x
	var max_x: float = SCREEN_WIDTH - SCREEN_MARGIN - half.x
	var min_y: float = SCREEN_MARGIN + half.y
	var max_y: float = PLAYABLE_HEIGHT - SCREEN_MARGIN - half.y
	var keep_x: float = LAPTOP_HALF_WIDTH + half.x + SPAWN_CLEARANCE

	var new_pos: Vector2 = Vector2.ZERO
	if laptop.is_port_on_right():
		new_pos.x = randf_range(LAPTOP_CENTER.x + keep_x, max_x)
	else:
		new_pos.x = randf_range(min_x, LAPTOP_CENTER.x - keep_x)
	new_pos.y = randf_range(min_y, max_y)

	position = new_pos


func flip() -> void:
	is_flipped = not is_flipped
	# El estado cambia al instante; la animación de giro es sólo visual
	sprite.play(ANIM_FLIP_TO_BACK if is_flipped else ANIM_FLIP_TO_FRONT)
	_update_slot_block()


# El sprite está dibujado con el conector a la derecha, así que el lado
# izquierdo es el mismo dibujo espejado, y las colisiones se espejan con él
func _apply_connector_side() -> void:
	var dir: float = 1.0 if connector_on_right else -1.0
	sprite.flip_h = not connector_on_right
	body_collision.position = Vector2(BODY_CENTER_X * dir, SPRITE_CENTER_Y)
	connector_collision.position = Vector2(CONNECTOR_CENTER_X * dir, SPRITE_CENTER_Y)


func update_visuals() -> void:
	_apply_connector_side()
	sprite.play(ANIM_BACK if is_flipped else ANIM_FRONT)
	_update_slot_block()


func _on_flip_animation_finished() -> void:
	# Sólo las de giro terminan (las estáticas loopean), así que al llegar acá
	# el giro se completó y toca dejar quieta la cara correspondiente
	sprite.play(ANIM_BACK if is_flipped else ANIM_FRONT)


# La ranura se destapa cuando la cara coincide con el logo. Si el conector ya
# está metido no se vuelve a tapar, para no expulsarlo al girar el USB
func _update_slot_block() -> void:
	if is_connected:
		return
	var should_block: bool = not is_correctly_oriented() and not _is_connector_in_slot()
	laptop.set_slot_blocked(should_block)


func _is_connector_in_slot() -> bool:
	var port: Vector2 = laptop.get_port_global_position()
	if absf(global_position.y - port.y) > laptop.get_slot_half_height():
		return false
	var tip_x: float = global_position.x + (CONNECTOR_TIP if connector_on_right else -CONNECTOR_TIP)
	if laptop.is_port_on_right():
		return tip_x < port.x
	return tip_x > port.x


# La cara visible tiene que ser del mismo color que el logo del puerto
func is_correctly_oriented() -> bool:
	var face_is_blue: bool = not is_flipped
	if face_is_blue != laptop.is_port_blue():
		return false

	# El conector debe apuntar hacia la laptop
	return connector_on_right != laptop.is_port_on_right()


# Lo llama la laptop cuando el conector llegó al fondo de la ranura. Sólo
# acomoda los últimos pixeles: el USB ya entró empujado por el jugador
func seat_in_port(port_global_pos: Vector2, port_on_right: bool) -> void:
	if is_connected:
		return
	is_connected = true
	is_grabbed = false

	# Queda apoyado con la cara del cuerpo contra el borde de la laptop
	var target: Vector2 = Vector2(
		port_global_pos.x + (BODY_FRONT if port_on_right else -BODY_FRONT),
		port_global_pos.y - SPRITE_CENTER_Y
	)

	var tween: Tween = create_tween()
	tween.tween_property(self, "global_position", target, SEAT_DURATION).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_callback(_on_connected_complete)


func _on_connected_complete() -> void:
	GameManager.notify_microgame_won()
