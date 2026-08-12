extends CanvasLayer

# El popup del OptionButton no hereda los theme_override del botón:
# hay que darle fuente y colores a mano o sale con el tema por defecto de Godot
const MENU_FONT: FontFile = preload("res://assets/fonts/press_start_k.ttf")
const MENU_FONT_SIZE: int = 11

# Paleta del menú principal (ver main_menu.tscn)
const COLOR_CREAM: Color = Color(1, 0.87058824, 0.6862745, 1)
const COLOR_PURPLE: Color = Color(0.6627451, 0.43529412, 0.94509804, 1)

@onready var background: ColorRect = $Background
@onready var frame: Panel = $Frame
@onready var title_label: Label = $Frame/Margin/Content/TopRow/Title
@onready var back_button: Button = $Frame/Margin/Content/TopRow/BackButton
@onready var window_scale_option: OptionButton = $Frame/Margin/Content/WindowScaleRow/WindowScaleOption
@onready var fullscreen_check: CheckBox = $Frame/Margin/Content/FullscreenRow/FullscreenCheck

@onready var master_slider: HSlider = $Frame/Margin/Content/VolumeMargin/VolumeRows/MasterRow/MasterSlider
@onready var master_value: Label = $Frame/Margin/Content/VolumeMargin/VolumeRows/MasterRow/MasterValue
@onready var sfx_slider: HSlider = $Frame/Margin/Content/VolumeMargin/VolumeRows/SfxRow/SfxSlider
@onready var sfx_value: Label = $Frame/Margin/Content/VolumeMargin/VolumeRows/SfxRow/SfxValue
@onready var music_slider: HSlider = $Frame/Margin/Content/VolumeMargin/VolumeRows/MusicRow/MusicSlider
@onready var music_value: Label = $Frame/Margin/Content/VolumeMargin/VolumeRows/MusicRow/MusicValue


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Llenar el desplegable de escalas antes de sincronizar el estado
	_build_scale_items()

	# Inicializar los controles con el estado actual
	fullscreen_check.button_pressed = SettingsManager.is_fullscreen
	_refresh_scale_items()
	_setup_volume_row(master_slider, master_value, SettingsManager.BUS_MASTER)
	_setup_volume_row(sfx_slider, sfx_value, SettingsManager.BUS_SFX)
	_setup_volume_row(music_slider, music_value, SettingsManager.BUS_MUSIC)

	# Conectar señales
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	window_scale_option.item_selected.connect(_on_scale_item_selected)
	back_button.pressed.connect(_on_back_pressed)
	SettingsManager.fullscreen_changed.connect(_on_settings_fullscreen_changed)  # ← nueva
	SettingsManager.window_scale_changed.connect(_on_settings_window_scale_changed)
	SettingsManager.volume_changed.connect(_on_settings_volume_changed)

	# Registrar sonidos UI
	AudioManager.register_button_back(back_button)
	fullscreen_check.mouse_entered.connect(AudioManager.play_hover)
	fullscreen_check.toggled.connect(_play_check_sound)
	window_scale_option.mouse_entered.connect(AudioManager.play_hover)
	window_scale_option.pressed.connect(AudioManager.play_click_neutral)

	hide_menu()


# Muestra el menú de opciones
func show_menu() -> void:
	background.visible = true
	frame.visible = true
	# Refrescar por si algo cambió desde otro lado (ej: F11) o cambió el monitor
	fullscreen_check.button_pressed = SettingsManager.is_fullscreen
	_refresh_scale_items()
	_refresh_volume_rows()


# Oculta el menú de opciones
func hide_menu() -> void:
	background.visible = false
	frame.visible = false


# Verifica si el menú está abierto
func is_open() -> bool:
	return background.visible


# Crea un item por cada escala disponible. El id del item ES la escala,
# así el índice del desplegable nunca hay que traducirlo a mano.
func _build_scale_items() -> void:
	_style_scale_popup()

	window_scale_option.clear()
	for window_scale: int in range(SettingsManager.MIN_WINDOW_SCALE, SettingsManager.MAX_WINDOW_SCALE + 1):
		window_scale_option.add_item("%dx" % window_scale, window_scale)


