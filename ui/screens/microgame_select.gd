extends Control

@onready var usb_button: Button = $ButtonsContainer/UsbButton
@onready var delete_button: Button = $ButtonsContainer/DeleteButton
@onready var draw_button: Button = $ButtonsContainer/DrawButton
@onready var wake_up_button: Button = $ButtonsContainer/WakeUpButton
@onready var correct_password_button: Button = $ButtonsContainer/CorrectPassword
@onready var back_button: Button = $BackButton


func _ready() -> void:
	AudioManager.register_button_positive(usb_button)
	AudioManager.register_button_positive(delete_button)
	AudioManager.register_button_positive(draw_button)
	AudioManager.register_button_positive(wake_up_button)
	AudioManager.register_button_positive(correct_password_button)
	AudioManager.register_button_back(back_button)

func _on_usb_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/usb/usb_data.tres")


func _on_delete_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/delete/delete_data.tres")


func _on_draw_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/draw/draw_data.tres")


func _on_wake_up_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/wake_up/wake_up_data.tres")


func _on_correct_password_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/correct_password/correct_password_data.tres")

func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()


# Esta pantalla no es pausable (ver GameManager._is_pausable_scene), así que
# ESC queda libre para volver al menú. El sonido se reproduce a mano porque
# register_button_back sólo lo engancha al clic del botón
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if IrisTransition.is_busy:
		return
	AudioManager.play_click_back()
	_on_back_pressed()
