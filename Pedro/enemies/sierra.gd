class_name sierra
extends RigidBody2D

@export var demasiado_abajo = 1000

func _process(_delta):
	if position.y > demasiado_abajo:
		queue_free()
