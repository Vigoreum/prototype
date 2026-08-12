extends Control

@onready var retry_button: Button = $ButtonsContainer/RetryButton
@onready var exit_button: Button = $ButtonsContainer/ExitButton
@onready var sound_player: AudioStreamPlayer = $SoundPlayer


func _ready() -> void:
	AudioManager.register_button_positive(retry_button)
	AudioManager.register_button_back(exit_button)

	_play_game_over_sound()

	# Desactivar botones brevemente para evitar clics accidentales 
	# durante la transición de entrada
	retry_button.disabled = true
	exit_button.disabled = true
	await get_tree().create_timer(0.5).timeout
	retry_button.disabled = false
	exit_button.disabled = false


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
