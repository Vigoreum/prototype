extends Control

# Duración total que se muestra la pantalla de aceleración
# 0.9 = 1.3 visible - 0.4 (duración de la transición iris de salida)
const DISPLAY_DURATION: float = 0.9

@onready var title_label: Label = $Title


func _ready() -> void:
	title_label.text = LocalizationManager.t("speed_up.title")

	# Timer pausable que respeta get_tree().paused
	var timer: SceneTreeTimer = get_tree().create_timer(DISPLAY_DURATION, false)
	await timer.timeout
	GameManager.continue_after_speed_up()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()
