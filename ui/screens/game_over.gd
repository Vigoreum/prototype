extends Control

@onready var retry_button: Button = $ButtonsContainer/RetryButton
@onready var exit_button: Button = $ButtonsContainer/ExitButton
@onready var sound_player: AudioStreamPlayer = $SoundPlayer
@onready var score_label: Label = $Score
@onready var title_label: Label = $Title


func _ready() -> void:
	AudioManager.register_button_positive(retry_button)
	AudioManager.register_button_back(exit_button)

	_apply_texts()
	LocalizationManager.language_changed.connect(_apply_texts)

	_show_score()

	_play_game_over_sound()

	# Desactivar botones brevemente para evitar clics accidentales 
	# durante la transición de entrada
	retry_button.disabled = true
	exit_button.disabled = true
	await get_tree().create_timer(0.5).timeout
	retry_button.disabled = false
	exit_button.disabled = false


# Puntaje = microjuegos ganados en la partida. En modo single (SELECT) no hay
# partida que puntuar, así que no se muestra
func _show_score() -> void:
	score_label.visible = GameManager.is_in_play_mode
	score_label.text = LocalizationManager.t_format("game_over.score", [GameManager.microgames_cleared])


func _apply_texts() -> void:
	title_label.text = LocalizationManager.t("game_over.title")
	retry_button.text = LocalizationManager.t("game_over.retry")
	exit_button.text = LocalizationManager.t("common.exit")
	_show_score()


# El sonido espera a que el iris termine de descubrir la pantalla, así
# imagen y sonido entran juntos. Sin transición (escena suelta) suena ya.
func _play_game_over_sound() -> void:
	if IrisTransition.is_busy:
		await IrisTransition.transition_finished
	sound_player.play()


func _on_retry_pressed() -> void:
	GameManager.retry_after_loss()


func _on_exit_pressed() -> void:
	GameManager.return_to_main_menu()
