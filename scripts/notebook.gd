extends Node2D

@onready var port: ColorRect = $Port

# true = puerto a la derecha del notebook, false = a la izquierda
var port_on_right: bool = true

# Posiciones del puerto según el lado
# El body del notebook va de x = -150 a x = 150 (ancho 300, centrado)
# El port mide 30 px de ancho y 40 px de alto
const PORT_POSITION_RIGHT: Vector2 = Vector2(120, -20)
const PORT_POSITION_LEFT: Vector2 = Vector2(-150, -20)


func _ready() -> void:
	randomize_port_side()
	update_port_position()


func randomize_port_side() -> void:
	port_on_right = randi() % 2 == 0


func update_port_position() -> void:
	if port_on_right:
		port.position = PORT_POSITION_RIGHT
	else:
		port.position = PORT_POSITION_LEFT


# Función pública para que el USB consulte si está bien orientado
func is_port_on_right() -> bool:
	return port_on_right


# Función pública para obtener la posición global del puerto (para detección de proximidad)
func get_port_global_position() -> Vector2:
	return port.global_position + port.size / 2
