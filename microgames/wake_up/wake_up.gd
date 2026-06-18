extends Node2D

# Valores configurables desde el Inspector
@export var energy_per_press: float = 30.0
@export var energy_drain_per_second: float = 60.0
@export var max_energy: float = 500.0   # ahora también configurable

@onready var energy_bar_background: ColorRect = $EnergyBarBackground
@onready var energy_bar_fill: ColorRect = $EnergyBarFill

# Estado
var current_energy: float = 0.0
var has_reached_max: bool = false


func _ready() -> void:
	# Ajustar el Fill al ancho y posición del Background automáticamente
	energy_bar_fill.size.x = energy_bar_background.size.x
	energy_bar_fill.position.x = energy_bar_background.position.x
	_update_bar_visual()


func _process(delta: float) -> void:
	if current_energy > 0:
		current_energy -= energy_drain_per_second * delta
		current_energy = max(current_energy, 0.0)
		_update_bar_visual()
	
	if has_reached_max and current_energy < max_energy:
		has_reached_max = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("space_bar"):
		_add_energy()
	
	if event.is_action_pressed("ui_cancel"):
		GameManager.return_to_main_menu()


func _add_energy() -> void:
	current_energy += energy_per_press
	current_energy = min(current_energy, max_energy)
	_update_bar_visual()
	
	if current_energy >= max_energy and not has_reached_max:
		has_reached_max = true
		print("¡Barra de energía llena! ⚡")


func _update_bar_visual() -> void:
	# Calcular el alto del Fill como proporción del alto del Background
	var fill_height: float = (current_energy / max_energy) * energy_bar_background.size.y
	energy_bar_fill.size.y = fill_height
	
	# Posicionar el Fill para que crezca desde abajo
	var bg_bottom: float = energy_bar_background.position.y + energy_bar_background.size.y
	energy_bar_fill.position.y = bg_bottom - fill_height
