extends CanvasLayer
## 战斗 HUD：左上状态条、右上圆形小地图、底部技能栏、Boss 血条、提示与暂停面板。

const INVENTORY_PANEL_SCENE := preload("res://scenes/ui/InventoryPanel.tscn")
const CRAFT_PANEL_SCENE := preload("res://scenes/ui/CraftPanel.tscn")
const PAUSE_MENU_SCENE := preload("res://scenes/ui/PauseMenu.tscn")
const MINIMAP_FONT: Font = preload("res://assets/fonts/SmileySans.otf")

var _root: Control
var _player: Node = null

var _hp_bar: ProgressBar
var _hp_label: Label
var _sanity_bar: ProgressBar
var _sanity_label: Label
var _exp_bar: ProgressBar
var _exp_label: Label
var _level_label: Label
var _time_label: Label
var _status_labels: Array[Label] = []

var _quest_label: Label
var _currency_label: Label
var _toast_label: Label
var _prompt_label: Label
var _warning_label: Label

var _slot_main: Array[Label] = []
var _slot_sub: Array[Label] = []
var _slot_panels: Array[Panel] = []

var _boss_panel: Panel
var _boss_name: Label
var _boss_bar: ProgressBar

var _dusk_edges: Control
var _minimap: Minimap
var _hub_button: Button

var _inventory_panel: Control
var _craft_panel: Control
var _pause_menu: Control
var _death_overlay: Control

var _toast_timer: float = 0.0
var _warning_timer: float = 0.0

func _ready() -> void:
	add_to_group("hud")
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_root()
	_build_status_panel()
	_build_minimap()
	_build_quest_and_currency()
	_build_bottom_bar()
	_build_boss_bar()
	_build_warning_and_toast()
	_build_death_overlay()
	_build_hub_button()
	_build_panels()
	_connect_signals()
	set_process(true)

func _build_root() -> void:
	_root = Control.new()
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_root)

func _build_status_panel() -> void:
	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.BORDER_LIGHT, 4)
	panel.position = Vector2(24, 20)
	panel.size = Vector2(560, 212)
	_root.add_child(panel)

	var portrait := UITheme.make_panel(UITheme.PANEL_BG_SOFT, UITheme.GOLD, 3)
	portrait.position = Vector2(14, 14)
	portrait.size = Vector2(92, 92)
	panel.add_child(portrait)
	var portrait_label := UITheme.make_label("杰", 48, UITheme.GOLD)
	portrait_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	portrait_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	portrait_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	portrait.add_child(portrait_label)

	_level_label = UITheme.make_label("Lv.1 杰克", 24, UITheme.GOLD)
	_level_label.position = Vector2(120, 10)
	_level_label.size = Vector2(300, 30)
	panel.add_child(_level_label)

	_hp_bar = _make_bar(Vector2(120, 46), Vector2(340, 24), UITheme.HP)
	panel.add_child(_hp_bar)
	_hp_label = _make_bar_label(Vector2(120, 46), Vector2(340, 24))
	panel.add_child(_hp_label)

	_sanity_bar = _make_bar(Vector2(120, 80), Vector2(340, 20), UITheme.SANITY)
	panel.add_child(_sanity_bar)
	_sanity_label = _make_bar_label(Vector2(120, 80), Vector2(340, 20))
	panel.add_child(_sanity_label)

	_exp_bar = _make_bar(Vector2(120, 112), Vector2(340, 12), UITheme.EXP)
	panel.add_child(_exp_bar)
	_exp_label = _make_bar_label(Vector2(120, 106), Vector2(340, 18), 13)
	panel.add_child(_exp_label)

	var status_names := ["黄昏", "中毒", "灼烧", "失控"]
	for i in range(status_names.size()):
		var label := UITheme.make_label("[%s]" % status_names[i], 15, UITheme.MUTED)
		label.position = Vector2(120 + i * 100, 136)
		label.size = Vector2(96, 22)
		panel.add_child(label)
		_status_labels.append(label)

	_time_label = UITheme.make_label("白天 00:00", 16, UITheme.TEXT)
	_time_label.position = Vector2(120, 166)
	_time_label.size = Vector2(380, 24)
	panel.add_child(_time_label)

