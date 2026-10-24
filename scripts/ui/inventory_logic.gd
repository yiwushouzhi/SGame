extends Control
## 背包 / 角色面板。4×8 格背包 + 7 个装备位 + 详情面板。

signal closed

const GRID_COLS: int = 8
const GRID_ROWS: int = 4
const CELL_SIZE: float = 96.0
const EQUIP_SLOTS: Array[String] = ["weapon", "helmet", "chest", "gloves", "boots", "amulet", "ring"]

var _selected_uid: int = -1
var _grid_buttons: Array[Button] = []
var _equip_buttons: Dictionary = {}
var _detail_name: Label
var _detail_stats: Label
var _detail_desc: Label
var _action_button: Button
var _drop_button: Button
var _stats_label: Label

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()
	InventoryManager.inventory_changed.connect(_on_inventory_changed)
	InventoryManager.equipment_changed.connect(_on_inventory_changed)

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.62)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.BORDER_LIGHT, 4)
	panel.position = Vector2(350, 150)
	panel.size = Vector2(1220, 780)
	add_child(panel)

	var title := UITheme.make_title("背包 / 角色", 40)
	title.position = Vector2(30, 16)
	panel.add_child(title)

	var close_btn := UITheme.make_button("×", 28, UITheme.DANGER)
	close_btn.position = Vector2(1134, 16)
	close_btn.size = Vector2(58, 46)
	close_btn.pressed.connect(close)
	panel.add_child(close_btn)

	var equip_title := UITheme.make_label("装备栏", 22, UITheme.GOLD)
	equip_title.position = Vector2(30, 78)
	panel.add_child(equip_title)

	for i in range(EQUIP_SLOTS.size()):
		var slot := EQUIP_SLOTS[i]
		var button := UITheme.make_button("", 17)
		button.position = Vector2(30, 112 + i * 64)
		button.size = Vector2(286, 54)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.clip_text = true
		button.pressed.connect(_on_equip_slot_pressed.bind(slot))
		panel.add_child(button)
		_equip_buttons[slot] = button

	_stats_label = UITheme.make_label("", 17, UITheme.MUTED)
	_stats_label.position = Vector2(30, 566)
	_stats_label.size = Vector2(300, 200)
	_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(_stats_label)

	var grid_title := UITheme.make_label("物品格 4×8（点击选中）", 22, UITheme.GOLD)
	grid_title.position = Vector2(360, 78)
	panel.add_child(grid_title)

	var grid := GridContainer.new()
	grid.columns = GRID_COLS
	grid.position = Vector2(360, 112)
	grid.add_theme_constant_override("h_separation", 6)
	grid.add_theme_constant_override("v_separation", 6)
	panel.add_child(grid)
	for i in range(GRID_COLS * GRID_ROWS):
		var button := UITheme.make_button("", 15)
		button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
		button.size = Vector2(CELL_SIZE, CELL_SIZE)
		button.clip_text = true
		button.pressed.connect(_on_grid_pressed.bind(i))
		grid.add_child(button)
		_grid_buttons.append(button)

	var detail := UITheme.make_panel(UITheme.PANEL_BG_SOFT, UITheme.BORDER_LIGHT, 3)
	detail.position = Vector2(360, 530)
	detail.size = Vector2(820, 220)
	panel.add_child(detail)

	_detail_name = UITheme.make_label("未选中物品", 24, UITheme.TEXT)
	_detail_name.position = Vector2(18, 12)
	_detail_name.size = Vector2(590, 32)
	_detail_name.clip_text = true
	detail.add_child(_detail_name)

	_detail_stats = UITheme.make_label("", 17, UITheme.GOLD)
	_detail_stats.position = Vector2(18, 50)
	_detail_stats.size = Vector2(600, 64)
	_detail_stats.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_stats)

	_detail_desc = UITheme.make_label("", 16, UITheme.MUTED)
	_detail_desc.position = Vector2(18, 120)
	_detail_desc.size = Vector2(600, 80)
	_detail_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	detail.add_child(_detail_desc)

	_action_button = UITheme.make_button("装备", 20, UITheme.GOLD)
	_action_button.position = Vector2(640, 18)
	_action_button.size = Vector2(158, 52)
	_action_button.disabled = true
	_action_button.pressed.connect(_on_action_pressed)
	detail.add_child(_action_button)

	_drop_button = UITheme.make_button("丢弃", 20, UITheme.DANGER)
	_drop_button.position = Vector2(640, 82)
	_drop_button.size = Vector2(158, 52)
	_drop_button.disabled = true
	_drop_button.pressed.connect(_on_drop_pressed)
	detail.add_child(_drop_button)

func open() -> void:
	_selected_uid = -1
	visible = true
	refresh()

func close() -> void:
	if not visible:
		return
	visible = false
	_selected_uid = -1
	closed.emit()

func _on_inventory_changed() -> void:
	if visible:
		refresh()

func refresh() -> void:
	_refresh_grid()
	_refresh_equipment()
	_refresh_stats()
	_refresh_detail()

func _refresh_grid() -> void:
	var items := InventoryManager.inventory
	for i in range(_grid_buttons.size()):
		var button := _grid_buttons[i]
		if i >= items.size():
			button.text = ""
			button.disabled = true
			button.tooltip_text = ""
			button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG.darkened(0.2), UITheme.BORDER, 2, 3))
			button.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.PANEL_BG, UITheme.BORDER, 2, 3))
			continue
		var item := items[i]
		var name := str(item.get("name", "?"))
		if name.length() > 5:
			name = name.substr(0, 5)
		var stack := int(item.get("stack", 1))
		button.text = name if stack <= 1 else "%s×%d" % [name, stack]
		button.disabled = false
		button.tooltip_text = _item_tooltip(item)
		var color := Color.html(str(item.get("color", "#d9d4c7")))
		button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG_SOFT, color, 3, 3))
		button.add_theme_stylebox_override("hover", UITheme.panel_style(UITheme.PANEL_BG_SOFT.lightened(0.1), color.lightened(0.2), 3, 3))

