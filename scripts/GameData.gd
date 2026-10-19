class_name GameData
extends RefCounted

## Loads the data exported from the original single-file game and ports auditStudent().

static var days: Array = []
static var rules: Array = []
static var tabs: Array = []
static var materials: Array = []
static var outcomes: Dictionary = {}
static var ref_pool: Array = []
static var audits: Array = []
static var night_scenes: Array = []
static var allocation: Dictionary = {}
static var college_groups: Dictionary = {}
static var loaded: bool = false

static func load_all() -> void:
	if loaded:
		return
	var f := FileAccess.open("res://assets/data.json", FileAccess.READ)
	if f == null:
		push_error("Cannot open assets/data.json")
		return
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("Bad data.json")
		return
	var d: Dictionary = parsed
	days = d.get("DAYS", [])
	rules = d.get("RULE_GROUPS", [])
	tabs = d.get("TABS", [])
	materials = d.get("EXTRA_MATERIALS", [])
	outcomes = d.get("OUTCOMES", {})
	ref_pool = d.get("REF_POOL", [])
	audits = d.get("audits", [])
	night_scenes = d.get("NIGHT_SCENES", [])
	allocation = d.get("ALLOCATION", {})
	college_groups = d.get("COLLEGE_GROUPS", {})
	loaded = true

static func day(i: int) -> Dictionary:
	if i < 0 or i >= days.size():
		return {}
	return days[i]

static func student(day_i: int, stu_i: int) -> Dictionary:
	var d := day(day_i)
	if d.is_empty():
		return {}
	var arr: Array = d.get("students", [])
	if stu_i < 0 or stu_i >= arr.size():
		return {}
	return arr[stu_i]

static func norm(v: Variant) -> String:
	var s := str(v)
	s = s.replace(" ", "").replace("\t", "").replace("\n", "").replace("\r", "")
	s = s.replace("\u3000", "").replace("\u00a0", "")
	return s.strip_edges()

static func outcome(id: String) -> Dictionary:
	return outcomes.get(id, {})

static func is_material_unlocked(item: Dictionary, day_index: int) -> bool:
	return int(item.get("unlockDay", 99)) <= day_index + 1

static func student_count(day_i: int) -> int:
	return day(day_i).get("students", []).size()

