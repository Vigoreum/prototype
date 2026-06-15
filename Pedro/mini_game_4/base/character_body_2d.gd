
extends CharacterBody2D

# Sube este número en el Inspector si el objeto no alcanza al mouse
@export var max_speed: float = 10000.0 

func _physics_process(_delta):
	var mouse_pos = get_global_mouse_position()
	
	# 1. Calcula la dirección y la distancia hacia el mouse
	var to_mouse = mouse_pos - global_position
	
	# 2. Si está muy cerca, se detiene para evitar que tiemble
	if to_mouse.length() < 5:
		velocity = Vector2.ZERO
	else:
		# 3. Se mueve a máxima velocidad hacia el cursor
		velocity = to_mouse.normalized() * max_speed
		
		# Opcional: Si el mouse está más cerca que la velocidad máxima,
		# frena para quedarse exactamente encima del cursor.
		if to_mouse.length() < velocity.length() * _delta:
			global_position = mouse_pos
			velocity = Vector2.ZERO

	# 4. Ejecuta el movimiento físico
	move_and_slide()
