extends Node2D

const TimerBarScene: PackedScene = preload("res://menus/timer_bar.tscn")
var timer_bar: Control = null


func _ready() -> void:
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


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.return_to_main_menu()
