extends Node
## 昆特拾荒魔方：原型 5 条基础配方，成功率 100%。

signal crafted(recipe: Dictionary, result: Dictionary)

const RECIPE_PATH := "res://data/recipe_data.json"

var recipe_list: Array = []

func _ready() -> void:
	var parsed: Variant = GameManager._load_json(RECIPE_PATH)
	if typeof(parsed) != TYPE_ARRAY:
		push_error("recipe_data.json 结构错误")
		return
	recipe_list = parsed

func match_recipe(items: Array) -> Dictionary:
	if items.size() != 3:
		return {}
	for recipe in recipe_list:
		var inputs: Array = recipe.get("inputs", [])
		if inputs.size() != items.size():
			continue
		if _matches(inputs, items):
			return recipe
	return {}

func _matches(inputs: Array, items: Array) -> bool:
	var used: Array[bool] = []
	used.resize(items.size())
	used.fill(false)
	for selector in inputs:
		var found := false
		for i in range(items.size()):
			if used[i]:
				continue
			if _item_matches(items[i], selector):
				used[i] = true
				found = true
				break
		if not found:
			return false
	return true

func _item_matches(item: Dictionary, selector: Dictionary) -> bool:
	if selector.has("id") and str(item.get("id", "")) != str(selector["id"]):
		return false
	if selector.has("type") and str(item.get("type", "")) != str(selector["type"]):
		return false
	if selector.has("rarity") and str(item.get("rarity", "")) != str(selector["rarity"]):
		return false
	return true

func try_craft(materials: Array) -> Dictionary:
	var recipe := match_recipe(materials)
	if recipe.is_empty():
		return {"success": false}
	var output: Dictionary = recipe.get("output", {})
	var count: int = int(output.get("count", 1))
	if output.has("type") and str(output["type"]) == "equipment":
		var rarity: String = str(output.get("rarity", "white"))
		for i in range(count):
			InventoryManager.add_generated_equipment(rarity)
	else:
		var id: String = str(output.get("id", ""))
		if id != "" and id != "<null>":
			if not InventoryManager.add_item(id, count):
				GameManager.show_toast("背包已满，产出掉在脚下")
				var player := get_tree().get_first_node_in_group("player")
				if player != null:
					InventoryManager.spawn_item_id(id, player.global_position, count)
	crafted.emit(recipe, output)
	return {"success": true, "recipe": recipe, "output": output}

func get_recipe_list() -> Array:
	return recipe_list

func recipe_output_text(recipe: Dictionary) -> String:
	var output: Dictionary = recipe.get("output", {})
	if output.has("type") and str(output["type"]) == "equipment":
		return "%s装备 ×%d" % [
			InventoryManager.rarity_name(str(output.get("rarity", "white"))),
			int(output.get("count", 1))
		]
	var id: String = str(output.get("id", ""))
	var def := InventoryManager.get_def(id)
	return "%s ×%d" % [def.get("name", id), int(output.get("count", 1))]
