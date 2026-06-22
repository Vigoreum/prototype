extends Control

@onready var usb_button: Button = $ButtonContainer/UsbButton
@onready var delete_button: Button = $ButtonContainer/DeleteButton
@onready var draw_button: Button = $ButtonContainer/DrawButton
@onready var wake_up_button: Button = $ButtonContainer/WakeUpButton
@onready var back_button: Button = $BackButton


func _ready() -> void:
	usb_button.pressed.connect(_on_usb_pressed)
	delete_button.pressed.connect(_on_delete_pressed)
	draw_button.pressed.connect(_on_draw_pressed)
	wake_up_button.pressed.connect(_on_wake_up_pressed)
	back_button.pressed.connect(_on_back_pressed)


func _on_usb_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/usb/usb_data.tres")


func _on_delete_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/delete/delete_data.tres")


func _on_draw_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/draw/draw_data.tres")


func _on_wake_up_pressed() -> void:
	GameManager.play_single_microgame("res://microgames/wake_up/wake_up_data.tres")


func _on_back_pressed() -> void:
	GameManager.return_to_main_menu()
