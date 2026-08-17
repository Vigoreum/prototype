# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

"Tecno - Dash" — a WarioWare-style microgame collection built in **Godot 4.6** (Forward+, d3d12 on Windows, Jolt physics). GDScript only, no addons, no test suite.

Code comments, UI strings, and `print()` debug messages are in **Spanish**. Match that when editing existing files.

## Commands

**Always use the `godot` MCP server for anything Godot-related.** It is the required interface on this project — do not shell out to the Godot binary.

| Task | MCP tool |
| --- | --- |
| Run the game | `mcp__godot__run_project` |
| Read stdout / errors from the running game | `mcp__godot__get_debug_output` |
| Stop it | `mcp__godot__stop_project` |
| Open the editor | `mcp__godot__launch_editor` |
| Create a scene / add a node / save | `mcp__godot__create_scene`, `mcp__godot__add_node`, `mcp__godot__save_scene` |
| Load a sprite into a node | `mcp__godot__load_sprite` |
| Engine version, project info, UIDs | `mcp__godot__get_godot_version`, `mcp__godot__get_project_info`, `mcp__godot__get_uid`, `mcp__godot__update_project_uids` |

Editing `.gd` / `.tres` / `.tscn` text still goes through the normal Read/Edit/Write tools — MCP covers running, inspecting, and scene construction.

The binary lives at `C:\Program Files\Godot\Godot.exe` (not in PATH). CLI is a fallback only, e.g. for exporting, which MCP does not cover:

```powershell
& "C:\Program Files\Godot\Godot.exe" --headless --path . --export-release "Windows Desktop"
```

Export target is `../../../buildsWindows/Tecno - Dash.exe` (outside the repo). There is no test suite.

Running a microgame scene on its own still loads all autoloads, so `GameManager.is_in_play_mode` is `false` → no timer bar, no lives. That is the intended way to iterate on a single microgame.

## Architecture

### Autoloads (project.godot, order matters)

`LocalizationManager` → `GameManager` → `IrisTransition` → `PauseMenu` → `CountdownOverlay` → `AudioManager` → `SettingsManager` → `OptionsMenu`

`LocalizationManager` is first because every other autoload's `_ready()` (and every UI scene) asks it for text.

`GameManager` (`core/managers/game_manager.gd`) is the whole game state machine: lives, play queue, pending microgame data, cursor policy, pause gating. Everything else defers to it.

### Boot and scene flow

`ui/screens/splash_screen.tscn` (main scene, logo fade) → `ui/screens/title_screen.tscn` (press any key) → `ui/screens/main_menu.tscn`. These first two use `get_tree().change_scene_to_file` + manual fade overlays directly; **everything after the main menu goes through `IrisTransition`**.

From the main menu:
- **PLAY** → `GameManager.start_play_mode()`: 4 lives, all `MicrogameData` loaded and `shuffle()`d into `play_queue`, played until the queue empties or lives hit 0.
- **SELECT** → `ui/screens/microgame_select.tscn` → `play_single_microgame(path)`: `is_in_play_mode = false`, no lives (a loss goes straight to game over), no timer bar.

Each microgame is preceded by `ui/screens/microgame_intro.tscn`, which reads `GameManager.pending_intro_data`, shows title + control icons for `INTRO_DURATION`, then calls `GameManager.start_pending_microgame()`.

### Microgame contract

A microgame is a directory under `microgames/<name>/` containing a scene, its scripts, and a `<name>_data.tres` (`MicrogameData` resource: `title_key`, `scene`, `duration`, `controls: Array[ControlData]`, `show_cursor`). `title_key` is a translation key (`microgame.usb`), not text — see Localization. The `.tres` is the registration unit — scenes are never referenced by path outside it.

The root script of a microgame scene is responsible for the shared boilerplate (see `microgames/usb/usb.gd` for the minimal version):

```gdscript
const TimerBarScene: PackedScene = preload("res://ui/overlays/timer_bar.tscn")

func _ready() -> void:
	if GameManager.is_in_play_mode:   # timer bar ONLY in play mode
		_setup_timer_bar()            # instantiate into a fresh CanvasLayer child

func _on_time_up() -> void:
	GameManager.notify_microgame_timed_out()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		GameManager.try_open_pause_menu()
```

Outcomes are reported only via `GameManager.notify_microgame_won() / _lost() / _timed_out()` — a microgame never changes scenes itself. Most microgames keep a `has_finished: bool` guard so a win and a timeout can't both fire; `GameManager` also guards with `is_transitioning`.

