extends "res://scripts/Main.gd"

## Test-only scene: inherits the whole game and adds the --state dispatcher,
## screenshot helpers and contract assertions. Not shipped; export_presets.cfg
## excludes tests/*. Run with:
##   godot --headless --path . res://tests/TestMain.tscn -- --state=rulecheck

# ============================================================
# COMMAND LINE / SCREENSHOTS
# ============================================================
func _apply_cmdline() -> void:
	var state_name := ""
	var shot := ""
	var nofx := false
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--state="):
			state_name = a.substr(8)
		elif a.begins_with("--shot="):
			shot = a.substr(7)
		elif a == "--nofx":
			nofx = true
	if nofx:
		layer_fx.visible = false
	if state_name != "":
		_dev_state(state_name)
	if shot != "":
		_capture_later(shot)

func _dev_state(s: String) -> void:
	if s != "metricscheck":
		SettingsStore.metrics_enabled = false
	_hide_modal()
	_reset_state()
	phase = "review"
	# Screenshot/contract states opt in to auto-presentation explicitly; the
	# real game leaves this on so a student's packet meets them at the window.
	face_auto_present = false
	if s == "architecturecheck":
		var errors: Array = await preload("res://tests/ArchitectureCheck.gd").run(self)
		if errors.is_empty():
			print("ARCHITECTURECHECK ok state isolation stacking pin scroll archive")
		else:
			print("ARCHITECTURECHECK failed: ", errors)
		get_tree().quit(0 if errors.is_empty() else 1)
		return
	if s == "startcheck":
		_show_title()
		await get_tree().create_timer(0.35).timeout
		await _click_modal_button("开始值班")
		await get_tree().create_timer(0.35).timeout
		await get_tree().process_frame
		var first_ok := phase == "intro" and modal_open
		await _click_modal_button("开始审查")
		await get_tree().create_timer(0.35).timeout
		if first_ok and phase == "review" and !modal_open:
			print("STARTCHECK ok")
			get_tree().quit(0)
		else:
			push_error("STARTCHECK failed phase=%s modal=%s first=%s" % [phase, str(modal_open), str(first_ok)])
			print("STARTCHECK failed")
			get_tree().quit(1)
		return
	if s == "startclick":
		_show_title()
		await get_tree().create_timer(0.35).timeout
		await _push_hover(Vector2(464, 559))
		print("STARTCLICK hover=", str(get_viewport().gui_get_hovered_control()))
		await _push_click(Vector2(464, 559))
		await get_tree().create_timer(0.5).timeout
		print("STARTCLICK phase=%s modal=%s title=%s" % [phase, str(modal_open), str(modal_center.get_child_count())])
		if modal_center.get_child_count() > 0:
			var btns = modal_center.get_child(0).find_children("*", "Button", true, false)
			for b in btns:
				print("STARTBTN ", b.text, " ", b.global_position, " ", b.size)
			if btns.size() > 0:
				var b2 = btns[btns.size() - 1]
				await _push_click(b2.global_position + b2.size * 0.5)
				await get_tree().create_timer(0.5).timeout
				print("STARTCLICK2 phase=%s modal=%s" % [phase, str(modal_open)])
		return
	if s == "title":
		_show_title()
		return
	if s == "intro":
		day = 0
		_show_day_intro()
		return
	if s.begins_with("day") and s.length() > 3 and s.substr(3).is_valid_int():
		day = clampi(int(s.substr(3)) - 1, 0, GameData.days.size() - 1)
	if s == "allocationcheck":
		await _dev_allocation_check()
		return
	if s == "visitorclick":
		await _dev_visitor_click()
		return
	if s == "collegecheck":
		_dev_college_check()
		return
	if s == "passreward":
		day = 0
		_begin_day()
		_auto_resolve_requests()
		for i in range(GameData.student_count(day)):
			var s2 := GameData.student(day, i)
			if str(GameData.audit(s2, day).get("expected", "")) == "pass":
				stu = i
				load_student(true)
				break
		_select_stamp("pass")
		stamp_decision()
		return
	if s == "colleges" or s == "collegemail":
		day = 0
		_begin_day()
		_auto_resolve_requests()
		if s == "colleges":
			college_favor = {
				"humanities": {"advisor": 4, "director": 3, "passes": 2, "milestone": true, "lastStudent": "林小满"},
				"social": {"advisor": 2, "director": 1, "passes": 1, "milestone": false, "lastStudent": "王芷晴"},
				"engineering": {"advisor": 3, "director": 2, "passes": 1, "milestone": false, "lastStudent": "赵一鸣"},
				"arts": {"advisor": 1, "director": 1, "passes": 1, "milestone": false, "lastStudent": "苏雨桐"},
			}
			run_state.college_log = [
				{"day": 0, "group": "humanities", "college": "文学院", "student": "林小满", "advisor": 1, "director": 1, "pass": true, "milestone": false, "perf": 30},
				{"day": 0, "group": "humanities", "college": "文学院", "student": "林小满", "advisor": 1, "director": 1, "pass": true, "milestone": true, "perf": 90},
				{"day": 1, "group": "social", "college": "商学院", "student": "王芷晴", "advisor": 1, "director": 1, "pass": true, "milestone": false, "perf": 35},
				{"day": 2, "group": "engineering", "college": "信息工程学院", "student": "赵一鸣", "advisor": 1, "director": 1, "pass": true, "milestone": false, "perf": 40},
			]
			_show_college_ledger()
			return
		college_favor = {
			"humanities": {"advisor": 2, "director": 2, "passes": 2, "milestone": true, "lastStudent": "林小满"},
		}
		run_state.college_letters = ["humanities"]
		_start_night_story()
		var docs := _story_docs()
		for i in range(docs.size()):
			if str(docs[i].get("tab", "")) == "感谢函":
				_open_story_doc(i)
				break
		return
	if s == "visitorleader":
		day = 0
		_begin_day()
		_start_allocation()
		var vs: Array = GameData.allocation.get("visitors", [])
		for i in range(vs.size()):
			if str(vs[i].get("role", "")) == "leader":
				alloc_visitors = [vs[i]]
				_show_visitor(0)
				break
		return
	if s == "deskitem":
		day = 0
		_begin_day()
		_start_allocation()
		_auto_resolve_visitors()
		alloc_view.auto_place_all()
		alloc_view.open_item("favor")
		return
	if s == "deskclick":
		day = 0
		_begin_day()
		_start_allocation()
		_auto_resolve_visitors()
		alloc_view.auto_place_all()
		await get_tree().create_timer(0.35).timeout
		await _push_click(Vector2(344, 415))
		print("DESKCLICK expanded=%s" % str(alloc_view._desk_items["favor"].expanded))
		await _push_click(Vector2(710, 392))
		print("DESKCLICK collapsed=%s" % str(alloc_view._desk_items["favor"].expanded))
		await _push_drag(Vector2(344, 415), Vector2(494, 465))
		print("DESKCLICK pos=%s" % str(alloc_view._desk_items["favor"].position))
		get_tree().quit()
		return
	if s == "visitoritem":
		day = 0
		_begin_day()
		_start_allocation()
		var before := int(favor.get("counselor", 0))
		var perf_before := perf
		_on_visitor_action("visitor-item:favor")
		_on_visitor_action("visitor:0")
		print("VISITORITEM favor=%d before=%d perf=%d perf_before=%d items=%d modal=%s" % [
			int(favor.get("counselor", 0)), before, perf, perf_before, run_state.items.size(), str(modal_open)])
		get_tree().quit()
		return
	if s == "visitoritemclick":
		day = 0
		_begin_day()
		_start_allocation()
		await get_tree().create_timer(0.35).timeout
		await _push_drag(Vector2(344, 415), Vector2(750, 200))
		print("VISITORITEMCLICK selected=%s" % visitor_item)
		await _push_click(Vector2(600, 245))
		print("VISITORITEMCLICK favor=%d perf=%d modal=%s" % [int(favor.get("counselor", 0)), perf, str(modal_open)])
		await get_tree().create_timer(0.5).timeout
		await _snap("visitoritem-result")
		get_tree().quit()
		return
	if s == "visitorpass":
		day = 0
		_begin_day()
		_start_allocation()
		_on_visitor_action("visitor:2")
		print("VISITORPASS items=%d pass=%s modal=%s" % [run_state.items.size(), str(!run_state.item_of("pass_0_0").is_empty()), str(modal_open)])
		get_tree().quit()
		return
	if s == "visitorconsume":
		day = 0
		_begin_day()
		_start_allocation()
		run_state.add_item({
			"id": "letter_test", "kind": "letter", "title": "感谢函 · 测试",
			"sub": "THANK YOU", "group": "humanities", "day": 0, "student": "林小满",
			"consumable": true, "submit_favor": 2, "submit_perf": 40,
		})
		visitor_item = "letter_test"
		_on_visitor_action("visitor:0")
		print("VISITORCONSUME letter=%s items=%d modal=%s" % [str(!run_state.item_of("letter_test").is_empty()), run_state.items.size(), str(modal_open)])
		get_tree().quit()
		return
	if s == "deskletters":
		day = 0
		_begin_day()
		_start_allocation()
		_auto_resolve_visitors()
		alloc_view.auto_place_all()
		run_state.add_item({
			"id": "letter_humanities_0", "kind": "letter", "title": "感谢函 · 人文与传播学部",
			"sub": "THANK YOU", "style": "sealed", "icon": "envelope", "stock": "SEALED", "stock_cn": "封函",
			"group": "humanities", "day": 0, "student": "林小满",
			"consumable": true, "submit_favor": 2, "submit_perf": 40,
		})
		run_state.add_item({
			"id": "pass_0_0", "kind": "pass", "title": "临时通行条", "sub": "PASS",
			"style": "carbonless", "icon": "ticket", "stock": "CARBONLESS", "stock_cn": "无碳",
			"day": 0, "consumable": true, "submit_favor": 1, "submit_perf": 20,
		})
		alloc_view.refresh()
		alloc_view.open_item("letter_humanities_0")
		return
	if s == "deskshapes":
		day = 0
		_begin_day()
		_start_allocation()
		_auto_resolve_visitors()
		alloc_view.auto_place_all()
		run_state.add_item({
			"id": "letter_humanities_0", "kind": "letter", "title": "感谢函 · 人文与传播学部",
			"sub": "THANK YOU", "style": "sealed", "icon": "envelope", "stock": "SEALED", "stock_cn": "封函",
			"group": "humanities", "day": 0, "student": "林小满", "consumable": true,
		})
		run_state.add_item({
			"id": "pass_0_0", "kind": "pass", "title": "临时通行条", "sub": "PASS",
			"style": "carbonless", "icon": "ticket", "stock": "CARBONLESS", "stock_cn": "无碳",
			"day": 0, "consumable": true,
		})
		alloc_view.refresh()
		await get_tree().create_timer(0.3).timeout
		return
	if s == "deskschedule" or s == "deskcollege":
		day = 0
		_begin_day()
		_start_allocation()
		_auto_resolve_visitors()
		alloc_view.auto_place_all()
		alloc_view.open_item("schedule" if s == "deskschedule" else "college")
		await get_tree().create_timer(0.35).timeout
		return
	if s == "deskpass":
		day = 0
		_begin_day()
		_start_allocation()
		_auto_resolve_visitors()
		alloc_view.auto_place_all()
		run_state.add_item({
			"id": "pass_0_0", "kind": "pass", "title": "临时通行条", "sub": "PASS",
			"style": "carbonless", "icon": "ticket", "stock": "CARBONLESS", "stock_cn": "无碳",
			"day": 0, "consumable": true, "submit_favor": 1, "submit_perf": 20,
		})
		alloc_view.refresh()
		alloc_view.open_item("pass_0_0")
		await get_tree().create_timer(0.35).timeout
		return
	if s == "visitordrag":
		day = 0
		_begin_day()
		_start_allocation()
		await get_tree().create_timer(0.35).timeout
		await _push_drag(Vector2(405, 116), Vector2(505, 216))
		print("VISITORDRAG pos=%s" % str(alloc_view._visitor_chat.position))
		await get_tree().create_timer(0.2).timeout
		return
	if s == "dutylog":
		day = 0
		_begin_day()
		_start_allocation()
		await get_tree().create_timer(0.35).timeout
		await _push_click(Vector2(600, 245))
		await get_tree().create_timer(0.3).timeout
		_open_duty_log()
		await get_tree().create_timer(0.35).timeout
		print("DUTYLOG entries=%d cards=%d" % [run_state.duty_log.size(), modal_top.get_child_count()])
		if modal_top.get_child_count() > 0:
			print("DUTYALPHA ", modal_top.get_child(0).modulate.a, " scale=", modal_top.get_child(0).scale)
		return
	if s == "deskarchive":
		day = 0
		_begin_day()
		_start_allocation()
		await get_tree().create_timer(0.35).timeout
		var it: Dictionary = run_state.item_of("favor")
		it["note"] = "先核学籍，再补材料"
		it["stamp"] = "已阅"
		alloc_view._on_item_archive("favor")
		alloc_view._toggle_archive()
		await get_tree().create_timer(0.25).timeout
		alloc_view.open_item("favor")
		await get_tree().create_timer(0.25).timeout
		print("DESKARCHIVE archived=%s" % str(bool(it.get("archived", false))))
		return
	if s == "weekending":
		day = 6
		perf = 4400
		rep = 4
		total_wrong = 1
		daily_wrong = 0
		perfect_days = 4
		run_state.favor = {"counselor": 4, "director": 3, "student": 2}
		run_state.college_favor = {"humanities": {"advisor": 3, "director": 2, "passes": 2, "milestone": true, "lastStudent": ""}}
		run_state.duty_log = [
			{"day": 0, "kind": "visitor", "who": "沈知夏", "title": "学生请假条", "tag": "批", "label": "先受理", "result": "已受理", "favor": {"counselor": 1}},
			{"day": 0, "kind": "projects", "counts": {"p1": 2}, "perf": 145},
			{"day": 3, "kind": "visitor", "who": "林嘉树", "title": "院系账本", "tag": "缓", "label": "缓办", "result": "待补", "favor": {}},
		]
		_show_ending()
		await get_tree().create_timer(0.35).timeout
		return
	if s == "paperdrag":
		day = 0
		_begin_day()
		_open_settings()
		await get_tree().create_timer(0.35).timeout
		var card: Control = modal_center.get_child(0)
		var from := card.global_position + Vector2(17, 18)
		var pw = card.get_meta("paper_window")
		print("PAPERGRIP ", pw.grip.position, " size=", pw.grip.size, " parent=", pw.grip.get_parent().name, " card=", card.global_position)
		await _push_hover(from)
		print("PAPERHOVER ", str(get_viewport().gui_get_hovered_control()))
		await _push_drag(from, from + Vector2(80, 90))
		print("PAPERDRAG parent=%s pos=%s" % [card.get_parent().name, str(card.position)])
		await get_tree().create_timer(0.2).timeout
		return
	if s == "visitorattach" or s == "visitorcancel":
		day = 0
		_begin_day()
		_start_allocation()
		await get_tree().create_timer(0.35).timeout
		await _push_drag(Vector2(344, 415), Vector2(750, 200))
		print("VISITORATTACH item=%s" % visitor_item)
		if s == "visitorcancel":
			await _push_click(Vector2(735, 338))
			print("VISITORCANCEL item=%s" % visitor_item)
			await _push_click(Vector2(600, 245))
			print("VISITORCANCEL favor=%d perf=%d" % [int(favor.get("counselor", 0)), perf])
			get_tree().quit()
			return
		await get_tree().create_timer(0.25).timeout
		return
	if s == "visitortip":
		day = 0
		_begin_day()
		_start_allocation()
		await get_tree().create_timer(0.35).timeout
		await _push_hover(Vector2(600, 245))
		await get_tree().create_timer(0.2).timeout
		return
	if s == "visitor" or s == "visitorresult" or s == "allocate" or s == "allocmid" or s == "favor":
		day = 0
		_begin_day()
		_start_allocation()
		if s == "visitorresult":
			_on_visitor_action("visitor:0")
			await get_tree().create_timer(0.35).timeout
			return
		if s == "allocate" or s == "allocmid":
			_auto_resolve_visitors()
			alloc_view.auto_place_all()
			if s == "allocmid":
				alloc_view._remove("thesis", true)
			await get_tree().create_timer(0.35).timeout
		elif s == "favor":
			_auto_resolve_visitors()
			_show_favor_ledger()
			await get_tree().create_timer(0.25).timeout
		else:
			await get_tree().create_timer(0.35).timeout
		return
	_begin_day()
	if s.begins_with("doc-"):
		tab = s.substr(4)
		render_tabs()
		render_doc()
	elif s == "help":
		_show_help()
	elif s == "shift":
		daily_correct = 3
		daily_wrong = 1
		day_start_perf = perf - 280
		_auto_resolve_requests()
		_end_day()
	elif s == "shiftfavor":
		daily_correct = 3
		daily_wrong = 1
		day_start_perf = perf - 280
		run_state.favor_log = [
			{"day": 0, "id": "counselor", "delta": 2, "reason": "来访 · 九点四十，辅导员来敲门"},
			{"day": 0, "id": "student", "delta": 3, "reason": "审查"},
			{"day": 0, "id": "director", "delta": -1, "reason": "误判投诉"},
		]
		_auto_resolve_requests()
		_end_day()
	elif s == "gameover":
		total_correct = 9
		total_wrong = 5
		day = 2
		perf = 640
		_show_game_over()
	elif s == "ending":
		perf = 4500
		rep = 5
		total_correct = 27
		total_wrong = 1
		perfect_days = 6
		annotation_hits = 18
		annotation_wrong = 3
		annotation_missed = 5
		stamp_counts = {"pass": 20, "revise": 6, "reject": 2}
		_show_ending()
	elif s == "endingfavor":
		perf = 5200
		rep = 5
		total_correct = 27
		total_wrong = 1
		perfect_days = 6
		annotation_hits = 18
		annotation_wrong = 3
		annotation_missed = 5
		stamp_counts = {"pass": 20, "revise": 6, "reject": 2}
		favor = {"director": 5, "leader": 3, "discipline": 2, "colleague": 4, "counselor": 7, "recruiter": 3, "student": 8}
		run_state.night_log = [
			{"day": 0, "label": "照章退回", "tone": "good"},
			{"day": 2, "label": "签字移送", "tone": "good"},
		]
		_show_ending()
	elif s == "endinglong":
		perf = 8300
		rep = 5
		total_correct = 27
		total_wrong = 1
		perfect_days = 6
		annotation_hits = 18
		annotation_wrong = 3
		annotation_missed = 5
		stamp_counts = {"pass": 20, "revise": 6, "reject": 2}
		favor = {"director": 8, "leader": 5, "discipline": 4, "colleague": 6, "counselor": 8, "recruiter": 5, "student": 10}
		college_favor = {
			"humanities": {"advisor": 4, "director": 3, "passes": 2, "milestone": true, "lastStudent": "林小满"},
			"engineering": {"advisor": 3, "director": 2, "passes": 1, "milestone": false, "lastStudent": "赵一鸣"},
			"arts": {"advisor": 1, "director": 1, "passes": 1, "milestone": false, "lastStudent": "苏雨桐"},
		}
		run_state.night_log = [
			{"day": 0, "label": "照章退回", "tone": "good"},
			{"day": 1, "label": "按归档为准", "tone": "good"},
			{"day": 2, "label": "签字移送", "tone": "good"},
			{"day": 3, "label": "按名单送检", "tone": "good"},
			{"day": 4, "label": "如实写", "tone": "good"},
			{"day": 5, "label": "按缺签退回", "tone": "good"},
			{"day": 6, "label": "如实写", "tone": "good"},
		]
		_show_ending()
	elif s == "complaint":
		var audit := GameData.audit(current, day)
		ann.record_attempt("cover", Vector2(100, 100), {}, "", false)
		ann.record_attempt("cover", Vector2(450, 154), {"anchor": "identity.id", "label": "封面学号不符"}, "封面学号不符", true)
		_show_modal(Modals.complaint(current, audit, "pass", _state_dict(), Callable(self, "_on_modal_action")))
	elif s == "loose":
		day = 2
		_begin_day()
		for m in GameData.materials:
			if GameData.is_material_unlocked(m, day):
				open_loose(str(m.get("id", "")), Vector2(-1, -1))
	elif s == "loose2":
		day = 1
		_begin_day()
		open_loose("opening", Vector2(520, 388))
	elif s == "looseall":
		day = 6
		_begin_day()
		var li := 0
		for m in GameData.materials:
			if GameData.is_material_unlocked(m, day):
				open_loose(str(m.get("id", "")), Vector2(520 + li * 22, 388 + li * 18))
				li += 1
	elif s.begins_with("loose-"):
		day = 6
		_begin_day()
		open_loose(s.substr(6), Vector2(520, 388))
	elif s == "stamps":
		selected = "pass"
		render_stamps()
	elif s == "clicktest":
		_dev_clicktest()
	elif s == "autoday":
		_dev_auto_day()
	elif s == "autowrong":
		_dev_auto_wrong()
	elif s == "dragtest":
		_dev_drag_test()
	elif s == "dragshow":
		_dev_drag_show(false)
	elif s == "dragshowmat":
		_dev_drag_show(true)
	elif s == "acktest":
		_dev_ack_test()
	elif s == "sfxtest":
		_dev_sfx_test()
	elif s == "night":
		_dev_night(0)
	elif s == "night1":
		_dev_night(1)
	elif s == "night2":
		_dev_night(2)
	elif s == "nightchoice":
		_dev_night_choice()
	elif s == "nightfinish":
		_dev_night_finish()
	elif s == "nightending":
		_dev_night_ending()
	elif s == "night-email":
		_dev_night_doc(1, 1)
	elif s == "night-chat":
		_dev_night_doc(2, 1)
	elif s == "night-file":
		_dev_night_doc(5, 0)
	elif s == "night-form":
		_dev_night_doc(1, 0)
	elif s == "storydocall":
		_story_doc_all()
	elif s == "shiftonight":
		daily_correct = 4
		daily_wrong = 0
		day_start_perf = perf - 480
		_end_day()
		_on_modal_action("next-day")
	elif s == "nightclick":
		_dev_night_click()
	elif s == "nightclickcheck":
		_dev_night_click_check()
	elif s == "requestcheck":
		_dev_request_check()
	elif s == "requestflow":
		_dev_request_flow()
	elif s == "requestmulti":
		_dev_request_multi()
	elif s == "facecheck":
		_dev_face_check()
	elif s == "facefuturecheck":
		_dev_face_future_check()
	elif s == "requestpacketcheck":
		_dev_request_packet_check()
	elif s == "requeststamp":
		_dev_request_stamp()
	elif s == "eventcheck":
		_dev_event_check()
	elif s == "transcriptnursing":
		_dev_request_doc_id(2, "transcript", "transcript-nursing")
	elif s == "transcriptbio":
		_dev_request_doc_id(4, "transcript", "transcript-biology")
	elif s == "leavefile":
		_dev_event_doc(0, "leave-d1-1d", "leave-file")
	elif s == "eventexchange":
		_dev_event_doc(2, "exchange-d3-exchange", "event-exchange")
	elif s == "eventlab":
		_dev_event_doc(4, "lab-d5-access", "event-lab")
	elif s == "eventinternship":
		_dev_event_doc(5, "internship-d6-recommend", "event-internship")
	elif s == "stampcheck":
		_dev_stamp_check()
	elif s == "stampmark":
		_dev_stamp_mark()
	elif s == "stylecheck":
		_dev_style_check()
	elif s == "stylegallery":
		_dev_style_gallery()
	elif s == "stampoverlap":
		_dev_stamp_overlap()
	elif s == "metricscheck":
		_dev_metrics_check()
	elif s == "largetextcheck":
		_dev_large_text_check()
	elif s == "portraitcheck":
		_dev_portrait_check()
	elif s == "portraitstyle":
		portrait.material = null
		day = 0
		stu = 0
		load_student(true)
		await get_tree().create_timer(0.5).timeout
		await _snap("portraitstyle")
		get_tree().quit()
	elif s == "portraithide":
		portrait.visible = false
		day = 0
		stu = 0
		load_student(true)
		await get_tree().create_timer(0.5).timeout
		await _snap("portraithide")
		get_tree().quit()
	elif s == "portraitexport":
		var img: Image = portrait.texture.get_image()
		img.save_png("res://_shots/imported.png")
		print("PORTRAITEXPORT ", img.get_width(), "x", img.get_height())
		get_tree().quit()
	elif s == "shaderlab":
		await _dev_shader_lab()
	elif s == "request":
		_dev_request_doc(1)
	elif s == "requestupper":
		_dev_request_upper()
	elif s == "request-transcript":
		_dev_request_doc_id(1, "transcript")
	elif s == "request-notice":
		_dev_request_doc_id(1, "notice")
	elif s == "request-difficulty":
		_dev_request_doc_id(1, "difficulty")
	elif s == "request-report":
		_dev_request_doc_id(3, "report")
	elif s == "facetask":
		_dev_face_task()
	elif s == "faceblocked":
		_dev_face_blocked()
	elif s == "requesthonors":
		_dev_request_doc(3)
	elif s == "requestleave":
		_dev_request_doc(5)
	elif s == "largetext":
		SettingsStore.text_scale = 1.25
		day = 0
		_begin_day()
		Ui.apply_text_scale(self)
		await get_tree().create_timer(0.6).timeout
		await _snap("largetext")
		get_tree().quit()
	elif s == "stampdrag":
		day = 0
		_begin_day()
		await get_tree().create_timer(0.3).timeout
		var g: Control = _make_ghost("revise")
		g.position = Vector2(540, 470)
		await get_tree().create_timer(0.25).timeout
		await _snap("stampdrag")
		get_tree().quit()
	elif s == "selected":
		_dev_selected()
	elif s == "verdict":
		_dev_verdict()
	elif s == "annotate":
		_dev_annotation(true)
	elif s == "annotatewrong":
		_dev_annotation(false)
	elif s == "annotateblank":
		_dev_annotation(true, true)
	elif s == "stampclick":
		_dev_stamp_click()
	elif s == "stampmiss":
		_dev_stamp_miss()
	elif s == "chat":
		_dev_chat(false)
	elif s == "chatreply":
		_dev_chat(true)
	elif s == "chatreply2":
		_dev_chat_defect()
	elif s == "chatdefect":
		_dev_chat_choices()
	elif s == "rulecheck":
		_dev_rule_check()
	elif s == "annotationcheck":
		_dev_annotation_check()
	elif s == "chatcheck":
		_dev_chat_check()
	elif s == "chatpause":
		_dev_chat_pause()
	elif s == "annotscroll":
		_dev_annotation_scroll()
	elif s == "annotrefs":
		_dev_annotation_refs()
	elif s == "anchors":
		_dev_anchors()
	elif s == "anchorsform":
		_dev_anchors_form()
	elif s == "anchorsdup":
		_dev_anchors_dup()
	elif s == "shiftstats":
		_dev_shift_stats()
	elif s == "penclick":
		_dev_pen_click()
	elif s == "docall":
		_doc_all()
	elif s == "nightmail":
		_dev_night_mail()
	elif s == "chatflow":
		_dev_chat_flow()
	elif s == "chatdialogue":
		_dev_chat_dialogue()
	elif s == "settings":
		_open_settings()
	elif s == "settingsshot":
		SettingsStore.metrics_enabled = true
		_open_settings()
		Input.warp_mouse(Vector2(10, 10))
		await get_tree().create_timer(0.5).timeout
		await _snap("settings")
		get_tree().quit()
	elif s == "savecheck":
		_dev_save_check()
	elif s == "backupcheck":
		_dev_backup_check()
	elif s == "continuecheck":
		_dev_continue_check()
	elif s == "chatmemory":
		_dev_chat_memory()
	elif s == "inputreplay":
		_dev_input_replay()
	elif s == "shotregress":
		_dev_shot_regress()
	elif s == "smoke":
		_dev_smoke()
	elif s == "settingscheck":
		_dev_settings_check()
	elif s == "titlesettings":
		_dev_title_settings_check()
	elif s == "routercheck":
		_dev_router_check()
	elif s == "autoweek":
		_dev_auto_week()

