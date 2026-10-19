extends Control

## Small drawn pictograms used instead of a single Chinese character on material
## cards, file headers and drag ghosts. Everything is line art so it stays inside
## the existing paper / ink / red-seal palette.

var kind := "form"
var ink := Color("#5d472a")

func configure(kind_name: String, color: Color) -> void:
	kind = kind_name
	ink = color
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()

static func key_for_doc(doc: Dictionary) -> String:
	var id := str(doc.get("id", "")).to_lower()
	if id.contains("clinic") or id.contains("medical") or id.contains("health"):
		return "medical"
	if id.contains("leave") or id.contains("absence"):
		return "leave"
	if id.contains("schedule") or id.contains("defense") or id.contains("conflict"):
		return "schedule"
	if id.contains("risk") or id.contains("safety"):
		return "risk"
	if id.contains("agreement") or id.contains("contract"):
		return "contract"
	if id.contains("recommend"):
		return "recommend"
	if id.contains("passport") or id.contains("visa"):
		return "passport"
	if id.contains("transcript") or id.contains("score") or id.contains("report"):
		return "report"
	if id.contains("notice") or id.contains("public"):
		return "notice"
	if id.contains("quota") or id.contains("ranking") or id.contains("roster"):
		return "roster"
	if id.contains("offer") or id.contains("admission") or id.contains("letter"):
		return "envelope"
	if id.contains("ledger") or id.contains("fee") or id.contains("tuition"):
		return "ledger"
	if id.contains("boarding") or id.contains("ticket"):
		return "ticket"
	if id.contains("lab") or id.contains("experiment"):
		return "lab"
	if id.contains("exchange"):
		return "exchange"
	if id.contains("internship") or id.contains("career"):
		return "briefcase"
	var k := str(doc.get("kind", ""))
	match k:
		"leave": return "leave"
		"transcript", "report": return "report"
		"notice": return "notice"
		"quota": return "roster"
		"recommend": return "recommend"
		"passport": return "passport"
		"id_card": return "id"
		"offer": return "envelope"
		"email": return "email"
		"result": return "night"
		"certificate": return "seal"
		"application": return "form"
		"slip": return "form"
	var icon := str(doc.get("icon", ""))
	match icon:
		"假": return "leave"
		"诊": return "medical"
		"奖", "优": return "recommend"
		"护": return "passport"
		"荐": return "recommend"
		"验": return "lab"
		"换": return "exchange"
		"审": return "seal"
		"函": return "envelope"
		"协": return "contract"
		"辩", "期": return "schedule"
		"评": return "risk"
		"安": return "risk"
		"语", "绩": return "report"
		"示": return "notice"
		"开": return "report"
		"导": return "envelope"
		"伦": return "seal"
		"学": return "ledger"
		"批": return "night"
		"邮": return "email"
	var style := str(doc.get("style", ""))
	match style:
		"student_id", "id_card": return "id"
		"passport": return "passport"
		"admission": return "envelope"
		"scholarship": return "recommend"
		"ledger": return "ledger"
		"index_card": return "roster"
		"boarding": return "ticket"
		"sealed": return "report"
		"mimeo": return "notice"
		"carbonless": return "form"
		"cardstock": return "form"
	return "form"

