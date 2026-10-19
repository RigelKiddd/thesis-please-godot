class_name VisitorPortrait
extends Control

## A visitor registration photo mounted on the desk.  The main game already has
## a set of hand-drawn student portraits; reuse one as a sepia contact print and
## add a paper matte, corner mounts and a red "来访" stamp.  The result reads as
## a different person from the student currently sitting across the desk while
## staying in the same ink-and-paper world.

var role: Dictionary = {}
var display_name := ""
var accent := Color("#8b382b")
var _texture: Texture2D = null

const FACES := {
	"director": "d4s4",
	"leader": "d3s2",
	"discipline": "d3s4",
	"colleague": "d2s4",
	"counselor": "d2s3",
	"recruiter": "d4s1",
	"student": "d5s3",
}

const FALLBACK_FACES := [
	"d2s3", "d3s2", "d4s4", "d2s4", "d4s1", "d5s3", "d3s4", "d1s2",
]


func setup(role_data: Dictionary, name_text: String) -> void:
	role = role_data
	display_name = name_text
	accent = _role_color(str(role.get("id", "")))
	custom_minimum_size = Vector2(78, 106)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_texture = null
	var key := _face_key()
	if key != "":
		var path := "res://assets/portraits/%s.png" % key
		if ResourceLoader.exists(path):
			_texture = load(path)
	queue_redraw()


func _face_key() -> String:
	var id := str(role.get("id", ""))
	if FACES.has(id):
		return str(FACES[id])
	if display_name == "":
		return ""
	var h: int = absi(display_name.hash())
	return str(FALLBACK_FACES[h % FALLBACK_FACES.size()])


func _role_color(id: String) -> Color:
	match id:
		"leader":
			return Color("#2f4a6d")
		"director":
			return Color("#6f4a2c")
		"discipline":
			return Color("#8b382b")
		"colleague":
			return Color("#4f6a4c")
		"counselor":
			return Color("#3f6b45")
		"recruiter":
			return Color("#7a5c1e")
	return Color("#5e4d32")


func _draw() -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(Vector2(3, 4), size), Color(0, 0, 0, 0.40))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#e9ddc2"))
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1b1710"), false, 2)
	var photo := Rect2(Vector2(8, 8), Vector2(w - 16, h - 16))
	draw_rect(Rect2(photo.position - Vector2(2, 2), photo.size + Vector2(4, 4)), Color("#cbbd9d"))
	if _texture != null:
		var tw := float(_texture.get_width())
		var th := float(_texture.get_height())
		var scale := maxf(photo.size.x / tw, photo.size.y / th)
		var src_w := photo.size.x / scale
		var src_h := photo.size.y / scale
		var src := Rect2((tw - src_w) * 0.5, 0.0, src_w, src_h)
		draw_texture_rect_region(_texture, photo, src, Color(1.0, 0.965, 0.895, 1.0))
		# Warm the print, then darken its edges into the paper.
		draw_rect(photo, Color(0.42, 0.30, 0.15, 0.055))
		var edge := 7.0
		draw_rect(Rect2(photo.position, Vector2(edge, photo.size.y)), Color(0.10, 0.07, 0.03, 0.18))
		draw_rect(Rect2(photo.position + Vector2(photo.size.x - edge, 0), Vector2(edge, photo.size.y)), Color(0.10, 0.07, 0.03, 0.18))
		draw_rect(Rect2(photo.position, Vector2(photo.size.x, edge)), Color(0.10, 0.07, 0.03, 0.14))
		draw_rect(Rect2(photo.position + Vector2(0, photo.size.y - edge), Vector2(photo.size.x, edge)), Color(0.10, 0.07, 0.03, 0.22))
	else:
		draw_rect(photo, Color("#d8c8a6"))
		draw_line(Vector2(photo.position.x + 18, photo.position.y + photo.size.y * 0.58),
			Vector2(photo.position.x + photo.size.x - 18, photo.position.y + photo.size.y * 0.58),
			Color(0.45, 0.38, 0.25, 0.28), 1)
		draw_string(Ui.F_UI_BOLD, Vector2(photo.position.x, photo.position.y + photo.size.y * 0.5),
			"等 待 来 访", HORIZONTAL_ALIGNMENT_CENTER, photo.size.x, 9, Color("#8a7752"))
	draw_rect(photo, Color("#2b2418"), false, 2)
	# Photo-album corner mounts.
	var mount := Color("#4a3b28")
	var arm := 9.0
	for p in [photo.position, Vector2(photo.end.x, photo.position.y),
			Vector2(photo.position.x, photo.end.y), photo.end]:
		var sx := 1.0 if p.x < photo.position.x + 1.0 else -1.0
		var sy := 1.0 if p.y < photo.position.y + 1.0 else -1.0
		draw_line(p, p + Vector2(arm * sx, 0), mount, 2)
		draw_line(p, p + Vector2(0, arm * sy), mount, 2)
	# A small red visitor stamp on the photo, plus the role seal in the corner.
	if !role.is_empty():
		var stamp := Rect2(Vector2(14, h - 53), Vector2(34, 14))
		draw_rect(stamp, Color(0.66, 0.20, 0.16, 0.08))
		draw_rect(stamp, Color(0.66, 0.20, 0.16, 0.82), false, 1)
		draw_string(Ui.F_UI_BOLD, Vector2(stamp.position.x, stamp.position.y + 10.5),
			"来 访", HORIZONTAL_ALIGNMENT_CENTER, stamp.size.x, 7, Color("#a83a2f"))
		var seal := Rect2(Vector2(w - 30, h - 33), Vector2(20, 17))
		draw_rect(seal, Color(accent.r, accent.g, accent.b, 0.12))
		draw_rect(seal, Color(accent.r, accent.g, accent.b, 0.86), false, 1)
		var seal_text := str(role.get("seal", ""))
		if seal_text != "":
			draw_string(Ui.F_UI_BOLD, Vector2(seal.position.x, seal.position.y + 12.5),
				seal_text, HORIZONTAL_ALIGNMENT_CENTER, seal.size.x, 9, accent)
	draw_string(Ui.F_MONO, Vector2(8, h - 4), "VISITOR / 03", HORIZONTAL_ALIGNMENT_LEFT, 80, 5.5,
		Color(0.35, 0.28, 0.17, 0.72))
