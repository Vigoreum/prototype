extends Control

@onready var title_label: Label = $Title
@onready var controls_container: HBoxContainer = $ControlsContainer

# Duración total que se muestra la pantalla de intro
# 1.1 = 1.5 visible - 0.4 (duración de la transición iris de salida)
const INTRO_DURATION: float = 1.1

# Tamaño con el que se muestran los iconos
const ICON_SIZE: Vector2 = Vector2(32, 32)

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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()
