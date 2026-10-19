class_name PixelPanel
extends Control

## A crisp, offset-shadow panel in the style of the original CSS boxes.

@export var bg_color: Color = Color(0, 0, 0, 0)
@export var bg_texture: Texture2D = null
@export var border_width: int = 0
@export var border_widths: Vector4i = Vector4i(-1, -1, -1, -1)  # left, top, right, bottom; -1 = uniform
@export var border_color: Color = Color(0, 0, 0, 1)
@export var shadow_offset: Vector2 = Vector2.ZERO
@export var shadow_color: Color = Color(0, 0, 0, 0.38)
@export var inner_highlight: Color = Color(0, 0, 0, 0)
@export var dashed: bool = false
@export var dash_length: float = 6.0
@export var stripe_width: float = 0.0
@export var stripe_color: Color = Color(0, 0, 0, 0)
@export var top_glow: Color = Color(0, 0, 0, 0)
@export var bottom_edge: Color = Color(0, 0, 0, 0)
@export var bottom_edge_height: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	if shadow_offset != Vector2.ZERO and shadow_color.a > 0.0:
		draw_rect(Rect2(shadow_offset, size), shadow_color)
	if bg_texture != null:
		draw_texture_rect(bg_texture, r, true)
	elif bg_color.a > 0.0:
		draw_rect(r, bg_color)
	if stripe_width > 0.0 and stripe_color.a > 0.0:
		var x := 0.0
		while x < size.x:
			draw_rect(Rect2(x, 0, stripe_width, size.y), stripe_color)
			x += stripe_width * 2.0
	if top_glow.a > 0.0:
		draw_rect(Rect2(0, 0, size.x, max(1.0, size.y * 0.3)), top_glow)
	if bottom_edge_height > 0.0 and bottom_edge.a > 0.0:
		draw_rect(Rect2(0, size.y - bottom_edge_height, size.x, bottom_edge_height), bottom_edge)
	if border_widths.x >= 0:
		var bw := border_widths
		if bw.y > 0:
			draw_rect(Rect2(0, 0, size.x, bw.y), border_color)
		if bw.w > 0:
			draw_rect(Rect2(0, size.y - bw.w, size.x, bw.w), border_color)
		if bw.x > 0:
			draw_rect(Rect2(0, 0, bw.x, size.y), border_color)
		if bw.z > 0:
			draw_rect(Rect2(size.x - bw.z, 0, bw.z, size.y), border_color)
	elif border_width > 0:
		if dashed:
			_draw_dashed(r)
		else:
			draw_rect(r, border_color, false, border_width)
		if inner_highlight.a > 0.0:
			draw_rect(r.grow(-border_width), inner_highlight, false, 1.0)

func _draw_dashed(r: Rect2) -> void:
	var w := border_width
	var x := 0.0
	while x < r.size.x:
		var x2: float = min(x + dash_length, r.size.x)
		draw_line(Vector2(x, 0), Vector2(x2, 0), border_color, w)
		draw_line(Vector2(x, r.size.y), Vector2(x2, r.size.y), border_color, w)
		x += dash_length * 2.0
	var y := 0.0
	while y < r.size.y:
		var y2: float = min(y + dash_length, r.size.y)
		draw_line(Vector2(0, y), Vector2(0, y2), border_color, w)
		draw_line(Vector2(r.size.x, y), Vector2(r.size.x, y2), border_color, w)
		y += dash_length * 2.0
