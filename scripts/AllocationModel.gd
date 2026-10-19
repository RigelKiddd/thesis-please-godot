class_name AllocationModel
extends RefCounted

## Data and rules for the between-days allocation phase (v1.14).
##
## The whole phase is authored in content/world.json -> allocation and compiled
## into assets/data.json -> ALLOCATION.  This module only reads that data and
## turns coins in boxes into favors / performance; rendering lives in
## AllocationView.gd, sequencing in Main / FlowController.

const COINS := ["energy", "money"]


static func data() -> Dictionary:
	return GameData.allocation


static func roles() -> Array:
	var rows: Array = data().get("roles", [])
	return rows


static func role(id: String) -> Dictionary:
	for row in roles():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func role_name(id: String) -> String:
	return str(role(id).get("name", id))


static func role_title(id: String) -> String:
	return str(role(id).get("role", ""))


static func projects() -> Array:
	var rows: Array = data().get("projects", [])
	return rows


static func project(id: String) -> Dictionary:
	for row in projects():
		if str(row.get("id", "")) == id:
			return row
	return {}


static func transitions() -> Array:
	var rows: Array = data().get("transitions", [])
	return rows


## day_index is 0-based: day 0 allocates for the morning of day 1.
static func transition(day_index: int) -> Dictionary:
	var wanted := day_index + 1
	for row in transitions():
		if int(row.get("afterDay", -1)) == wanted:
			return row
	return {}


static func visitor(id: String) -> Dictionary:
	var rows: Array = data().get("visitors", [])
	for row in rows:
		if str(row.get("id", "")) == id:
			return row
	return {}


static func caps() -> Dictionary:
	var c: Dictionary = data().get("caps", {})
	if c.is_empty():
		return {"energy": 7, "money": 6}
	return c


static func favor_levels() -> Array:
	var rows: Array = data().get("favorLevels", [])
	return rows


static func favor_level(value: int) -> Dictionary:
	var row := {}
	for r in favor_levels():
		if value >= int(r.get("at", 0)):
			row = r
	return row


static func favor_label(value: int) -> String:
	if favor_levels().is_empty():
		return str(value)
	return str(favor_level(value).get("label", ""))


static func perk_active(role_row: Dictionary, value: int) -> bool:
	var perk: Dictionary = role_row.get("perk", {})
	if perk.is_empty():
		return false
	return value >= int(perk.get("at", 999))


## Budget for one night.  Favor perks add coins; flat perf perks are paid on
## finish.  The result is clamped to the authored slot capacity.
static func budget(day_index: int, favor: Dictionary) -> Dictionary:
	var t := transition(day_index)
	var energy := int(t.get("energy", 0))
	var money := int(t.get("money", 0))
	var flat := 0
	var details: Array = []
	for row in roles():
		var perk: Dictionary = row.get("perk", {})
		if perk.is_empty():
			continue
		var value := int(favor.get(str(row.get("id", "")), 0))
		if value < int(perk.get("at", 999)):
			continue
		var de := int(perk.get("energy", 0))
		var dm := int(perk.get("money", 0))
		var dp := int(perk.get("perf", 0))
		energy += de
		money += dm
		flat += dp
		if de != 0 or dm != 0 or dp != 0:
			details.append({
				"id": str(row.get("id", "")),
				"name": str(row.get("name", "")),
				"energy": de,
				"money": dm,
				"perf": dp,
			})
	var c := caps()
	return {
		"energy": mini(energy, int(c.get("energy", 99))),
		"money": mini(money, int(c.get("money", 99))),
		"flat_perf": flat,
		"details": details,
		"base": {"energy": int(t.get("energy", 0)), "money": int(t.get("money", 0))},
	}


static func begin(state, day_index: int) -> void:
	var b := budget(day_index, state.favor)
	state.energy = int(b.get("energy", 0))
	state.money = int(b.get("money", 0))
	state.alloc_offer = b
	state.alloc_placed = {}


static func requested_visitors(day_index: int) -> Array:
	var t := transition(day_index)
	var out: Array = []
	for vid in t.get("visitors", []):
		var v := visitor(str(vid))
		if !v.is_empty():
			out.append(v)
	return out