func _make_bar(pos: Vector2, bar_size: Vector2, color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.position = pos
	bar.size = bar_size
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	UITheme.style_progress(bar, color)
	return bar

func _make_bar_label(pos: Vector2, bar_size: Vector2, font_size: int = 14) -> Label:
	var label := UITheme.make_label("", font_size, UITheme.TEXT)
	label.position = pos
	label.size = bar_size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_constant_override("outline_size", 4)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label

func _build_minimap() -> void:
	_minimap = Minimap.new()
	_minimap.position = Vector2(1510, 22)
	_minimap.size = Vector2(380, 380)
	_root.add_child(_minimap)

	var legend := UITheme.make_label("绿=杰克  红=怪物  紫=Boss  黄=宝箱  蓝=NPC/传送", 13, UITheme.MUTED)
	legend.position = Vector2(1440, 408)
	legend.size = Vector2(440, 22)
	legend.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(legend)

func _build_quest_and_currency() -> void:
	_quest_label = UITheme.make_label("", 18, UITheme.TEXT)
	_quest_label.position = Vector2(1430, 440)
	_quest_label.size = Vector2(460, 66)
	_quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_quest_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_root.add_child(_quest_label)

	_currency_label = UITheme.make_label("金币 0    ◆ 虚空碎片 0", 20, UITheme.GOLD)
	_currency_label.position = Vector2(1510, 1030)
	_currency_label.size = Vector2(380, 30)
	_currency_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_root.add_child(_currency_label)

func _build_bottom_bar() -> void:
	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.BORDER_LIGHT, 4)
	panel.position = Vector2(420, 948)
	panel.size = Vector2(1080, 104)
	_root.add_child(panel)

	var mains := ["Q 燃烧瓶", "F 捕兽夹", "空格 翻滚", "1 生命药水", "2 理智药水", "T 回城"]
	var accent_colors := [UITheme.EXP, UITheme.MUTED, UITheme.SANITY, UITheme.HP, UITheme.SANITY, UITheme.GOLD]
	for i in range(mains.size()):
		var slot_panel := UITheme.make_panel(UITheme.PANEL_BG_SOFT, accent_colors[i], 2)
		slot_panel.position = Vector2(16 + i * 172, 14)
		slot_panel.size = Vector2(160, 76)
		panel.add_child(slot_panel)
		_slot_panels.append(slot_panel)

		var main_label := UITheme.make_label(mains[i], 17, UITheme.TEXT)
		main_label.position = Vector2(8, 8)
		main_label.size = Vector2(144, 28)
		main_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_panel.add_child(main_label)
		_slot_main.append(main_label)

		var sub_label := UITheme.make_label("就绪", 14, UITheme.MUTED)
		sub_label.position = Vector2(8, 42)
		sub_label.size = Vector2(144, 24)
		sub_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		slot_panel.add_child(sub_label)
		_slot_sub.append(sub_label)

func _build_boss_bar() -> void:
	_boss_panel = UITheme.make_panel(UITheme.PANEL_BG, UITheme.VOID, 3)
	_boss_panel.position = Vector2(620, 24)
	_boss_panel.size = Vector2(680, 76)
	_boss_panel.visible = false
	_root.add_child(_boss_panel)

	_boss_name = UITheme.make_label("藤蔓母怪 Lv.5", 19, UITheme.VOID)
	_boss_name.position = Vector2(12, 6)
	_boss_name.size = Vector2(656, 26)
	_boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_boss_panel.add_child(_boss_name)

	_boss_bar = ProgressBar.new()
	_boss_bar.position = Vector2(20, 40)
	_boss_bar.size = Vector2(640, 18)
	_boss_bar.min_value = 0
	_boss_bar.max_value = 450
	_boss_bar.value = 450
	UITheme.style_progress(_boss_bar, UITheme.VOID)
	_boss_panel.add_child(_boss_bar)

