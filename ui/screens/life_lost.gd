extends Control

const SHAKE_DURATION: float = 0.3
const SHAKE_INTENSITY: float = 8.0
const BREAK_DURATION: float = 0.5
const HOLD_AFTER: float = 0.4
# Fundido del game over cuando se pierde la última vida: dura lo mismo que
# romperse + la espera, así termina justo cuando acaba la animación
const GAME_OVER_FADE_DURATION: float = BREAK_DURATION + HOLD_AFTER
# Separación entre corazones (ancho del icono + margen), igual a la de la escena
const LIFE_STEP: float = 132.0
# Lo que tardan las vidas restantes en recolocarse tras romperse una
const RECENTER_DURATION: float = 0.25

const GameOverScene: PackedScene = preload("res://ui/screens/game_over.tscn")

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
		if life.visible:
			life.position.x = _centered_x(i, lives_before)


# X del corazón `index` con `count` corazones visibles, centrados en el
# contenedor. El contenedor mide justo lo que ocupan todas las vidas, así que
# centrar es correr la fila media separación por cada vida que falta.
func _centered_x(index: int, count: int) -> float:
	var slots: int = lives_container.get_child_count()
	var start_x: float = (slots - count) * LIFE_STEP / 2.0
	return start_x + index * LIFE_STEP

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

	# Era la última vida: el game over entra fundiéndose por encima mientras
	# el corazón se rompe, en vez de esperar a que termine y cambiar de escena
	if GameManager.lives <= 0:
		tween.tween_callback(_fade_in_game_over)

	# Esperar y continuar. Las vidas que quedan se recolocan durante la espera
	tween.set_parallel(false)
	tween.tween_callback(_recenter_remaining_lives)
	tween.tween_interval(HOLD_AFTER)
	tween.tween_callback(_finish)


# Vuelve a centrar la fila con las vidas que sobreviven
func _recenter_remaining_lives() -> void:
	var count: int = GameManager.lives
	if count <= 0:
		return

	var children: Array[Node] = lives_container.get_children()
	var slide: Tween = create_tween()
	slide.set_parallel(true)
	for i in count:
		var life: TextureRect = children[i]
		slide.tween_property(life, "position:x", _centered_x(i, count), RECENTER_DURATION) \
			.set_ease(Tween.EASE_OUT)

# Instancia el game over encima de esta escena y lo funde. No se cambia de
# escena: el game over queda como overlay y sus botones se encargan del resto
func _fade_in_game_over() -> void:
	var layer: CanvasLayer = CanvasLayer.new()
	add_child(layer)

	var game_over: Control = GameOverScene.instantiate()
	game_over.modulate.a = 0.0
	layer.add_child(game_over)

	# El sonido lo dispara el propio game_over al entrar al árbol
	GameManager.enter_game_over_overlay()

	var fade: Tween = create_tween()
	fade.tween_property(game_over, "modulate:a", 1.0, GAME_OVER_FADE_DURATION)


func _finish() -> void:
	# Con el game over ya fundido encima no hay nada que continuar
	if GameManager.is_game_over_overlay:
		return
	GameManager.continue_after_life_lost()
