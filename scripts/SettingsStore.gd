extends RefCounted

const UserDataCtl := preload("res://scripts/UserData.gd")

## Accessibility + audio preferences, persisted separately from the run save.
##
## ui_scale resizes the window around the fixed 1380x860 canvas (canvas_items
## stretch), so the whole desk grows without reflowing the hand-placed layout.
## reduce_motion suppresses screen shake and full-screen flashes.
## text_speed scales the typewriter and WeChat pacing.

static var PATH := UserDataCtl.file("settings.cfg")

static var ui_scale := 1.0
static var text_scale := 1.0
static var reduce_motion := false
static var text_speed := "normal"
static var muted := false
static var portrait_shader := true
static var metrics_enabled := true
static var loaded := false

static func load_settings() -> void:
	if loaded:
		return
	loaded = true
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	ui_scale = clampf(float(cfg.get_value("display", "ui_scale", 1.0)), 1.0, 1.5)
	text_scale = clampf(float(cfg.get_value("display", "text_scale", 1.0)), 1.0, 1.25)
	reduce_motion = bool(cfg.get_value("access", "reduce_motion", false))
	portrait_shader = bool(cfg.get_value("display", "portrait_shader", true))
	metrics_enabled = bool(cfg.get_value("access", "metrics_enabled", true))
	muted = bool(cfg.get_value("audio", "muted", false))
	var sp := str(cfg.get_value("access", "text_speed", "normal"))
	text_speed = sp if sp in ["slow", "normal", "fast"] else "normal"

static func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("display", "ui_scale", ui_scale)
	cfg.set_value("display", "text_scale", text_scale)
	cfg.set_value("display", "portrait_shader", portrait_shader)
	cfg.set_value("access", "reduce_motion", reduce_motion)
	cfg.set_value("access", "text_speed", text_speed)
	cfg.set_value("access", "metrics_enabled", metrics_enabled)
	cfg.set_value("audio", "muted", muted)
	cfg.save(PATH)

static func speed_factor() -> float:
	match text_speed:
		"slow":
			return 0.65
		"fast":
			return 1.8
	return 1.0

static func type_interval() -> float:
	return 0.024 / speed_factor()

static func chat_delay(base: float) -> float:
	return base / speed_factor()

static func scale_percent() -> String:
	return "%d%%" % int(round(ui_scale * 100.0))

static func text_scale_percent() -> String:
	return "%d%%" % int(round(text_scale * 100.0))

static func cycle_text_scale() -> float:
	var values := [1.0, 1.15, 1.25]
	var idx := values.find(text_scale)
	if idx == -1:
		idx = 0
	text_scale = values[(idx + 1) % values.size()]
	save_settings()
	return text_scale

static func speed_label() -> String:
	match text_speed:
		"slow":
			return "慢"
		"fast":
			return "快"
	return "正常"

static func apply_window(window: Window) -> void:
	if window == null:
		return
	if DisplayServer.get_name() == "headless":
		return
	if window.mode != Window.MODE_WINDOWED:
		return
	var usable := DisplayServer.screen_get_usable_rect(window.current_screen)
	var s := ui_scale
	var w := int(round(1380.0 * s))
	var h := int(round(860.0 * s))
	if usable.size.x > 0 and w > usable.size.x - 40:
		s = float(usable.size.x - 40) / 1380.0
	if usable.size.y > 0 and h > usable.size.y - 80:
		s = minf(s, float(usable.size.y - 80) / 860.0)
	s = clampf(s, 1.0, 1.5)
	window.size = Vector2i(int(round(1380.0 * s)), int(round(860.0 * s)))
	window.position = Vector2i(
		usable.position.x + maxi(0, (usable.size.x - window.size.x) / 2),
		usable.position.y + maxi(0, (usable.size.y - window.size.y) / 2))

static func set_scale(main, value: float) -> void:
	ui_scale = clampf(value, 1.0, 1.5)
	apply_window(main.get_window())
	save_settings()

static func cycle_scale(main) -> void:
	var values := [1.0, 1.25, 1.5]
	var idx := values.find(ui_scale)
	if idx == -1:
		idx = 0
	ui_scale = values[(idx + 1) % values.size()]
	apply_window(main.get_window())
	save_settings()

static func cycle_text_speed() -> void:
	var values := ["slow", "normal", "fast"]
	var idx := values.find(text_speed)
	if idx == -1:
		idx = 1
	text_speed = values[(idx + 1) % values.size()]
	save_settings()

static func toggle_motion() -> void:
	reduce_motion = !reduce_motion
	save_settings()

static func toggle_portrait_shader() -> bool:
	portrait_shader = !portrait_shader
	save_settings()
	return portrait_shader

static func toggle_metrics() -> bool:
	metrics_enabled = !metrics_enabled
	save_settings()
	return metrics_enabled

static func toggle_muted() -> bool:
	muted = !muted
	save_settings()
	return muted
