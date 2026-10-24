extends Control
## 昆特的拾荒魔方面板：3 个材料槽 + 配方匹配 + 产出预览 + 已解锁配方。

signal closed

var _slots: Array[Dictionary] = []
var _slot_buttons: Array[Button] = []
var _material_grid: GridContainer
var _match_label: Label
var _output_label: Label
var _craft_button: Button
var _recipe_label: Label
var _hint_label: Label

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_slots = [{}, {}, {}]
	_build()
	InventoryManager.inventory_changed.connect(_on_inventory_changed)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.BORDER_LIGHT, 4)
	panel.position = Vector2(360, 160)
	panel.size = Vector2(1200, 760)
	add_child(panel)

	var title := UITheme.make_title("昆特的拾荒魔方", 40)
	title.position = Vector2(32, 16)
	panel.add_child(title)

	var subtitle := UITheme.make_label("原型配方全部 100% 成功 · 无失败惩罚", 17, UITheme.MUTED)
	subtitle.position = Vector2(36, 66)
	panel.add_child(subtitle)

	var close_btn := UITheme.make_button("×", 28, UITheme.DANGER)
	close_btn.position = Vector2(1120, 16)
	close_btn.size = Vector2(58, 46)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)

	panel.add_child(_section_label("材料槽（3）", Vector2(60, 96)))
	for i in range(3):
		var button := UITheme.make_button("空槽位", 16)
		button.position = Vector2(60 + i * 132, 128)
		button.size = Vector2(110, 110)
		button.clip_text = true
		button.pressed.connect(_on_slot_pressed.bind(i))
		panel.add_child(button)
		_slot_buttons.append(button)

	panel.add_child(_section_label("产出预览", Vector2(520, 96)))
	var output_panel := UITheme.make_panel(UITheme.PANEL_BG_SOFT, UITheme.BORDER_LIGHT, 3)
	output_panel.position = Vector2(520, 128)
	output_panel.size = Vector2(190, 110)
	panel.add_child(output_panel)
	_output_label = UITheme.make_label("等待配方", 18, UITheme.MUTED)
	_output_label.position = Vector2(12, 12)
	_output_label.size = Vector2(166, 86)
	_output_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_output_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_output_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	output_panel.add_child(_output_label)

	_match_label = UITheme.make_label("放入 3 个材料以匹配配方", 18, UITheme.MUTED)
	_match_label.position = Vector2(340, 140)
	_match_label.size = Vector2(380, 50)
	_match_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_match_label)

	_craft_button = UITheme.make_button("合成", 26, UITheme.GOLD)
	_craft_button.position = Vector2(340, 196)
	_craft_button.size = Vector2(240, 62)
	_craft_button.disabled = true
	_craft_button.pressed.connect(_on_craft_pressed)
	panel.add_child(_craft_button)

	var recipe_panel := UITheme.make_panel(UITheme.PANEL_BG_SOFT, UITheme.BORDER_LIGHT, 3)
	recipe_panel.position = Vector2(760, 96)
	recipe_panel.size = Vector2(400, 300)
	panel.add_child(recipe_panel)
	recipe_panel.add_child(_section_label("已解锁配方", Vector2(16, 10)))
	_recipe_label = UITheme.make_label("", 15, UITheme.MUTED)
	_recipe_label.position = Vector2(16, 46)
	_recipe_label.size = Vector2(368, 240)
	_recipe_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_panel.add_child(_recipe_label)
	_build_recipe_text()

	panel.add_child(_section_label("背包材料（点击放入槽位）", Vector2(60, 372)))
	_material_grid = GridContainer.new()
	_material_grid.columns = 8
	_material_grid.position = Vector2(60, 408)
	_material_grid.add_theme_constant_override("h_separation", 6)
	_material_grid.add_theme_constant_override("v_separation", 6)
	panel.add_child(_material_grid)

	_hint_label = UITheme.make_label("点击材料放入槽位；关闭面板会把槽位材料退回背包。", 16, UITheme.MUTED)
	_hint_label.position = Vector2(60, 706)
	_hint_label.size = Vector2(1080, 30)
	panel.add_child(_hint_label)

func _section_label(text: String, pos: Vector2) -> Label:
	var label := UITheme.make_label(text, 22, UITheme.GOLD)
	label.position = pos
	return label

func _build_recipe_text() -> void:
	var lines: Array[String] = []
	var index := 1
	for recipe in CraftManager.get_recipe_list():
		lines.append("%d. %s：%s" % [index, recipe.get("name", ""), recipe.get("hint", "")])
		index += 1
	_recipe_label.text = "\n".join(lines)

func open() -> void:
	visible = true
	refresh()

func close() -> void:
	if not visible:
		return
	_return_slot_items()
	visible = false
	closed.emit()

func _return_slot_items() -> void:
	for i in range(_slots.size()):
		var item := _slots[i]
		if item.is_empty():
			continue
		if not InventoryManager.add_item_instance(item):
			var player := get_tree().get_first_node_in_group("player")
			if player != null and is_instance_valid(player):
				InventoryManager.spawn_pickup(item, player.global_position + Vector2(50, 0))
			GameManager.show_toast("背包已满，材料掉在脚下")
		_slots[i] = {}
	_refresh_slots()

