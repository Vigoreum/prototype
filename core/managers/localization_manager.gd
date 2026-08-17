extends Node

# Sistema de idiomas. Los textos viven en res://locales/<código>.json, un
# archivo plano de clave → texto. Agregar un idioma es soltar un .json nuevo
# en esa carpeta: se detecta solo y aparece en el menú de opciones.

const LOCALES_DIR: String = "res://locales"
const LOCALE_EXTENSION: String = ".json"

# Mismo archivo que SettingsManager pero en su propia sección. Los dos releen
# el .cfg antes de escribir para no pisarse las secciones del otro.
const CONFIG_PATH: String = "user://settings.cfg"
const SECTION_LANGUAGE: String = "language"
const KEY_CODE: String = "code"

# Idioma que se usa cuando el del sistema no está traducido
const DEFAULT_LANGUAGE: String = "en"

# Clave con el nombre del idioma escrito en ese mismo idioma ("ESPAÑOL"),
# para que el desplegable de opciones no tenga que conocer los idiomas
const KEY_LANGUAGE_NAME: String = "language.name"

signal language_changed

# Código del idioma activo ("en", "es", ...)
var current_language: String = DEFAULT_LANGUAGE

# Códigos disponibles, ordenados alfabéticamente
var available_languages: Array[String] = []

# Textos del idioma activo: clave → texto
var _texts: Dictionary[String, String] = {}

# Nombre de cada idioma disponible, para el desplegable de opciones
var _language_names: Dictionary[String, String] = {}


func _ready() -> void:
	# El idioma se puede cambiar desde el menú de opciones con el juego pausado
	process_mode = Node.PROCESS_MODE_ALWAYS

	_scan_available_languages()
	_apply_language(_resolve_startup_language())


# Texto de una clave. Si falta, devuelve la clave misma: el hueco se ve en
# pantalla en vez de quedar en blanco.
func t(key: String) -> String:
	return _texts.get(key, key)


# Igual que t(), rellenando los {0}, {1}... del texto
func t_format(key: String, values: Array) -> String:
	return t(key).format(values)


# Cambia el idioma, lo guarda y avisa a las pantallas abiertas
func set_language(code: String) -> void:
	if code == current_language or not available_languages.has(code):
		return
	_apply_language(code)
	_save_language()
	language_changed.emit()


# Nombre del idioma en su propio idioma ("ENGLISH", "ESPAÑOL")
func get_language_name(code: String) -> String:
	return _language_names.get(code, code.to_upper())


# ===== INTERNO =====

func _apply_language(code: String) -> void:
	current_language = code
	_texts = _load_locale(code)


# Prioridad: idioma guardado → idioma del sistema → idioma por defecto
func _resolve_startup_language() -> String:
	var saved: String = _load_saved_language()
	if available_languages.has(saved):
		return saved

	# get_locale_language() ya devuelve solo el idioma ("es" de "es_AR")
	var system: String = OS.get_locale_language()
	if available_languages.has(system):
		return system

	return DEFAULT_LANGUAGE


# Un idioma por cada .json de la carpeta. Los archivos vacíos o rotos se
# ignoran para no ofrecer un idioma que dejaría la UI en blanco.
func _scan_available_languages() -> void:
	available_languages.clear()
	_language_names.clear()

	var dir: DirAccess = DirAccess.open(LOCALES_DIR)
	if dir != null:
		for file_name: String in dir.get_files():
			if not file_name.ends_with(LOCALE_EXTENSION):
				continue
			_register_language(file_name.get_basename())

	# Red de seguridad: si la carpeta no se pudo listar, al menos el idioma
	# por defecto (cargarlo por ruta directa siempre funciona)
	if available_languages.is_empty():
		_register_language(DEFAULT_LANGUAGE)

	available_languages.sort()


func _register_language(code: String) -> void:
	var texts: Dictionary[String, String] = _load_locale(code)
	if texts.is_empty():
		return
	available_languages.append(code)
	_language_names[code] = texts.get(KEY_LANGUAGE_NAME, code.to_upper())


func _load_locale(code: String) -> Dictionary[String, String]:
	var result: Dictionary[String, String] = {}
	var path: String = "%s/%s%s" % [LOCALES_DIR, code, LOCALE_EXTENSION]

	if not FileAccess.file_exists(path):
		push_warning("Falta el archivo de idioma: %s" % path)
		return result

	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Archivo de idioma inválido: %s" % path)
		return result

	var entries: Dictionary = parsed
	for key: Variant in entries:
		result[str(key)] = str(entries[key])
	return result


func _load_saved_language() -> String:
	var config: ConfigFile = ConfigFile.new()
	if config.load(CONFIG_PATH) != OK:
		return ""
	return config.get_value(SECTION_LANGUAGE, KEY_CODE, "")


# Releemos el archivo antes de escribir: SettingsManager guarda sus propias
# secciones en el mismo .cfg y no hay que borrárselas
func _save_language() -> void:
	var config: ConfigFile = ConfigFile.new()
	config.load(CONFIG_PATH)
	config.set_value(SECTION_LANGUAGE, KEY_CODE, current_language)
	config.save(CONFIG_PATH)
