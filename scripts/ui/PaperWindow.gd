class_name PaperWindow
extends RefCounted

## Shared drag / snap / position-memory controller for paper windows.
##
## It deliberately does not own the card's layout or buttons: a window can
## start life inside a CenterContainer and is reparented to a loose full-screen
## host on the first drag, so existing modal layouts keep working.

const EDGE := 10.0
const SNAP := 26.0
const TOP := 64.0

static var _positions: Dictionary = {}

var card: Control
var host: Control
var id: String
var dragging := false
var moved := false
var drag_offset := Vector2.ZERO
var _base_shadow := Vector2.ZERO
var _shadow_saved := false
var _lift_tween: Tween
var grip: Control

static func attach(target: Control, loose_host: Control, window_id: String) -> PaperWindow:
	var existing: Variant = target.get_meta("paper_window", null) if target.has_meta("paper_window") else null
	if existing is PaperWindow:
		return existing
	var pw := PaperWindow.new()
	pw.card = target
	pw.host = loose_host
	pw.id = window_id
	target.set_meta("paper_window", pw)
	target.gui_input.connect(pw._on_input)
	target.item_rect_changed.connect(pw._update_grip)
	target.mouse_default_cursor_shape = Control.CURSOR_DRAG
	pw._add_grip()
	pw._update_grip.call_deferred()
	return pw

func _add_grip() -> void:
	grip = Control.new()
	grip.name = "PaperGrip"
	grip.position = Vector2(7, 7)
	grip.size = Vector2(20, 22)
	grip.mouse_filter = Control.MOUSE_FILTER_STOP
	grip.mouse_default_cursor_shape = Control.CURSOR_DRAG
	grip.z_index = 90
	grip.gui_input.connect(_on_input)
	for i in range(3):
		var dot := ColorRect.new()
		dot.color = Color(111 / 255.0, 90 / 255.0, 60 / 255.0, 0.78)
		dot.position = Vector2(8, 5 + i * 4)
		dot.size = Vector2(3, 3)
		dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
		grip.add_child(dot)
	host.add_child(grip)

func _update_grip() -> void:
	if is_instance_valid(grip) and is_instance_valid(card) and is_instance_valid(host):
		grip.position = host.get_global_transform().affine_inverse() * (card.global_position + Vector2(7, 7))

static func forget(window_id: String) -> void:
	_positions.erase(window_id)

static func remembered(window_id: String) -> Variant:
	return _positions.get(window_id, null)

func _on_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index != MOUSE_BUTTON_LEFT:
			return
		if mb.pressed:
			_begin(mb.global_position)
			card.accept_event()
		elif dragging:
			_end()
			card.accept_event()
	elif event is InputEventMouseMotion and dragging:
		var mm := event as InputEventMouseMotion
		if !moved:
			moved = true
			_lift_to_host()
		var at := mm.global_position + drag_offset
		card.position = _clamp(host.get_global_transform().affine_inverse() * at)
		_update_grip()
		card.queue_redraw()
		card.accept_event()

func _begin(global_mouse: Vector2) -> void:
	dragging = true
	moved = false
	drag_offset = card.global_position - global_mouse
	card.move_to_front()
	_update_grip()
	card.pivot_offset = card.size * 0.5
	var pp := card as PixelPanel
	if pp != null:
		_base_shadow = pp.shadow_offset
		_shadow_saved = true
		pp.shadow_offset = _base_shadow + Vector2(3, 4)
		pp.queue_redraw()
	card.modulate = Color(1.03, 1.03, 1.03, 1.0)
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = card.create_tween()
	_lift_tween.tween_property(card, "scale", Vector2(1.012, 1.012), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _lift_to_host() -> void:
	if card.get_parent() == host:
		return
	var global := card.global_position
	card.reparent(host)
	host.move_child(card, host.get_child_count() - 1)
	card.position = host.get_global_transform().affine_inverse() * global
	card.pivot_offset = card.size * 0.5
	_update_grip()

func _end() -> void:
	dragging = false
	var p := card.position
	if moved:
		var max_x := maxf(EDGE, host.size.x - card.size.x - EDGE)
		var max_y := maxf(TOP, host.size.y - card.size.y - EDGE)
		if p.x < EDGE + SNAP:
			p.x = EDGE
		elif p.x > max_x - SNAP:
			p.x = max_x
		if p.y < TOP + SNAP:
			p.y = TOP
		elif p.y > max_y - SNAP:
			p.y = max_y
		_positions[id] = p
	var tw := card.create_tween().set_parallel(true)
	tw.tween_property(card, "scale", Vector2.ONE, 0.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "position", p, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(card, "modulate", Color.WHITE, 0.14)
	var pp := card as PixelPanel
	if pp != null and _shadow_saved:
		pp.shadow_offset = _base_shadow
		pp.queue_redraw()
	_update_grip()
	moved = false

func _clamp(at: Vector2) -> Vector2:
	var max_x := maxf(EDGE, host.size.x - card.size.x - EDGE)
	var max_y := maxf(TOP, host.size.y - card.size.y - EDGE)
	return Vector2(clampf(at.x, EDGE, max_x), clampf(at.y, TOP, max_y))

func sync_grip() -> void:
	_update_grip()

func apply_memory() -> bool:
	var p: Variant = _positions.get(id, null)
	if p == null:
		_update_grip()
		return false
	if card.get_parent() != host:
		var global := card.global_position
		card.reparent(host)
		card.position = host.get_global_transform().affine_inverse() * global
	card.position = _clamp(p)
	card.scale = Vector2.ONE
	_update_grip()
	return true
