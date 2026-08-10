extends CanvasLayer

# Duración de cada número del countdown (configurable desde Inspector)
@export var time_per_number: float = 0.8

@onready var background: ColorRect = $Background
@onready var number_label: Label = $NumberLabel

# Señal emitida cuando el countdown termina
signal countdown_finished


func _ready() -> void:
	# Debe funcionar aunque el juego esté pausado
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Arrancar oculto
	hide_overlay()


# Inicia el countdown desde el número indicado (3 por defecto, baja hasta 1)
func start_countdown(starting_number: int = 3) -> void:
	show_overlay()
	
	for n in range(starting_number, 0, -1):
		number_label.text = str(n)
		# Timer que NO se pausa (queremos que corra siempre cuando esté visible)
		await get_tree().create_timer(time_per_number, true).timeout
	
	hide_overlay()
	countdown_finished.emit()


func show_overlay() -> void:
	background.visible = true
	number_label.visible = true


func hide_overlay() -> void:
	background.visible = false
	number_label.visible = false
