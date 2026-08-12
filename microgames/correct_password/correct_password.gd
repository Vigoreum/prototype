extends Node2D

const PASSWORD_LENGTH: int = 4
const WRONG_DELAY: float = 0.4
const SHAKE_DURATION: float = 0.3
const SHAKE_INTENSITY: float = 10.0
# Caracteres válidos: A-Z (sin Ñ) + 0-9
const VALID_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

@onready var password_label: Label = $PostIt/PasswordLabel
@onready var typed_label: Label = $InputArea/TypedLabel
@onready var input_area: Control = $InputArea
@onready var caret: ColorRect = $InputArea/Caret
@onready var caret_blink: Timer = $InputArea/CaretBlink

var target_password: String = ""
var typed_text: String = ""
var has_finished: bool = false
var is_locked: bool = false  # bloquea input durante el delay de error

var timer_bar: Control = null

const TimerBarScene: PackedScene = preload("res://ui/overlays/timer_bar.tscn")

func _ready() -> void:
	randomize()
	_generate_password()
	_update_typed_display()
	if GameManager.is_in_play_mode:
		_setup_timer_bar()

func _generate_password() -> void:
	target_password = ""
	for i in PASSWORD_LENGTH:
		var idx: int = randi() % VALID_CHARS.length()
		target_password += VALID_CHARS[idx]
	password_label.text = target_password

func _setup_timer_bar() -> void:
	timer_bar = TimerBarScene.instantiate()
	var canvas: CanvasLayer = CanvasLayer.new()
	add_child(canvas)
	canvas.add_child(timer_bar)
	timer_bar.time_up.connect(_on_time_up)
	timer_bar.start(GameManager.get_microgame_duration())

func _on_time_up() -> void:
	if has_finished:
		return
	has_finished = true
	GameManager.notify_microgame_timed_out()

func _unhandled_input(event: InputEvent) -> void:
	if has_finished or is_locked:
		return
	
	# Pausa con ESC
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		_handle_key(event)

func _handle_key(event: InputEventKey) -> void:
	# Borrar con backspace
	if event.keycode == KEY_BACKSPACE:
		if typed_text.length() > 0:
			typed_text = typed_text.substr(0, typed_text.length() - 1)
			_update_typed_display()
		return
	
	# Solo aceptar si no llegamos al largo máximo
	if typed_text.length() >= PASSWORD_LENGTH:
		return
	
	# Obtener el carácter tipeado como unicode
	var unicode: int = event.unicode
	if unicode == 0:
		return
	
	var character: String = char(unicode).to_upper()
	
	# Validar que sea un carácter permitido
	if not VALID_CHARS.contains(character):
		return
	
	typed_text += character
	_update_typed_display()
	
	# Si completó los 4, chequear
	if typed_text.length() == PASSWORD_LENGTH:
		_check_password()

func _update_typed_display() -> void:
	# Muestra lo tecleado, con guiones bajos para los espacios restantes
	var display: String = typed_text
	for i in range(typed_text.length(), PASSWORD_LENGTH):
		display += "_"
	typed_label.text = display
	_update_caret()


# Ubica el cursor justo antes del hueco que se va a escribir. El texto está
# centrado, así que hay que medirlo con la fuente para saber dónde empieza
func _update_caret() -> void:
	if has_finished or is_locked or typed_text.length() >= PASSWORD_LENGTH:
		caret.visible = false
		return

	var font: Font = typed_label.get_theme_font(&"font")
	var font_size: int = typed_label.get_theme_font_size(&"font_size")
	var full_width: float = font.get_string_size(
		typed_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x
	var typed_width: float = font.get_string_size(
		typed_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size
	).x

	var text_start_x: float = (input_area.size.x - full_width) / 2.0
	caret.position = Vector2(
		text_start_x + typed_width,
		(input_area.size.y - caret.size.y) / 2.0
	)
	# Reaparece al tipear para que no quede apagado justo cuando escribís
	caret.visible = true
	caret_blink.start()


func _on_caret_blink() -> void:
	if has_finished or is_locked or typed_text.length() >= PASSWORD_LENGTH:
		caret.visible = false
		return
	caret.visible = not caret.visible

func _check_password() -> void:
	if typed_text == target_password:
		_on_win()
	else:
		_on_wrong()

func _on_wrong() -> void:
	is_locked = true
	_update_caret()
	_shake_camera()
	# Delay antes de limpiar y dejar reintentar
	await get_tree().create_timer(WRONG_DELAY).timeout
	if has_finished:
		return
	typed_text = ""
	# Desbloquear antes de refrescar: si no, _update_caret esconde el cursor
	is_locked = false
	_update_typed_display()

func _shake_camera() -> void:
	# Shake del contenedor de input (placeholder; después será la cámara/pantalla)
	var original_pos: Vector2 = input_area.position
	var tween: Tween = create_tween()
	for i in 6:
		var offset: Vector2 = Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		)
		tween.tween_property(input_area, "position", original_pos + offset, SHAKE_DURATION / 6.0)
	tween.tween_property(input_area, "position", original_pos, 0.05)

func _on_win() -> void:
	if has_finished:
		return
	has_finished = true
	_update_caret()
	if timer_bar != null:
		timer_bar.stop()
	GameManager.notify_microgame_won()