func _on_inventory_changed() -> void:
	if visible:
		refresh()

func refresh() -> void:
	_refresh_slots()
	_refresh_materials()
	_refresh_match()

func _refresh_slots() -> void:
	for i in range(3):
		var button := _slot_buttons[i]
		var item := _slots[i]
		if item.is_empty():
			button.text = "空槽位"
			button.tooltip_text = "点击下方的背包材料放入"
			button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG.darkened(0.15), UITheme.BORDER, 2, 3))
		else:
			var name := str(item.get("name", "?"))
			if name.length() > 5:
				name = name.substr(0, 5)
			button.text = name
			button.tooltip_text = "点击取回：%s" % item.get("name", "")
			var color := Color.html(str(item.get("color", "#d9d4c7")))
			button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG_SOFT, color, 3, 3))

func _refresh_materials() -> void:
	for child in _material_grid.get_children():
		_material_grid.remove_child(child)
		child.queue_free()
	var items := InventoryManager.inventory
	if items.is_empty():
		var empty := UITheme.make_label("背包是空的。去城郊搜刮材料吧。", 17, UITheme.MUTED)
		empty.custom_minimum_size = Vector2(300, 60)
		_material_grid.add_child(empty)
		return
	for i in range(items.size()):
		var item := items[i]
		var button := UITheme.make_button("", 15)
		button.custom_minimum_size = Vector2(118, 64)
		button.size = Vector2(118, 64)
		button.clip_text = true
		var name := str(item.get("name", "?"))
		if name.length() > 5:
			name = name.substr(0, 5)
		var stack := int(item.get("stack", 1))
		button.text = name if stack <= 1 else "%s×%d" % [name, stack]
		button.tooltip_text = "%s\n%s" % [item.get("name", ""), item.get("desc", "")]
		var color := Color.html(str(item.get("color", "#d9d4c7")))
		button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG_SOFT, color, 3, 3))
		button.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.PANEL_BG_SOFT.lightened(0.1), color.lightened(0.2), 3, 3))
		button.pressed.connect(_on_material_pressed.bind(i))
		_material_grid.add_child(button)

func _refresh_match() -> void:
	var filled := 0
	for item in _slots:
		if not item.is_empty():
			filled += 1
	if filled < 3:
		_match_label.text = "还需放入 %d 个材料" % (3 - filled)
		_match_label.add_theme_color_override("font_color", UITheme.MUTED)
		_output_label.text = "等待配方"
		_output_label.add_theme_color_override("font_color", UITheme.MUTED)
		_craft_button.disabled = true
		return
	var recipe := CraftManager.match_recipe(_slots)
	if recipe.is_empty():
		_match_label.text = "材料不对，无法匹配配方"
		_match_label.add_theme_color_override("font_color", UITheme.DANGER)
		_output_label.text = "无产出"
		_output_label.add_theme_color_override("font_color", UITheme.DANGER)
		_craft_button.disabled = true
		return
	_match_label.text = "匹配配方：%s" % recipe.get("name", "")
	_match_label.add_theme_color_override("font_color", UITheme.GOLD)
	_output_label.text = CraftManager.recipe_output_text(recipe)
	_output_label.add_theme_color_override("font_color", UITheme.GOLD)
	_craft_button.disabled = false

func _on_material_pressed(index: int) -> void:
	var free_slot := -1
	for i in range(_slots.size()):
		if _slots[i].is_empty():
			free_slot = i
			break
	if free_slot < 0:
		GameManager.show_toast("材料槽已满，点击槽位可取出")
		return
	var items := InventoryManager.inventory
	if index < 0 or index >= items.size():
		return
	var item := items[index]
	if item.get("type", "") == "equipment" or int(item.get("stack", 1)) <= 1:
		var copy := item.duplicate(true)
		InventoryManager.remove_item(int(item.get("uid", -1)), 1)
		_slots[free_slot] = copy
	else:
		var id: String = str(item.get("id", ""))
		InventoryManager.remove_item(int(item.get("uid", -1)), 1)
		_slots[free_slot] = InventoryManager.make_item(id, 1)
	refresh()

func _on_slot_pressed(index: int) -> void:
	var item := _slots[index]
	if item.is_empty():
		return
	if InventoryManager.add_item_instance(item):
		_slots[index] = {}
	else:
		GameManager.show_toast("背包已满，无法取回材料")
	refresh()

func _on_craft_pressed() -> void:
	if _craft_button.disabled:
		return
	var recipe := CraftManager.match_recipe(_slots)
	if recipe.is_empty():
		return
	var result := CraftManager.try_craft(_slots)
	if result.get("success", false):
		GameManager.show_toast("合成成功：%s" % CraftManager.recipe_output_text(recipe))
		for i in range(_slots.size()):
			_slots[i] = {}
		refresh()
	else:
		GameManager.show_toast("合成失败：材料不对")
