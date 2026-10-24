extends Control
## ESC 暂停菜单：继续 / 返回树屋 / 设置 / 返回主菜单。

signal closed

var _main_buttons: Control
var _settings_panel: Panel
var _hub_button: Button

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.66)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.BORDER_LIGHT, 4)
	panel.position = Vector2(700, 250)
	panel.size = Vector2(520, 580)
	add_child(panel)

	var title := UITheme.make_title("暂停", 44)
	title.position = Vector2(34, 20)
	panel.add_child(title)

	var hint := UITheme.make_label("ESC 继续游戏", 16, UITheme.MUTED)
	hint.position = Vector2(34, 74)
	panel.add_child(hint)

	_main_buttons = Control.new()
	_main_buttons.position = Vector2.ZERO
	_main_buttons.size = Vector2(520, 580)
	_main_buttons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(_main_buttons)

	var resume := UITheme.make_button("继续游戏", 26, UITheme.GOLD)
	resume.position = Vector2(100, 120)
	resume.size = Vector2(320, 62)
	resume.pressed.connect(close)
	_main_buttons.add_child(resume)

	_hub_button = UITheme.make_button("返回树屋（主城）", 24, UITheme.GOLD)
	_hub_button.position = Vector2(100, 202)
	_hub_button.size = Vector2(320, 62)
	_hub_button.pressed.connect(_on_return_hub)
	_main_buttons.add_child(_hub_button)

	var settings_btn := UITheme.make_button("设置", 24, UITheme.SANITY)
	settings_btn.position = Vector2(100, 284)
	settings_btn.size = Vector2(320, 62)
	settings_btn.pressed.connect(_open_settings)
	_main_buttons.add_child(settings_btn)

	var menu_btn := UITheme.make_button("返回主菜单", 24, UITheme.DANGER)
	menu_btn.position = Vector2(100, 366)
	menu_btn.size = Vector2(320, 62)
	menu_btn.pressed.connect(_on_return_menu)
	_main_buttons.add_child(menu_btn)

	var note := UITheme.make_label("原型边界：不做联机、不做赛季、不做 4 职业。", 15, UITheme.MUTED)
	note.position = Vector2(100, 456)
	note.size = Vector2(340, 50)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_main_buttons.add_child(note)

	_settings_panel = UITheme.make_panel(UITheme.PANEL_BG_SOFT, UITheme.BORDER_LIGHT, 3)
	_settings_panel.position = Vector2(30, 104)
	_settings_panel.size = Vector2(460, 420)
	_settings_panel.visible = false
	panel.add_child(_settings_panel)
	var st := UITheme.make_label("设置", 28, UITheme.GOLD)
	st.position = Vector2(20, 12)
	_settings_panel.add_child(st)

	var vol_label := UITheme.make_label("主音量", 18, UITheme.TEXT)
	vol_label.position = Vector2(20, 62)
	_settings_panel.add_child(vol_label)
	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.step = 1
	slider.value = 80
	slider.position = Vector2(20, 94)
	slider.size = Vector2(350, 30)
	slider.value_changed.connect(_on_volume_changed)
	_settings_panel.add_child(slider)

	var keys_title := UITheme.make_label("键位", 18, UITheme.GOLD)
	keys_title.position = Vector2(20, 136)
	_settings_panel.add_child(keys_title)
	var keys := UITheme.make_label(
		"WASD 移动   左键 攻击\nSpace 翻滚   Q 燃烧瓶   F 捕兽夹\n1 生命药水   2 理智药水   E 交互\nB 背包   M 魔方   T 回城   ESC 暂停\n\n说明：原作键位表中 W 同时用于前进与技能，\n原型将捕兽夹改到 F，避免移动冲突。",
		15, UITheme.MUTED
	)
	keys.position = Vector2(20, 170)
	keys.size = Vector2(420, 190)
	keys.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_settings_panel.add_child(keys)

	var back := UITheme.make_button("返回", 20, UITheme.GOLD)
	back.position = Vector2(20, 360)
	back.size = Vector2(140, 46)
	back.pressed.connect(_close_settings)
	_settings_panel.add_child(back)

func open() -> void:
	visible = true
	_main_buttons.visible = true
	_settings_panel.visible = false
	_hub_button.disabled = GameManager.current_area == "hub"

func close() -> void:
	if not visible:
		return
	visible = false
	closed.emit()

func _open_settings() -> void:
	_main_buttons.visible = false
	_settings_panel.visible = true

func _close_settings() -> void:
	_settings_panel.visible = false
	_main_buttons.visible = true

func _on_volume_changed(value: float) -> void:
	var bus := AudioServer.get_bus_index("Master")
	if value <= 0.0:
		AudioServer.set_bus_mute(bus, true)
	else:
		AudioServer.set_bus_mute(bus, false)
		AudioServer.set_bus_volume_db(bus, linear_to_db(value / 100.0))

func _on_return_hub() -> void:
	visible = false
	GameManager.go_to_hub()

func _on_return_menu() -> void:
	visible = false
	GameManager.go_to_main_menu()
