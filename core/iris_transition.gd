extends CanvasLayer

# DURACIÓN POR DEFECTO (modificable desde el Inspector)
@export var default_duration: float = 0.4

@onready var overlay: ColorRect = $Overlay

# Señal que se emite cuando una transición termina
signal transition_finished


func _ready() -> void:
	# Empezar oculto (pantalla descubierta)
	_set_progress(1.0)


# Cubre la pantalla con el círculo (efecto "iris-out", el círculo se cierra)
func iris_out(duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration
	
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 1.0, 0.0, duration)
	await tween.finished
	transition_finished.emit()


# Descubre la pantalla (efecto "iris-in", el círculo se abre)
func iris_in(duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration
	
	var tween: Tween = create_tween()
	tween.tween_method(_set_progress, 0.0, 1.0, duration)
	await tween.finished
	transition_finished.emit()


# Cambia de escena con transición iris completa (out → cambio → in)
func transition_to_scene(scene_path: String, duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration
	
	# Fase 1: cubrir pantalla
	await iris_out(duration)
	
	# Fase 2: cambiar de escena (mientras está cubierto)
	get_tree().change_scene_to_file(scene_path)
	
	# Pequeña espera para que la nueva escena se cargue
	await get_tree().process_frame
	
	# Fase 3: descubrir pantalla
	await iris_in(duration)


# Versión que recibe PackedScene en vez de path
func transition_to_packed_scene(scene: PackedScene, duration: float = -1.0) -> void:
	if duration < 0:
		duration = default_duration
	
	await iris_out(duration)
	get_tree().change_scene_to_packed(scene)
	await get_tree().process_frame
	await iris_in(duration)


# Función interna que actualiza el shader
func _set_progress(value: float) -> void:
	if overlay.material is ShaderMaterial:
		overlay.material.set_shader_parameter("progress", value)
