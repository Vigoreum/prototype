extends Node2D

# La laptop es un rectángulo sólido con una RANURA abierta en uno de sus
# cuatro puertos. El conector del USB (20x24) entra por ahí; su cuerpo (36 de
# alto) no, así que el USB frena justo cuando el conector quedó todo adentro.
# Si la cara del USB no coincide con el color del logo, PortBlocker tapa la
# ranura y el USB rebota contra el costado.

# Rectángulo de la laptop en coordenadas locales (el sprite mide 279x202)
const LEFT_EDGE: float = -139.0
const RIGHT_EDGE: float = 140.0
const TOP_EDGE: float = -101.0
const BOTTOM_EDGE: float = 101.0

# Ranura del puerto. 30 de alto deja 3 de juego arriba y abajo del conector
# (24) sin que llegue a pasar el cuerpo del USB (36)
const SLOT_DEPTH: float = 22.0
const SLOT_HALF_HEIGHT: float = 15.0

# Profundidad a la que se da por insertado (el conector entra 20)
const DETECT_DEPTH: float = 16.0
const DETECT_HALF_HEIGHT: float = 10.0

# Alturas de los dos puertos de cada lado
const PORT_OFFSETS_Y: Array[float] = [-45.0, 45.0]

# Logo del puerto: 11x21 en la spritesheet. Va a la altura del puerto y unos
# pixeles adentro del borde, o sea justo sobre el conector enchufado. Se lo ve
# porque la laptop se dibuja por encima del USB (z_index), que es lo mismo que
# esconde el conector cuando entra
const LOGO_SIZE: Vector2 = Vector2(11, 21)
const LOGO_INSET: float = 6.0

# Rayo de luz que sale del puerto hacia afuera para marcar dónde enchufar.
# La forma y el degradado están en la escena (Polygon2D con vertex_colors y
# material aditivo); acá sólo se lo ubica y se lo hace latir
const GLOW_PULSE_MIN: float = 0.5
const GLOW_PULSE_MAX: float = 1.0
const GLOW_PULSE_TIME: float = 0.9
const GLOW_FADE_TIME: float = 0.15

@onready var port_glow: Polygon2D = $PortGlow
@onready var port_logo_blue: Sprite2D = $PortLogoBlue
@onready var port_logo_red: Sprite2D = $PortLogoRed
@onready var wall_top: CollisionShape2D = $Solid/WallTop
@onready var wall_bottom: CollisionShape2D = $Solid/WallBottom
@onready var wall_back: CollisionShape2D = $Solid/WallBack
@onready var port_blocker: CollisionShape2D = $Solid/PortBlocker
@onready var port_detector: Area2D = $PortDetector
@onready var port_detector_shape: CollisionShape2D = $PortDetector/CollisionShape2D

# Estado del puerto elegido para esta partida
var port_on_right: bool = true
var port_offset_y: float = 0.0
var port_is_blue: bool = true

var glow_tween: Tween = null


func _ready() -> void:
	randomize_port()
	_apply_port()
	_start_glow_pulse()
	port_detector.body_entered.connect(_on_port_detector_body_entered)


# Uno de los cuatro puertos (dos por lado) y uno de los dos colores
func randomize_port() -> void:
	port_on_right = randi() % 2 == 0
	port_offset_y = PORT_OFFSETS_Y[randi() % PORT_OFFSETS_Y.size()]
	port_is_blue = randi() % 2 == 0


