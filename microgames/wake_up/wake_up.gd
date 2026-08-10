extends Node2D

# Valores configurables desde el Inspector
@export var energy_per_press: float = 30.0
@export var energy_drain_per_second: float = 60.0
@export var max_energy: float = 500.0

@onready var energy_bar_background: ColorRect = $EnergyBarBackground
@onready var energy_bar_fill: ColorRect = $EnergyBarFill

@onready var hand_pivot: Node2D = $HandPivot
@onready var can_pivot: Node2D = $CanPivot
@onready var head_anim: AnimatedSprite2D = $HeadAnim

const TimerBarScene: PackedScene = preload("res://ui/overlays/timer_bar.tscn")

# Estado
var current_energy: float = 0.0
var has_reached_max: bool = false
var timer_bar: Control = null

# Posiciones originales para volver al estado base
var hand_original_position: Vector2
var can_original_position: Vector2

func _ready() -> void:
	# Ajustar el Fill al ancho y posición del Background automáticamente
	energy_bar_fill.size.x = energy_bar_background.size.x
	energy_bar_fill.position.x = energy_bar_background.position.x
	_update_bar_visual()
	
	# Guardar posiciones originales de mano y lata
	hand_original_position = hand_pivot.position
	can_original_position = can_pivot.position
	
	# Arrancar la animación de cabeza en loop
	head_anim.play("head_nod")
	
	if GameManager.is_in_play_mode:
		_setup_timer_bar()
		
func _setup_timer_bar() -> void:
	timer_bar = TimerBarScene.instantiate()
	# Agregar la barra como hijo de un CanvasLayer para que se vea sobre todo
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(timer_bar)
	timer_bar.time_up.connect(_on_time_up)
	timer_bar.start(GameManager.get_microgame_duration())

func _on_time_up() -> void:
	GameManager.notify_microgame_timed_out()

func _process(delta: float) -> void:
	if current_energy > 0:
		current_energy -= energy_drain_per_second * delta
		current_energy = max(current_energy, 0.0)
		_update_bar_visual()
	
	if has_reached_max and current_energy < max_energy:
		has_reached_max = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("space_bar"):
		print("WAKE UP recibió espacio. has_reached_max: ", has_reached_max)
	
	if has_reached_max:
		return
	
	if event.is_action_pressed("space_bar"):
		_add_energy()
	
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()


func _add_energy() -> void:
	if has_reached_max:
		return
	
	current_energy += energy_per_press
	current_energy = min(current_energy, max_energy)
	_update_bar_visual()
	
	_play_press_animation()
	
	if current_energy >= max_energy and not has_reached_max:
		has_reached_max = true
		print("🎉 ¡Barra llena!")
		# Deshabilitar TODO el procesamiento de input desde ahora
		set_process_input(false)
		set_process_unhandled_input(false)
		set_process(false)
		GameManager.notify_microgame_won()



func _play_press_animation() -> void:
	# Valores aleatorios pequeños para que cada presión se sienta distinta
	var rotation_amount: float = deg_to_rad(randf_range(-8.0, 8.0))
	var shake_offset_x: float = randf_range(-3.0, 3.0)
	var shake_offset_y: float = randf_range(-3.0, 3.0)
	var target_hand_pos: Vector2 = hand_original_position + Vector2(shake_offset_x, shake_offset_y)
	var target_can_pos: Vector2 = can_original_position + Vector2(shake_offset_x * 0.5, shake_offset_y * 0.5)
	
	# === Animar la mano ===
	var hand_tween: Tween = create_tween()
	hand_tween.set_parallel(true)
	# Fase 1: ir al punto exagerado (rotación + posición)
	hand_tween.tween_property(hand_pivot, "rotation", rotation_amount, 0.05)
	hand_tween.tween_property(hand_pivot, "position", target_hand_pos, 0.05)
	# Fase 2: volver al estado original (con delay para que arranque después)
	hand_tween.tween_property(hand_pivot, "rotation", 0.0, 0.08).set_delay(0.05)
	hand_tween.tween_property(hand_pivot, "position", hand_original_position, 0.08).set_delay(0.05)
	
	# === Animar la lata ===
	var can_tween: Tween = create_tween()
	can_tween.set_parallel(true)
	can_tween.tween_property(can_pivot, "rotation", rotation_amount * 0.3, 0.05)
	can_tween.tween_property(can_pivot, "position", target_can_pos, 0.05)
	can_tween.tween_property(can_pivot, "rotation", 0.0, 0.08).set_delay(0.05)
	can_tween.tween_property(can_pivot, "position", can_original_position, 0.08).set_delay(0.05)

func _update_bar_visual() -> void:
	# Calcular el alto del Fill como proporción del alto del Background
	var fill_height: float = (current_energy / max_energy) * energy_bar_background.size.y
	energy_bar_fill.size.y = fill_height
	
	# Posicionar el Fill para que crezca desde abajo
	var bg_bottom: float = energy_bar_background.position.y + energy_bar_background.size.y
	energy_bar_fill.position.y = bg_bottom - fill_height
