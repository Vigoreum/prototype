extends Control

const FADE_DURATION: float = 0.6  # ajustá a tu gusto

@onready var delay_timer: Timer = $Timer
@onready var press_label: Label = $PressStart
@onready var fade_overlay: ColorRect = $FadeOverlay

var input_allowed := false
var did_press_any_button := false
var blink_tween: Tween

func _ready() -> void:
	# Entramos desde el negro del splash: el overlay arranca tapando y se abre
	fade_overlay.modulate.a = 1.0
	var fade_in_tween: Tween = create_tween()
	fade_in_tween.tween_property(fade_overlay, "modulate:a", 0.0, FADE_DURATION)

	# Parpadeo del "Presiona cualquier botón"
	delay_timer.timeout.connect(_on_delay_timer_timeout)
	blink_tween = create_tween()
	blink_tween.set_loops()
	blink_tween.tween_property(press_label, "modulate:a", 0.0, 0.7)
	blink_tween.tween_property(press_label, "modulate:a", 1.0, 0.7)

func _on_delay_timer_timeout() -> void:
	input_allowed = true

func _input(event: InputEvent) -> void:
	if not input_allowed:
		return
	if event.is_released() and (
		event is InputEventKey
		or event is InputEventJoypadButton
		or event is InputEventMouseButton
	):
		if did_press_any_button:
			return
		did_press_any_button = true
		AudioManager.play_click_positive()
		if blink_tween:
			blink_tween.kill()
		press_label.modulate.a = 1.0
		_fade_and_proceed()

func _fade_and_proceed() -> void:
	var tween: Tween = create_tween()
	tween.tween_property(fade_overlay, "modulate:a", 1.0, FADE_DURATION).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_CUBIC)
	await tween.finished
	get_tree().change_scene_to_file("res://ui/screens/main_menu.tscn")
