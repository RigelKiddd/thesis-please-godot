extends RefCounted

## Single input-context router.
##
## Main.gd used to carry four overlapping guards: `_input`, `_unhandled_input`,
## `modal_open` and Control focus. This module names the contexts explicitly and
## is the only place that decides which one receives mouse/keyboard. Handlers
## still live on Main for now; the router calls them with `main.` so a future
## extraction can move the bodies without changing call sites.
##
## CHAT is deliberately a submode of REVIEW: the chat panel's own Buttons consume
## mouse/Enter through Godot's Control focus, while 1/2/3 and the paper remain
## available. Do not turn chat into a blocking context or the player will lose
## the ability to stamp while a message is on screen.

const TITLE := "TITLE"
const MODAL := "MODAL"
const REVIEW := "REVIEW"
const ANNOTATION := "ANNOTATION"
const CHAT := "CHAT"
const NIGHT := "NIGHT"
const ALLOCATION := "ALLOCATION"
const GAMEOVER := "GAMEOVER"
const ENDING := "ENDING"

static func context(main) -> String:
	if main.modal_open:
		return MODAL
	if main.story_active:
		return NIGHT
	match str(main.phase):
		"title":
			return TITLE
		"gameover":
			return GAMEOVER
		"ending":
			return ENDING
		"allocate":
			return ALLOCATION
		"review", "verdict":
			if main.annotating:
				return ANNOTATION
			return REVIEW
	return TITLE

static func chat_open(main) -> bool:
	return main.chat_panel != null and main.chat_panel.visible \
		and main.chat_reply == -1 and str(main.phase) == "review"

static func allows_mouse(main) -> bool:
	var ctx := context(main)
	return ctx == REVIEW or ctx == ANNOTATION or ctx == NIGHT

static func allows_review_keys(main) -> bool:
	var ctx := context(main)
	return ctx == REVIEW or ctx == ANNOTATION

static func allows_annotation(main) -> bool:
	return context(main) == ANNOTATION

static func release_focus(main) -> void:
	var vp: Viewport = main.get_viewport()
	if vp == null:
		return
	var owner := vp.gui_get_focus_owner()
	if owner != null:
		owner.release_focus()

static func handle_mouse(main, event: InputEvent) -> void:
	var ctx := context(main)
	if ctx != REVIEW and ctx != ANNOTATION and ctx != NIGHT:
		return
	if ctx == ANNOTATION:
		if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
			var ab := event as InputEventMouseButton
			if ab.pressed and main._paper_rect().has_point(ab.position):
				main._begin_annotation(ab.position)
				main.get_viewport().set_input_as_handled()
				return
			if !ab.pressed and main.annot_drawing:
				main._finish_annotation(ab.position)
				main.get_viewport().set_input_as_handled()
				return
		if event is InputEventMouseMotion and main.annot_drawing:
			main._update_annotation((event as InputEventMouseMotion).position)
			main.get_viewport().set_input_as_handled()
			return
		# A pen click outside the paper falls through so stamps/UI still work.

	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT:
		var mb := event as InputEventMouseButton
		var pos := mb.position
		if mb.pressed:
			if mb.double_click and main._try_double(pos):
				main.get_viewport().set_input_as_handled()
				return
			if main._try_press(pos):
				main._click_fx(pos)
				main.get_viewport().set_input_as_handled()
		else:
			if !main.drag_state.is_empty():
				main._end_drag(pos)
				main.get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and !main.drag_state.is_empty():
		main._move_drag((event as InputEventMouseMotion).position)
		main.get_viewport().set_input_as_handled()

