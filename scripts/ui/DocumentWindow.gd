extends "res://scripts/PixelPanel.gd"

## Reusable paper-window shell. Callers supply content and task actions.
signal archive_requested
@export var request_size := Vector2(520, 500)
@export var attachment_size := Vector2(460, 350)

var header: PixelPanel:
	get: return $Header
var body: ScrollContainer:
	get: return $Body
var footer: PixelPanel:
	get: return $Footer

func configure(request: bool, primary: bool = false) -> void:
	size = request_size if request else attachment_size
	mouse_filter = Control.MOUSE_FILTER_STOP
	header.bg_color = Color("#6f4e2f") if !request or primary else Color("#4c3a27")
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	header.mouse_default_cursor_shape = Control.CURSOR_DRAG
	Ui.place(header, 0, 0, size.x, 34 if request else 32)
	if request:
		Ui.place(body, 3, 37, 514, 348 if primary else 430)
		Ui.place(footer, 0, 385 if primary else 470, 520, 115 if primary else 30)
	else:
		Ui.place(body, 3, 35, 454, 296)
		Ui.place(footer, 0, 331, 460, 19)
	footer.bg_color = Color("#433120") if primary else Color("#cdbd95")
	footer.border_color = Color("#17130d") if primary else Color(27 / 255.0, 20 / 255.0, 12 / 255.0, 0.55)
	footer.queue_redraw()
	header.queue_redraw()
	var archive: Button = $Header/Archive
	Ui.place(archive, 440 if request else 410, 6, 72 if request else 42, 22 if request else 20)
	Ui.style_button(archive, "归档", 8 if request else 7, 22 if request else 20, Color("#dac9a4"), Color("#2c2116"), Color("#17130d"), Ui.F_UI_BOLD if request else Ui.F_PIXEL)
	archive.pressed.connect(func(): archive_requested.emit())

func scroll_value() -> int:
	return body.scroll_vertical

func restore_scroll(value: int) -> void:
	body.set_deferred("scroll_vertical", value)
