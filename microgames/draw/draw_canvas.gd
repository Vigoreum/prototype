extends Sprite2D

signal drawing_completed

@export var brush_radius: float = 40.0
@export var mask_downscale: int = 6
@export_range(0.0, 100.0) var win_percent: float = 90.0
@export_range(0.0, 1.0) var soft_edge: float = 0.35

const THRESHOLD: int = 128

var mask_buffer: PackedByteArray
var mask_image: Image
var mask_texture: ImageTexture
var mask_w: int = 1
var mask_h: int = 1

var canvas_w: float = 1.0
var canvas_h: float = 1.0

var drawing: bool = false
var last_uv: Vector2 = Vector2(-1, -1)

var total_pixels: int = 1
var drawn_pixels: int = 0
var won: bool = false

func _ready() -> void:
	var size: Vector2 = texture.get_size()
	canvas_w = size.x
	canvas_h = size.y
	mask_w = max(1, int(round(canvas_w / mask_downscale)))
	mask_h = max(1, int(round(canvas_h / mask_downscale)))
	total_pixels = mask_w * mask_h

	mask_buffer = PackedByteArray()
	mask_buffer.resize(total_pixels)
	mask_buffer.fill(0)

	mask_image = Image.create_from_data(mask_w, mask_h, false, Image.FORMAT_L8, mask_buffer)
	mask_texture = ImageTexture.create_from_image(mask_image)
	if material is ShaderMaterial:
		material.set_shader_parameter("mask", mask_texture)
	else:
		push_error("Drawing no tiene un ShaderMaterial asignado. Asigná draw_canvas.gdshader en el inspector.")

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		drawing = event.pressed
		if event.pressed:
			last_uv = Vector2(-1, -1)

func _process(_delta: float) -> void:
	if not drawing:
		return
	var uv: Vector2 = _mouse_uv()
	if uv.x < -0.5:
		return
	if uv.is_equal_approx(last_uv):
		return

	if last_uv.x < -0.5:
		_stamp(uv)
	else:
		var step: float = (brush_radius / canvas_w) * 0.5
		var dist: float = last_uv.distance_to(uv)
		var steps: int = int(dist / step) if step > 0.0001 else 0
		if steps <= 0:
			_stamp(uv)
		else:
			for i in range(steps + 1):
				_stamp(last_uv.lerp(uv, float(i) / float(steps)))

	last_uv = uv
	_upload_and_check()

func _mouse_uv() -> Vector2:
	var local: Vector2 = get_local_mouse_position()
	var top_left: Vector2 = local
	if centered:
		top_left = local + Vector2(canvas_w, canvas_h) / 2.0
	var uv: Vector2 = Vector2(top_left.x / canvas_w, top_left.y / canvas_h)
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return Vector2(-1, -1)
	return uv

func _stamp(uv: Vector2) -> void:
	var cx: float = uv.x * mask_w
	var cy: float = uv.y * mask_h
	var r: float = brush_radius / mask_downscale
	var r_solid: float = r * (1.0 - soft_edge)
	var r_sq: float = r * r
	var r_solid_sq: float = r_solid * r_solid
	var fade: float = max(r - r_solid, 0.0001)

	var x_min: int = max(int(cx - r), 0)
	var x_max: int = min(int(cx + r), mask_w - 1)
	var y_min: int = max(int(cy - r), 0)
	var y_max: int = min(int(cy + r), mask_h - 1)

	for y in range(y_min, y_max + 1):
		var dy: float = y - cy
		var row: int = y * mask_w
		for x in range(x_min, x_max + 1):
			var dx: float = x - cx
			var d_sq: float = dx * dx + dy * dy
			if d_sq >= r_sq:
				continue
			var idx: int = row + x
			var current: int = mask_buffer[idx]
			var value: int
			if d_sq <= r_solid_sq:
				value = 255
			else:
				var f: float = (sqrt(d_sq) - r_solid) / fade
				value = int(clampf(1.0 - f, 0.0, 1.0) * 255.0)
			if value > current:
				if current < THRESHOLD and value >= THRESHOLD:
					drawn_pixels += 1
				mask_buffer[idx] = value

func _upload_and_check() -> void:
	mask_image = Image.create_from_data(mask_w, mask_h, false, Image.FORMAT_L8, mask_buffer)
	mask_texture.update(mask_image)
	if won:
		return
	var pct: float = float(drawn_pixels) / float(total_pixels) * 100.0
	if pct >= win_percent:
		won = true
		drawing_completed.emit()
