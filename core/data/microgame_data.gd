class_name MicrogameData
extends Resource

# Título que se muestra en la pantalla de intro
@export var title: String = ""

# Escena del microjuego que se carga después de la intro
@export var scene: PackedScene

# Duración del microjuego en segundos (timer)
@export var duration: float = 5.0

# Lista de controles que usa este microjuego
@export var controls: Array[ControlData] = []

# Si el cursor del mouse es visible durante este microjuego.
# Desactivar en microjuegos que solo usan teclado (ej. CORRECT PASSWORD)
@export var show_cursor: bool = true