func _click_modal_button(text: String) -> void:
	if modal_center.get_child_count() == 0:
		return
	var card: Control = modal_center.get_child(modal_center.get_child_count() - 1)
	var buttons = card.find_children("*", "Button", true, false)
	for b in buttons:
		if str(b.text) == text:
			await _push_click(b.global_position + b.size * 0.5)
			return

func _push_click(pos: Vector2) -> void:
	var vp := pos
	var p := InputEventMouseButton.new()
	p.button_index = MOUSE_BUTTON_LEFT
	p.pressed = true
	p.position = vp
	p.global_position = vp
	get_viewport().push_input(p, true)
	await get_tree().process_frame
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_LEFT
	r.pressed = false
	r.position = vp
	r.global_position = vp
	get_viewport().push_input(r, true)
	await get_tree().process_frame

func _push_right_click(pos: Vector2) -> void:
	var vp := pos
	var p := InputEventMouseButton.new()
	p.button_index = MOUSE_BUTTON_RIGHT
	p.pressed = true
	p.position = vp
	p.global_position = vp
	get_viewport().push_input(p, true)
	await get_tree().process_frame
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_RIGHT
	r.pressed = false
	r.position = vp
	r.global_position = vp
	get_viewport().push_input(r, true)
	await get_tree().process_frame

func _dev_drag_show(material: bool) -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.35).timeout
	if material:
		_try_press(Vector2(1100, 445))
		_move_drag(Vector2(900, 560))
	else:
		_try_press(Vector2(330, 388))
		_move_drag(Vector2(560, 520))