func _draw() -> void:
	var w := size.x
	var h := size.y
	if w < 2 or h < 2:
		return
	var c := ink
	var lw := maxf(1.0, minf(w, h) * 0.045)
	var cx := w * 0.5
	var cy := h * 0.5
	var page := Rect2(w * 0.2, h * 0.12, w * 0.58, h * 0.74)
	match kind:
		"leave":
			_calendar(w, h, c, lw)
		"medical":
			_medical(w, h, c, lw)
		"report":
			_page(c, lw)
			for i in range(4):
				var y := h * (0.36 + i * 0.12)
				draw_line(Vector2(w * 0.31, y), Vector2(w * (0.66 if i < 3 else 0.55), y), c, lw)
		"notice":
			_page(c, lw)
			draw_line(Vector2(w * 0.3, h * 0.48), Vector2(w * 0.46, h * 0.40), c, lw)
			draw_line(Vector2(w * 0.3, h * 0.60), Vector2(w * 0.46, h * 0.52), c, lw)
			draw_line(Vector2(w * 0.46, h * 0.40), Vector2(w * 0.46, h * 0.52), c, lw)
			draw_line(Vector2(w * 0.55, h * 0.38), Vector2(w * 0.73, h * 0.34), c, lw)
			draw_line(Vector2(w * 0.55, h * 0.46), Vector2(w * 0.68, h * 0.44), c, lw)
		"roster":
			_page(c, lw)
			for i in range(3):
				draw_circle(Vector2(w * 0.32, h * (0.36 + i * 0.15)), w * 0.035, c)
				draw_line(Vector2(w * 0.4, h * (0.36 + i * 0.15)), Vector2(w * 0.69, h * (0.36 + i * 0.15)), c, lw)
		"recommend":
			draw_circle(Vector2(cx * 0.98, h * 0.36), w * 0.14, c, false, lw)
			draw_line(Vector2(cx * 0.88, h * 0.47), Vector2(cx * 0.78, h * 0.74), c, lw)
			draw_line(Vector2(cx * 1.08, h * 0.47), Vector2(cx * 1.18, h * 0.74), c, lw)
			draw_line(Vector2(cx * 0.88, h * 0.47), Vector2(cx * 1.08, h * 0.47), c, lw)
			draw_circle(Vector2(cx * 0.98, h * 0.36), w * 0.055, c)
		"seal":
			_page(c, lw)
			draw_circle(Vector2(w * 0.64, h * 0.68), w * 0.13, c, false, lw)
			draw_line(Vector2(w * 0.57, h * 0.68), Vector2(w * 0.62, h * 0.73), c, lw)
			draw_line(Vector2(w * 0.62, h * 0.73), Vector2(w * 0.72, h * 0.61), c, lw)
		"passport":
			draw_rect(Rect2(w * 0.2, h * 0.12, w * 0.58, h * 0.76), c, false, lw)
			draw_line(Vector2(w * 0.27, h * 0.2), Vector2(w * 0.27, h * 0.8), c, lw)
			draw_circle(Vector2(cx * 1.05, cy * 0.98), w * 0.17, c, false, lw)
			draw_line(Vector2(cx * 1.05, h * 0.32), Vector2(cx * 1.05, h * 0.64), c, lw)
			draw_line(Vector2(w * 0.38, h * 0.48), Vector2(w * 0.72, h * 0.48), c, lw)
		"id":
			draw_rect(Rect2(w * 0.12, h * 0.26, w * 0.76, h * 0.48), c, false, lw)
			draw_circle(Vector2(w * 0.33, h * 0.44), w * 0.07, c)
			draw_line(Vector2(w * 0.23, h * 0.62), Vector2(w * 0.43, h * 0.62), c, lw)
			draw_line(Vector2(w * 0.52, h * 0.42), Vector2(w * 0.76, h * 0.42), c, lw)
			draw_line(Vector2(w * 0.52, h * 0.53), Vector2(w * 0.7, h * 0.53), c, lw)
		"envelope":
			draw_rect(Rect2(w * 0.14, h * 0.26, w * 0.72, h * 0.48), c, false, lw)
			draw_line(Vector2(w * 0.14, h * 0.26), Vector2(w * 0.5, h * 0.54), c, lw)
			draw_line(Vector2(w * 0.86, h * 0.26), Vector2(w * 0.5, h * 0.54), c, lw)
		"ledger":
			draw_rect(Rect2(w * 0.16, h * 0.18, w * 0.66, h * 0.64), c, false, lw)
			draw_line(Vector2(w * 0.37, h * 0.18), Vector2(w * 0.37, h * 0.82), c, lw)
			for i in range(3):
				var y := h * (0.32 + i * 0.16)
				draw_line(Vector2(w * 0.21, y), Vector2(w * 0.33, y), c, lw)
				draw_line(Vector2(w * 0.43, y), Vector2(w * 0.76, y), c, lw)
			draw_circle(Vector2(w * 0.68, h * 0.62), w * 0.07, c, false, lw)
		"ticket":
			draw_rect(Rect2(w * 0.12, h * 0.3, w * 0.76, h * 0.4), c, false, lw)
			draw_line(Vector2(w * 0.68, h * 0.3), Vector2(w * 0.68, h * 0.7), c, lw)
			for i in range(3):
				draw_circle(Vector2(w * 0.74, h * (0.4 + i * 0.1)), w * 0.02, c)
			draw_line(Vector2(w * 0.2, h * 0.42), Vector2(w * 0.5, h * 0.42), c, lw)
			draw_line(Vector2(w * 0.2, h * 0.53), Vector2(w * 0.55, h * 0.53), c, lw)
		"exchange":
			draw_circle(Vector2(cx, cy), w * 0.28, c, false, lw)
			draw_line(Vector2(cx, h * 0.22), Vector2(cx, h * 0.78), c, lw)
			draw_line(Vector2(w * 0.22, cy), Vector2(w * 0.78, cy), c, lw)
			draw_arc(Vector2(cx, cy), w * 0.28, -0.9, 0.9, 10, c, lw)
			draw_arc(Vector2(cx, cy), w * 0.28, 2.25, 4.05, 10, c, lw)
			draw_line(Vector2(w * 0.58, h * 0.16), Vector2(w * 0.76, h * 0.16), c, lw)
			draw_line(Vector2(w * 0.76, h * 0.16), Vector2(w * 0.69, h * 0.11), c, lw)
			draw_line(Vector2(w * 0.76, h * 0.16), Vector2(w * 0.69, h * 0.21), c, lw)
		"lab":
			draw_line(Vector2(w * 0.4, h * 0.16), Vector2(w * 0.6, h * 0.16), c, lw)
			draw_line(Vector2(w * 0.44, h * 0.16), Vector2(w * 0.44, h * 0.4), c, lw)
			draw_line(Vector2(w * 0.56, h * 0.16), Vector2(w * 0.56, h * 0.4), c, lw)
			draw_polyline(PackedVector2Array([Vector2(w * 0.44, h * 0.4), Vector2(w * 0.26, h * 0.76), Vector2(w * 0.25, h * 0.84), Vector2(w * 0.75, h * 0.84), Vector2(w * 0.74, h * 0.76), Vector2(w * 0.56, h * 0.4)]), c, lw)
			draw_line(Vector2(w * 0.34, h * 0.68), Vector2(w * 0.66, h * 0.68), c, lw)
			draw_circle(Vector2(w * 0.42, h * 0.58), w * 0.03, c)
			draw_circle(Vector2(w * 0.5, h * 0.5), w * 0.025, c)
		"briefcase":
			draw_rect(Rect2(w * 0.16, h * 0.36, w * 0.68, h * 0.44), c, false, lw)
			draw_line(Vector2(w * 0.38, h * 0.36), Vector2(w * 0.38, h * 0.25), c, lw)
			draw_line(Vector2(w * 0.62, h * 0.36), Vector2(w * 0.62, h * 0.25), c, lw)
			draw_line(Vector2(w * 0.38, h * 0.25), Vector2(w * 0.62, h * 0.25), c, lw)
			draw_line(Vector2(w * 0.16, h * 0.52), Vector2(w * 0.84, h * 0.52), c, lw)
			draw_circle(Vector2(w * 0.5, h * 0.56), w * 0.035, c)
		"email":
			draw_rect(Rect2(w * 0.14, h * 0.28, w * 0.72, h * 0.44), c, false, lw)
			draw_line(Vector2(w * 0.14, h * 0.28), Vector2(w * 0.5, h * 0.54), c, lw)
			draw_line(Vector2(w * 0.86, h * 0.28), Vector2(w * 0.5, h * 0.54), c, lw)
			draw_arc(Vector2(w * 0.5, h * 0.5), w * 0.1, 0.4, 5.8, 12, c, lw)
		"night":
			draw_arc(Vector2(w * 0.46, h * 0.5), w * 0.26, -1.3, 1.3, 12, c, lw)
			draw_arc(Vector2(w * 0.58, h * 0.5), w * 0.24, 1.9, 4.4, 12, c, lw)
			for p in [Vector2(0.72, 0.28), Vector2(0.82, 0.42), Vector2(0.7, 0.7)]:
				draw_circle(Vector2(w * p.x, h * p.y), w * 0.025, c)
		"contract":
			_page(c, lw)
			draw_line(Vector2(w * 0.3, h * 0.62), Vector2(w * 0.5, h * 0.62), c, lw)
			draw_line(Vector2(w * 0.3, h * 0.72), Vector2(w * 0.62, h * 0.72), c, lw)
			draw_circle(Vector2(w * 0.64, h * 0.68), w * 0.11, c, false, lw)
		"schedule":
			_calendar(w, h, c, lw)
			draw_circle(Vector2(w * 0.66, h * 0.66), w * 0.15, c, false, lw)
			draw_line(Vector2(w * 0.66, h * 0.66), Vector2(w * 0.66, h * 0.55), c, lw)
			draw_line(Vector2(w * 0.66, h * 0.66), Vector2(w * 0.75, h * 0.7), c, lw)
		"risk":
			_page(c, lw)
			draw_polyline(PackedVector2Array([Vector2(w * 0.5, h * 0.3), Vector2(w * 0.32, h * 0.66), Vector2(w * 0.68, h * 0.66), Vector2(w * 0.5, h * 0.3)]), c, lw)
			draw_line(Vector2(w * 0.5, h * 0.41), Vector2(w * 0.5, h * 0.55), c, lw)
			draw_circle(Vector2(w * 0.5, h * 0.61), w * 0.025, c)
		_:
			_page(c, lw)
			for i in range(3):
				var y := h * (0.38 + i * 0.13)
				draw_line(Vector2(w * 0.3, y), Vector2(w * 0.65, y), c, lw)
			draw_rect(Rect2(w * 0.3, h * 0.66, w * 0.14, h * 0.08), c, false, lw)