func _build_warning_and_toast() -> void:
	_warning_label = UITheme.make_label("", 46, UITheme.VOID)
	_warning_label.position = Vector2(460, 210)
	_warning_label.size = Vector2(1000, 120)
	_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_warning_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_warning_label.add_theme_constant_override("outline_size", 10)
	_warning_label.add_theme_color_override("font_outline_color", UITheme.BORDER)
	_warning_label.visible = false
	_root.add_child(_warning_label)

	_toast_label = UITheme.make_label("", 22, UITheme.GOLD)
	_toast_label.position = Vector2(460, 866)
	_toast_label.size = Vector2(1000, 44)
	_toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_label.add_theme_constant_override("outline_size", 6)
	_toast_label.add_theme_color_override("font_outline_color", UITheme.BORDER)
	_toast_label.visible = false
	_root.add_child(_toast_label)

	_prompt_label = UITheme.make_label("", 20, UITheme.TEXT)
	_prompt_label.position = Vector2(460, 910)
	_prompt_label.size = Vector2(1000, 30)
	_prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt_label.add_theme_constant_override("outline_size", 5)
	_prompt_label.add_theme_color_override("font_outline_color", UITheme.BORDER)
	_prompt_label.visible = false
	_root.add_child(_prompt_label)

	# 黄昏/黑夜画面边缘泛紫
	_dusk_edges = Control.new()
	_dusk_edges.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dusk_edges.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dusk_edges.visible = false
	_root.add_child(_dusk_edges)
	_add_edge_rect(Vector2(0, 0), Vector2(1920, 26))
	_add_edge_rect(Vector2(0, 1054), Vector2(1920, 26))
	_add_edge_rect(Vector2(0, 0), Vector2(26, 1080))
	_add_edge_rect(Vector2(1894, 0), Vector2(26, 1080))

func _add_edge_rect(pos: Vector2, rect_size: Vector2) -> void:
	var rect := ColorRect.new()
	rect.position = pos
	rect.size = rect_size
	rect.color = Color(0.45, 0.2, 0.75, 0.28)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dusk_edges.add_child(rect)