func _refresh_equipment() -> void:
	for slot in EQUIP_SLOTS:
		var button: Button = _equip_buttons[slot]
		var item: Variant = InventoryManager.get_equipped(slot)
		var slot_label: String = InventoryManager.slot_name(slot)
		if item == null:
			button.text = "%s：空" % slot_label
			button.tooltip_text = "点击装备栏中的物品可卸下"
			button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG.darkened(0.1), UITheme.BORDER, 2, 3))
		else:
			button.text = "%s：%s" % [slot_label, item.get("name", "?")]
			button.tooltip_text = _item_tooltip(item)
			button.add_theme_stylebox_override("normal", UITheme.panel_style(UITheme.PANEL_BG_SOFT, Color.html(str(item.get("color", "#d9d4c7"))), 3, 3))

func _refresh_stats() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		_stats_label.text = ""
		return
	_stats_label.text = "Lv.%d 杰克\n生命 %d / %d\n理智 %d / %d\n攻击 %d ~ %d\n暴击 %.1f%%（血量>80%% 再 +10%%）\n闪避 %.1f%%\n护甲 %d%%\n移速 %.2f 码/秒" % [
		player.level, player.hp, player.max_hp, player.sanity, player.max_sanity,
		int(round(player.get_attack_damage_min())), int(round(player.get_attack_damage_max())),
		player.get_crit_chance(), player.get_dodge_chance(),
		int(round(player.get_armor_percent())), player.get_move_speed_value()
	]

func _refresh_detail() -> void:
	var item := InventoryManager.find_item(_selected_uid)
	if item.is_empty():
		_detail_name.text = "未选中物品"
		_detail_stats.text = "点击背包格子查看详情"
		_detail_desc.text = "装备可提升属性；药水可立即使用；材料用于拾荒魔方。"
		_action_button.disabled = true
		_drop_button.disabled = true
		return
	var rarity: String = str(item.get("rarity", "white"))
	_detail_name.text = "【%s】%s" % [InventoryManager.rarity_name(rarity), item.get("name", "?")]
	_detail_name.add_theme_color_override("font_color", Color.html(str(item.get("color", "#d9d4c7"))))
	var type: String = str(item.get("type", "material"))
	if type == "equipment":
		_detail_stats.text = "部位：%s\n%s" % [InventoryManager.slot_name(str(item.get("slot", ""))), InventoryManager.stats_text(item)]
		_action_button.text = "装备"
		_action_button.disabled = false
	elif type == "consumable":
		var effect: Array[String] = []
		if int(item.get("heal", 0)) > 0:
			effect.append("回复生命 %d" % int(item.get("heal", 0)))
		if int(item.get("sanity", 0)) > 0:
			effect.append("回复理智 %d" % int(item.get("sanity", 0)))
		if str(item.get("use", "")) != "":
			effect.append("使用后释放道具")
		_detail_stats.text = "消耗品：" + "，".join(effect)
		_action_button.text = "使用"
		_action_button.disabled = false
	else:
		_detail_stats.text = "材料：可用于昆特的拾荒魔方"
		_action_button.text = "不可使用"
		_action_button.disabled = true
	_detail_desc.text = str(item.get("desc", ""))
	_drop_button.disabled = false

func _on_grid_pressed(index: int) -> void:
	var items := InventoryManager.inventory
	if index >= items.size():
		return
	_selected_uid = int(items[index].get("uid", -1))
	_refresh_detail()

func _on_equip_slot_pressed(slot: String) -> void:
	if InventoryManager.unequip_slot(slot):
		GameManager.show_toast("已卸下装备")
		refresh()

func _on_action_pressed() -> void:
	var item := InventoryManager.find_item(_selected_uid)
	if item.is_empty():
		return
	if item.get("type", "") == "equipment":
		if InventoryManager.equip_item(_selected_uid):
			GameManager.show_toast("已装备：%s" % item.get("name", ""))
			_selected_uid = -1
			refresh()
		return
	if item.get("type", "") == "consumable":
		var player := get_tree().get_first_node_in_group("player")
		if player == null or not is_instance_valid(player):
			return
		if player.consume_item(item):
			InventoryManager.remove_item(_selected_uid, 1)
			_selected_uid = -1
			refresh()

func _on_drop_pressed() -> void:
	var item := InventoryManager.find_item(_selected_uid)
	if item.is_empty():
		return
	var player := get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		var drop_pos: Vector2 = player.global_position + Vector2(52, 0)
		InventoryManager.spawn_pickup(item, drop_pos)
	InventoryManager.remove_item(_selected_uid, int(item.get("stack", 1)))
	_selected_uid = -1
	refresh()

func _item_tooltip(item: Dictionary) -> String:
	var parts: Array[String] = [str(item.get("name", ""))]
	parts.append(InventoryManager.rarity_name(str(item.get("rarity", "white"))))
	if item.get("type", "") == "equipment":
		parts.append(InventoryManager.stats_text(item))
	parts.append(str(item.get("desc", "")))
	return "\n".join(parts)

func _on_close_clicked() -> void:
	close()