static func project_effects(placed: Dictionary) -> Dictionary:
	var fav: Dictionary = {}
	var perf := 0
	var rep := 0
	var counts: Dictionary = {}
	for row in projects():
		var id := str(row.get("id", ""))
		var n := int(placed.get(id, 0))
		if n <= 0:
			continue
		counts[id] = n
		perf += n * int(row.get("perf", 0))
		var pf: Dictionary = row.get("favor", {})
		for key in pf:
			fav[key] = int(fav.get(key, 0)) + n * int(pf[key])
		if int(row.get("repAtCap", 0)) != 0 and n >= int(row.get("cap", 0)):
			rep += int(row.get("repAtCap", 0))
	return {"favor": fav, "perf": perf, "rep": rep, "counts": counts}


static func flat_perf(favor: Dictionary) -> int:
	var total := 0
	for row in roles():
		var perk: Dictionary = row.get("perk", {})
		if perk.is_empty():
			continue
		if int(favor.get(str(row.get("id", "")), 0)) >= int(perk.get("at", 999)):
			total += int(perk.get("perf", 0))
	return total


static func remaining(state) -> int:
	return int(state.energy) + int(state.money)


static func can_afford(option: Dictionary, energy: int, money: int) -> bool:
	return energy + int(option.get("energy", 0)) >= 0 and money + int(option.get("money", 0)) >= 0


## Short human-readable preview for visitor options / project boxes.
static func effect_text(effects: Dictionary, with_names: bool = true) -> String:
	var parts: Array = []
	var fav: Dictionary = effects.get("favor", {})
	for key in fav:
		var delta := int(fav[key])
		if delta == 0:
			continue
		var who := role_name(str(key)) if with_names else role_title(str(key))
		if who == "":
			who = str(key)
		parts.append("%s %s%d" % [who, "+" if delta > 0 else "−", absi(delta)])
	var perf := int(effects.get("perf", 0))
	if perf != 0:
		parts.append("绩效 %s¥%s" % ["+" if perf > 0 else "−", Ui.fmt_money(absi(perf))])
	var energy := int(effects.get("energy", 0))
	if energy != 0:
		parts.append("精力 %s%d" % ["+" if energy > 0 else "−", absi(energy)])
	var money := int(effects.get("money", 0))
	if money != 0:
		parts.append("金钱 %s%d" % ["+" if money > 0 else "−", absi(money)])
	var rep := int(effects.get("rep", 0))
	if rep != 0:
		parts.append("声誉 %s%d" % ["+" if rep > 0 else "−", absi(rep)])
	return " · ".join(PackedStringArray(parts))


static func project_text(row: Dictionary) -> String:
	var fav: Dictionary = row.get("favor", {})
	var parts: Array = []
	for key in fav:
		var delta := int(fav[key])
		if delta != 0:
			parts.append("%s %s%d" % [role_name(str(key)), "+" if delta > 0 else "−", absi(delta)])
	var perf := int(row.get("perf", 0))
	if perf != 0:
		parts.append("绩效 +¥%s" % Ui.fmt_money(perf))
	var cap_text := ""
	if rel_at_cap(row) != 0:
		cap_text = "排满 %d 枚：声誉 +%d" % [int(row.get("cap", 0)), rel_at_cap(row)]
	if parts.is_empty():
		return cap_text if cap_text != "" else "没有直接收益"
	var out := "每枚：%s" % " · ".join(PackedStringArray(parts))
	if cap_text != "":
		out += " · " + cap_text
	return out


static func rel_at_cap(row: Dictionary) -> int:
	return int(row.get("repAtCap", 0))


static func coin_label(kind: String) -> String:
	return "精力" if kind == "energy" else "金钱"


static func fill(text: String, tokens: Dictionary) -> String:
	var out := text
	for key in tokens:
		out = out.replace("{{%s}}" % str(key), str(tokens[key]))
	return out


static func favor_total(favor: Dictionary) -> int:
	var total := 0
	for row in roles():
		total += int(favor.get(str(row.get("id", "")), 0))
	return total


static func favor_line(favor: Dictionary) -> String:
	var parts: Array = []
	for row in roles():
		var id := str(row.get("id", ""))
		var value := int(favor.get(id, 0))
		if value <= 0:
			continue
		parts.append("%s %d" % [str(row.get("name", id)), value])
	return " · ".join(PackedStringArray(parts))
