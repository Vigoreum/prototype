extends Control

@onready var usb_button: Button = $ButtonContainer/UsbButton
@onready var delete_button: Button = $ButtonContainer/DeleteButton
@onready var draw_button: Button = $ButtonContainer/DrawButton
@onready var wake_up_button: Button = $ButtonContainer/WakeUpButton
@onready var back_button: Button = $BackButton


func _on_usb_pressed() -> void:
	GameManager.play_single_minigame("res://scenes/minigame_usb.tscn")


func _on_delete_pressed() -> void:
	GameManager.play_single_minigame("res://scenes/minigame_3.tscn")


func _on_draw_pressed() -> void:
	GameManager.play_single_minigame("res://scenes/Minigame4.tscn")


func _on_wake_up_pressed() -> void:
	pass


func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()
