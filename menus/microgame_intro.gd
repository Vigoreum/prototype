extends Control

@onready var title_label: Label = $Title
@onready var controls_container: HBoxContainer = $ControlsContainer

# Duración total que se muestra la pantalla de intro
const INTRO_DURATION: float = 1.1  # 1.5 - 0.4 (duración de la transición de salida)

# Tamaño con el que se muestran los iconos
const ICON_SIZE: Vector2 = Vector2(128, 128)

# Datos del microjuego que se va a presentar
var microgame_data: MicrogameData = null


func _ready() -> void:
	# TEST: hardcodear datos para verificar visualmente
	title_label.text = "¡USB!"
	# Si el GameManager nos pasó datos, los usamos
	if GameManager.pending_intro_data != null:
		microgame_data = GameManager.pending_intro_data
		GameManager.pending_intro_data = null  # limpiar después de usar
		_apply_data()
	else:
		# Caso edge: nadie nos pasó datos. Volver al menú.
		print("⚠️ MicrogameIntro: no hay datos de microjuego, volviendo al menú")
		GameManager.return_to_main_menu()
		return
	
	# Esperar la duración configurada y después continuar
	await get_tree().create_timer(INTRO_DURATION).timeout
	_on_intro_finished()


func _apply_data() -> void:
	# Aplicar el título
	title_label.text = microgame_data.title
	
	# Aplicar los iconos de controles
	for control_data in microgame_data.controls:
		var icon: TextureRect = TextureRect.new()
		icon.texture = control_data.icon
		icon.custom_minimum_size = ICON_SIZE
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		controls_container.add_child(icon)


func _on_intro_finished() -> void:
	# Avisar al GameManager que la intro terminó, ahora carga el microjuego real
	GameManager.start_pending_microgame()
