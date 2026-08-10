extends Control

signal time_up

@onready var fill: ColorRect = $Fill

var duration: float = 5.0
var time_remaining: float = 5.0
var is_running: bool = false


func _ready() -> void:
	# Asegurar que la barra empieza llena
	_update_visual()


func start(time_seconds: float) -> void:
	duration = time_seconds
	time_remaining = time_seconds
	is_running = true
	_update_visual()


func stop() -> void:
	is_running = false


func _process(delta: float) -> void:
	if not is_running:
		return
	
	time_remaining -= delta
	
	if time_remaining <= 0:
		time_remaining = 0
		is_running = false
		_update_visual()
		time_up.emit()
	else:
		_update_visual()


func _update_visual() -> void:
	# La barra se reduce de derecha a izquierda
	var progress: float = time_remaining / duration
	fill.size.x = size.x * progress
	
	# Cambiar color según el tiempo restante (opcional, queda bonito)
	if progress > 0.5:
		fill.color = Color("#4CAF50")  # verde
	elif progress > 0.25:
		fill.color = Color("#FFC107")  # amarillo
	else:
		fill.color = Color("#F44336")  # rojo