func _page(c: Color, lw: float) -> void:
	var w := size.x
	var h := size.y
	draw_rect(Rect2(w * 0.2, h * 0.12, w * 0.58, h * 0.74), c, false, lw)
	draw_line(Vector2(w * 0.62, h * 0.12), Vector2(w * 0.78, h * 0.28), c, lw)
	draw_line(Vector2(w * 0.62, h * 0.12), Vector2(w * 0.62, h * 0.28), c, lw)
	draw_line(Vector2(w * 0.62, h * 0.28), Vector2(w * 0.78, h * 0.28), c, lw)

func _calendar(w: float, h: float, c: Color, lw: float) -> void:
	draw_rect(Rect2(w * 0.18, h * 0.24, w * 0.64, h * 0.56), c, false, lw)
	draw_line(Vector2(w * 0.18, h * 0.4), Vector2(w * 0.82, h * 0.4), c, lw)
	draw_line(Vector2(w * 0.34, h * 0.17), Vector2(w * 0.34, h * 0.3), c, lw)
	draw_line(Vector2(w * 0.66, h * 0.17), Vector2(w * 0.66, h * 0.3), c, lw)
	for p in [Vector2(0.32, 0.52), Vector2(0.5, 0.52), Vector2(0.68, 0.52), Vector2(0.32, 0.66), Vector2(0.5, 0.66)]:
		draw_circle(Vector2(w * p.x, h * p.y), w * 0.035, c)

func _medical(w: float, h: float, c: Color, lw: float) -> void:
	draw_circle(Vector2(w * 0.5, h * 0.46), w * 0.24, c, false, lw)
	draw_line(Vector2(w * 0.5, h * 0.3), Vector2(w * 0.5, h * 0.62), c, lw)
	draw_line(Vector2(w * 0.34, h * 0.46), Vector2(w * 0.66, h * 0.46), c, lw)
	draw_line(Vector2(w * 0.34, h * 0.76), Vector2(w * 0.66, h * 0.76), c, lw)