**Adding a microgame** requires touching three places: the new `_data.tres`, `GameManager.MICROGAME_DATA_PATHS`, and `ui/screens/microgame_select.gd` + its scene (note: `_on_correct_password_pressed()` exists there but has no `@onready` button — CORRECT PASSWORD is reachable in play mode only).

### Transitions

`IrisTransition` (autoload, `CanvasLayer` + `core/transitions/iris_transition.gdshader`) animates a `progress` shader param. `transition_to_scene()` / `transition_to_packed_scene()` do iris-out → change scene → `_await_scene_ready()` → `GameManager.refresh_cursor()` → iris-in. `is_busy` blocks overlapping transitions (e.g. button spam). `_await_scene_ready()` polls up to 30 frames because Godot's scene change is deferred — `current_scene` is stale immediately after `change_scene_*`.

### Cursor and pause policy

Both are centralized in `GameManager` and keyed off `scene_file_path` string suffixes:
- `refresh_cursor()` — visible in main menu / select / game over; hidden in intro and life lost; otherwise falls back to the current `MicrogameData.show_cursor`.
- `_is_pausable_scene()` — everything except main menu, select, game over.

**A new menu scene must be added to both functions**, or it inherits the wrong cursor/pause behavior.

Pause is triggered by ESC (each microgame forwards `ui_cancel`) or by `NOTIFICATION_APPLICATION_FOCUS_OUT`. It sets `get_tree().paused = true` and shows `PauseMenu`. Resuming runs `CountdownOverlay.start_countdown(3)` and only then unpauses. Anything that must keep working while paused sets `process_mode = Node.PROCESS_MODE_ALWAYS` (`IrisTransition`, `PauseMenu`, `CountdownOverlay`, `OptionsMenu`, `SettingsManager`, and `AudioManager`'s player).

### Life loss

`_handle_life_loss()` decrements `lives` then transitions to `ui/screens/life_lost.tscn`. That scene reads the **already-decremented** `GameManager.lives` to know which heart to break (it renders `lives + 1` hearts and animates index `lives`), then calls back into `GameManager.continue_after_life_lost()`. Keep the decrement-before-transition ordering if you touch either side.

### UI audio

Never wire button sounds by hand — call `AudioManager.register_button_positive/neutral/back(button)` in `_ready()`. Positive = affirmative actions (play, retry), back = leaving (volver, salir), neutral = navigation.

### Audio buses

`default_bus_layout.tres` (repo root — Godot's default path, so no project.godot entry) defines **Master**, **Music** and **SFX**; the latter two send to Master. Every new `AudioStreamPlayer` must set `bus` to `Music` or `SFX`, never leave it on Master, or its slider won't reach it. `AudioManager`'s `ui_player` uses the `&"SFX"` literal rather than `SettingsManager.BUS_SFX` because `AudioManager` loads first in the autoload order.

### Localization

All UI text lives in `locales/<code>.json` — a flat `"key": "text"` file, one per language (`en.json`, `es.json`). `LocalizationManager` loads the active one and exposes `t(key)` / `t_format(key, values)` (the latter fills `{0}`, `{1}`).

**No translated string may be hardcoded in a script or a `.tscn`.** Scene `text =` properties hold the *key* (`text = "menu.play"`), and the screen's script overwrites it at runtime:

```gdscript
func _ready() -> void:
	_apply_texts()
	LocalizationManager.language_changed.connect(_apply_texts)

func _apply_texts() -> void:
	play_button.text = LocalizationManager.t("menu.play")
```

Connecting `language_changed` is what makes an already-open screen (the pause menu, the options menu) redraw when the player switches language. Godot drops the connection when the node is freed, so no cleanup is needed. One-shot screens that can't be open while the language changes (title, speed up, microgame intro) just set their text in `_ready()`.

Startup language: saved choice → `OS.get_locale_language()` if a locale file matches → `DEFAULT_LANGUAGE` (`en`).

**Adding a language** is dropping a new `locales/<code>.json` next to the others — `_scan_available_languages()` picks it up and the options dropdown lists it. Its `language.name` key is the name shown in that dropdown, written in its own language ("ESPAÑOL"), so languages are never translated between each other. Keys missing from a file render as the key itself, which is how you spot them.

The choice is saved to `user://settings.cfg` under `[language]`, the same file `SettingsManager` uses. Both managers reload the `ConfigFile` before writing so neither erases the other's section — keep that if you touch either `_save_*`.

Note `export_presets.cfg` sets `include_filter="*.json"`: without it the locale files stay out of the exported PCK.

### Settings

`SettingsManager` persists fullscreen (default on), window scale (default 2x) and per-bus volumes (default 0.8) to `user://settings.cfg`, applies all of them at boot, and owns the global F11 toggle. `OptionsMenu` mirrors them with `set_pressed_no_signal()` / `set_value_no_signal()` to avoid signal loops.

Volumes live in `volumes: Dictionary[StringName, float]` keyed by bus name, 0.0–1.0, converted with `linear_to_db()` and hard-muted below `SILENCE_THRESHOLD` (`linear_to_db(0.0)` is `-inf`). Sliders fire many times per second, so `set_bus_volume()` applies instantly but routes saving through a `SAVE_DEBOUNCE_SECONDS` one-shot Timer; `_exit_tree()` flushes a pending save on quit. Fullscreen and window scale still save immediately.

Window scale is an integer multiple of `BASE_RESOLUTION` (640×360) so pixels stay square — 1x/2x/3x = 360p/720p/1080p. 3x is the cap (`MAX_WINDOW_SCALE`) because 4x would be 1440p. It only applies in windowed mode; `_apply_fullscreen(false)` reapplies it on the way out, so that is the single place the window gets resized. Picking a scale while fullscreen just saves it — the window changes when fullscreen is turned off. Scales larger than the monitor's usable rect are disabled in the menu and sanitized on load.

## Layout

```
assets/             shared only — audio/ui/, fonts/, sprites/{icons,ui}/
core/data/          MicrogameData / ControlData + controls/*.tres
core/managers/      game / audio / settings / localization autoloads
locales/            en.json, es.json — every UI string, keyed
core/transitions/   iris transition: script + scene + its shader
ui/screens/         scenes you navigate to (splash, title, main_menu, select, intro, game_over, life_lost)
ui/overlays/        CanvasLayers drawn on top (pause_menu, options_menu, countdown_overlay, timer_bar)
microgames/<name>/  <name>.tscn + <name>.gd + <name>_data.tres + assets/ for art it owns
```

Assets used by exactly one microgame live in that microgame's `assets/`; `assets/` at the root is for genuinely shared things only.

## Conventions

- **Naming:** files and folders are `snake_case`, English, descriptive — no PascalCase, no hyphens, no Spanish. Scene root nodes are `PascalCase` matching the filename (`correct_password.tscn` → `CorrectPasswordMicrogame`), with acronyms title-cased (`Usb`, not `USB`). Name assets for what they are, not for the tool that made them.
- Explicit static types on every var, const, param, and return (`var lives: int = MAX_LIVES`). The codebase is uniformly typed — keep it.
- `GameManager` uses `# ===== SECCIÓN =====` banner comments; smaller scripts just group by concern.
- Tuning values are `const` at the top of the script, or `@export` when they're meant to be adjusted from the Inspector.
- Microgames are authored in a large internal space (~1152×648) and scaled down in the scene root (`position = (128, 72)`, `scale = 0.333`) to fit the 640×360 viewport. Coordinate constants inside microgame scripts refer to that internal space, not screen pixels.
- Display: 640×360 viewport, `viewport` stretch, `default_texture_filter = 0` (nearest) — pixel art, no filtering.
- Custom input action: `space_bar`. `ui_cancel` (ESC) is reserved for pause.
- `.godot/` is gitignored; `.tres`/`.tscn`/`.uid` files are tracked and must be committed alongside script changes.
- **Moving or renaming a file:** its sidecar goes with it — `.gd`/`.gdshader` carry a `.uid`, imported assets carry a `.import`. Never edit a `uid=` value; Godot resolves `uid://` before paths, so intact sidecars keep every `ext_resource` working. What does break is path strings with no uid behind them: `preload()`/`load()` literals, `GameManager`'s `MICROGAME_DATA_PATHS` and scene constants, `microgame_select.gd`'s hardcoded paths, `change_scene_to_file()` calls, and `source_file=` in `.import`. Renaming an asset also changes its import-cache name (`.godot/imported/<file>-<md5 of its res:// path>.<ext>`), so a reimport is required — `Godot.exe --headless --path . --import`, the one task the MCP server can't do.
