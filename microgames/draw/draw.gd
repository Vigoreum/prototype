extends Node2D

const TimerBarScene: PackedScene = preload("res://ui/overlays/timer_bar.tscn")

var timer_bar: Control = null
var has_finished: bool = false

func _ready() -> void:
	if GameManager.is_in_play_mode:
		_setup_timer_bar()

func _setup_timer_bar() -> void:
	timer_bar = TimerBarScene.instantiate()
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(timer_bar)
	timer_bar.time_up.connect(_on_time_up)
	timer_bar.start(GameManager.get_microgame_duration())

func _on_drawing_completed() -> void:
	if has_finished:
		return
	has_finished = true
	if timer_bar != null:
		timer_bar.stop()
	GameManager.notify_microgame_won()

func _on_time_up() -> void:
	if has_finished:
		return
	has_finished = true
	if timer_bar != null:
		timer_bar.stop()
	GameManager.notify_microgame_timed_out()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()