func _dev_auto_day() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	_begin_day()
	_auto_resolve_requests()
	await get_tree().create_timer(0.7).timeout
	for i in range(GameData.student_count(day)):
		var a := GameData.audit(current, day)
		_select_stamp(str(a.get("expected", "pass")))
		stamp_decision()
		await get_tree().create_timer(1.8).timeout
	await get_tree().create_timer(0.4).timeout
	await _snap("auto-shift")
	_on_modal_action("next-day")
	await get_tree().create_timer(0.4).timeout
	await _snap("auto-night")
	_on_story_choice(0)
	_finish_night_story()
	await get_tree().create_timer(0.6).timeout
	await _snap("auto-allocation")
	_auto_allocate()
	await get_tree().create_timer(0.6).timeout
	await _snap("auto-day2-intro")
	get_tree().quit()

func _dev_auto_wrong() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	_begin_day()
	await get_tree().create_timer(0.7).timeout
	var a := GameData.audit(current, day)
	var wrong := "pass" if str(a.get("expected", "pass")) == "revise" else ("reject" if str(a.get("expected", "pass")) == "pass" else "pass")
	_select_stamp(wrong)
	stamp_decision()
	await get_tree().create_timer(1.0).timeout
	await _snap("auto-complaint")
	get_tree().quit()

func _dev_clicktest() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	_begin_day()
	await get_tree().create_timer(0.8).timeout
	await _snap("click-0-start")
	await _push_click(Vector2(502, 412))
	await get_tree().create_timer(0.3).timeout
	await _snap("click-1-dup-tab")
	await _push_click(Vector2(404, 811))
	await get_tree().create_timer(0.25).timeout
	await _snap("click-2-selected")
	await _push_click(Vector2(1112, 811))
	await get_tree().create_timer(0.35).timeout
	await _snap("click-3-verdict")
	await get_tree().create_timer(1.8).timeout
	await _snap("click-4-next")
	get_tree().quit()

func _push_drag(from: Vector2, to: Vector2) -> void:
	var p := InputEventMouseButton.new()
	p.button_index = MOUSE_BUTTON_LEFT
	p.pressed = true
	p.position = from
	p.global_position = from
	get_viewport().push_input(p, true)
	await get_tree().process_frame
	for i in range(1, 11):
		var t := float(i) / 10.0
		var m := InputEventMouseMotion.new()
		m.position = from.lerp(to, t)
		m.global_position = m.position
		m.button_mask = MOUSE_BUTTON_MASK_LEFT
		get_viewport().push_input(m, true)
		await get_tree().process_frame
	var r := InputEventMouseButton.new()
	r.button_index = MOUSE_BUTTON_LEFT
	r.pressed = false
	r.position = to
	r.global_position = to
	get_viewport().push_input(r, true)
	await get_tree().process_frame

func _push_hover(pos: Vector2) -> void:
	var m := InputEventMouseMotion.new()
	m.position = pos
	m.global_position = pos
	get_viewport().push_input(m, true)
	await get_tree().process_frame

func _dev_drag_test() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	_begin_day()
	await get_tree().create_timer(0.6).timeout
	await _push_drag(Vector2(500, 200), Vector2(560, 250))
	await get_tree().create_timer(0.3).timeout
	await _snap("drag-1-card")
	_reset_all_layout()
	await get_tree().create_timer(0.2).timeout
	await _push_drag(Vector2(350, 386), Vector2(410, 450))
	await get_tree().create_timer(0.3).timeout
	await _snap("drag-2-folder")
	_reset_all_layout()
	await get_tree().create_timer(0.2).timeout
	await _push_drag(Vector2(404, 811), Vector2(1112, 811))
	await get_tree().create_timer(0.4).timeout
	await _snap("drag-3-stamp")
	await get_tree().create_timer(1.8).timeout
	_hide_modal()
	_reset_state()
	day = 2
	phase = "review"
	_begin_day()
	await get_tree().create_timer(0.6).timeout
	await _push_drag(Vector2(1148, 445), Vector2(800, 600))
	await get_tree().create_timer(0.4).timeout
	await _snap("drag-4-material")
	await _push_drag(Vector2(720, 397), Vector2(780, 440))
	await get_tree().create_timer(0.4).timeout
	await _snap("drag-5-loose")
	get_tree().quit()

func _dev_ack_test() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	_begin_day()
	await get_tree().create_timer(0.6).timeout
	await _push_drag(Vector2(350, 386), Vector2(620, 560))
	await get_tree().create_timer(0.3).timeout
	_select_stamp("reject")
	stamp_decision()
	await get_tree().create_timer(1.0).timeout
	await _snap("ack-1-complaint")
	await _push_click(Vector2(482, 556))
	await get_tree().create_timer(0.6).timeout
	await _snap("ack-2-next")
	get_tree().quit()

func _dev_sfx_test() -> void:
	print("SFX streams=", sfx.streams.size())
	for n in sfx.streams.keys():
		var st: AudioStreamWAV = sfx.streams[n]
		print("SFX ", n, " bytes=", st.data.size(), " rate=", st.mix_rate, " fmt=", st.format)
		_play(n)
	await get_tree().create_timer(0.8).timeout
	get_tree().quit()

func _doc_all() -> void:
	var tabs := ["cover", "abstract", "body", "refs", "dup", "form"]
	var extras := ["opening", "advisor", "ethics", "records"]
	var n := 0
	for d in range(GameData.days.size()):
		for si in range(GameData.student_count(d)):
			var st := GameData.student(d, si)
			for t in tabs:
				var holder := Control.new()
				add_child(holder)
				holder.add_child(Docs.render(t, st, 696))
				holder.queue_free()
				n += 1
			for e in extras:
				var holder2 := Control.new()
				add_child(holder2)
				holder2.add_child(Docs.render(e, st, 430))
				holder2.queue_free()
				n += 1
	print("DOCALL rendered ", n)
	await get_tree().process_frame
	get_tree().quit()

func _dev_auto_week() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	for d in range(GameData.days.size()):
		day = d
		_begin_day()
		_auto_resolve_requests()
		var count := GameData.student_count(day)
		for si in range(count):
			var a := GameData.audit(current, day)
			_select_stamp(str(a.get("expected", "pass")))
			stamp_decision()
			_next_student()
		var is_last := day >= GameData.days.size() - 1
		_on_modal_action("next-day")
		_on_story_choice(0)
		_finish_night_story()
		if is_last:
			break
		_auto_allocate()
		_begin_day()
	await get_tree().create_timer(0.6).timeout
	print("AUTOWEEK day=", day + 1, " perf=", perf, " rep=", rep)
	await _snap("autoweek-ending")
	get_tree().quit()

func _auto_resolve_visitors() -> void:
	var guard := 0
	while alloc_active and !alloc_visitors.is_empty() and guard < 16:
		guard += 1
		if alloc_visitor_index < 0 or alloc_visitor_index >= alloc_visitors.size():
			break
		var v := _filled_visitor(alloc_visitors[alloc_visitor_index])
		var options: Array = v.get("options", [])
		var pick := -1
		for i in range(options.size()):
			if AllocCtl.can_afford(options[i], int(run_state.energy), int(run_state.money)):
				pick = i
				break
		if pick < 0:
			break
		_on_visitor_action("visitor:%d" % pick)
		_on_visitor_action("visitor-next")

func _auto_allocate() -> void:
	_auto_resolve_visitors()
	if !alloc_active:
		return
	alloc_view.auto_place_all()
	_finish_allocation()

func _dev_visitor_click() -> void:
	_hide_modal()
	_reset_state()
	day = 0
	phase = "review"
	_begin_day()
	_start_allocation()
	await get_tree().create_timer(0.35).timeout
	var before := int(favor.get("counselor", 0))
	await _push_click(Vector2(600, 245))
	print("VISITORCLICK favor=%d before=%d chat=%s" % [int(favor.get("counselor", 0)), before, str(alloc_view._visitor_chat.visible)])
	get_tree().quit()


