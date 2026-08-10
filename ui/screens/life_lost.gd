extends Control

const SHAKE_DURATION: float = 0.3
const SHAKE_INTENSITY: float = 8.0
const BREAK_DURATION: float = 0.5
const HOLD_AFTER: float = 0.4

@onready var lives_container: Control = $LivesContainer

func _ready() -> void:
	_setup_lives()
	_animate_life_loss()

func _setup_lives() -> void:
	# GameManager.lives ya fue decrementado antes de entrar acá.
	# Mostramos lives+1 vidas visibles: las primeras `lives` quedan,
	# la última (índice lives) es la que se va a romper.
	var lives_before: int = GameManager.lives + 1
	var children: Array[Node] = lives_container.get_children()
	for i in children.size():
		var life: TextureRect = children[i]
		life.visible = i < lives_before

func _animate_life_loss() -> void:
	var children: Array[Node] = lives_container.get_children()
	var lost_index: int = GameManager.lives  # la vida que se rompe
	
	if lost_index < 0 or lost_index >= children.size():
		_finish()
		return
	
	var lost_life: TextureRect = children[lost_index]
	lost_life.pivot_offset = lost_life.size / 2
	
	var tween: Tween = create_tween()
	
	# Shake
	var original_pos: Vector2 = lost_life.position
	for i in 6:
		var offset: Vector2 = Vector2(
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY),
			randf_range(-SHAKE_INTENSITY, SHAKE_INTENSITY)
		)
		tween.tween_property(lost_life, "position", original_pos + offset, SHAKE_DURATION / 6.0)
	tween.tween_property(lost_life, "position", original_pos, 0.05)
	
	# Romperse: scale up + fade out
	tween.set_parallel(true)
	tween.tween_property(lost_life, "scale", Vector2(1.4, 1.4), BREAK_DURATION).set_ease(Tween.EASE_OUT)
	tween.tween_property(lost_life, "modulate:a", 0.0, BREAK_DURATION)
	
	# Esperar y continuar
	tween.set_parallel(false)
	tween.tween_interval(HOLD_AFTER)
	tween.tween_callback(_finish)

func _finish() -> void:
	GameManager.continue_after_life_lost()
