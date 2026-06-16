extends Node2D

@onready var port: ColorRect = $Port
@onready var port_area: Area2D = $PortArea

# Señal que se emite cuando el USB se conecta correctamente
signal usb_connected

# Estado del notebook
var port_on_right: bool = true

# Posiciones del Port (cuadrado azul) según el lado
# El body del notebook mide 300, va de -150 a 150
const PORT_POSITION_RIGHT: Vector2 = Vector2(120, -20)
const PORT_POSITION_LEFT: Vector2 = Vector2(-150, -20)

# Posiciones del PortArea (área de detección del USB) según el lado
# Lo ponemos extendido hacia afuera del notebook para detectar la entrada del USB
const PORT_AREA_POSITION_RIGHT: Vector2 = Vector2(170, 0)
const PORT_AREA_POSITION_LEFT: Vector2 = Vector2(-170, 0)


func _ready() -> void:
	randomize_port_side()
	update_port_position()
	port_area.body_entered.connect(_on_port_area_body_entered)


func randomize_port_side() -> void:
	port_on_right = randi() % 2 == 0


func update_port_position() -> void:
	if port_on_right:
		port.position = PORT_POSITION_RIGHT
		port_area.position = PORT_AREA_POSITION_RIGHT
	else:
		port.position = PORT_POSITION_LEFT
		port_area.position = PORT_AREA_POSITION_LEFT


# Función pública para que el USB consulte el lado del puerto
func is_port_on_right() -> bool:
	return port_on_right


# Devuelve la posición global del CENTRO del Port (cuadrado azul)
func get_port_global_position() -> Vector2:
	return port.global_position + port.size / 2


# Se llama cuando un cuerpo físico entra en el área del puerto
func _on_port_area_body_entered(body: Node2D) -> void:
	# Verificar si es un USB bien orientado
	if body.has_method("is_correctly_oriented") and body.is_correctly_oriented():
		body.connect_to_port(get_port_global_position())
		usb_connected.emit()
