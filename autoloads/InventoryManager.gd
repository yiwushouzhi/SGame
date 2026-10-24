extends Node
## 背包、装备、掉落生成。物品静态数据来自 data/item_data.json。

signal inventory_changed
signal equipment_changed

const CAPACITY: int = 32
const ITEM_DATA_PATH := "res://data/item_data.json"

var item_db: Dictionary = {}
var equipment_bases: Dictionary = {}
var rarity_multiplier: Dictionary = {}
var affix_pool: Array = []
var slot_chinese: Dictionary = {}
var slot_order: Array[String] = ["weapon", "helmet", "chest", "gloves", "boots", "amulet", "ring"]

var inventory: Array[Dictionary] = []
var equipment: Dictionary = {}
var _next_uid: int = 1

func _ready() -> void:
	_load_data()
	reset_inventory()

func _load_data() -> void:
	var parsed: Variant = GameManager._load_json(ITEM_DATA_PATH)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("item_data.json 结构错误")
		return
	item_db = parsed.get("items", {})
	equipment_bases = parsed.get("equipment_bases", {})
	rarity_multiplier = parsed.get("rarity_multiplier", {})
	affix_pool = parsed.get("affix_pool", [])
	slot_chinese = parsed.get("slot_chinese", {})

func reset_inventory() -> void:
	inventory.clear()
	equipment.clear()
	for slot in slot_order:
		equipment[slot] = null
	_next_uid = 1
	inventory_changed.emit()
	equipment_changed.emit()

func get_def(id: String) -> Dictionary:
	return item_db.get(id, {})

func make_item(id: String, count: int = 1) -> Dictionary:
	var def := get_def(id)
	if def.is_empty():
		push_warning("未知物品: %s" % id)
		return {}
	return {
		"uid": _take_uid(),
		"id": id,
		"name": def.get("name", id),
		"type": def.get("type", "material"),
		"rarity": def.get("rarity", "white"),
		"color": def.get("color", "#cfc7b8"),
		"desc": def.get("desc", ""),
		"max_stack": int(def.get("max_stack", 1)),
		"stack": max(1, count),
		"heal": int(def.get("heal", 0)),
		"sanity": int(def.get("sanity", 0)),
		"use": def.get("use", "")
	}

func _take_uid() -> int:
	var uid := _next_uid
	_next_uid += 1
	return uid

# ---------------------------------------------------------------- 添加 / 移除

func add_item(id: String, count: int = 1) -> bool:
	if count <= 0:
		return true
	return add_item_instance(make_item(id, count))

