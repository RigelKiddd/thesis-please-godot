extends RefCounted

## Material traits for the between-days prop documents.  The main game's
## MaterialCard gives every supplement a stock, a pictogram, a tab and a
## material tag; the desk files (人情簿 / 院系账本 / 明日安排 / 感谢函 /
## 通行条) should read as the same family of physical material.

const DEFAULTS := {
	"favor": {
		"style": "ledger", "icon": "ledger", "stock": "LEDGER", "stock_cn": "账本",
		"paper": "#e6ddc4", "accent": "#3f6b45", "serial": "M-01", "tag": "材料",
		"shape": "book", "short": "人情",
	},
	"college": {
		"style": "sealed", "icon": "ledger", "stock": "SEALED", "stock_cn": "密封",
		"paper": "#f6efdc", "accent": "#a83a2f", "serial": "M-02", "tag": "材料",
		"shape": "book", "short": "账本",
	},
	"schedule": {
		"style": "cardstock", "icon": "schedule", "stock": "CARDSTOCK", "stock_cn": "卡纸",
		"paper": "#d9b98a", "accent": "#8b382b", "serial": "M-03", "tag": "材料",
		"shape": "schedule", "short": "明日",
	},
	"letter": {
		"style": "sealed", "icon": "envelope", "stock": "SEALED", "stock_cn": "封函",
		"paper": "#f6efdc", "accent": "#a83a2f", "serial": "M-04", "tag": "材料",
		"shape": "envelope", "short": "感谢",
	},
	"pass": {
		"style": "carbonless", "icon": "ticket", "stock": "CARBONLESS", "stock_cn": "无碳",
		"paper": "#dce8ee", "accent": "#2d4d78", "serial": "M-05", "tag": "材料",
		"shape": "ticket", "short": "通行",
	},
	"_": {
		"style": "mimeo", "icon": "form", "stock": "MIMEO", "stock_cn": "油印",
		"paper": "#e9ddc2", "accent": "#7a6847", "serial": "M-00", "tag": "材料",
		"shape": "schedule", "short": "文件",
	},
}


static func traits(kind: String, item: Dictionary = {}) -> Dictionary:
	var t: Dictionary = DEFAULTS.get(kind, DEFAULTS["_"]).duplicate(true)
	for key in ["style", "icon", "stock", "stock_cn", "paper", "accent", "serial", "tag"]:
		if item.has(key) and str(item.get(key, "")) != "":
			t[key] = item[key]
	t["kind"] = kind
	t["paper_color"] = Color(str(t.get("paper", "#e9ddc2")))
	t["accent_color"] = Color(str(t.get("accent", "#7a6847")))
	return t


static func stock_line(t: Dictionary) -> String:
	return "%s / %s" % [str(t.get("stock", "MIMEO")), str(t.get("stock_cn", "油印"))]


static func material_tag(t: Dictionary) -> String:
	return str(t.get("tag", "材料"))


static func serial(t: Dictionary) -> String:
	return str(t.get("serial", "M-00"))