## Port of the original auditStudent(): deterministic, all currently active rules.
static func audit(s: Dictionary, day_index: int) -> Dictionary:
	var active := {}
	for g in rules:
		if int(g.get("day", 99)) <= day_index + 1:
			active[str(g.get("id", ""))] = true

	var defects: Array = []
	var o: Dictionary = s.get("official", {})
	var c: Dictionary = s.get("cover", {})
	var d: Dictionary = s.get("dup", {})
	var f: Dictionary = s.get("form", {})

	if active.has("identity"):
		if norm(c.get("name", "")) != norm(o.get("name", "")):
			defects.append({"group": "identity", "rule": "A1", "anchor": "identity.name", "label": "封面姓名不符", "text": "封面姓名「%s」与学籍档案「%s」不一致。" % [c.get("name", ""), o.get("name", "")], "severity": "minor"})
		if norm(c.get("id", "")) != norm(o.get("id", "")):
			defects.append({"group": "identity", "rule": "A1", "anchor": "identity.id", "label": "封面学号不符", "text": "封面学号「%s」与学籍档案「%s」不一致。" % [c.get("id", ""), o.get("id", "")], "severity": "minor"})
		if norm(c.get("major", "")) != norm(o.get("major", "")):
			defects.append({"group": "identity", "rule": "A1", "anchor": "identity.major", "label": "封面专业不符", "text": "封面专业「%s」与学籍档案「%s」不一致。" % [c.get("major", ""), o.get("major", "")], "severity": "minor"})
		if norm(s.get("abstractTitle", "")) != norm(c.get("title", s.get("title", ""))):
			defects.append({"group": "identity", "rule": "A2", "anchor": "identity.title", "label": "摘要题目不符", "text": "摘要页题目与封面题目不一致。", "severity": "minor"})

	if active.has("summary"):
		var chars := int(s.get("abstractChars", 0))
		if chars < 300 or chars > 500:
			defects.append({"group": "summary", "rule": "B1", "anchor": "summary.chars", "label": "摘要 %d 字" % chars, "text": "摘要字数 %d 字，不在 300—500 字范围内。" % chars, "severity": "minor"})
		var kw: Array = s.get("keywords", [])
		if kw.size() < 3 or kw.size() > 5:
			defects.append({"group": "summary", "rule": "B2", "anchor": "summary.keywords", "label": "关键词 %d 个" % kw.size(), "text": "关键词 %d 个，不在 3—5 个范围内。" % kw.size(), "severity": "minor"})

	if active.has("dup"):
		var report_no := str(d.get("reportNo", ""))
		var identity_bad := norm(d.get("name", "")) != norm(o.get("name", "")) \
			or norm(d.get("id", "")) != norm(o.get("id", "")) \
			or report_no == "" or report_no == "—"
		if identity_bad:
			defects.append({"group": "dup", "rule": "C2", "anchor": "dup.identity", "label": "报告身份/编号异常", "text": "查重报告身份信息或报告编号异常（%s / %s / %s），按伪造报告处理。" % [d.get("name", ""), d.get("id", ""), report_no if report_no != "" else "无编号"], "severity": "critical"})
		var rate := float(d.get("rate", 0.0))
		if rate > 30.0:
			defects.append({"group": "dup", "rule": "C1", "anchor": "dup.rate", "label": "复制比 %.1f%%" % rate, "text": "总文字复制比 %.1f%%，超过 30%% 红线，构成学术不端。" % rate, "severity": "critical"})
		elif rate > 20.0:
			defects.append({"group": "dup", "rule": "C1", "anchor": "dup.rate", "label": "复制比 %.1f%%" % rate, "text": "总文字复制比 %.1f%%，处于 20%%—30%% 区间，须退回修改。" % rate, "severity": "minor"})
		if !bool(d.get("seal", true)):
			defects.append({"group": "dup", "rule": "C3", "anchor": "dup.seal", "label": "缺电子签章", "text": "查重报告缺少教务处电子签章，须补交正式报告。", "severity": "minor"})

	if active.has("refs"):
		var refs: Array = s.get("refs", [])
		var recent := 0
		for r in refs:
			var y := int(r.get("y", 0))
			if y >= 2021 and y <= 2026:
				recent += 1
		if refs.size() < 15:
			defects.append({"group": "refs", "rule": "D1", "anchor": "refs.header", "label": "仅 %d 篇参考文献" % refs.size(), "text": "参考文献共 %d 篇，少于 15 篇。" % refs.size(), "severity": "minor"})
		if recent < 5:
			defects.append({"group": "refs", "rule": "D1", "anchor": "refs.header", "label": "近五年仅 %d 篇" % recent, "text": "近五年（2021—2026）文献仅 %d 篇，少于 5 篇。" % recent, "severity": "minor"})
		for i in range(refs.size()):
			var r2: Dictionary = refs[i]
			var kind := str(r2.get("kind", "journal"))
			if kind == "web" or kind == "ai":
				var src := str(r2.get("a", ""))
				if src == "":
					src = str(r2.get("j", ""))
				if src == "":
					src = str(r2.get("t", ""))
				var short := _short(src, 16)
				var kind_label := "网络来源" if kind == "web" else "AI 生成内容"
				defects.append({
					"group": "refs",
					"rule": "D2",
					"anchor": "refs.item.%d" % (i + 1),
					"label": "第%d条：%s" % [i + 1, short],
					"text": "第 %d 条参考文献「%s」为%s（[%s]），须撤换为正式出版物。" % [
						i + 1, src, kind_label, "EB/OL" if kind == "web" else "AI"],
					"severity": "minor",
					"refIndex": i + 1,
				})

	if active.has("body"):
		var body: Dictionary = s.get("body", {})
		var pages := int(body.get("pages", 0))
		if pages < 20:
			defects.append({"group": "body", "rule": "E1", "anchor": "body.pages", "label": "正文仅 %d 页" % pages, "text": "正文共 %d 页，少于 20 页。" % pages, "severity": "minor"})
		if body.get("gap", null) != null:
			defects.append({"group": "body", "rule": "E2", "anchor": "body.gap", "label": "缺第 %d 页" % int(body.get("gap", 0)), "text": "页码不连续：装订顺序中缺少第 %d 页。" % int(body.get("gap", 0)), "severity": "minor"})
		var wc := int(body.get("wordCount", 0))
		if wc < 8000:
			defects.append({"group": "body", "rule": "E1", "anchor": "body.words", "label": "正文 %s 字" % Ui.fmt_money(wc), "text": "正文约 %s 字，少于 8000 字。" % Ui.fmt_money(wc), "severity": "minor"})

	if active.has("form"):
		var labels := {"advisor": "导师", "chair": "系主任", "dean": "教学院长"}
		var sigs: Dictionary = f.get("signatures", {})
		for key in ["advisor", "chair", "dean"]:
			if !sigs.get(key, null):
				defects.append({
					"group": "form",
					"rule": "F1",
					"anchor": "form.sig.%s" % key,
					"label": "缺%s签字" % labels[key],
					"text": "答辩资格审查表缺少%s签字。" % labels[key],
					"severity": "minor",
				})
		if bool(f.get("human", false)) and !f.get("ethicsNo", null):
			defects.append({"group": "form", "rule": "F2", "anchor": "form.ethics", "label": "缺伦理批件号", "text": "研究涉及人体，但资格审查表未填写伦理批件编号。", "severity": "minor"})

	if active.has("admin"):
		if int(f.get("credits", 0)) < 160:
			defects.append({"group": "admin", "rule": "G1", "anchor": "admin.credits", "label": "学分 %d/160" % int(f.get("credits", 0)), "text": "已修学分 %d，少于 160 学分。" % int(f.get("credits", 0)), "severity": "minor"})
		if str(f.get("tuition", "paid")) != "paid":
			defects.append({"group": "admin", "rule": "G2", "anchor": "admin.tuition", "label": "欠缴 ¥%s" % Ui.fmt_money(int(f.get("tuitionOwed", 0))), "text": "学费未结清（欠缴 ¥%s）。" % Ui.fmt_money(int(f.get("tuitionOwed", 0))), "severity": "minor"})

	var critical := false
	for it in defects:
		if str(it.get("severity", "")) == "critical":
			critical = true
			break
	var expected := "pass"
	if critical:
		expected = "reject"
	elif defects.size() > 0:
		expected = "revise"
	return {"defects": defects, "critical": critical, "expected": expected}

static func _short(text: String, limit: int) -> String:
	var s := text.strip_edges()
	if s.length() <= limit:
		return s
	return s.substr(0, limit) + "…"

static func group_label(group: String) -> String:
	match group:
		"identity":
			return "身份 / 题目"
		"summary":
			return "摘要规格"
		"dup":
			return "查重报告"
		"refs":
			return "参考文献"
		"body":
			return "正文 / 页码"
		"form":
			return "签字 / 伦理"
		"admin":
			return "学分 / 学费"
	return "条例"
