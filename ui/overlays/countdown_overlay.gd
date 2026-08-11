extends CanvasLayer

# Duración de cada número del countdown (configurable desde Inspector)
@export var time_per_number: float = 0.8

@onready var background: ColorRect = $Background
@onready var number_label: Label = $NumberLabel

# Señal emitida cuando el countdown termina (haya terminado o se haya cancelado)
signal countdown_finished

var _is_counting: bool = false
var _cancelled: bool = false


func _ready() -> void:
	# Debe funcionar aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Arrancar oculto
	hide_overlay()


# Inicia el countdown desde el número indicado (3 por defecto, baja hasta 1)
func start_countdown(starting_number: int = 3) -> void:
	_is_counting = true
	_cancelled = false
	show_overlay()

	for n in range(starting_number, 0, -1):
		number_label.text = str(n)
		# Timer que NO se pausa (queremos que corra siempre cuando esté visible)
		await get_tree().create_timer(time_per_number, true).timeout
		if _cancelled:
			break

	_is_counting = false
	hide_overlay()
	# Se emite también al cancelar, para que quien esté esperando no quede colgado
	countdown_finished.emit()


# Corta el countdown en curso (ej: se volvió a pausar por perder el foco)
func cancel_countdown() -> void:
	if _is_counting:
		_cancelled = true


func is_counting() -> bool:
	return _is_counting


func show_overlay() -> void:
	background.visible = true
	number_label.visible = true


func hide_overlay() -> void:
	background.visible = false
	number_label.visible = false
