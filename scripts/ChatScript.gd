class_name ChatScript
extends RefCounted

## Builds the deterministic WeChat sequence for one student.
## The UI only renders events; it does not decide when a manual reply is needed.

static func build(s: Dictionary, day_index: int) -> Dictionary:
	# Authored WeChat tree: speakers, reply choices and per-choice follow-ups.
	# Missing/empty dialogue keeps the deterministic generated script below.
	var authored: Variant = s.get("dialogue", {})
	if authored is Dictionary and !str(authored.get("start", "")).is_empty():
		var nodes: Array = authored.get("nodes", [])
		if nodes is Array and !nodes.is_empty():
			return {
				"events": [],
				"needs_reply": _has_choices(authored),
				"dialogue": authored,
				"custom": true,
			}
	var o: Dictionary = s.get("official", {})
	var au := GameData.audit(s, day_index)
	var defects: Array = au.get("defects", [])
	var needs_reply := defects.size() > 0
	var student_msgs: Array = []
	var custom: Variant = s.get("chat", [])
	if custom is Array and custom.size() > 0:
		for line in custom:
			student_msgs.append(str(line))
	else:
		student_msgs.append("老师好，我是%s，%s的论文材料交到 03 窗口了。" % [s.get("name", ""), o.get("major", "")])
		student_msgs.append(str(s.get("line", "")))
		if needs_reply:
			student_msgs.append(_defect_line(defects))
		else:
			student_msgs.append("材料我按清单核对过了，麻烦您看一下。")
	var events: Array = []
	var auto_replies := ["收到，材料放窗口就好。", "好，我先按清单核对。"]
	for i in range(student_msgs.size()):
		events.append({"kind": "student", "text": str(student_msgs[i]), "delay": 0.62})
		if i < 2:
			events.append({"kind": "auto", "text": auto_replies[i], "delay": 0.38})
		elif !needs_reply:
			events.append({"kind": "auto", "text": "材料齐全，我核对后给你结论。", "delay": 0.38})
	return {"events": events, "needs_reply": needs_reply}

static func _has_choices(dialogue: Dictionary) -> bool:
	for node in dialogue.get("nodes", []):
		if node is Dictionary and node.get("choices", []) is Array and !node.get("choices", []).is_empty():
			return true
	return false

static func primary(defects: Array) -> Dictionary:
	var ds := defects.duplicate()
	ds.sort_custom(func(a, b):
		return _rank(a) < _rank(b)
	)
	return ds[0] if !ds.is_empty() else {}

static func _defect_line(defects: Array) -> String:
	var d := primary(defects)
	var group := str(d.get("group", ""))
	var hints := {
		"identity": "封面信息我照着旧学生证填的，可能有地方没改。",
		"summary": "摘要我删到 468 字，关键词也按老师说的改了。",
		"dup": "查重报告是同学帮我跑的，编号我不太记得。",
		"refs": "参考文献有几篇是网上找的，但都写了。",
		"body": "页码我重新排过，第十三页可能有点问题。",
		"form": "签字我跑了两趟，有一个老师出差了。",
		"admin": "学分和学费我上周查过，应该没问题。"
	}
	return str(hints.get(group, "有一处我不太确定，您看材料时能不能帮我留意一下？"))

static func _rank(d: Dictionary) -> int:
	return 0 if str(d.get("severity", "")) == "critical" else 1