func _dev_allocation_check() -> void:
	var errors: Array = []
	var data := GameData.allocation
	if data.is_empty():
		errors.append("allocation data missing")
	var roles: Array = data.get("roles", [])
	var projects: Array = data.get("projects", [])
	var transitions: Array = data.get("transitions", [])
	var visitors: Array = data.get("visitors", [])
	if roles.size() != 7:
		errors.append("roles=%d" % roles.size())
	if projects.size() != 8:
		errors.append("projects=%d" % projects.size())
	if transitions.size() != 6:
		errors.append("transitions=%d" % transitions.size())
	if visitors.size() != 9:
		errors.append("visitors=%d" % visitors.size())
	var seen_roles: Dictionary = {}
	for v in visitors:
		seen_roles[str(v.get("role", ""))] = true
	if seen_roles.size() != 7:
		errors.append("visitor role coverage=%d" % seen_roles.size())
	var energy_cap := 0
	var money_cap := 0
	for project in projects:
		if str(project.get("coin", "")) == "energy":
			energy_cap += int(project.get("cap", 0))
		else:
			money_cap += int(project.get("cap", 0))
	var caps := AllocCtl.caps()
	if int(caps.get("energy", 0)) != energy_cap:
		errors.append("energy caps %d != %d" % [int(caps.get("energy", 0)), energy_cap])
	if int(caps.get("money", 0)) != money_cap:
		errors.append("money caps %d != %d" % [int(caps.get("money", 0)), money_cap])
	var rich := {"colleague": 3, "counselor": 2, "student": 6, "director": 3, "leader": 3}
	var b := AllocCtl.budget(0, rich)
	if int(b.get("energy", 0)) != int(caps.get("energy", 0)):
		errors.append("perk energy budget=%d" % int(b.get("energy", 0)))
	if int(b.get("money", 0)) != int(caps.get("money", 0)):
		errors.append("perk money budget=%d" % int(b.get("money", 0)))
	if AllocCtl.can_afford({"energy": -2}, 1, 0):
		errors.append("affordability accepted an impossible cost")

	_hide_modal()
	_reset_state()
	day = 0
	phase = "review"
	_begin_day()
	_start_allocation()
	if phase != "allocate" or !alloc_active:
		errors.append("allocation did not start")
	if int(run_state.energy) != 5 or int(run_state.money) != 4:
		errors.append("base budget=%d/%d" % [int(run_state.energy), int(run_state.money)])
	if alloc_view._visitor_chat == null or !alloc_view._visitor_chat.visible or alloc_visitors.size() != 1:
		errors.append("first visitor missing")
	var counselor_before := int(favor.get("counselor", 0))
	var rep_before := rep
	var energy_before := int(run_state.energy)
	_on_visitor_action("visitor:0")
	if int(favor.get("counselor", 0)) != counselor_before + 2:
		errors.append("counselor favor=%d" % int(favor.get("counselor", 0)))
	if rep != rep_before - 1:
		errors.append("visitor rep=%d" % rep)
	if int(run_state.energy) != energy_before - 1:
		errors.append("visitor energy=%d" % int(run_state.energy))
	_on_visitor_action("visitor-next")
	if alloc_view._visitor_chat != null and alloc_view._visitor_chat.visible:
		errors.append("visitor result did not close")
	if alloc_active:
		alloc_view.auto_place_all()
	if AllocCtl.remaining(run_state) != 0:
		errors.append("coins remain=%d" % AllocCtl.remaining(run_state))
	var effects: Dictionary = alloc_view.preview_effects()
	var perf_before := perf
	var director_before := int(favor.get("director", 0))
	_finish_allocation()
	if day != 1:
		errors.append("day after allocation=%d" % day)
	if phase != "intro":
		errors.append("phase after allocation=%s" % phase)
	if perf != perf_before + int(effects.get("perf", 0)) + int(effects.get("flat_perf", 0)):
		errors.append("perf after allocation=%d" % perf)
	if int(favor.get("director", 0)) < director_before:
		errors.append("allocation favor lost")
	if run_state.alloc_log.size() != 1:
		errors.append("alloc_log=%d" % run_state.alloc_log.size())
	if !AllocCtl.favor_line(favor).contains("吴敬之") and int(favor.get("director", 0)) > 0:
		errors.append("favor line missing names")
	var snapshot := GameState.snapshot(run_state)
	var saved_favor := favor.duplicate(true)
	run_state.reset()
	if !GameState.apply(run_state, snapshot):
		errors.append("save apply failed")
	elif int(favor.get("counselor", 0)) != int(saved_favor.get("counselor", 0)):
		errors.append("favor did not survive save")
	favor["student"] = 9
	_favor_changes({"student": 5}, "test")
	if int(favor.get("student", 0)) != 10:
		errors.append("favor cap=%d" % int(favor.get("student", 0)))
	favor["student"] = 1
	_favor_changes({"student": -9}, "test")
	if int(favor.get("student", 0)) != 0:
		errors.append("favor floor=%d" % int(favor.get("student", 0)))
	# Real mouse path: click a project box to place a coin, click the coin to take it back.
	_hide_modal()
	_reset_state()
	day = 0
	phase = "review"
	_begin_day()
	_start_allocation()
	_auto_resolve_visitors()
	await get_tree().process_frame
	var click_energy := int(run_state.energy)
	await _push_click(Vector2(100, 154))
	if int(run_state.alloc_placed.get("thesis", 0)) != 1:
		errors.append("box click did not place a coin")
	if int(run_state.energy) != click_energy - 1:
		errors.append("box click energy=%d" % int(run_state.energy))
	await get_tree().process_frame
	await _push_right_click(Vector2(100, 154))
	if int(run_state.alloc_placed.get("thesis", 0)) != 0:
		errors.append("right click did not take the coin back")
	if int(run_state.energy) != click_energy:
		errors.append("coin return energy=%d" % int(run_state.energy))
	_hide_modal()
	if errors.is_empty():
		print("ALLOCATIONCHECK ok roles=%d projects=%d visitors=%d" % [roles.size(), projects.size(), visitors.size()])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("ALLOCATIONCHECK " + str(e))
		print("ALLOCATIONCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_college_check() -> void:
	var errors: Array = []
	var groups := CollegeModel.groups()
	if groups.size() != 6:
		errors.append("college groups=%d" % groups.size())
	var group_by_college: Dictionary = {}
	for group in groups:
		for college in group.get("colleges", []):
			var name := str(college)
			if group_by_college.has(name):
				errors.append("college mapped twice: %s" % name)
			group_by_college[name] = str(group.get("id", ""))
	for d in range(GameData.days.size()):
		for si in range(GameData.student_count(d)):
			var s := GameData.student(d, si)
			var o: Dictionary = s.get("official", {})
			var college := str(o.get("college", ""))
			if !group_by_college.has(college):
				errors.append("unmapped college %s" % college)
				continue
			var gid := str(group_by_college[college])
			if str(o.get("collegeGroup", "")) != gid:
				errors.append("%s collegeGroup=%s expected %s" % [str(s.get("name", "")), str(o.get("collegeGroup", "")), gid])
			var group := CollegeModel.group(gid)
			if str(o.get("advisor", "")) != CollegeModel.advisor_name(group):
				errors.append("%s advisor mismatch" % str(s.get("name", "")))
			if str(o.get("director", "")) != CollegeModel.director_name(group):
				errors.append("%s director mismatch" % str(s.get("name", "")))
			var sigs: Dictionary = s.get("form", {}).get("signatures", {})
			if sigs.get("advisor") is String and str(sigs.get("advisor")) != CollegeModel.advisor_name(group):
				errors.append("%s form advisor mismatch" % str(s.get("name", "")))
			if sigs.get("chair") is String and str(sigs.get("chair")) != CollegeModel.director_name(group):
				errors.append("%s form chair mismatch" % str(s.get("name", "")))

	_hide_modal()
	_reset_state()
	day = 0
	phase = "review"
	_begin_day()
	_auto_resolve_requests()
	var chosen_index := -1
	for i in range(GameData.student_count(day)):
		var s := GameData.student(day, i)
		if str(GameData.audit(s, day).get("expected", "")) == "pass":
			chosen_index = i
			break
	if chosen_index < 0:
		errors.append("no passing student on day 1")
	else:
		stu = chosen_index
		load_student(true)
		var group: Dictionary = _group_for_student(current)
		if group.is_empty():
			errors.append("current student has no college group")
		else:
			var gid := str(group.get("id", ""))
			if !official_advisor.text.contains(CollegeModel.advisor_name(group)):
				errors.append("dossier advisor=%s" % official_advisor.text)
			if !official_director.text.contains(CollegeModel.director_name(group)):
				errors.append("dossier director=%s" % official_director.text)
			var pass_perf := CollegeModel.pass_perf(group)
			var before := perf
			_select_stamp("pass")
			stamp_decision()
			var row: Dictionary = _college_entry(gid)
			if int(row.get("advisor", 0)) != 1:
				errors.append("advisor favor=%d" % int(row.get("advisor", 0)))
			if int(row.get("director", 0)) != 1:
				errors.append("director favor=%d" % int(row.get("director", 0)))
			if int(row.get("passes", 0)) != 1:
				errors.append("college passes=%d" % int(row.get("passes", 0)))
			if perf != before + 120 + pass_perf:
				errors.append("pass perf=%d expected %d" % [perf, before + 120 + pass_perf])
			var college := str(current.get("official", {}).get("college", ""))
			var before2 := perf
			var milestone_bits: String = _college_pass({"name": "测试乙", "official": {"college": college}}, true)
			if int(row.get("passes", 0)) != 2 or !bool(row.get("milestone", false)):
				errors.append("milestone not reached: %s" % str(row))
			if run_state.college_letters.size() != 1:
				errors.append("college letters=%d" % run_state.college_letters.size())
			if perf != before2 + pass_perf + CollegeModel.milestone_perf(group):
				errors.append("milestone perf=%d" % perf)
			if milestone_bits.find("感谢函") < 0:
				errors.append("milestone toast=%s" % milestone_bits)
			var snapshot := GameState.snapshot(run_state)
			run_state.reset()
			if !GameState.apply(run_state, snapshot):
				errors.append("college save apply failed")
			else:
				var restored: Dictionary = _college_entry(gid)
				if int(restored.get("passes", 0)) != 2 or !bool(restored.get("milestone", false)):
					errors.append("college save did not round-trip")
			# The thank-you letter must be stable across repeated doc builds.
			run_state.college_letters = [gid]
			_start_night_story()
			var letters_seen := 0
			for doc in _story_docs():
				if str(doc.get("tab", "")) == "感谢函":
					letters_seen += 1
			if letters_seen != 1:
				errors.append("night letter docs=%d" % letters_seen)
			var letters_again := 0
			for doc in _story_docs():
				if str(doc.get("tab", "")) == "感谢函":
					letters_again += 1
			if letters_again != 1:
				errors.append("night letter duplicated=%d" % letters_again)
			_clear_story_mode()
			if !run_state.night_letters.is_empty():
				errors.append("night letters not cleared")
	_hide_modal()
	if errors.is_empty():
		print("COLLEGECHECK ok groups=%d colleges=%d" % [groups.size(), group_by_college.size()])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("COLLEGECHECK " + str(e))
		print("COLLEGECHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_night(idx: int) -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	_begin_day()
	_start_night_story()
	if idx > 0:
		_open_story_doc(idx)

func _dev_night_choice() -> void:
	_dev_night(0)
	_on_story_choice(0)

func _dev_night_finish() -> void:
	_dev_night_choice()
	_finish_night_story()
	_auto_allocate()

func _dev_request_multi() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 3
	_begin_day()
	var errors: Array = []
	if requests.pending_count() != 2:
		errors.append("D4 expected 2 requests, got %d" % requests.pending_count())
	_end_day()
	if request_paper == null or phase != "review":
		errors.append("D4 end-day did not open the first request")
	for i in range(2):
		var r: Dictionary = requests.first_pending()
		if r.is_empty():
			errors.append("missing pending request %d" % i)
			break
		var action := "request-approve" if str(r.get("expected", "return")) == "approve" else "request-return"
		_on_request_action(action)
		await get_tree().create_timer(0.12).timeout
	if requests.pending_count() != 0:
		errors.append("multi request not cleared")
	if phase != "dayend":
		errors.append("multi request did not resume end-day (phase=%s)" % phase)
	if errors.is_empty():
		print("REQUESTMULTI ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("REQUESTMULTI " + str(e))
		print("REQUESTMULTI failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_metrics_check() -> void:
	var old_enabled: bool = SettingsStore.metrics_enabled
	var old_path: String = MetricsCtl.path
	var test_path := preload("res://scripts/UserData.gd").file("session_test.json")
	SettingsStore.metrics_enabled = true
	MetricsCtl.path = test_path
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + ".tmp"))
	var m := MetricsCtl.new()
	m.begin_run(0)
	m.begin_student(0, 0, {"name": "测试学生"})
	await get_tree().create_timer(0.22).timeout
	m.finish_student(true, 2, 1, 0, 3, true, "concern")
	m.record_request("r-test", "scholarship", false)
	m.record_complaint()
	m.record_restart()
	m.finish_run(120, 5)
	var errors: Array = []
	var f := FileAccess.open(test_path, FileAccess.READ)
	if f == null:
		errors.append("session.json missing")
	else:
		var parsed: Variant = JSON.parse_string(f.get_as_text())
		f.close()
		if typeof(parsed) != TYPE_DICTIONARY:
			errors.append("session.json invalid")
		else:
			var sessions: Array = parsed.get("sessions", [])
			if sessions.size() != 1:
				errors.append("sessions=%d" % sessions.size())
			else:
				var run: Dictionary = sessions[0]
				if !bool(run.get("finished", false)):
					errors.append("run not finished")
				var students: Array = run.get("students", [])
				if students.size() != 1:
					errors.append("students=%d" % students.size())
				else:
					var st: Dictionary = students[0]
					if int(st.get("emptyCircles", 0)) != 3:
						errors.append("emptyCircles=%d" % int(st.get("emptyCircles", 0)))
					if !bool(st.get("askedHint", false)):
						errors.append("askedHint not recorded")
					if float(st.get("seconds", 0.0)) <= 0.0:
						errors.append("seconds not recorded")
				var totals: Dictionary = run.get("totals", {})
				if int(totals.get("requestBad", 0)) != 1:
					errors.append("requestBad=%d" % int(totals.get("requestBad", 0)))
				if int(totals.get("complaints", 0)) != 1:
					errors.append("complaints=%d" % int(totals.get("complaints", 0)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path + ".tmp"))
	SettingsStore.metrics_enabled = old_enabled
	MetricsCtl.path = old_path
	if errors.is_empty():
		print("METRICSCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("METRICSCHECK " + str(e))
		print("METRICSCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_request_doc(day_index: int) -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = day_index
	_begin_day()
	await get_tree().create_timer(0.45).timeout
	var first: Dictionary = requests.first_pending()
	if !first.is_empty() and int(first.get("queueIndex", -1)) >= 0:
		stu = int(first.get("queueIndex", 0))
		load_student(true)
	_open_request()
	await get_tree().create_timer(0.5).timeout
	await _snap("request-%s" % str(requests.first_pending().get("kind", "doc")))
	get_tree().quit()

func _dev_request_doc_id(day_index: int, doc_id: String, snap_name: String = "") -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = day_index
	_begin_day()
	await get_tree().create_timer(0.3).timeout
	var first: Dictionary = requests.first_pending()
	if !first.is_empty() and int(first.get("queueIndex", -1)) >= 0:
		stu = int(first.get("queueIndex", 0))
		load_student(true)
	_open_request("", doc_id)
	await get_tree().create_timer(0.45).timeout
	await _snap(snap_name if !snap_name.is_empty() else "request-%s" % doc_id)
	get_tree().quit()

func _dev_request_upper() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.3).timeout
	var first: Dictionary = requests.first_pending()
	if !first.is_empty() and int(first.get("queueIndex", -1)) >= 0:
		stu = int(first.get("queueIndex", 0))
		load_student(true)
	_open_request()
	await get_tree().create_timer(0.4).timeout
	if request_paper != null:
		request_paper.position = Vector2(430, 70)
	await get_tree().create_timer(0.25).timeout
	await _snap("request-upper")
	get_tree().quit()

func _dev_face_task() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.3).timeout
	_on_request_action("request-close")
	await get_tree().create_timer(0.3).timeout
	await _snap("face-task")
	get_tree().quit()

func _dev_face_blocked() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.3).timeout
	_on_request_action("request-close")
	selected = "pass"
	stamp_decision()
	await get_tree().create_timer(0.4).timeout
	await _snap("face-blocked")
	get_tree().quit()

func _dev_night_click() -> void:
	_dev_night(0)
	await get_tree().create_timer(0.25).timeout
	await _push_click(Vector2(390, 409))
	await get_tree().create_timer(0.2).timeout
	await _push_click(Vector2(1212, 796))

func _dev_night_click_check() -> void:
	_dev_night(0)
	await get_tree().create_timer(0.35).timeout
	var errors: Array = []
	if story_doc != 0:
		errors.append("night starts on doc %d" % story_doc)
	await _push_click(Vector2(390, 409))
	await get_tree().create_timer(0.12).timeout
	if story_doc != 1:
		errors.append("tab click did not open doc 1 (got %d)" % story_doc)
	await _push_click(Vector2(1148, 540))
	await get_tree().create_timer(0.12).timeout
	if story_doc != 2:
		errors.append("rail card click did not open doc 2 (got %d)" % story_doc)
	var key := InputEventKey.new()
	key.keycode = KEY_LEFT
	key.pressed = true
	Input.parse_input_event(key)
	await get_tree().create_timer(0.12).timeout
	if story_doc != 1:
		errors.append("left arrow did not open doc 1 (got %d)" % story_doc)
	if errors.is_empty():
		print("NIGHTCLICKCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("NIGHTCLICKCHECK " + str(e))
		print("NIGHTCLICKCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_request_check() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	var errors: Array = []
	if requests.pending_count() != 1:
		errors.append("expected 1 pending request, got %d" % requests.pending_count())
	var req: Dictionary = requests.first_pending()
	if str(req.get("kind", "")) != "scholarship":
		errors.append("wrong request kind %s" % str(req.get("kind", "")))
	var before := perf
	# The task is a card in "其他材料"; clicking it drags out the task file.
	var face_card: Control = null
	var want_task := str(requests.first_pending().get("id", ""))
	for c in materials_box.get_children():
		if c is Control and c.has_meta("material_id") and str(c.get_meta("material_id", "")).begins_with("req:"):
			if str(c.get_meta("task_id", "")) == want_task:
				face_card = c
				break
	if face_card == null:
		errors.append("task file card is missing from 其他材料")
	else:
		await _push_click(face_card.get_global_rect().get_center())
	await get_tree().create_timer(0.1).timeout
	if request_paper == null:
		errors.append("task file card click did not open the file")
	await get_tree().create_timer(0.1).timeout
	if request_paper == null:
		errors.append("request paper did not open")
	else:
		stamp_decision()
		if phase != "review":
			errors.append("stamping was allowed while request paper is open")
		var start: Vector2 = request_paper.get_global_position()
		await _push_drag(start + Vector2(100, 12), start + Vector2(-40, 70))
		if request_paper == null or request_paper.get_global_position().distance_to(start) < 2.0:
			errors.append("request file did not drag")
		# Loose papers must be able to travel up over the student/chat panels,
		# matching the dossier's upper bound instead of being trapped below y=368.
		var up_start: Vector2 = request_paper.get_global_position() + Vector2(100, 12)
		await _push_drag(up_start, Vector2(700, 110))
		var up_y := -1.0
		if request_paper != null:
			up_y = request_paper.position.y
		if request_paper == null or up_y > 140.0 or up_y < 64.0:
			errors.append("request file could not be dragged to the upper desk (y=%.1f)" % up_y)
	_on_request_action("request-approve")
	if perf != before - 40:
		errors.append("wrong approval perf=%d expected %d" % [perf, before - 40])
	if int(favor.get("director", 0)) < 2:
		errors.append("request favor director=%d" % int(favor.get("director", 0)))
	if requests.pending_count() != 0:
		errors.append("request was not marked done")
	# Re-open a clean day and take the correct return path.
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	var before2 := perf
	favor["student"] = 2
	await get_tree().create_timer(0.1).timeout
	var card2: Control = null
	var want2 := str(requests.first_pending().get("id", ""))
	for c in materials_box.get_children():
		if c is Control and c.has_meta("task_id") and str(c.get_meta("task_id", "")) == want2:
			card2 = c
			break
	if card2 == null:
		errors.append("second request card missing")
		_open_request()
	else:
		await _push_drag(card2.get_global_rect().get_center(), Vector2(700, 120))
		await get_tree().create_timer(0.12).timeout
		var dropped_y := -1.0
		if request_paper != null:
			dropped_y = request_paper.position.y
		if request_paper == null or dropped_y > 200.0:
			errors.append("material could not be dropped on the upper desk (y=%.1f)" % dropped_y)
	await get_tree().create_timer(0.15).timeout
	_on_request_action("request-return")
	if perf != before2 + 40:
		errors.append("correct return perf=%d expected %d" % [perf, before2 + 40])
	if int(favor.get("director", 0)) != 1:
		errors.append("request return favor director=%d" % int(favor.get("director", 0)))
	if int(favor.get("student", 0)) != 1:
		errors.append("request return favor student=%d" % int(favor.get("student", 0)))
	# All packet documents must build.
	var docs_view := preload("res://scripts/RequestDocs.gd")
	for r in RequestDataCtl.requests:
		for d in r.get("documents", []):
			var card: Control = docs_view.render(d, 430.0)
			if card == null or card.get_child_count() == 0:
				errors.append("failed to render request %s/%s" % [str(r.get("id", "")), str(d.get("id", ""))])
			elif card != null:
				card.free()
	if errors.is_empty():
		print("REQUESTCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("REQUESTCHECK " + str(e))
		print("REQUESTCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_request_flow() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	var errors: Array = []
	_end_day()
	if request_paper == null:
		errors.append("end-day did not open pending request")
	if phase != "review":
		errors.append("end-day advanced phase to %s before request" % phase)
	if requests.pending_count() != 1:
		errors.append("pending count changed before decision")
	_on_request_action("request-return")
	await get_tree().create_timer(0.15).timeout
	if phase != "dayend":
		errors.append("end-day did not resume after request (phase=%s)" % phase)
	if requests.pending_count() != 0:
		errors.append("pending request remains")
	if errors.is_empty():
		print("REQUESTFLOW ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("REQUESTFLOW " + str(e))
		print("REQUESTFLOW failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_face_check() -> void:
	_hide_modal()
	_reset_state()
	face_auto_present = true
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.28).timeout
	var errors: Array = []
	var active: Dictionary = requests.active_for_student(stu)
	if active.is_empty():
		errors.append("D2 start has no face task")
	if request_paper != null:
		errors.append("task file should wait in the rail until clicked")
	# clicking a rail card opens the task file; simulate that click
	_open_request()
	await get_tree().create_timer(0.1).timeout
	if request_paper == null:
		errors.append("clicking the task file did not open it")
	# close the packet, then try to stamp: the flow must not advance
	_on_request_action("request-close")
	await get_tree().create_timer(0.08).timeout
	selected = "pass"
	stamp_decision()
	if phase != "review":
		errors.append("stamp advanced while a face task was pending (phase=%s)" % phase)
	if request_paper == null:
		errors.append("blocked stamp did not reopen the packet")
	var held_stu := stu
	_next_student()
	if stu != held_stu:
		errors.append("next-student advanced with a pending face task")
	# deciding the packet correctly unlocks the queue
	_on_request_action("request-return")
	await get_tree().create_timer(0.12).timeout
	if requests.pending_count() != 0:
		errors.append("correct face decision did not clear the task")
	_next_student()
	if stu != 1:
		errors.append("next student did not advance after the task was filed (stu=%d)" % stu)
	if request_paper != null:
		errors.append("next student inherited the previous packet")
	if errors.is_empty():
		print("FACECHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("FACECHECK " + str(e))
		print("FACECHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_face_future_check() -> void:
	_hide_modal()
	_reset_state()
	face_auto_present = true
	phase = "review"
	day = 3
	_begin_day()
	await get_tree().create_timer(0.25).timeout
	var errors: Array = []
	if !requests.active_for_student(0).is_empty():
		errors.append("D4 student 0 should have no packet")
	if request_paper != null:
		errors.append("D4 student 0 opened a packet too early")
	_next_student()
	await get_tree().create_timer(0.2).timeout
	if stu != 1:
		errors.append("did not reach D4 student 1")
	if requests.active_for_student(1).is_empty():
		errors.append("D4 student 1 task missing")
	if request_paper != null:
		errors.append("D4 student 1 task opened without a click")
	_open_request()
	await get_tree().create_timer(0.08).timeout
	if request_paper == null:
		errors.append("D4 student 1 task file did not open")
	_on_request_action("request-return")
	await get_tree().create_timer(0.1).timeout
	_next_student()
	await get_tree().create_timer(0.2).timeout
	if stu != 2:
		errors.append("did not reach D4 student 2")
	_open_request()
	await get_tree().create_timer(0.08).timeout
	if request_paper == null:
		errors.append("D4 student 2 task file did not open")
	_on_request_action("request-approve")
	await get_tree().create_timer(0.1).timeout
	_next_student()
	if stu != 3:
		errors.append("D4 queue did not continue after both packets (stu=%d)" % stu)
	if errors.is_empty():
		print("FACEFUTURECHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("FACEFUTURECHECK " + str(e))
		print("FACEFUTURECHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_request_packet_check() -> void:
	_hide_modal()
	_reset_state()
	face_auto_present = true
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.28).timeout
	var errors: Array = []
	var req: Dictionary = requests.active_for_student(stu)
	if req.is_empty():
		errors.append("no active scholarship packet")
	var docs: Array = req.get("documents", [])
	if docs.size() < 4:
		errors.append("scholarship packet should contain 4 documents, got %d" % docs.size())
	var styles := {}
	var docs_script := preload("res://scripts/RequestDocs.gd")
	for doc in docs:
		styles[str(doc.get("style", ""))] = true
		var card: Control = docs_script.render(doc, 430.0)
		if card == null:
			errors.append("document card is null: %s" % str(doc.get("id", "")))
		else:
			card.free()
	for wanted in ["certificate", "sealed", "carbonless", "mimeo"]:
		if !styles.has(wanted):
			errors.append("missing paper style: " + wanted)
	var rendered_docs := 0
	for r in RequestDataCtl.requests:
		for d in r.get("documents", []):
			var holder := Control.new()
			add_child(holder)
			var sheet: Control = docs_script.render(d, 500.0)
			if sheet == null:
				errors.append("failed to render request doc %s/%s" % [str(r.get("id", "")), str(d.get("id", ""))])
			else:
				holder.add_child(sheet)
			holder.queue_free()
			rendered_docs += 1
	if rendered_docs < 20:
		errors.append("too few request docs rendered: %d" % rendered_docs)
	_open_request()
	await get_tree().create_timer(0.12).timeout
	if request_paper == null:
		errors.append("task file was not open for button inspection")
	else:
		var buttons: Array = request_paper.find_children("*", "Button", true, false)
		var found := {}
		for n in buttons:
			var b := n as Button
			if b == null:
				continue
			var t := b.text.replace(" ", "")
			if t == "批准" or t == "退回":
				found[t] = true
				var fs := b.get_theme_font_size("font_size")
				var min_h: float = b.custom_minimum_size.y
				if fs < 16:
					errors.append("%s button font too small: %d" % [t, fs])
				if min_h < 44.0:
					errors.append("%s button too short: %.1f" % [t, min_h])
		if !found.has("批准") or !found.has("退回"):
			errors.append("approve/return buttons missing from packet")
	# data wiring: each task is attached to the correct queue slot
	for r in RequestDataCtl.requests:
		if int(r.get("day", 0)) < 1:
			continue
		var rows := RequestDataCtl.for_day(int(r.get("day", 1)) - 1)
		var matched := false
		for row in rows:
			if str(row.get("id", "")) == str(r.get("id", "")):
				matched = true
				if str(row.get("applicantId", "")) == "":
					errors.append("request %s has no applicantId" % str(r.get("id", "")))
				if int(row.get("queueIndex", -1)) < 0:
					errors.append("request %s has no queueIndex" % str(r.get("id", "")))
		if !matched:
			errors.append("request %s not resolved by RequestData.for_day" % str(r.get("id", "")))
	if errors.is_empty():
		print("REQUESTPACKETCHECK ok docs=%d styles=%d rendered=%d" % [docs.size(), styles.size(), rendered_docs])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("REQUESTPACKETCHECK " + str(e))
		print("REQUESTPACKETCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_request_stamp() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.25).timeout
	_open_request()
	await get_tree().create_timer(0.25).timeout
	_on_request_action("request-approve")
	await get_tree().create_timer(0.1).timeout
	await _snap("request-stamp")
	get_tree().quit()

func _dev_event_doc(day_index: int, task_id: String, snap_name: String) -> void:
	_hide_modal()
	_reset_state()
	face_auto_present = true
	phase = "review"
	day = day_index
	_begin_day()
	await get_tree().create_timer(0.25).timeout
	var req: Dictionary = requests.get_request(task_id)
	if req.is_empty():
		push_error("event task not on today's queue: " + task_id)
		get_tree().quit(1)
		return
	stu = int(req.get("queueIndex", 0))
	face_prompted_for = -1
	load_student(true)
	await get_tree().create_timer(0.2).timeout
	present_for_current_student()
	open_task_file(task_id)
	await get_tree().create_timer(0.4).timeout
	await _snap(snap_name)
	get_tree().quit()

func _dev_event_check() -> void:
	var ids := ["exchange-d3-exchange", "lab-d5-access", "internship-d6-recommend"]
	var errors: Array = []
	var docs_script := preload("res://scripts/RequestDocs.gd")
	var total_docs := 0
	for tid in ids:
		var req: Dictionary = {}
		for r in RequestDataCtl.requests:
			if str(r.get("id", "")) == tid:
				req = r
				break
		if req.is_empty():
			errors.append("missing event task: " + tid)
			continue
		var row: Dictionary = {}
		for r in RequestDataCtl.for_day(int(req.get("day", 1)) - 1):
			if str(r.get("id", "")) == tid:
				row = r
				break
		if row.is_empty() or int(row.get("queueIndex", -1)) < 0:
			errors.append("%s has no queueIndex" % tid)
		if str(row.get("applicantId", "")) == "":
			errors.append("%s has no applicantId" % tid)
		var docs: Array = req.get("documents", [])
		if docs.size() < 3:
			errors.append("%s should have at least 3 documents" % tid)
		var styles := {}
		for d in docs:
			styles[str(d.get("style", ""))] = true
			var sheet: Control = docs_script.render(d, 430.0)
			if sheet == null or sheet.get_child_count() == 0:
				errors.append("failed to render %s/%s" % [tid, str(d.get("id", ""))])
			if sheet != null:
				sheet.free()
			total_docs += 1
		if !styles.has("passport") and tid == "exchange-d3-exchange":
			errors.append("exchange is missing passport-page style")
		if !styles.has("id_card") and tid == "lab-d5-access":
			errors.append("lab is missing id-card safety style")
		if !styles.has("cardstock") and tid == "internship-d6-recommend":
			errors.append("internship is missing cardstock recommendation")
		# Open the main task file on its actual day/slot.
		_hide_modal()
		_reset_state()
		phase = "review"
		day = int(req.get("day", 1)) - 1
		_begin_day()
		await get_tree().create_timer(0.15).timeout
		stu = int(row.get("queueIndex", 0))
		load_student(true)
		await get_tree().create_timer(0.12).timeout
		open_task_file(tid)
		await get_tree().create_timer(0.15).timeout
		if request_paper == null:
			errors.append("%s did not open its task file" % tid)
		else:
			var buttons: Array = request_paper.find_children("*", "Button", true, false)
			var has_approve := false
			var has_return := false
			for n in buttons:
				var b := n as Button
				if b == null:
					continue
				var text := b.text.replace(" ", "")
				has_approve = has_approve or text == "批准"
				has_return = has_return or text == "退回"
			if !has_approve or !has_return:
				errors.append("%s task file is missing approve/return" % tid)
		_close_request_windows()
	if errors.is_empty():
		print("EVENTCHECK ok tasks=%d docs=%d" % [ids.size(), total_docs])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("EVENTCHECK " + str(e))
		print("EVENTCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_stamp_check() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 1
	_begin_day()
	await get_tree().create_timer(0.2).timeout
	var errors: Array = []
	if stamp_mark_holder == null or stamp_mark_holder.get_parent() != stamp_target:
		errors.append("stamp ink is not clipped inside the stamp target")
	if stamp_target == null or stamp_target.get_global_rect().position != Vector2(966, 780):
		errors.append("stamp target moved unexpectedly")
	if stamp_target != null and stamp_target.get_parent().z_index >= layer_loose.z_index:
		errors.append("stamp target is above loose material files")
	if sfx != null and (!sfx.streams.has("approve") or !sfx.streams.has("return")):
		errors.append("approve/return sound cues missing")
	# A document seal must not use a positive relative z_index: it would escape
	# its 520px window and draw on top of a second overlapping material.
	var leave_task: Dictionary = {}
	for r in RequestDataCtl.requests:
		if str(r.get("id", "")) == "leave-d1-1d":
			leave_task = r
			break
	var leave_doc: Dictionary = {}
	for d in leave_task.get("documents", []):
		if str(d.get("id", "")) == "leave-form":
			leave_doc = d
			break
	if leave_doc.is_empty():
		errors.append("leave-form document missing")
	else:
		var sheet: Control = preload("res://scripts/RequestDocs.gd").render(leave_doc, 430.0)
		var seals := 0
		for n in sheet.find_children("*", "Control", true, false):
			if n is RequestSeal:
				seals += 1
				if n.z_index != 0:
					errors.append("document seal has relative z_index=%d" % n.z_index)
		if seals == 0:
			errors.append("leave-form seal was not rendered")
		sheet.free()
	_open_request()
	await get_tree().create_timer(0.12).timeout
	if request_paper == null:
		errors.append("stampcheck could not open a task file")
	else:
		# A material window covers the stamp target; dropping a stamp through it
		# must not stamp the thesis or place ink on the wrong layer.
		drag_state = {"kind": "stamp", "type": "pass", "moved": true, "ghost": null}
		_end_drag(stamp_target.get_global_rect().get_center())
		drag_state = {}
		if phase != "review":
			errors.append("stamp went through an open material file")
		if stamp_mark_holder.get_child_count() != 0:
			errors.append("stamp ink appeared while a material covered the target")
		_close_request_windows()
	# With the desk clear, the ink belongs in the dedicated layer.
	_show_stamp_mark("pass")
	if stamp_mark_holder.get_child_count() == 0:
		errors.append("stamp ink did not render after clearing the material")
	if stamp_mark_holder.get_parent() != stamp_target:
		errors.append("stamp ink moved off the stamp target after rendering")
	if errors.is_empty():
		print("STAMPCHECK ok target=%s loose_z=%d" % [str(stamp_target.get_global_rect().position), layer_loose.z_index])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("STAMPCHECK " + str(e))
		print("STAMPCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_stamp_mark() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	await get_tree().create_timer(0.25).timeout
	selected = "pass"
	_show_stamp_mark("pass")
	await get_tree().create_timer(0.3).timeout
	await _snap("stampmark")
	get_tree().quit()

func _dev_stamp_overlap() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	await get_tree().create_timer(0.25).timeout
	var task: Dictionary = requests.first_pending()
	var tid := str(task.get("id", ""))
	# D1: leave form first, clinic appointment slip second. The second window
	# must cover the first window's school seal, not inherit it.
	open_request_doc_file(tid, "leave-form")
	await get_tree().create_timer(0.12).timeout
	open_request_doc_file(tid, "clinic-slip")
	await get_tree().create_timer(0.2).timeout
	for wid in loose_files.keys():
		var win: Control = loose_files[wid]
		if !is_instance_valid(win):
			continue
		if str(win.get_meta("request_doc_id", "")) == "leave-form":
			win.position = Vector2(420, 325)
		else:
			win.position = Vector2(680, 455)
			desktop.bring_front(win)
	await get_tree().create_timer(0.3).timeout
	await _snap("stamp-overlap")
	get_tree().quit()

func _dev_style_check() -> void:
	_hide_modal()
	_reset_state()
	var styles := [
		"certificate", "sealed", "mimeo", "carbonless", "cardstock",
		"student_id", "id_card", "scholarship", "admission", "ledger",
		"index_card", "passport", "boarding",
	]
	var docs_script := preload("res://scripts/RequestDocs.gd")
	var errors: Array = []
	for style in styles:
		var doc := {
			"style": style,
			"org": "明州大学 · 材料样本",
			"title": "材料样式 · %s" % style,
			"subtitle": "STOCK SAMPLE / 纸张与材料样式",
			"ref": "MZ-2026-%s" % style.substr(0, 3).to_upper(),
			"photo": style in ["student_id", "id_card", "passport"],
			"fields": [["姓名", "王芷晴"], ["学号", "2022010516"], ["学院", "商学院"], ["专业", "会计学"]],
			"stats": [{"k": "样式", "v": style}, {"k": "用途", "v": "材料样本"}],
			"paragraphs": [{"label": "说明", "text": "这是 %s 纸张样式的运行时渲染样本，用于验证字体、栏线、印章和裁切。" % style}],
			"signature": ["教务处 · 2026.05.12"],
			"seal": {"top": "明州大学", "bottom": "教务处", "date": "2026.05.12"},
			"note": "样本材料 · 不进入正式待办",
		}
		var sheet: Control = docs_script.render(doc, 430.0)
		if sheet == null or sheet.get_child_count() == 0:
			errors.append("style failed: " + style)
		if sheet != null:
			sheet.free()
	if errors.is_empty():
		print("STYLECHECK ok styles=%d" % styles.size())
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("STYLECHECK " + str(e))
		print("STYLECHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_style_gallery() -> void:
	_hide_modal()
	_reset_state()
	var bg := ColorRect.new()
	bg.color = Color("#2b2418")
	bg.z_index = 500
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)
	Ui.place(bg, 0, 0, 1380, 860)
	var title := Ui.label(bg, "材料样式样本 / MATERIAL STOCK GALLERY", 28, 16, 1320, 24, 16, Color("#e8d6ae"), Ui.F_DOC_BOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 10)
	bg.add_child(grid)
	Ui.place(grid, 22, 52, 1336, 790)
	var styles := ["student_id", "id_card", "scholarship", "admission", "ledger", "index_card", "passport", "boarding"]
	var docs_script := preload("res://scripts/RequestDocs.gd")
	for style in styles:
		var doc := {
			"style": style,
			"org": "明州大学",
			"title": "材料样本",
			"subtitle": style.to_upper(),
			"ref": "MZ-2026-%s" % style.substr(0, 3).to_upper(),
			"photo": style in ["student_id", "id_card", "passport"],
			"fields": [["姓名", "王芷晴"], ["学院", "商学院"]],
			"signature": ["教务处 · 2026.05"],
			"seal": {"top": "明州大学", "bottom": "教务处", "date": "2026.05.12"},
		}
		var sheet: Control = docs_script.render(doc, 315.0)
		grid.add_child(sheet)
	await get_tree().create_timer(0.5).timeout
	await _snap("style-gallery")
	get_tree().quit()

func _dev_night_ending() -> void:
	_hide_modal()
	_reset_state()
	day = 6
	perf = 4800
	rep = 5
	phase = "review"
	_begin_day()
	_start_night_story()
	_on_story_choice(0)
	_finish_night_story()

func _dev_night_doc(d: int, idx: int) -> void:
	_hide_modal()
	_reset_state()
	day = d
	phase = "review"
	_begin_day()
	_start_night_story()
	_open_story_doc(idx)

func _story_doc_all() -> void:
	var n := 0
	for scene in GameData.night_scenes:
		for doc in scene.get("docs", []):
			var holder := Control.new()
			add_child(holder)
			holder.add_child(StoryDocs.render(doc, {"student": "测试", "studentId": "2022000000", "date": "2026.05.11", "verdict": "通过", "verdictLabel": "通过"}))
			holder.queue_free()
			n += 1
	print("STORYDOCALL rendered ", n)
	await get_tree().process_frame
	get_tree().quit()

func _dev_verdict() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	var audit := GameData.audit(current, day)
	_select_stamp(str(audit.get("expected", "pass")))
	stamp_decision()

func _dev_trace_loop(center: Vector2, rx: float, ry: float) -> void:
	var a := center - Vector2(rx, ry)
	var b := center + Vector2(rx, ry)
	_begin_annotation(a)
	_update_annotation(b)
	_finish_annotation(b)

func _dev_annotation(correct: bool, blank: bool = false) -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1 if correct else 0
	load_student(true)
	tab = "cover"
	render_tabs()
	render_doc()
	await get_tree().process_frame
	_toggle_annotation()
	if blank:
		_begin_annotation(Vector2(300, 720))
		_update_annotation(Vector2(380, 760))
		_finish_annotation(Vector2(380, 760))
	else:
		_dev_trace_loop(Vector2(735, 592), 120, 35)
	await get_tree().create_timer(0.75).timeout
	await _snap("annotate" if correct and !blank else ("annotateblank" if blank else "annotatewrong"))
	get_tree().quit()

func _dev_chat(with_reply: bool) -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	if with_reply:
		stu = 1
		load_student(true)
		await get_tree().create_timer(4.5).timeout
		_on_chat_reply(1)
		await get_tree().create_timer(1.0).timeout
		await _snap("chat-reply")
	else:
		await get_tree().create_timer(4.5).timeout
		await _snap("chat-all")
	get_tree().quit()

func _dev_chat_defect() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1
	load_student(true)
	await get_tree().create_timer(4.5).timeout
	_on_chat_reply(1)
	await get_tree().create_timer(1.2).timeout
	await _snap("chat-defect")
	get_tree().quit()

func _dev_chat_choices() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1
	load_student(true)
	await get_tree().create_timer(4.5).timeout
	await _snap("chat-defect-choices")
	get_tree().quit()

func _dev_rule_check() -> void:
	var all_rules := {}
	var active_by_day := {}
	for g in GameData.rules:
		var code := str(g.get("code", ""))
		var rs: Array = g.get("rules", [])
		for i in range(rs.size()):
			all_rules["%s%d" % [code, i + 1]] = true
		var active := []
		for d in range(7):
			if int(g.get("day", 99)) <= d + 1:
				active.append(d)
		active_by_day[str(g.get("id", ""))] = active
	var covered := {}
	var errors: Array = []
	for di in range(7):
		for si in range(GameData.student_count(di)):
			var s := GameData.student(di, si)
			var au := GameData.audit(s, di)
			for d in au.get("defects", []):
				var rule := str(d.get("rule", ""))
				var group := str(d.get("group", ""))
				var anchor := str(d.get("anchor", ""))
				if !all_rules.has(rule):
					errors.append("D%d S%d bad rule=%s" % [di + 1, si + 1, rule])
				else:
					covered[rule] = true
				if !active_by_day.get(group, []).has(di):
					errors.append("D%d S%d inactive group=%s" % [di + 1, si + 1, group])
				if !AuditRegions.supports(anchor):
					errors.append("D%d S%d missing anchor=%s" % [di + 1, si + 1, anchor])
				if str(d.get("label", "")) == "":
					errors.append("D%d S%d missing label=%s" % [di + 1, si + 1, anchor])
			var critical := false
			for d in au.get("defects", []):
				if str(d.get("severity", "")) == "critical":
					critical = true
			var expected := "reject" if critical else ("revise" if au.get("defects", []).size() > 0 else "pass")
			if expected != str(au.get("expected", "")):
				errors.append("D%d S%d expected mismatch" % [di + 1, si + 1])
	var missing: Array = []
	for code in all_rules.keys():
		if !covered.has(code):
			missing.append(code)
	for code in missing:
		errors.append("uncovered rule=%s" % code)
	if errors.is_empty():
		print("RULECHECK ok rules=%d covered=%d" % [all_rules.size(), covered.size()])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("RULECHECK " + str(e))
		print("RULECHECK failed errors=%d covered=%d/%d" % [errors.size(), covered.size(), all_rules.size()])
		get_tree().quit(1)

func _dev_chat_pause() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	await get_tree().create_timer(0.9).timeout
	var before := chat_box.get_child_count()
	_show_help()
	await get_tree().create_timer(2.0).timeout
	var during := chat_box.get_child_count()
	_hide_modal()
	await get_tree().create_timer(4.5).timeout
	var after := chat_box.get_child_count()
	if before == during and after > during:
		print("CHATPAUSE ok before=%d during=%d after=%d" % [before, during, after])
		get_tree().quit(0)
	else:
		push_error("CHATPAUSE before=%d during=%d after=%d" % [before, during, after])
		print("CHATPAUSE failed")
		get_tree().quit(1)

func _dev_annotation_check() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1
	load_student(true)
	tab = "cover"
	render_tabs()
	render_doc()
	await get_tree().process_frame
	await get_tree().process_frame
	var errors: Array = []
	var id_rect := AnnotationCtl.rect_for("identity.id", "cover", doc_box, annotation_content)
	if id_rect.size.x <= 0.0:
		errors.append("dynamic cover anchor missing")
	else:
		var hit := _defect_for_circle(id_rect.get_center())
		if hit.is_empty() or str(hit.get("group", "")) != "identity":
			errors.append("dynamic anchor center did not hit identity")
		var near := AnnotationCtl.near_miss(id_rect.position - Vector2(30, 0), "cover",
			GameData.audit(current, day).get("defects", []), doc_box, annotation_content, ann.found)
		if near.is_empty():
			errors.append("near miss found nothing next to a real anchor")
	if !_defect_for_circle(Vector2(20, 900)).is_empty():
		errors.append("blank area hit a defect")
	_toggle_annotation()
	var a := annotation_content.get_global_position() + id_rect.position - Vector2(12, 10)
	var b := annotation_content.get_global_position() + id_rect.end + Vector2(12, 10)
	_begin_annotation(a)
	_update_annotation(b)
	_finish_annotation(b)
	if !ann.marks.has("cover") or ann.marks["cover"].size() != 1:
		errors.append("valid annotation not stored")
	if perf != 20:
		errors.append("valid annotation did not award 20, perf=%d" % perf)
	if day_annotation_count != 1:
		errors.append("day annotation count not incremented")
	var mark: Dictionary = ann.marks["cover"][0]
	if str(mark.get("label", "")) == "身份 / 题目不一致":
		errors.append("annotation label is still group-level")
	switch_tab("abstract")
	switch_tab("cover")
	if !ann.marks.has("cover") or ann.marks["cover"].size() != 1:
		errors.append("annotation lost on tab switch")
	_undo_annotation()
	if perf != 0 or ann.awarded != 0 or !ann.found.is_empty():
		errors.append("undo did not refund/reset")
	if day_annotation_count != 0:
		errors.append("undo did not decrement day annotation count")
	_begin_annotation(annotation_content.get_global_position() + Vector2(300, 800))
	_update_annotation(annotation_content.get_global_position() + Vector2(380, 840))
	_finish_annotation(annotation_content.get_global_position() + Vector2(380, 840))
	if ann.marks.has("cover") and !ann.marks["cover"].is_empty():
		errors.append("blank annotation was stored")
	if ann.attempts.is_empty() or bool(ann.attempts[-1].get("hit", true)):
		errors.append("missed circle was not recorded for replay")

	# Per-item reference anchor.
	var ref_case := _find_student_with("refs.item.")
	if ref_case.is_empty():
		errors.append("no student with per-item reference defect")
	else:
		day = int(ref_case.get("day", 0))
		stu = int(ref_case.get("stu", 0))
		load_student(true)
		tab = "refs"
		render_tabs()
		render_doc()
		await get_tree().process_frame
		await get_tree().process_frame
		var au := GameData.audit(current, day)
		var ref_def: Dictionary = {}
		for d in au.get("defects", []):
			if str(d.get("anchor", "")).begins_with("refs.item."):
				ref_def = d
				break
		var rr := AnnotationCtl.rect_for(str(ref_def.get("anchor", "")), "refs", doc_box, annotation_content)
		if rr.size.x <= 0.0:
			errors.append("per-item ref anchor has no rect")
		else:
			var rh := _defect_for_circle(rr.get_center())
			if str(rh.get("anchor", "")) != str(ref_def.get("anchor", "")):
				errors.append("per-item ref anchor did not hit")

	# Signature anchors (three separate cells).
	var sig_case := _find_student_with("form.sig.")
	if sig_case.is_empty():
		errors.append("no student with signature defect")
	else:
		day = int(sig_case.get("day", 0))
		stu = int(sig_case.get("stu", 0))
		load_student(true)
		tab = "form"
		render_tabs()
		render_doc()
		await get_tree().process_frame
		await get_tree().process_frame
		var au2 := GameData.audit(current, day)
		var sig_count := 0
		var seen := {}
		for d in au2.get("defects", []):
			if str(d.get("anchor", "")).begins_with("form.sig."):
				sig_count += 1
				seen[str(d.get("anchor", ""))] = true
		if sig_count < 1:
			errors.append("signature defects missing")
		for anchor in seen.keys():
			var sr := AnnotationCtl.rect_for(str(anchor), "form", doc_box, annotation_content)
			if sr.size.x <= 0.0:
				errors.append("signature anchor has no rect: " + str(anchor))

	if errors.is_empty():
		print("ANNOTCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("ANNOTCHECK " + str(e))
		print("ANNOTCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _find_student_with(prefix: String) -> Dictionary:
	for di in range(7):
		for si in range(GameData.student_count(di)):
			var au := GameData.audit(GameData.student(di, si), di)
			for d in au.get("defects", []):
				if str(d.get("anchor", "")).begins_with(prefix):
					return {"day": di, "stu": si}
	return {}

func _dev_anchors() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	tab = "cover"
	render_tabs()
	render_doc()
	_toggle_anchor_debug()
	await get_tree().create_timer(0.5).timeout
	await _snap("anchor-debug")
	get_tree().quit()

func _dev_anchors_form() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 5
	_begin_day()
	stu = 1
	load_student(true)
	tab = "form"
	render_tabs()
	render_doc()
	_toggle_anchor_debug()
	await get_tree().create_timer(0.5).timeout
	await _snap("anchor-form")
	get_tree().quit()

func _dev_anchors_dup() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 2
	_begin_day()
	stu = 1
	load_student(true)
	tab = "dup"
	render_tabs()
	render_doc()
	_toggle_anchor_debug()
	await get_tree().create_timer(0.5).timeout
	await _snap("anchor-dup")
	get_tree().quit()

func _dev_pen_click() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	await get_tree().create_timer(0.5).timeout
	await _push_click(Vector2(742, 811))
	await get_tree().create_timer(0.4).timeout
	await _snap("pen-active")
	get_tree().quit()

func _dev_shift_stats() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	daily_correct = 3
	daily_wrong = 1
	day_annotation_count = 2
	day_chat_replies = [1, 0]
	chat.style = "concern"
	chat.hint_label = "第7条：百度百科"
	chat.last_reply = "可能是%s，麻烦您帮我看看。" % chat.hint_label
	chat_student = current
	time_saved_total = 10
	clock = 17 * 60 + 10
	_end_day()

func _dev_chat_check() -> void:
	var errors: Array = []
	var checked := 0
	for di in range(7):
		for si in range(GameData.student_count(di)):
			var s := GameData.student(di, si)
			var script := ChatScript.build(s, di)
			if script.has("dialogue"):
				var authored: Dictionary = script.get("dialogue", {})
				var authored_nodes: Array = authored.get("nodes", [])
				if authored_nodes.is_empty() or str(authored.get("start", "")).is_empty():
					errors.append("D%d S%d malformed authored dialogue" % [di + 1, si + 1])
				checked += 1
				continue
			var au := GameData.audit(s, di)
			var need: bool = au.get("defects", []).size() > 0
			var events: Array = script.get("events", [])
			if bool(script.get("needs_reply", false)) != need:
				errors.append("D%d S%d needs_reply mismatch" % [di + 1, si + 1])
			var students := 0
			var autos := 0
			for ev in events:
				if str(ev.get("kind", "")) == "student":
					students += 1
				elif str(ev.get("kind", "")) == "auto":
					autos += 1
				if str(ev.get("text", "")).strip_edges() == "":
					errors.append("D%d S%d empty event" % [di + 1, si + 1])
			if students < 3:
				errors.append("D%d S%d too few student events" % [di + 1, si + 1])
			if need and autos != 2:
				errors.append("D%d S%d auto count %d != 2" % [di + 1, si + 1, autos])
			if !need and autos != 3:
				errors.append("D%d S%d auto count %d != 3" % [di + 1, si + 1, autos])
			var last := ""
			if !events.is_empty():
				last = str(events[-1].get("kind", ""))
			if need and last != "student":
				errors.append("D%d S%d manual path does not end on student" % [di + 1, si + 1])
			if !need and last != "auto":
				errors.append("D%d S%d auto path does not end on auto" % [di + 1, si + 1])
			checked += 1
	if errors.is_empty():
		print("CHATCHECK ok students=%d" % checked)
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("CHATCHECK " + str(e))
		print("CHATCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_annotation_scroll() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 3
	_begin_day()
	stu = 2
	load_student(true)
	tab = "refs"
	render_tabs()
	render_doc()
	_toggle_annotation()
	_dev_trace_loop(Vector2(642, 650), 180, 45)
	doc_scroll.scroll_vertical = 64
	_sync_annotation_offset()
	await get_tree().create_timer(0.6).timeout
	await _snap("annotate-scroll")
	get_tree().quit()

func _dev_annotation_refs() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	var found := _find_student_with("refs.item.")
	if found.is_empty():
		push_error("no refs.item student")
		get_tree().quit(1)
		return
	day = int(found.get("day", 0))
	_begin_day()
	stu = int(found.get("stu", 0))
	load_student(true)
	tab = "refs"
	render_tabs()
	render_doc()
	await get_tree().process_frame
	await get_tree().process_frame
	var au := GameData.audit(current, day)
	var target: Dictionary = {}
	for d in au.get("defects", []):
		if str(d.get("anchor", "")).begins_with("refs.item."):
			target = d
			break
	var r := AnnotationCtl.rect_for(str(target.get("anchor", "")), "refs", doc_box, annotation_content)
	_toggle_annotation()
	_begin_annotation(annotation_content.get_global_position() + r.position - Vector2(12, 8))
	_update_annotation(annotation_content.get_global_position() + r.end + Vector2(12, 8))
	_finish_annotation(annotation_content.get_global_position() + r.end + Vector2(12, 8))
	await get_tree().create_timer(0.7).timeout
	await _snap("annotation-refs")
	get_tree().quit()

func _dev_stamp_click() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	await get_tree().create_timer(0.35).timeout
	await _push_click(Vector2(450, 811))

func _dev_stamp_miss() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	await get_tree().create_timer(0.35).timeout
	await _push_drag(Vector2(450, 811), Vector2(1200, 700))

func _dev_selected() -> void:
	_hide_modal()
	_reset_state()
	day = 1
	phase = "review"
	_begin_day()
	tab = "refs"
	render_tabs()
	render_doc()
	_select_stamp("revise")
	open_loose("opening", Vector2(520, 430))

func _dev_night_mail() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1
	load_student(true)
	await get_tree().create_timer(4.8).timeout
	_on_chat_reply(0)
	await get_tree().create_timer(1.4).timeout
	_start_night_story()
	await get_tree().create_timer(0.5).timeout
	var docs := _story_docs()
	var idx := -1
	for i in range(docs.size()):
		if str(docs[i].get("kind", "")) == "email":
			idx = i
			break
	if idx == -1:
		push_error("NIGHTMAIL no generated email")
		print("NIGHTMAIL failed docs=%d" % docs.size())
		get_tree().quit(1)
		return
	_open_story_doc(idx)
	await get_tree().create_timer(0.6).timeout
	print("NIGHTMAIL ok docs=%d email=%d" % [docs.size(), idx])
	await _snap("nightmail")
	get_tree().quit()

func _dev_chat_flow() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1
	load_student(true)
	await get_tree().create_timer(4.8).timeout
	var errors: Array = []
	var visible := 0
	for b in chat_reply_btns:
		if b.visible:
			visible += 1
	if visible != 3:
		errors.append("expected 3 reply buttons, got %d" % visible)
	if chat_reply_btns.size() > 1 and str(chat_reply_btns[1].text) != "最担心哪项？":
		errors.append("concern button label wrong: " + str(chat_reply_btns[1].text))
	if !str(chat_status.text).contains("只能回复一次"):
		errors.append("chat status does not warn about the single reply")
	_on_chat_reply(1)
	await get_tree().create_timer(1.6).timeout
	if !chat.asked:
		errors.append("concern reply was not recorded")
	if str(chat.hint_group) == "":
		errors.append("concern reply produced no hint")
	if errors.is_empty():
		print("CHATFLOW ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("CHATFLOW " + str(e))
		print("CHATFLOW failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_chat_dialogue() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	_begin_day()
	stu = 1
	load_student(true)
	await get_tree().create_timer(0.2).timeout
	current["dialogue"] = {
		"start": "n1",
		"nodes": [
			{"id": "n1", "speaker": "student", "text": "老师好，材料我放窗口了。", "next": "n2"},
			{"id": "n2", "speaker": "student", "text": "有一处我不太确定，您能帮我看看吗？", "next": "", "choices": [
				{"label": "按清单核对", "next": "n3", "style": "checklist"},
				{"label": "最担心哪项？", "next": "n4", "style": "concern"},
				{"label": "先放桌上", "next": "n5", "style": "desk", "timeSaved": 10},
			]},
			{"id": "n3", "speaker": "student", "text": "好的，我按清单再核一遍。", "next": "", "choices": [
				{"label": "那你去改吧", "next": "n6"},
			]},
			{"id": "n4", "speaker": "student", "text": "可能是参考文献那一页。", "next": "n6"},
			{"id": "n5", "speaker": "student", "text": "好，那我先放桌上。", "next": "n6"},
			{"id": "n6", "speaker": "auto", "text": "收到，改完放窗口就好。"},
		],
	}
	_start_chat()
	await get_tree().create_timer(2.0).timeout
	var errors: Array = []
	var visible := 0
	for b in chat_reply_btns:
		if b.visible:
			visible += 1
	if visible != 3:
		errors.append("custom dialogue expected 3 choices, got %d" % visible)
	if !chat_dialogue_active:
		errors.append("custom dialogue was not activated")
	await _snap("chat-dialogue-choices")
	_on_chat_reply(0)
	await get_tree().create_timer(1.1).timeout
	var branch_visible := 0
	for b in chat_reply_btns:
		if b.visible:
			branch_visible += 1
	if branch_visible != 1:
		errors.append("follow-up should show 1 choice, got %d" % branch_visible)
	if branch_visible == 1 and !str(chat_reply_btns[0].text).contains("改"):
		errors.append("follow-up label wrong: " + str(chat_reply_btns[0].text))
	_on_chat_reply(0)
	await get_tree().create_timer(1.2).timeout
	if str(chat.last_reply).is_empty():
		errors.append("custom dialogue did not record the last reply")
	if !str(chat_status.text).is_empty():
		errors.append("custom dialogue end status should be blank, got: " + str(chat_status.text))
	if chat_auto_note != null and chat_auto_note.visible:
		errors.append("custom dialogue end should not show the auto note")
	if errors.is_empty():
		print("CHATDIALOGUE ok nodes=6")
		await _snap("chat-dialogue")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("CHATDIALOGUE " + str(e))
		print("CHATDIALOGUE failed errors=%d" % errors.size())
		get_tree().quit(1)

func _push_key(code: int) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	get_viewport().push_input(e)
	await get_tree().process_frame
	var r := InputEventKey.new()
	r.keycode = code
	r.physical_keycode = code
	r.pressed = false
	get_viewport().push_input(r, true)
	await get_tree().process_frame

func _dev_save_check() -> void:
	var errors: Array = []
	var had := FileAccess.file_exists(GameState.PATH)
	var backup := ""
	if had:
		var bf := FileAccess.open(GameState.PATH, FileAccess.READ)
		if bf != null:
			backup = bf.get_as_text()
			bf.close()
	_reset_state()
	day = 3
	perf = 1234
	rep = 3
	total_correct = 9
	total_wrong = 2
	perfect_days = 1
	night_log = [{"day": 1, "label": "测试批示", "tone": "good"}]
	annotation_hits = 5
	if !GameState.write(GameState.snapshot(self)):
		errors.append("write failed")
	var got := GameState.read()
	if got.is_empty():
		errors.append("read returned empty")
	else:
		perf = 0
		rep = 5
		day = 0
		night_log = []
		annotation_hits = 0
		if !GameState.apply(self, got):
			errors.append("apply failed")
		if day != 3:
			errors.append("day mismatch %d" % day)
		if perf != 1234:
			errors.append("perf mismatch %d" % perf)
		if rep != 3:
			errors.append("rep mismatch %d" % rep)
		if night_log.size() != 1 or str(night_log[0].get("label", "")) != "测试批示":
			errors.append("night log mismatch")
		if annotation_hits != 5:
			errors.append("annotation hits mismatch")
	if had:
		var wf := FileAccess.open(GameState.PATH, FileAccess.WRITE)
		if wf != null:
			wf.store_string(backup)
			wf.close()
	else:
		GameState.clear()
	if errors.is_empty():
		print("SAVECHECK ok day=%d perf=%d" % [day, perf])
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("SAVECHECK " + str(e))
		print("SAVECHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_backup_check() -> void:
	var errors: Array = []
	var files := {}
	for p in [GameState.PATH, GameState.BAK_PATH, GameState.TMP_PATH]:
		if FileAccess.file_exists(p):
			var bf := FileAccess.open(p, FileAccess.READ)
			if bf != null:
				files[p] = bf.get_as_text()
				bf.close()
	GameState.clear()

	# A: day 0 / 100, then B: day 1 / 200. B's write must leave A in save.bak.
	_reset_state()
	day = 0
	perf = 100
	GameState.write(GameState.snapshot(self))
	day = 1
	perf = 200
	GameState.write(GameState.snapshot(self))

	var broken := FileAccess.open(GameState.PATH, FileAccess.WRITE)
	if broken == null:
		errors.append("cannot corrupt primary save")
	else:
		broken.store_string("{broken")
		broken.close()
		var d := GameState.read()
		if d.is_empty():
			errors.append("backup fallback returned empty")
		elif int(d.get("day", -1)) != 0:
			errors.append("backup day=%d expected 0" % int(d.get("day", -1)))

	# v1 payload (no version/counters) must be migrated, not rejected.
	GameState.clear()
	var old := FileAccess.open(GameState.PATH, FileAccess.WRITE)
	if old == null:
		errors.append("cannot write v1 payload")
	else:
		old.store_string(JSON.stringify({"day": 4, "perf": 555, "rep": 2}))
		old.close()
		var m := GameState.read()
		if m.is_empty():
			errors.append("v1 migration returned empty")
		else:
			if int(m.get("version", 0)) != GameState.VERSION:
				errors.append("v1 migration version=%d" % int(m.get("version", 0)))
			if int(m.get("day", -1)) != 4:
				errors.append("v1 migration day=%d" % int(m.get("day", -1)))
			if int(m.get("annotation_hits", -1)) != 0:
				errors.append("v1 migration did not default annotation_hits")

	GameState.clear()
	for p in files.keys():
		var rf := FileAccess.open(p, FileAccess.WRITE)
		if rf != null:
			rf.store_string(files[p])
			rf.close()

	if errors.is_empty():
		print("BACKUPCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("BACKUPCHECK " + str(e))
		print("BACKUPCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_continue_check() -> void:
	var errors: Array = []
	var had := FileAccess.file_exists(GameState.PATH)
	var backup := ""
	if had:
		var bf := FileAccess.open(GameState.PATH, FileAccess.READ)
		if bf != null:
			backup = bf.get_as_text()
			bf.close()
	_reset_state()
	day = 2
	perf = 777
	rep = 4
	night_log = [{"day": 1, "label": "留档批示", "tone": "good"}]
	GameState.write(GameState.snapshot(self))
	_reset_state()
	_continue_from_save()
	await get_tree().process_frame
	if day != 2:
		errors.append("continue day=%d" % day)
	if perf != 777:
		errors.append("continue perf=%d" % perf)
	if rep != 4:
		errors.append("continue rep=%d" % rep)
	if phase != "intro":
		errors.append("continue phase=%s" % phase)
	if night_log.size() != 1:
		errors.append("continue night log lost")
	if had:
		var wf := FileAccess.open(GameState.PATH, FileAccess.WRITE)
		if wf != null:
			wf.store_string(backup)
			wf.close()
	else:
		GameState.clear()
	if errors.is_empty():
		print("CONTINUECHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("CONTINUECHECK " + str(e))
		print("CONTINUECHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_chat_memory() -> void:
	var errors: Array = []
	var found := _find_student_with("refs.item.")
	if found.is_empty():
		errors.append("no defect student")
	else:
		var s := GameData.student(int(found.get("day", 0)), int(found.get("stu", 0)))
		var defects: Array = GameData.audit(s, int(found.get("day", 0))).get("defects", [])
		chat.reset_student()
		var first: Dictionary = chat.choose(1, defects)
		if str(first.get("hint_group", "")) == "":
			errors.append("first concern gave no hint")
		if !chat.asked:
			errors.append("concern did not mark asked")
		if chat.button_label(1) != "已问过":
			errors.append("second ask button label wrong")
		var second: Dictionary = chat.choose(1, defects)
		if !second.is_empty():
			errors.append("second concern was not blocked")
		var mail_concern: Dictionary = chat.night_email(s, {"date": "2026.05.11"})
		if mail_concern.is_empty():
			errors.append("concern night email missing")
		chat.reset_student()
		var desk: Dictionary = chat.choose(2, defects)
		if int(desk.get("time_saved", 0)) != 10:
			errors.append("desk reply did not save time")
		var mail_desk: Dictionary = chat.night_email(s, {"date": "2026.05.11"})
		if mail_desk.is_empty():
			errors.append("desk night email missing")
		if str(mail_desk.get("email", {}).get("subject", "")) == str(mail_concern.get("email", {}).get("subject", "")):
			errors.append("three replies produced identical night emails")
		chat.reset_student()
		chat.choose(0, defects)
		if chat.night_email(s, {"date": "2026.05.11"}).is_empty():
			errors.append("checklist night email missing")
	if errors.is_empty():
		print("CHATMEM ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("CHATMEM " + str(e))
		print("CHATMEM failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_input_replay() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	# D4 student 1 has no face-to-face packet, so this state exercises the
	# generic mouse/keyboard path without the task gate.
	day = 3
	_begin_day()
	await get_tree().create_timer(0.8).timeout
	var errors: Array = []
	await _push_click(Vector2(545, 412))
	if tab != "dup":
		errors.append("tab click did not open dup, tab=%s" % tab)
	await _push_click(Vector2(320, 811))
	if selected != "pass":
		errors.append("stamp click did not select pass, selected=%s" % selected)
	await _push_key(KEY_ENTER)
	await get_tree().create_timer(1.9).timeout
	if total_correct + total_wrong != 1:
		errors.append("Enter stamp did not resolve a student")
	await _push_key(KEY_H)
	if !modal_open:
		errors.append("H did not open help")
	await _push_key(KEY_ESCAPE)
	if modal_open:
		errors.append("Esc did not close help")
	if errors.is_empty():
		print("INPUTREPLAY ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("INPUTREPLAY " + str(e))
		print("INPUTREPLAY failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_shot_regress() -> void:
	if DisplayServer.get_name() == "headless":
		print("SHOTREGRESS skipped headless")
		get_tree().quit(0)
		return
	var errors: Array = []
	var update := OS.get_cmdline_user_args().has("--update-baselines")
	var cases := [
		{"name": "title", "wait": 0.5},
		{"name": "selected", "wait": 0.5},
		{"name": "chat", "wait": 4.8},
		{"name": "annotate", "wait": 0.8},
		{"name": "night", "wait": 0.8},
		{"name": "request", "wait": 0.8},
		{"name": "settings", "wait": 0.5},
	]
	for c in cases:
		_prepare_regress(str(c.get("name", "")))
		await get_tree().create_timer(float(c.get("wait", 0.6))).timeout
		await _capture_regress(str(c.get("name", "")), errors, update)
		print("SHOTREGRESS case ", str(c.get("name", "")))
	if errors.is_empty():
		print("SHOTREGRESS ok cases=%d" % cases.size())
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("SHOTREGRESS " + str(e))
		print("SHOTREGRESS failed errors=%d" % errors.size())
		get_tree().quit(1)

func _prepare_regress(name: String) -> void:
	_hide_modal()
	_close_request_paper()
	_reset_state()
	phase = "review"
	match name:
		"title":
			GameState.clear()
			if toast_panel != null:
				toast_panel.visible = false
			_show_title()
		"selected":
			day = 1
			_begin_day()
			tab = "refs"
			render_tabs()
			render_doc()
			_select_stamp("revise")
		"chat":
			day = 0
			stu = 1
			load_student(true)
		"annotate":
			day = 0
			stu = 1
			load_student(true)
			tab = "cover"
			render_tabs()
			render_doc()
			_toggle_annotation()
		"request":
			day = 1
			_begin_day()
			_open_request()
			_dev_trace_loop(Vector2(735, 592), 120, 35)
		"night":
			day = 0
			_begin_day()
			_start_night_story()
		"settings":
			_open_settings()

func _capture_regress(name: String, errors: Array, update: bool = false) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img.get_width() != int(W):
		img.resize(int(W), int(H), Image.INTERPOLATE_LANCZOS)
	img.save_png(preload("res://scripts/UserData.gd").file("shot-" + name + ".png"))
	var dir := ProjectSettings.globalize_path("res://tests/baseline")
	DirAccess.make_dir_recursive_absolute(dir)
	var path := dir.path_join(name + ".png")
	if update:
		img.save_png(path)
		print("SHOTREGRESS baseline %s %s" % ["updated" if update else "created", name])
		return
	if !FileAccess.file_exists(path):
		errors.append("missing baseline " + name + "; create explicitly with --update-baselines")
		return
	var base := Image.load_from_file(path)
	if base == null:
		errors.append("cannot load baseline " + name)
		return
	if base.get_size() != img.get_size():
		base.resize(img.get_width(), img.get_height(), Image.INTERPOLATE_LANCZOS)
	var diff := _image_diff(img, base)
	print("SHOTREGRESS diff %s = %.5f" % [name, diff])
	if diff > 0.012:
		errors.append("%s diff %.4f" % [name, diff])

func _image_diff(a: Image, b: Image) -> float:
	var total := 0.0
	var n := 0
	var step := 2
	for y in range(0, a.get_height(), step):
		for x in range(0, a.get_width(), step):
			var ca := a.get_pixel(x, y)
			var cb := b.get_pixel(x, y)
			total += absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			n += 1
	return total / maxf(1.0, float(n)) / 3.0

func _dev_smoke() -> void:
	var errors: Array = []
	var rendered := 0
	for di in range(GameData.days.size()):
		for si in range(GameData.student_count(di)):
			var s := GameData.student(di, si)
			var au := GameData.audit(s, di)
			for d in au.get("defects", []):
				if str(d.get("label", "")) == "" or !AuditRegions.supports(str(d.get("anchor", ""))):
					errors.append("bad defect D%d S%d %s" % [di + 1, si + 1, str(d.get("anchor", ""))])
			for tab_id in ["cover", "abstract", "body", "refs", "dup", "form"]:
				var holder := Control.new()
				add_child(holder)
				holder.add_child(Docs.render(tab_id, s, 696))
				holder.queue_free()
				rendered += 1
	var chat_ok := true
	for di in range(GameData.days.size()):
		for si in range(GameData.student_count(di)):
			var stu_data := GameData.student(di, si)
			var need: bool = GameData.audit(stu_data, di).get("defects", []).size() > 0
			var scripted: bool = bool(ChatScript.build(stu_data, di).get("needs_reply", false))
			if scripted != need:
				chat_ok = false
	if !chat_ok:
		errors.append("chat branch mismatch")
	if errors.is_empty():
		print("SMOKE ok docs=%d students=28" % rendered)
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("SMOKE " + str(e))
		print("SMOKE failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_large_text_check() -> void:
	var old := SettingsStore.text_scale
	SettingsStore.text_scale = 1.25
	day = 0
	_begin_day()
	Ui.apply_text_scale(self)
	await get_tree().create_timer(0.2).timeout
	var errors: Array = []
	var found := false
	for n in find_children("*", "Label", true, false):
		if n is Label and n.has_meta("base_font_size") and int(n.get_meta("base_font_size")) == 10:
			found = true
			var fs: int = n.get_theme_font_size("font_size")
			if fs < 12:
				errors.append("base 10 label scaled to %d" % fs)
			break
	if !found:
		errors.append("no base 10 label found")
	if SettingsStore.text_scale_percent() != "125%":
		errors.append("percent label %s" % SettingsStore.text_scale_percent())
	SettingsStore.text_scale = old
	Ui.apply_text_scale(self)
	if errors.is_empty():
		print("LARGETEXTCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("LARGETEXTCHECK " + str(e))
		print("LARGETEXTCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_portrait_check() -> void:
	var errors: Array = []
	if !SettingsStore.portrait_shader:
		errors.append("portrait shader setting is off")
	var shader_res: Shader = load("res://shaders/grimoire_bust.gdshader") as Shader
	if shader_res == null:
		errors.append("grimoire shader missing")
	if portrait == null:
		errors.append("portrait TextureRect missing")
	elif !(portrait.material is ShaderMaterial):
		errors.append("portrait material is not ShaderMaterial")
	else:
		var mat: ShaderMaterial = portrait.material
		if mat.shader != shader_res:
			errors.append("portrait uses the wrong shader")
		var vs: Variant = mat.get_shader_parameter("virtual_size")
		if typeof(vs) != TYPE_VECTOR2 or Vector2(vs).distance_to(Vector2(144, 192)) > 0.1:
			errors.append("virtual_size is not 144x192")
		if float(mat.get_shader_parameter("rim_strength")) > 0.001:
			errors.append("rim_strength is not 0")
		if absf(float(mat.get_shader_parameter("intensity")) - 0.35) > 0.01:
			errors.append("intensity is not 0.35")
		if absf(float(mat.get_shader_parameter("palette_mix")) - 0.55) > 0.01:
			errors.append("palette_mix is not 0.55")
	if portrait_shadow == null:
		errors.append("portrait shadow underlay missing")
	elif portrait_shadow.texture == null:
		errors.append("portrait shadow has no texture")
	var count := 0
	for d in range(1, 8):
		for s in range(1, 5):
			var key := "d%ds%d" % [d, s]
			var tex: Texture2D = load("res://assets/portraits/%s.png" % key) as Texture2D
			if tex == null:
				errors.append("%s missing" % key)
				continue
			if tex.get_width() != 144 or tex.get_height() != 192:
				errors.append("%s size=%dx%d" % [key, tex.get_width(), tex.get_height()])
			var blink: Texture2D = load("res://assets/portraits/%s-blink.png" % key) as Texture2D
			if blink == null:
				errors.append("%s blink missing" % key)
			count += 1
	if count != 28:
		errors.append("portrait count=%d" % count)
	if errors.is_empty():
		print("PORTRAITCHECK ok portraits=%d" % count)
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("PORTRAITCHECK " + str(e))
		print("PORTRAITCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_shader_lab() -> void:
	_hide_modal()
	_reset_state()
	phase = "review"
	day = 0
	stu = 0
	_begin_day()
	SettingsStore.portrait_shader = true
	load_student(true)
	if portrait_shader_mat == null:
		print("SHADERLAB no shader")
		get_tree().quit(1)
		return
	portrait.material = portrait_shader_mat
	var variants := [
		{"name": "00-style-off", "off": true, "intensity": 0.0, "palette": 0.0, "grade": 0.0, "dither": 0.0, "stipple": 0.0, "scan": 0.0, "ca": 0.0},
		{"name": "01-soft", "off": false, "intensity": 0.35, "palette": 0.55, "grade": 0.30, "dither": 0.04, "stipple": 0.04, "scan": 0.012, "ca": 0.0007},
		{"name": "02-current", "off": false, "intensity": 1.0, "palette": 0.76, "grade": 0.48, "dither": 0.06, "stipple": 0.07, "scan": 0.02, "ca": 0.0010},
		{"name": "03-strong", "off": false, "intensity": 1.4, "palette": 0.92, "grade": 0.75, "dither": 0.10, "stipple": 0.14, "scan": 0.05, "ca": 0.0018},
		{"name": "04-max", "off": false, "intensity": 1.85, "palette": 1.0, "grade": 1.0, "dither": 0.14, "stipple": 0.24, "scan": 0.09, "ca": 0.0035},
	]
	for v in variants:
		if bool(v.get("off", false)):
			portrait.material = null
		else:
			portrait.material = portrait_shader_mat
			portrait_shader_mat.set_shader_parameter("intensity", float(v.intensity))
			portrait_shader_mat.set_shader_parameter("palette_mix", float(v.palette))
			portrait_shader_mat.set_shader_parameter("grade_strength", float(v.grade))
			portrait_shader_mat.set_shader_parameter("dither_strength", float(v.dither))
			portrait_shader_mat.set_shader_parameter("stipple_strength", float(v.stipple))
			portrait_shader_mat.set_shader_parameter("scanline_strength", float(v.scan))
			portrait_shader_mat.set_shader_parameter("ca_strength", float(v.ca))
		await get_tree().create_timer(0.3).timeout
		await _snap("shader-" + str(v.name))
		print("SHADERLAB ", v.name)
	portrait.material = portrait_shader_mat
	get_tree().quit()

func _dev_settings_check() -> void:
	var errors: Array = []
	var old_speed := SettingsStore.text_speed
	var old_motion := SettingsStore.reduce_motion
	var old_scale := SettingsStore.ui_scale
	var old_text := SettingsStore.text_scale
	var old_portrait := SettingsStore.portrait_shader
	SettingsStore.text_speed = "fast"
	SettingsStore.reduce_motion = true
	SettingsStore.ui_scale = 1.25
	SettingsStore.text_scale = 1.25
	SettingsStore.portrait_shader = true
	SettingsStore.save_settings()
	var cfg := ConfigFile.new()
	if cfg.load(SettingsStore.PATH) != OK:
		errors.append("settings file missing")
	else:
		if str(cfg.get_value("access", "text_speed", "")) != "fast":
			errors.append("text_speed not saved")
		if !bool(cfg.get_value("access", "reduce_motion", false)):
			errors.append("reduce_motion not saved")
		if absf(float(cfg.get_value("display", "ui_scale", 1.0)) - 1.25) > 0.01:
			errors.append("ui_scale not saved")
		if absf(float(cfg.get_value("display", "text_scale", 1.0)) - 1.25) > 0.01:
			errors.append("text_scale not saved")
		if !bool(cfg.get_value("display", "portrait_shader", false)):
			errors.append("portrait_shader not saved")
	SettingsStore.text_speed = old_speed
	SettingsStore.reduce_motion = old_motion
	SettingsStore.ui_scale = old_scale
	SettingsStore.text_scale = old_text
	SettingsStore.portrait_shader = old_portrait
	SettingsStore.save_settings()
	if errors.is_empty():
		print("SETTINGSCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("SETTINGSCHECK " + str(e))
		print("SETTINGSCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _dev_title_settings_check() -> void:
	_hide_modal()
	_reset_state()
	phase = "title"
	_show_title()
	_open_settings()
	await get_tree().process_frame
	if !settings_modal:
		push_error("TITLESETTINGS settings did not open from title")
		print("TITLESETTINGS failed")
		get_tree().quit(1)
		return
	if phase != "title":
		push_error("TITLESETTINGS phase changed to %s" % phase)
		print("TITLESETTINGS failed")
		get_tree().quit(1)
		return
	print("TITLESETTINGS ok")
	get_tree().quit(0)

func _dev_router_check() -> void:
	var errors: Array = []
	_hide_modal()
	_reset_state()
	phase = "title"
	if InputRouter.context(self) != InputRouter.TITLE:
		errors.append("title context=%s" % InputRouter.context(self))
	phase = "review"
	if InputRouter.context(self) != InputRouter.REVIEW:
		errors.append("review context=%s" % InputRouter.context(self))
	_toggle_annotation()
	if InputRouter.context(self) != InputRouter.ANNOTATION:
		errors.append("annotation context=%s" % InputRouter.context(self))
	if !InputRouter.allows_annotation(self):
		errors.append("annotation not allowed")
	if !InputRouter.allows_review_keys(self):
		errors.append("annotation should still allow review keys")
	_toggle_annotation()
	_show_help()
	if InputRouter.context(self) != InputRouter.MODAL:
		errors.append("modal context=%s" % InputRouter.context(self))
	if InputRouter.allows_mouse(self):
		errors.append("modal should block mouse")
	_hide_modal()
	_start_night_story()
	if InputRouter.context(self) != InputRouter.NIGHT:
		errors.append("night context=%s" % InputRouter.context(self))
	_clear_story_mode()
	phase = "review"
	load_student(true)
	if !InputRouter.allows_mouse(self):
		errors.append("review should allow mouse")
	if errors.is_empty():
		print("ROUTERCHECK ok")
		get_tree().quit(0)
	else:
		for e in errors:
			push_error("ROUTERCHECK " + str(e))
		print("ROUTERCHECK failed errors=%d" % errors.size())
		get_tree().quit(1)

func _snap(snap_name: String) -> void:
	if DisplayServer.get_name() == "headless":
		print("skip snap ", snap_name)
		return
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if img.get_width() != int(W):
		img.resize(int(W), int(H), Image.INTERPOLATE_LANCZOS)
	var dir := ProjectSettings.globalize_path("res://_shots")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir.path_join(snap_name + ".png"))
	print("saved ", snap_name, " ", img.get_width(), "x", img.get_height())

func _capture_later(shot_name: String) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().create_timer(0.6).timeout
	await _snap(shot_name)
	get_tree().quit()