static func handle_unhandled(main, event: InputEvent) -> void:
	if !(event is InputEventKey) or !event.pressed or event.echo:
		return
	var k := (event as InputEventKey).keycode
	var ctx := context(main)
	if main.request_paper != null:
		if k == KEY_ESCAPE:
			main._on_request_action("request-close")
			main.get_viewport().set_input_as_handled()
		elif k == KEY_A:
			main._on_request_action("request-approve")
			main.get_viewport().set_input_as_handled()
		elif k == KEY_R:
			main._on_request_action("request-return")
			main.get_viewport().set_input_as_handled()
		return
	if ctx == MODAL:
		if k == KEY_ESCAPE and (main.modal_is_help or main.modal_closable):
			if main.settings_modal and str(main.phase) == "title":
				main._show_title()
			else:
				main._hide_modal()
			main.get_viewport().set_input_as_handled()
		return
	if ctx == ALLOCATION:
		match k:
			KEY_F:
				main._show_favor_ledger()
				main.get_viewport().set_input_as_handled()
			KEY_C:
				main._show_college_ledger()
				main.get_viewport().set_input_as_handled()
			KEY_L:
				main._open_duty_log()
				main.get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				if main._alloc_ready():
					main._finish_allocation()
					main.get_viewport().set_input_as_handled()
		return
	if k == KEY_F and (str(main.phase) == "review" or str(main.phase) == "verdict"):
		main._show_favor_ledger()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_C and (str(main.phase) == "review" or str(main.phase) == "verdict"):
		main._show_college_ledger()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_L and (str(main.phase) == "review" or str(main.phase) == "verdict" or str(main.phase) == "allocate"):
		main._open_duty_log()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_G and (str(main.phase) == "review" or str(main.phase) == "verdict"):
		main._open_settings()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_ESCAPE and !main.drag_state.is_empty():
		main._cancel_drag()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_R:
		main._reset_all_layout()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_BACKSPACE and str(main.phase) == "review" and !main.story_active:
		if (event as InputEventKey).ctrl_pressed:
			main._clear_tab_annotations(main.tab, true)
		else:
			main._undo_annotation()
		main.get_viewport().set_input_as_handled()
		return
	if k == KEY_F9:
		main._toggle_anchor_debug()
		main.get_viewport().set_input_as_handled()
		return
	if ctx == NIGHT:
		var docs_n: int = main._story_docs().size()
		match k:
			KEY_LEFT:
				main._open_story_doc(maxi(0, main.story_doc - 1))
				main.get_viewport().set_input_as_handled()
			KEY_RIGHT:
				main._open_story_doc(mini(docs_n - 1, main.story_doc + 1))
				main.get_viewport().set_input_as_handled()
			KEY_1:
				if main.story_choice == -1:
					main._on_story_choice(0)
					main.get_viewport().set_input_as_handled()
			KEY_2:
				if main.story_choice == -1:
					main._on_story_choice(1)
					main.get_viewport().set_input_as_handled()
			KEY_ENTER, KEY_KP_ENTER:
				if main.story_choice != -1:
					main._finish_night_story()
					main.get_viewport().set_input_as_handled()
		return
	if ctx != REVIEW and ctx != ANNOTATION:
		return
	match k:
		KEY_1:
			main._select_stamp("pass")
			main.get_viewport().set_input_as_handled()
		KEY_2:
			main._select_stamp("revise")
			main.get_viewport().set_input_as_handled()
		KEY_3:
			main._select_stamp("reject")
			main.get_viewport().set_input_as_handled()
		KEY_ENTER, KEY_KP_ENTER:
			main.stamp_decision()
			main.get_viewport().set_input_as_handled()
		KEY_LEFT:
			var idx: int = main._tab_index()
			main.switch_tab(str(GameData.tabs[(idx - 1 + GameData.tabs.size()) % GameData.tabs.size()].get("id", "cover")))
			main.get_viewport().set_input_as_handled()
		KEY_RIGHT:
			var idx2: int = main._tab_index()
			main.switch_tab(str(GameData.tabs[(idx2 + 1) % GameData.tabs.size()].get("id", "cover")))
			main.get_viewport().set_input_as_handled()
		KEY_H:
			main._show_help()
			main.get_viewport().set_input_as_handled()
		KEY_M:
			main._toggle_sound()
			main.get_viewport().set_input_as_handled()
