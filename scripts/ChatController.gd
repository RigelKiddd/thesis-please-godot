extends RefCounted

## Chat reply policy for one student.
##
## Main.gd renders the WeChat bubbles. This controller remembers what the player
## asked, because the same choice should not be free twice: "最担心哪项？" can
## only be used once per student, "按清单核对" yields no hint, and "先放桌上"
## saves a few minutes but makes the student stop volunteering information. The
## choice is echoed in the student's next line and a night-shift email.

const CHECKLIST := "checklist"
const CONCERN := "concern"
const DESK := "desk"

var asked := false
var style := ""
var hint_group := ""
var hint_label := ""
var last_reply := ""
var replies: Array = []
var time_saved := 0

func reset_student() -> void:
	asked = false
	style = ""
	hint_group = ""
	hint_label = ""
	last_reply = ""
	replies.clear()
	time_saved = 0

func can_ask() -> bool:
	return !asked

## Authored dialogue choices can still leave a night-mail trail. The editor can
## tag a choice with style=checklist/concern/desk; unknown styles simply produce
## no generated email (the custom messages still remain in the chat log).
func record_custom(label: String, choice_style: String = "", saved_minutes: int = 0) -> void:
	last_reply = label
	if choice_style in [CHECKLIST, CONCERN, DESK]:
		style = choice_style
		if choice_style == CONCERN:
			asked = true
	if saved_minutes > 0:
		time_saved = saved_minutes

func is_used(index: int) -> bool:
	return index == 1 and asked

func button_label(index: int) -> String:
	if index == 1 and asked:
		return "已问过"
	return ["按清单核对", "最担心哪项？", "先放桌上"][index]

## Applies one of the three replies. Returns {} when that option is unavailable.
func choose(index: int, defects: Array) -> Dictionary:
	if is_used(index):
		return {}
	var result := {}
	match index:
		0:
			style = CHECKLIST
			last_reply = "好的，我按清单再核一遍，谢谢老师。"
			result = {
				"style": CHECKLIST,
				"line": last_reply,
				"toast": "学生按清单核对",
				"tone": "good",
			}
		1:
			style = CONCERN
			asked = true
			var d: Dictionary = _primary(defects)
			if d.is_empty():
				last_reply = "应该没问题，麻烦您正常看。"
				hint_group = ""
				hint_label = ""
				result = {
					"style": CONCERN,
					"line": last_reply,
					"toast": "学生没有特别担心的地方",
					"tone": "warn",
				}
			else:
				hint_group = str(d.get("group", ""))
				hint_label = str(d.get("label", ""))
				if hint_label == "":
					hint_label = GameData.group_label(hint_group)
				last_reply = "可能是%s，麻烦您帮我看看。" % hint_label
				result = {
					"style": CONCERN,
					"line": last_reply,
					"toast": "学生提示：%s" % hint_label,
					"tone": "warn",
					"hint_group": hint_group,
					"hint_label": hint_label,
				}
		2:
			style = DESK
			time_saved = 10
			last_reply = "好，那我先放桌上。"
			result = {
				"style": DESK,
				"line": last_reply,
				"toast": "学生不再补充 · 省下 10 分钟",
				"tone": "warn",
				"time_saved": time_saved,
			}
	replies.append({
		"index": index,
		"style": style,
		"label": ["按清单核对", "最担心哪项？", "先放桌上"][index],
		"reply": last_reply,
	})
	return result

## A short second line that makes the three choices visibly different.
func followup() -> String:
	match style:
		CHECKLIST:
			return "清单我压在最上面了，您照着看就行。"
		CONCERN:
			return "我在门口等，您圈出来我马上改。"
		DESK:
			return "那我先去吃饭了，材料放桌上。"
	return ""

func summary_line() -> String:
	if style == "":
		return ""
	match style:
		CHECKLIST:
			return "按清单核对"
		CONCERN:
			return "问过最担心哪项 · 已用掉一次提示"
		DESK:
			return "先放桌上 · 省 10 分钟"
	return ""

## Night-shift email generated from the daytime conversation.
func night_email(student: Dictionary, tokens: Dictionary) -> Dictionary:
	if style == "" or student.is_empty():
		return {}
	var name := str(student.get("name", "学生"))
	var major := str(student.get("official", {}).get("major", ""))
	var quote := last_reply
	var subject := ""
	var intro := ""
	var body := ""
	match style:
		CHECKLIST:
			subject = "材料已按清单重新核对"
			intro = "%s 同学在下班后补发了一封邮件。" % name
			body = "周老师：\n\n您让我按清单核对，我又把 %s 的材料从头看了一遍。%s 如果还有格式问题，我明天一早来改。\n\n辛苦了。" % [major, quote]
		CONCERN:
			subject = "关于“最担心哪项”的补充"
			intro = "%s 同学在下班后补发了一封邮件。" % name
			body = "周老师：\n\n白天您问我最担心哪项，我说了“%s”。回来想想还是不放心，把相关那几页单独抽出来放在信封里了。\n\n麻烦您明天再看一眼。" % [hint_label if hint_label != "" else "材料"]
		DESK:
			subject = "材料先放在 03 窗口"
			intro = "%s 同学没有再来补充说明。" % name
			body = "周老师：\n\n今天时间紧，我把材料先放在桌上了，没有再核一遍。如果有问题，麻烦按退改处理。\n\n%s" % [quote]
	return {
		"id": "n-email-chat",
		"tab": "邮件",
		"icon": "邮",
		"badge": "学生来信",
		"kind": "email",
		"kicker": "03号窗口 / AFTER HOURS MAIL",
		"officeLeft": "教务处 · 夜间值班",
		"officeRight": "{{date}}",
		"title": "下班后收到的一封邮件",
		"subtitle": "STUDENT MAIL / PRINTED",
		"email": {
			"from": "%s <%s@stu.mingzhou.edu.cn>" % [name, str(student.get("id", "student"))],
			"to": "周明远 <zhou.my@mingzhou.edu.cn>",
			"cc": "",
			"date": "{{date}} 18:42",
			"subject": subject,
			"stamp": "学生来信",
			"printedAt": "打印于 18:47",
			"signature": name,
			"footer": "本邮件由 MailGate 自动打印，随当日卷宗归档。",
		},
		"intro": intro,
		"sections": [
			{"h": "正文", "p": body},
		],
		"note": "这封邮件由白天的微信回复触发；不同的回复会留下不同的信。",
		"signature": name,
	}

func _primary(defects: Array) -> Dictionary:
	var ds := defects.duplicate()
	ds.sort_custom(func(a, b):
		return _rank(a) < _rank(b)
	)
	return ds[0] if !ds.is_empty() else {}

func _rank(d: Dictionary) -> int:
	return 0 if str(d.get("severity", "")) == "critical" else 1