func _apply_port() -> void:
	var edge_x: float = RIGHT_EDGE if port_on_right else LEFT_EDGE
	var dir: float = 1.0 if port_on_right else -1.0
	# Fondo de la ranura, hacia adentro de la laptop
	var inner_x: float = edge_x - SLOT_DEPTH * dir
	var slot_top: float = port_offset_y - SLOT_HALF_HEIGHT
	var slot_height: float = SLOT_HALF_HEIGHT * 2.0
	var slot_bottom: float = port_offset_y + SLOT_HALF_HEIGHT
	var width: float = RIGHT_EDGE - LEFT_EDGE

	# La laptop entera, menos la franja de la ranura
	_set_rect(wall_top, Rect2(LEFT_EDGE, TOP_EDGE, width, slot_top - TOP_EDGE))
	_set_rect(wall_bottom, Rect2(LEFT_EDGE, slot_bottom, width, BOTTOM_EDGE - slot_bottom))

	# A la altura de la ranura sólo queda pared del lado opuesto
	var back_left: float = LEFT_EDGE if port_on_right else inner_x
	var back_width: float = (inner_x - LEFT_EDGE) if port_on_right else (RIGHT_EDGE - inner_x)
	_set_rect(wall_back, Rect2(back_left, slot_top, back_width, slot_height))

	# Tapón que se saca sólo cuando el USB está bien orientado
	var slot_left: float = inner_x if port_on_right else edge_x
	_set_rect(port_blocker, Rect2(slot_left, slot_top, SLOT_DEPTH, slot_height))
	port_blocker.disabled = false

	# Detector al fondo de la ranura: sólo lo alcanza el conector
	var detect_width: float = SLOT_DEPTH - DETECT_DEPTH
	var detect_left: float = inner_x if port_on_right else inner_x - detect_width
	_set_rect(port_detector_shape, Rect2(
		detect_left,
		port_offset_y - DETECT_HALF_HEIGHT,
		detect_width,
		DETECT_HALF_HEIGHT * 2.0
	))

	_place_logo()

	# El rayo nace en la boca de la ranura y apunta para afuera. El polígono
	# está dibujado hacia +x, así que del lado izquierdo se lo espeja
	port_glow.position = Vector2(edge_x, port_offset_y)
	port_glow.scale = Vector2(dir, 1.0)


# Late despacio para llamar la atención sin molestar. El tween se pausa solo
# cuando se pausa el juego, porque el nodo no es PROCESS_MODE_ALWAYS
func _start_glow_pulse() -> void:
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(port_glow, "modulate:a", GLOW_PULSE_MIN, GLOW_PULSE_TIME) \
		.set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(port_glow, "modulate:a", GLOW_PULSE_MAX, GLOW_PULSE_TIME) \
		.set_trans(Tween.TRANS_SINE)


# Ya no hay nada que guiar una vez que el USB entró
func _fade_out_glow() -> void:
	if glow_tween != null and glow_tween.is_valid():
		glow_tween.kill()
	var tween: Tween = create_tween()
	tween.tween_property(port_glow, "modulate:a", 0.0, GLOW_FADE_TIME)


# La ranura no se dibuja: el logo es la única pista de dónde está. Va a la
# altura del puerto, tapando el lugar por donde va a entrar el conector
func _place_logo() -> void:
	var edge_x: float = RIGHT_EDGE if port_on_right else LEFT_EDGE
	# El sprite se posiciona por su esquina, así que del lado derecho hay que
	# restarle el ancho para que quede metido hacia adentro
	var logo_x: float = edge_x - LOGO_INSET - LOGO_SIZE.x if port_on_right else edge_x + LOGO_INSET

	var logo_pos: Vector2 = Vector2(
		logo_x,
		port_offset_y - floorf(LOGO_SIZE.y / 2.0)
	)

	port_logo_blue.position = logo_pos
	port_logo_red.position = logo_pos
	port_logo_blue.visible = port_is_blue
	port_logo_red.visible = not port_is_blue


func _set_rect(shape_node: CollisionShape2D, rect: Rect2) -> void:
	var box: RectangleShape2D = RectangleShape2D.new()
	box.size = rect.size
	shape_node.shape = box
	shape_node.position = rect.position + rect.size / 2.0


# ===== API para el USB =====

func is_port_on_right() -> bool:
	return port_on_right


func is_port_blue() -> bool:
	return port_is_blue


func get_slot_half_height() -> float:
	return SLOT_HALF_HEIGHT


# Centro de la BOCA de la ranura, sobre el borde de la laptop
func get_port_global_position() -> Vector2:
	var edge_x: float = RIGHT_EDGE if port_on_right else LEFT_EDGE
	return to_global(Vector2(edge_x, port_offset_y))


# El tapón se saca cuando el USB puede entrar; nunca se vuelve a poner si el
# conector ya está adentro, para no empujarlo hacia afuera al girarlo
func set_slot_blocked(blocked: bool) -> void:
	port_blocker.set_deferred(&"disabled", not blocked)


func _on_port_detector_body_entered(body: Node2D) -> void:
	if not body.has_method("is_correctly_oriented"):
		return
	if not body.is_correctly_oriented():
		return
	body.seat_in_port(get_port_global_position(), port_on_right)
	_fade_out_glow()
