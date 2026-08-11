extends Control

@export var in_time: float = 0.3       # espera antes de aparecer
@export var fade_in_time: float = 0.5
@export var pause_time: float = 1.2    # cuánto se queda visible
@export var fade_out_time: float = 0.6
@export var out_time: float = 0.3      # espera después de desaparecer
@export var skip_lock_time: float = 0.5  # no se puede saltar durante este tiempo
@export var skip_fade_time: float = 0.15  # fundido rápido al saltar

@onready var logo: TextureRect = $TextureRect

var _can_skip: bool = false
var _tween: Tween = null

func _ready() -> void:
	GameManager.hide_cursor()
	logo.modulate.a = 0.0
	_start_skip_lock()
	_play()

func _play() -> void:
	_tween = create_tween()
	_tween.tween_interval(in_time)
	_tween.tween_property(logo, "modulate:a", 1.0, fade_in_time)
	_tween.tween_interval(pause_time)
	_tween.tween_property(logo, "modulate:a", 0.0, fade_out_time)
	_tween.tween_interval(out_time)
	_tween.finished.connect(_finish, CONNECT_ONE_SHOT)

func _finish() -> void:
	_tween = null
	get_tree().change_scene_to_file("res://ui/screens/title_screen.tscn")

func _start_skip_lock() -> void:
	_can_skip = false
	var timer: SceneTreeTimer = get_tree().create_timer(max(skip_lock_time, 0.0))
	timer.timeout.connect(func(): _can_skip = true, CONNECT_ONE_SHOT)

func _skip() -> void:
	if not _can_skip:
		return
	_can_skip = false
	if _tween:
		_tween.kill()
	# No cortamos en seco: apagamos el logo rápido y recién ahí cambiamos
	_tween = create_tween()
	_tween.tween_property(logo, "modulate:a", 0.0, skip_fade_time)
	_tween.finished.connect(_finish, CONNECT_ONE_SHOT)

func _unhandled_input(event: InputEvent) -> void:
	if _can_skip and event.is_pressed() and not event.is_echo():
		_skip()
