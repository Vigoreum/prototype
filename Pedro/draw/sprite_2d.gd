extends Sprite2D

@export var radio_borrado: int = 150 # Tamaño del pincel borrador
var imagen_editable: Image
var textura_dinamica: ImageTexture
var mouse_presionado: bool = false

var pixeles_totales: float = 0.0
var pixeles_borrados: float = 0.0
#@onready var etiqueta_progreso = $"../ProgresoTexto" # Ajusta la ruta a tu nodo Label


func _ready():
	# 1. Creamos una copia local y modificable de la textura
	imagen_editable = texture.get_image()
	textura_dinamica = ImageTexture.create_from_image(imagen_editable)

	# 1. Creamos la copia local de la textura
	imagen_editable = texture.get_image()
	
	# Fuerza a la imagen a usar el formato RGBA8 (Soporta Transparencia)
	imagen_editable.convert(Image.FORMAT_RGBA8)
	
	# 2. Creamos y asignamos la textura dinámica
	textura_dinamica = ImageTexture.create_from_image(imagen_editable)
	texture = textura_dinamica # Reemplazamos la textura original
	
	# Guardamos el total de píxeles que tiene la imagen
	pixeles_totales = imagen_editable.get_width() * imagen_editable.get_height()
	#actualizar_interfaz(0.0)


func _input(event):
	# Detecta si el usuario mantiene presionado el clic izquierdo
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		mouse_presionado = event.pressed

func _process(_delta):
	# Si el mouse está presionado, borramos en la posición actual del mouse
	if mouse_presionado:
		var pos_mouse = get_local_mouse_position()
		borrar_en_posicion(pos_mouse)

func borrar_en_posicion(pos_local: Vector2):
	var centro_x = int(pos_local.x + imagen_editable.get_width() / 2.0)
	var centro_y = int(pos_local.y + imagen_editable.get_height() / 2.0)
	
	var modificado = false
	
	# Definimos dónde empieza a difuminarse (ej. al 50% del radio)
	var radio_solido = radio_borrado * 0.7
	
	for x in range(centro_x - radio_borrado, centro_x + radio_borrado):
		for y in range(centro_y - radio_borrado, centro_y + radio_borrado):
			
			if x >= 0 and x < imagen_editable.get_width() and y >= 0 and y < imagen_editable.get_height():
				# 1. Calculamos la distancia exacta del píxel al centro del pincel
				var distancia = Vector2(x, y).distance_to(Vector2(centro_x, centro_y))
				
				# Si está dentro del rango total del pincel
				if distancia < radio_borrado:
					# 2. Obtenemos el color actual del píxel antes de modificarlo
					var color_actual = imagen_editable.get_pixel(x, y)
					
					var nueva_transparencia: float
					
					if distancia <= radio_solido:
						# Si está muy cerca del centro, se borra al 100% (Alfa = 0)
						nueva_transparencia = 0.0
					else:
						# Si está en el borde, calculamos un desvanecimiento suave (0.0 a 1.0)
						var factor_difuminado = (distancia - radio_solido) / (radio_borrado - radio_solido)
						
						# Mantener el mínimo de transparencia para no "pintar de vuelta" si ya estaba borrado
						nueva_transparencia = min(color_actual.a, factor_difuminado)
					
					# 3. Solo aplicamos el cambio si el nuevo alfa es más transparente que el actual
					if nueva_transparencia < color_actual.a:
						# Conservamos los colores originales (r, g, b) pero reducimos el canal Alfa (a)
						imagen_editable.set_pixel(x, y, Color(color_actual.r, color_actual.g, color_actual.b, nueva_transparencia))
						modificado = true
	
	if modificado:
		textura_dinamica.update(imagen_editable)
		
		# Calculamos el porcentaje final (0 a 100)
		var porcentaje = (pixeles_borrados / pixeles_totales) * 100.0
		#actualizar_interfaz(porcentaje)

# Función para mostrar el texto formateado
#func actualizar_interfaz(porcentaje: float):
	#if etiqueta_progreso:
		## "%.1f" muestra solo 1 decimal (ejemplo: "42.5%")
		#etiqueta_progreso.text = "Borrado: " + "%.1f" % porcentaje + "%"