func add_item_instance(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	if item.get("type", "") == "equipment":
		if inventory.size() >= CAPACITY:
			return false
		if not item.has("uid"):
			item["uid"] = _take_uid()
		inventory.append(item)
		inventory_changed.emit()
		return true

	var remaining: int = int(item.get("stack", 1))
	var max_stack: int = max(1, int(item.get("max_stack", 1)))
	for stack in inventory:
		if remaining <= 0:
			break
		if stack.get("id", "") != item.get("id", ""):
			continue
		if stack.get("type", "") == "equipment":
			continue
		var space: int = max_stack - int(stack.get("stack", 0))
		if space <= 0:
			continue
		var moved: int = min(space, remaining)
		stack["stack"] = int(stack["stack"]) + moved
		remaining -= moved

	while remaining > 0 and inventory.size() < CAPACITY:
		var portion: int = min(remaining, max_stack)
		var new_stack := item.duplicate(true)
		new_stack["uid"] = _take_uid()
		new_stack["stack"] = portion
		inventory.append(new_stack)
		remaining -= portion

	if remaining < int(item.get("stack", 1)):
		inventory_changed.emit()
	return remaining == 0

func remove_item(uid: int, count: int = 1) -> bool:
	for i in range(inventory.size()):
		var item := inventory[i]
		if int(item.get("uid", -1)) != uid:
			continue
		var stack: int = int(item.get("stack", 1))
		if stack <= count:
			inventory.remove_at(i)
		else:
			item["stack"] = stack - count
		inventory_changed.emit()
		return true
	return false

func count_item(id: String) -> int:
	var total := 0
	for item in inventory:
		if item.get("id", "") == id:
			total += int(item.get("stack", 1))
	return total

func consume_id(id: String, count: int = 1) -> bool:
	if count_item(id) < count:
		return false
	var remaining := count
	for i in range(inventory.size() - 1, -1, -1):
		if remaining <= 0:
			break
		var item := inventory[i]
		if item.get("id", "") != id:
			continue
		var stack: int = int(item.get("stack", 1))
		var used: int = min(stack, remaining)
		remaining -= used
		if used >= stack:
			inventory.remove_at(i)
		else:
			item["stack"] = stack - used
	inventory_changed.emit()
	return true

func find_item(uid: int) -> Dictionary:
	for item in inventory:
		if int(item.get("uid", -1)) == uid:
			return item
	return {}

# ---------------------------------------------------------------- 装备

func equip_item(uid: int) -> bool:
	var item := find_item(uid)
	if item.is_empty() or item.get("type", "") != "equipment":
		return false
	var slot: String = item.get("slot", "")
	if not equipment.has(slot):
		return false
	var old: Variant = equipment[slot]
	inventory.erase(item)
	equipment[slot] = item
	if old != null:
		inventory.append(old)
	inventory_changed.emit()
	equipment_changed.emit()
	return true

func unequip_slot(slot: String) -> bool:
	if not equipment.has(slot) or equipment[slot] == null:
		return false
	if inventory.size() >= CAPACITY:
		GameManager.show_toast("背包已满，无法卸下装备")
		return false
	var item: Dictionary = equipment[slot]
	equipment[slot] = null
	inventory.append(item)
	inventory_changed.emit()
	equipment_changed.emit()
	return true

func get_equipped(slot: String) -> Variant:
	return equipment.get(slot, null)

func get_equipment_stats() -> Dictionary:
	var total := {
		"damage": 0.0,
		"armor": 0.0,
		"max_hp": 0.0,
		"max_sanity": 0.0,
		"crit": 0.0,
		"speed": 0.0
	}
	for slot in slot_order:
		var item: Variant = equipment.get(slot, null)
		if item == null:
			continue
		var stats: Dictionary = item.get("stats", {})
		for key in total.keys():
			total[key] = float(total[key]) + float(stats.get(key, 0.0))
	return total

# ---------------------------------------------------------------- 装备生成

func generate_equipment(rarity: String, slot: String = "") -> Dictionary:
	if not equipment_bases.has(slot):
		slot = slot_order.pick_random()
	var base: Dictionary = equipment_bases.get(slot, {})
	var mult: float = float(rarity_multiplier.get(rarity, 1.0))
	var stats: Dictionary = {}
	var base_stats: Dictionary = base.get("base_stat", {})
	for key in base_stats.keys():
		stats[key] = float(base_stats[key]) * mult

	var affix_count := 0
	match rarity:
		"blue":
			affix_count = randi_range(1, 2)
		"yellow":
			affix_count = randi_range(3, 4)

	var affixes: Array[String] = []
	for i in range(affix_count):
		var affix: Dictionary = affix_pool.pick_random()
		var value := snappedf(randf_range(float(affix["min"]), float(affix["max"])), 0.1)
		var stat_key: String = affix["stat"]
		stats[stat_key] = float(stats.get(stat_key, 0.0)) + value
		var value_text := str(int(round(value)))
		if float(value) < 1.0:
			value_text = "%.2f" % value
		affixes.append("+%s %s%s" % [value_text, affix["label"], affix["suffix"]])

	var names: Dictionary = base.get("names", {})
	var item := {
		"uid": _take_uid(),
		"id": "equipment_" + slot,
		"name": names.get(rarity, base.get("name", "装备")),
		"type": "equipment",
		"slot": slot,
		"rarity": rarity,
		"color": rarity_color(rarity),
		"desc": base.get("desc", ""),
		"stats": stats,
		"affixes": affixes,
		"max_stack": 1,
		"stack": 1
	}
	return item

func rarity_color(rarity: String) -> String:
	match rarity:
		"blue":
			return "#4e8fd8"
		"yellow":
			return "#e0b23c"
		_:
			return "#d9d4c7"

func rarity_name(rarity: String) -> String:
	match rarity:
		"blue":
			return "蓝色改造"
		"yellow":
			return "黄色稀有"
		_:
			return "白色残破"

func slot_name(slot: String) -> String:
	return slot_chinese.get(slot, slot)

func stats_text(item: Dictionary) -> String:
	if item.get("type", "") != "equipment":
		return ""
	var stats: Dictionary = item.get("stats", {})
	var parts: Array[String] = []
	if float(stats.get("damage", 0)) > 0:
		parts.append("伤害 +%d" % int(round(float(stats["damage"]))))
	if float(stats.get("armor", 0)) > 0:
		parts.append("护甲 +%d" % int(round(float(stats["armor"]))))
	if float(stats.get("max_hp", 0)) > 0:
		parts.append("生命 +%d" % int(round(float(stats["max_hp"]))))
	if float(stats.get("max_sanity", 0)) > 0:
		parts.append("理智 +%d" % int(round(float(stats["max_sanity"]))))
	if float(stats.get("crit", 0)) > 0:
		parts.append("暴击 +%.1f%%" % float(stats["crit"]))
	if float(stats.get("speed", 0)) > 0:
		parts.append("移速 +%.2f" % float(stats["speed"]))
	var affixes: Array = item.get("affixes", [])
	if not affixes.is_empty():
		parts.append("词缀：" + "，".join(affixes))
	return "  ".join(parts)

# ---------------------------------------------------------------- 掉落

func spawn_pickup(item: Dictionary, pos: Vector2) -> void:
	if item.is_empty():
		return
	var scene := get_tree().current_scene
	if scene == null:
		return
	var node := Node2D.new()
	node.set_script(preload("res://scripts/props/pickup.gd"))
	node.item_data = item
	var jitter := Vector2(randf_range(-22.0, 22.0), randf_range(-22.0, 22.0))
	node.position = pos + jitter
	scene.add_child(node)

func spawn_item_id(id: String, pos: Vector2, count: int = 1) -> void:
	spawn_pickup(make_item(id, count), pos)

func roll_enemy_drops(enemy_type: String, pos: Vector2, is_elite: bool) -> void:
	match enemy_type:
		"zombie":
			_roll_material_table(pos, [
				{"id": "white_junk", "chance": 65.0},
				{"id": "scrap", "chance": 25.0},
				{"id": "small_hp", "chance": 10.0}
			])
			_roll_equipment_table(pos, is_elite)
		"winged_wretch":
			var material := _roll_weighted([
				{"id": "void_shard", "chance": 12.0},
				{"id": "cloth", "chance": 28.0},
				{"id": "white_equipment", "chance": 60.0}
			])
			if material == "white_equipment":
				spawn_pickup(generate_equipment("white"), pos)
			elif material != "":
				spawn_item_id(material, pos)
			_roll_equipment_table(pos, is_elite)
		"vine_spawn":
			if randf() < 0.25:
				spawn_item_id("scrap", pos)
		_:
			pass

func _roll_material_table(pos: Vector2, table: Array) -> void:
	var result := _roll_weighted(table)
	if result != "":
		spawn_item_id(result, pos)

func _roll_equipment_table(pos: Vector2, is_elite: bool) -> void:
	var roll := randf() * 100.0
	if is_elite:
		if roll < 6.0:
			spawn_pickup(generate_equipment("yellow"), pos)
		elif roll < 36.0:
			spawn_pickup(generate_equipment("blue"), pos)
		elif roll < 76.0:
			spawn_pickup(generate_equipment("white"), pos)
	else:
		if roll < 0.8:
			spawn_pickup(generate_equipment("yellow"), pos)
		elif roll < 8.8:
			spawn_pickup(generate_equipment("blue"), pos)
		elif roll < 70.8:
			spawn_pickup(generate_equipment("white"), pos)

func _roll_weighted(table: Array) -> String:
	var total := 0.0
	for entry in table:
		total += float(entry["chance"])
	var roll := randf() * maxf(total, 0.001)
	var cursor := 0.0
	for entry in table:
		cursor += float(entry["chance"])
		if roll <= cursor:
			return str(entry["id"])
	return ""

func roll_boss_drops(pos: Vector2) -> void:
	# 保底蓝色改造装备 ×1
	spawn_pickup(generate_equipment("blue"), pos)
	# 稀有黄色装备 22%
	if randf() < 0.22:
		spawn_pickup(generate_equipment("yellow"), pos)
	# 虚空碎片 ×2 / 金属废料 ×4 / 小型理智药水 ×1
	spawn_item_id("void_shard", pos, 2)
	spawn_item_id("scrap", pos, 4)
	spawn_item_id("small_sanity", pos, 1)

func roll_chest_drops(pos: Vector2) -> void:
	var gold_amount := randi_range(12, 30)
	GameManager.add_gold(gold_amount)
	var equipment_roll := randf()
	if equipment_roll < 0.15:
		spawn_pickup(generate_equipment("yellow"), pos)
	elif equipment_roll < 0.55:
		spawn_pickup(generate_equipment("blue"), pos)
	else:
		spawn_pickup(generate_equipment("white"), pos)
	spawn_item_id("small_hp", pos, randi_range(1, 2))
	if randf() < 0.55:
		spawn_item_id("void_shard", pos)
	if randf() < 0.5:
		spawn_item_id("scrap", pos, randi_range(1, 3))

func add_generated_equipment(rarity: String) -> bool:
	var item := generate_equipment(rarity)
	if add_item_instance(item):
		return true
	GameManager.show_toast("背包已满，产出掉在脚下")
	var player := get_tree().get_first_node_in_group("player")
	if player != null:
		spawn_pickup(item, player.global_position)
	return false
