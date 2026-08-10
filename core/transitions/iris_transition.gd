extends CanvasLayer

# Evita que se encadenen transiciones (ej. spamear click en un botón)
var is_busy: bool = false

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
	if is_busy:
		return
	is_busy = true
	
	if duration < 0:
		duration = default_duration
	
	GameManager.hide_cursor()
	await iris_out(duration)
	get_tree().change_scene_to_file(scene_path)
	await _await_scene_ready(scene_path)
	GameManager.refresh_cursor()
	await iris_in(duration)
	
	is_busy = false


func transition_to_packed_scene(scene: PackedScene, duration: float = -1.0) -> void:
	if is_busy:
		return
	is_busy = true
	
	if duration < 0:
		duration = default_duration
	
	GameManager.hide_cursor()
	await iris_out(duration)
	get_tree().change_scene_to_packed(scene)
	await _await_scene_ready(scene.resource_path)
	GameManager.refresh_cursor()
	await iris_in(duration)
	
	is_busy = false

# Espera a que la escena indicada sea realmente la current_scene.
# El cambio de escena en Godot es diferido, así que leer current_scene
# justo después de change_scene_* puede devolver null o la escena vieja.
func _await_scene_ready(expected_path: String) -> void:
	await get_tree().process_frame
	for attempt in 30:
		var scene: Node = get_tree().current_scene
		if scene != null and scene.scene_file_path == expected_path:
			return
		await get_tree().process_frame

# Función interna que actualiza el shader
func _set_progress(value: float) -> void:
	if overlay.material is ShaderMaterial:
		overlay.material.set_shader_parameter("progress", value)