func _build_death_overlay() -> void:
	_death_overlay = Control.new()
	_death_overlay.visible = false
	_death_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	_death_overlay.process_mode = Node.PROCESS_MODE_ALWAYS
	_death_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_death_overlay)

	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.01, 0.03, 0.78)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_death_overlay.add_child(dim)

	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.DANGER, 4)
	panel.position = Vector2(640, 370)
	panel.size = Vector2(640, 330)
	_death_overlay.add_child(panel)

	var title := UITheme.make_title("杰克倒下了", 50, UITheme.DANGER)
	title.position = Vector2(30, 26)
	title.size = Vector2(580, 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(title)

	var desc := UITheme.make_label("生命耗尽或理智崩塌。\n回树屋重整装备，再来一次。", 20, UITheme.MUTED)
	desc.position = Vector2(40, 104)
	desc.size = Vector2(560, 70)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	panel.add_child(desc)

	var button := UITheme.make_button("返回树屋（恢复状态）", 24, UITheme.GOLD)
	button.position = Vector2(160, 220)
	button.size = Vector2(320, 66)
	button.pressed.connect(GameManager.respawn_in_hub)
	panel.add_child(button)

func _build_hub_button() -> void:
	_hub_button = UITheme.make_button("出发探索 → 城郊居民区", 22, UITheme.EXP)
	_hub_button.position = Vector2(1540, 880)
	_hub_button.size = Vector2(350, 76)
	_hub_button.visible = false
	_hub_button.pressed.connect(GameManager.go_to_suburb)
	_root.add_child(_hub_button)

func _build_panels() -> void:
	_inventory_panel = INVENTORY_PANEL_SCENE.instantiate()
	_root.add_child(_inventory_panel)
	_inventory_panel.closed.connect(_on_panel_closed)

	_craft_panel = CRAFT_PANEL_SCENE.instantiate()
	_root.add_child(_craft_panel)
	_craft_panel.closed.connect(_on_panel_closed)

	_pause_menu = PAUSE_MENU_SCENE.instantiate()
	_root.add_child(_pause_menu)
	_pause_menu.closed.connect(_on_panel_closed)

func _connect_signals() -> void:
	GameManager.toast_requested.connect(_show_toast)
	GameManager.player_died.connect(_on_player_died)
	GameManager.currency_changed.connect(_on_currency_changed)
	GameManager.boss_changed.connect(_on_boss_changed)
	DayNightManager.dusk_started.connect(_on_dusk)
	DayNightManager.night_started.connect(_on_night)
	DayNightManager.day_returned.connect(_on_day)

# ---------------------------------------------------------------- 输入

func _unhandled_input(event: InputEvent) -> void:
	if _death_overlay.visible:
		return
	if event.is_action_pressed("pause"):
		if _any_panel_open():
			_close_all_panels()
		else:
			_open_pause()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("inventory"):
		if _inventory_panel.visible:
			_inventory_panel.close()
		else:
			_open_panel(_inventory_panel)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("craft"):
		if _craft_panel.visible:
			_craft_panel.close()
		else:
			_open_panel(_craft_panel)
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("return_home"):
		if GameManager.current_area == "suburb" and not _any_panel_open():
			GameManager.show_toast("返回树屋")
			GameManager.go_to_hub()
		get_viewport().set_input_as_handled()

func _open_panel(panel: Control) -> void:
	_close_all_panels()
	panel.open()
	GameManager.set_ui_paused(true)

## 供场景内的 NPC / 交互物调用
func open_craft_panel() -> void:
	_open_panel(_craft_panel)

func open_inventory_panel() -> void:
	_open_panel(_inventory_panel)

func _open_pause() -> void:
	_close_all_panels()
	_pause_menu.open()
	GameManager.set_ui_paused(true)

func _close_all_panels() -> void:
	if _inventory_panel.visible:
		_inventory_panel.close()
	if _craft_panel.visible:
		_craft_panel.close()
	if _pause_menu.visible:
		_pause_menu.close()

func _any_panel_open() -> bool:
	return _inventory_panel.visible or _craft_panel.visible or _pause_menu.visible

func _on_panel_closed() -> void:
	if _any_panel_open() or _death_overlay.visible:
		return
	GameManager.set_ui_paused(false)

# ---------------------------------------------------------------- 每帧刷新

func _process(delta: float) -> void:
	_player = get_tree().get_first_node_in_group("player")
	_update_bars()
	_update_status()
	_update_slots()
	_update_quest()
	_update_currency()
	_update_boss()
	_update_prompt()
	_update_hub_button()
	_update_timers(delta)

func _update_bars() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_level_label.text = "Lv.%d 杰克" % _player.level
	_hp_bar.max_value = _player.max_hp
	_hp_bar.value = _player.hp
	_hp_label.text = "%d / %d" % [_player.hp, _player.max_hp]
	_sanity_bar.max_value = _player.max_sanity
	_sanity_bar.value = _player.sanity
	_sanity_label.text = "%d / %d" % [_player.sanity, _player.max_sanity]
	var exp_cap: int = _player.get_exp_to_next()
	_exp_bar.max_value = exp_cap
	_exp_bar.value = _player.exp
	if _player.level >= GameManager.MAX_LEVEL:
		_exp_label.text = "Lv.MAX"
	else:
		_exp_label.text = "EXP %d / %d" % [_player.exp, exp_cap]

func _update_status() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	var active := [
		DayNightManager.is_dark(),
		_player.poison_timer > 0.0,
		_player.burn_timer > 0.0,
		_player.out_of_control
	]
	for i in range(_status_labels.size()):
		var label := _status_labels[i]
		if active[i]:
			label.add_theme_color_override("font_color", UITheme.GOLD)
		else:
			label.add_theme_color_override("font_color", UITheme.MUTED.darkened(0.45))
	if GameManager.current_area == "suburb":
		_time_label.text = DayNightManager.get_time_label()
		_time_label.add_theme_color_override("font_color", UITheme.VOID if DayNightManager.is_dark() else UITheme.TEXT)
	else:
		_time_label.text = "树屋 · 安全区"
		_time_label.add_theme_color_override("font_color", UITheme.GOLD)
	_dusk_edges.visible = GameManager.current_area == "suburb" and DayNightManager.is_dark()

func _update_slots() -> void:
	if _player == null or not is_instance_valid(_player):
		return
	_set_slot(0, _player.q_cd, "燃烧瓶")
	_set_slot(1, _player.w_cd, "捕兽夹")
	_set_slot(2, _player.roll_cd, "翻滚")
	var hp_count := InventoryManager.count_item("small_hp")
	var sanity_count := InventoryManager.count_item("small_sanity")
	_slot_sub[3].text = "×%d" % hp_count
	_slot_sub[4].text = "×%d" % sanity_count
	_slot_sub[3].add_theme_color_override("font_color", UITheme.TEXT if hp_count > 0 else UITheme.MUTED)
	_slot_sub[4].add_theme_color_override("font_color", UITheme.TEXT if sanity_count > 0 else UITheme.MUTED)
	_slot_panels[3].modulate = Color(1, 1, 1, 1) if hp_count > 0 else Color(0.55, 0.55, 0.55, 1)
	_slot_panels[4].modulate = Color(1, 1, 1, 1) if sanity_count > 0 else Color(0.55, 0.55, 0.55, 1)
	if GameManager.current_area == "suburb":
		_slot_sub[5].text = "回树屋"
		_slot_panels[5].modulate = Color(1, 1, 1, 1)
	else:
		_slot_sub[5].text = "仅城郊"
		_slot_panels[5].modulate = Color(0.55, 0.55, 0.55, 1)

func _set_slot(index: int, cooldown: float, label_name: String) -> void:
	if cooldown > 0.02:
		_slot_sub[index].text = "%.1fs" % cooldown
		_slot_sub[index].add_theme_color_override("font_color", UITheme.MUTED)
		_slot_panels[index].modulate = Color(0.55, 0.55, 0.65, 1)
	else:
		_slot_sub[index].text = "就绪"
		_slot_sub[index].add_theme_color_override("font_color", UITheme.TEXT)
		_slot_panels[index].modulate = Color(1, 1, 1, 1)
	_slot_sub[index].tooltip_text = label_name

func _update_quest() -> void:
	var text := GameManager.get_quest_text()
	if GameManager.current_area == "suburb":
		text += "\n%s" % DayNightManager.get_time_label()
	_quest_label.text = text

func _update_currency() -> void:
	_currency_label.text = "金币 %d    ◆ 虚空碎片 %d" % [GameManager.gold, InventoryManager.count_item("void_shard")]

func _update_boss() -> void:
	var boss: Variant = GameManager.active_boss
	if boss == null or not is_instance_valid(boss) or boss.get("dead") == true:
		_boss_panel.visible = false
		return
	_boss_panel.visible = true
	_boss_name.text = "%s  Lv.%d" % [boss.enemy_name, boss.level]
	_boss_bar.max_value = boss.max_hp
	_boss_bar.value = boss.hp

func _update_prompt() -> void:
	_prompt_label.visible = GameManager.interaction_prompt != ""
	_prompt_label.text = GameManager.interaction_prompt

func _update_hub_button() -> void:
	var hub := GameManager.current_area == "hub"
	_hub_button.visible = hub and not _death_overlay.visible
	if hub:
		_hub_button.text = "出发探索 → 城郊居民区"

func _update_timers(delta: float) -> void:
	if _toast_timer > 0.0:
		_toast_timer -= delta
		if _toast_timer <= 0.0:
			_toast_label.visible = false
	if _warning_timer > 0.0:
		_warning_timer -= delta
		if _warning_timer <= 0.0:
			_warning_label.visible = false

# ---------------------------------------------------------------- 信号回调

func _show_toast(text: String) -> void:
	_toast_label.text = text
	_toast_label.visible = true
	_toast_timer = 3.2

func _on_currency_changed() -> void:
	_update_currency()

func _on_boss_changed(_boss: Variant) -> void:
	_update_boss()

func _on_dusk() -> void:
	_show_warning("黄昏降临！\n怪物正在变强", 6.0, UITheme.VOID)

func _on_night() -> void:
	_show_warning("黑夜降临！\n怪物全属性提升", 5.0, UITheme.DANGER)

func _on_day() -> void:
	_show_toast("天亮了，怪物恢复了常态")

func _show_warning(text: String, duration: float, color: Color) -> void:
	_warning_label.text = text
	_warning_label.add_theme_color_override("font_color", color)
	_warning_label.visible = true
	_warning_timer = duration

func _on_player_died() -> void:
	_death_overlay.visible = true
	if _any_panel_open():
		_close_all_panels()
	_warning_label.visible = false
	_toast_label.visible = false

# ---------------------------------------------------------------- 小地图

class Minimap extends Control:
	const RADIUS: float = 178.0
	const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_process(true)

	func _process(_delta: float) -> void:
		queue_redraw()

	func _map_point(world: Vector2) -> Vector2:
		var rect := GameManager.get_world_rect()
		if rect.size.x <= 0.0 or rect.size.y <= 0.0:
			return size * 0.5
		var normalized := (world - rect.position) / rect.size
		var center := size * 0.5
		var point := center + (normalized * 2.0 - Vector2.ONE) * (RADIUS - 24.0)
		var offset := point - center
		var limit := RADIUS - 26.0
		if offset.length() > limit:
			point = center + offset.normalized() * limit
		return point

	func _draw() -> void:
		var center := size * 0.5
		draw_circle(center, RADIUS, Color(0.035, 0.03, 0.05, 0.92))
		draw_circle(center, RADIUS - 8.0, Color(0.055, 0.047, 0.07, 0.85))
		draw_arc(center, RADIUS, 0, TAU, 80, UITheme.BORDER, 7.0)
		draw_arc(center, RADIUS - 5.0, 0, TAU, 80, UITheme.BORDER_LIGHT, 2.0)
		# 十字路网
		draw_line(center + Vector2(-RADIUS + 20, 0), center + Vector2(RADIUS - 20, 0), Color(0.25, 0.22, 0.3, 0.35), 2.0)
		draw_line(center + Vector2(0, -RADIUS + 20), center + Vector2(0, RADIUS - 20), Color(0.25, 0.22, 0.3, 0.35), 2.0)
		draw_string(FONT, center + Vector2(-5, -RADIUS + 26), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UITheme.MUTED)

		for npc in get_tree().get_nodes_in_group("npc"):
			_draw_dot(_map_point(npc.global_position), Color(0.35, 0.65, 1.0), 4.5)
		for chest in get_tree().get_nodes_in_group("chest"):
			_draw_dot(_map_point(chest.global_position), Color(0.95, 0.78, 0.3), 4.5)
		for portal in get_tree().get_nodes_in_group("portal"):
			_draw_dot(_map_point(portal.global_position), Color(0.45, 0.85, 1.0), 6.0)
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.get("dead") == true:
				continue
			if enemy.get("is_boss") == true:
				_draw_dot(_map_point(enemy.global_position), Color(0.75, 0.35, 1.0), 9.0)
			elif enemy.get("is_elite") == true:
				_draw_dot(_map_point(enemy.global_position), Color(0.8, 0.4, 1.0), 4.0)
			else:
				_draw_dot(_map_point(enemy.global_position), Color(0.85, 0.22, 0.24), 3.0)
		var player := get_tree().get_first_node_in_group("player")
		if player != null and is_instance_valid(player):
			var p := _map_point(player.global_position)
			var angle: float = player.facing.angle()
			var points := PackedVector2Array([
				p + Vector2(0, -9).rotated(angle),
				p + Vector2(-6, 7).rotated(angle),
				p + Vector2(6, 7).rotated(angle)
			])
			draw_colored_polygon(points, Color(0.35, 0.95, 0.5))
			draw_arc(p, 10.0, 0, TAU, 16, Color(0.35, 0.95, 0.5, 0.35), 2.0)

	func _draw_dot(pos: Vector2, color: Color, radius: float) -> void:
		draw_circle(pos, radius + 1.5, UITheme.BORDER)
		draw_circle(pos, radius, color)