# El desplegable es una ventana aparte con su propio tema: crema con texto
# morado, igual que los botones del menú principal.
func _style_scale_popup() -> void:
	var popup: PopupMenu = window_scale_option.get_popup()
	popup.add_theme_font_override("font", MENU_FONT)
	popup.add_theme_font_size_override("font_size", MENU_FONT_SIZE)
	popup.add_theme_color_override("font_color", COLOR_PURPLE)
	popup.add_theme_color_override("font_hover_color", COLOR_PURPLE)
	popup.add_theme_color_override("font_disabled_color", Color(COLOR_PURPLE, 0.4))

	var panel: StyleBoxFlat = StyleBoxFlat.new()
	panel.bg_color = COLOR_CREAM
	panel.set_corner_radius_all(3)
	panel.set_content_margin_all(2)
	popup.add_theme_stylebox_override("panel", panel)

	var hover: StyleBoxFlat = StyleBoxFlat.new()
	hover.bg_color = Color(COLOR_PURPLE, 0.25)
	hover.set_corner_radius_all(2)
	popup.add_theme_stylebox_override("hover", hover)


# Marca la escala activa y desactiva las que no entran en el monitor.
# select() no emite item_selected, así que no hay loop de señales.
func _refresh_scale_items() -> void:
	for index: int in window_scale_option.item_count:
		var window_scale: int = window_scale_option.get_item_id(index)
		window_scale_option.set_item_disabled(index, not SettingsManager.scale_fits_screen(window_scale))
	window_scale_option.select(window_scale_option.get_item_index(SettingsManager.window_scale))


# Cada slider trabaja en 0.0..1.0 y lleva pegado su bus y su etiqueta de %
func _setup_volume_row(slider: HSlider, value_label: Label, bus: StringName) -> void:
	slider.min_value = 0.0
	slider.max_value = 1.0
	slider.step = 0.01
	slider.value = SettingsManager.get_bus_volume(bus)
	slider.value_changed.connect(_on_volume_slider_changed.bind(bus, value_label))
	slider.drag_ended.connect(_on_volume_drag_ended)
	slider.mouse_entered.connect(AudioManager.play_hover)
	_update_volume_label(value_label, slider.value)


func _refresh_volume_rows() -> void:
	_refresh_volume_row(master_slider, master_value, SettingsManager.BUS_MASTER)
	_refresh_volume_row(sfx_slider, sfx_value, SettingsManager.BUS_SFX)
	_refresh_volume_row(music_slider, music_value, SettingsManager.BUS_MUSIC)


func _refresh_volume_row(slider: HSlider, value_label: Label, bus: StringName) -> void:
	var value: float = SettingsManager.get_bus_volume(bus)
	slider.set_value_no_signal(value)
	_update_volume_label(value_label, value)


func _update_volume_label(value_label: Label, value: float) -> void:
	value_label.text = "%d%%" % roundi(value * 100.0)


func _on_volume_slider_changed(value: float, bus: StringName, value_label: Label) -> void:
	SettingsManager.set_bus_volume(bus, value)
	_update_volume_label(value_label, value)


# Un sonido al soltar para oír a qué volumen quedó
func _on_volume_drag_ended(value_changed: bool) -> void:
	if value_changed:
		AudioManager.play_click_neutral()


func _on_fullscreen_toggled(enabled: bool) -> void:
	SettingsManager.set_fullscreen(enabled)


# En fullscreen la escala solo se guarda; se ve al desactivar pantalla completa
func _on_scale_item_selected(index: int) -> void:
	AudioManager.play_click_neutral()
	SettingsManager.set_window_scale(window_scale_option.get_item_id(index))


func _on_back_pressed() -> void:
	AudioManager.play_click_back()
	hide_menu()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return

	if event.is_action_pressed("ui_cancel"):
		AudioManager.play_click_back()
		hide_menu()
		get_viewport().set_input_as_handled()


func _play_check_sound(_pressed: bool) -> void:
	AudioManager.play_click_neutral()

# Se ejecuta cuando el fullscreen cambia desde fuera (ej: tecla F11)
func _on_settings_fullscreen_changed(enabled: bool) -> void:
	# Actualizamos el checkbox sin disparar la señal toggled
	# (set_pressed_no_signal evita el loop infinito)
	fullscreen_check.set_pressed_no_signal(enabled)


# La escala cambió desde fuera (o se ajustó sola porque no cabía en la pantalla)
func _on_settings_window_scale_changed(_window_scale: int) -> void:
	_refresh_scale_items()


# El volumen cambió desde fuera. set_value_no_signal evita el loop
# slider → SettingsManager → slider.
func _on_settings_volume_changed(bus: StringName, _value: float) -> void:
	match bus:
		SettingsManager.BUS_MASTER:
			_refresh_volume_row(master_slider, master_value, bus)
		SettingsManager.BUS_SFX:
			_refresh_volume_row(sfx_slider, sfx_value, bus)
		SettingsManager.BUS_MUSIC:
			_refresh_volume_row(music_slider, music_value, bus)
