extends Control

@onready var title_label: Label = $Title
@onready var controls_container: HBoxContainer = $ControlsContainer

# Duración total que se muestra la pantalla de intro
# 1.1 = 1.5 visible - 0.4 (duración de la transición iris de salida)
const INTRO_DURATION: float = 1.1

# Caja máxima de cada icono: se escala manteniendo proporción para que entre
# acá dentro. No es un cuadrado porque hay iconos muy anchos (la barra
# espaciadora es 150x39) que en una caja cuadrada quedaban de 6 px de alto.
# Los PNG ya vienen guardados al tamaño final, así que acá el factor da 1.0
# y se dibujan 1:1 con el filtro nearest del proyecto
const ICON_MAX_SIZE: Vector2 = Vector2(150, 56)

# Datos del microjuego que se va a presentar
var microgame_data: MicrogameData = null


func _ready() -> void:
	# Si el GameManager nos pasó datos, los usamos
	if GameManager.pending_intro_data != null:
		microgame_data = GameManager.pending_intro_data
		GameManager.pending_intro_data = null
		_apply_data()
	else:
		print("⚠️ MicrogameIntro: no hay datos de microjuego, volviendo al menú")
		GameManager.return_to_main_menu()
		return
	
	# Crear timer pausable que respeta get_tree().paused
	var timer: SceneTreeTimer = get_tree().create_timer(INTRO_DURATION, false)
	await timer.timeout
	_on_intro_finished()


func _apply_data() -> void:
	# Aplicar el título (el MicrogameData guarda la clave, no el texto)
	title_label.text = LocalizationManager.t(microgame_data.title_key)
	
	# Aplicar los iconos de controles
	for control_data in microgame_data.controls:
		if control_data.icon == null:
			continue
		var icon: TextureRect = TextureRect.new()
		icon.texture = control_data.icon
		icon.custom_minimum_size = _icon_display_size(control_data.icon)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		controls_container.add_child(icon)


# Tamaño final del icono: el mayor que entra en ICON_MAX_SIZE sin deformarlo
func _icon_display_size(texture: Texture2D) -> Vector2:
	var source: Vector2 = texture.get_size()
	if source.x <= 0.0 or source.y <= 0.0:
		return ICON_MAX_SIZE
	var factor: float = minf(ICON_MAX_SIZE.x / source.x, ICON_MAX_SIZE.y / source.y)
	return source * factor


func _on_intro_finished() -> void:
	# Avisar al GameManager que la intro terminó, ahora carga el microjuego real
	GameManager.start_pending_microgame()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()
