extends Control
## 主菜单：开始新游戏 / 继续 / 操作说明 / 退出。

const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

var _continue_button: Button
var _help_panel: Panel
var _time: float = 0.0

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	_build()
	set_process(true)

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _build() -> void:
	var title := UITheme.make_title("灾墟树屋", 92, UITheme.GOLD)
	title.position = Vector2(150, 210)
	title.size = Vector2(1000, 120)
	add_child(title)

	var subtitle := UITheme.make_label("《地球上最后的孩子》 · 2D 俯视角 ARPG 垂直切片原型", 26, UITheme.TEXT)
	subtitle.position = Vector2(156, 330)
	subtitle.size = Vector2(1100, 40)
	add_child(subtitle)

	var tagline := UITheme.make_label(
		"杰克 · 裂隙猎手  |  城郊居民区  |  藤蔓母怪  |  拾荒魔方  |  黄昏与黑夜",
		18, UITheme.MUTED
	)
	tagline.position = Vector2(158, 372)
	tagline.size = Vector2(1100, 28)
	add_child(tagline)

	var start := UITheme.make_button("开始新游戏", 28, UITheme.GOLD)
	start.position = Vector2(160, 470)
	start.size = Vector2(380, 68)
	start.pressed.connect(_on_start)
	add_child(start)

	_continue_button = UITheme.make_button("继续游戏", 26, UITheme.SANITY)
	_continue_button.position = Vector2(160, 556)
	_continue_button.size = Vector2(380, 62)
	_continue_button.disabled = GameManager.player_state.is_empty()
	_continue_button.pressed.connect(_on_continue)
	add_child(_continue_button)

	var help := UITheme.make_button("操作说明", 24, UITheme.VOID)
	help.position = Vector2(160, 634)
	help.size = Vector2(380, 58)
	help.pressed.connect(_open_help)
	add_child(help)

	var quit := UITheme.make_button("退出游戏", 24, UITheme.DANGER)
	quit.position = Vector2(160, 708)
	quit.size = Vector2(380, 58)
	quit.pressed.connect(func() -> void: get_tree().quit())
	add_child(quit)

	var note := UITheme.make_label(
		"原型边界：不做联机、不做赛季、不做 4 职业、不做全部四幕。\n目标：先跑通 战斗 → 拾取 → 合成 → Boss 战 闭环。",
		16, UITheme.MUTED
	)
	note.position = Vector2(160, 800)
	note.size = Vector2(760, 60)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	add_child(note)

	_help_panel = _build_help_panel()
	_help_panel.visible = false
	add_child(_help_panel)

func _build_help_panel() -> Panel:
	var panel := UITheme.make_panel(UITheme.PANEL_BG, UITheme.BORDER_LIGHT, 4)
	panel.position = Vector2(1050, 190)
	panel.size = Vector2(700, 480)

	var title := UITheme.make_title("操作说明", 32)
	title.position = Vector2(28, 18)
	panel.add_child(title)

	var text := UITheme.make_label(
		"WASD / 方向键   移动\nSpace   翻滚（无敌 0.4s，CD 4s）\n鼠标左键   近战挥击（钉棒球棍）\nQ   燃烧瓶投掷\nF   捕兽夹（原键位 W 与前进冲突，改为 F）\n1 / 2   快速使用生命 / 理智药水\nE   与 NPC、箱子、传送门交互\nB   背包与角色面板\nM   拾荒魔方合成\nT   战斗中返回树屋\nESC   暂停菜单\n\n白天 75 秒 → 黄昏预警 10 秒 → 黑夜 35 秒",
		18, UITheme.TEXT
	)
	text.position = Vector2(30, 74)
	text.size = Vector2(640, 340)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	panel.add_child(text)

	var close := UITheme.make_button("知道了", 20, UITheme.GOLD)
	close.position = Vector2(260, 410)
	close.size = Vector2(180, 48)
	close.pressed.connect(func() -> void: _help_panel.visible = false)
	panel.add_child(close)
	return panel

func _open_help() -> void:
	_help_panel.visible = true

func _on_start() -> void:
	GameManager.start_new_game()

func _on_continue() -> void:
	GameManager.go_to_hub()

func _draw() -> void:
	var w := size.x
	var h := size.y
	# 夜色渐变底层
	draw_rect(Rect2(0, 0, w, h), Color(0.035, 0.03, 0.048))
	draw_rect(Rect2(0, h * 0.42, w, h * 0.58), Color(0.055, 0.04, 0.07))
	draw_circle(Vector2(w * 0.73, h * 0.34), 320, Color(0.28, 0.12, 0.42, 0.16))
	draw_circle(Vector2(w * 0.73, h * 0.34), 190, Color(0.45, 0.2, 0.7, 0.1))

	# 远处裂隙裂纹
	for i in range(7):
		var angle := -0.9 + i * 0.26
		var origin := Vector2(w * 0.76, h * 0.30)
		var mid := origin + Vector2(cos(angle), sin(angle)) * (120.0 + i * 16.0)
		var end := mid + Vector2(cos(angle + 0.5), sin(angle + 0.5)) * (90.0 + sin(_time + i) * 14.0)
		draw_line(origin, mid, Color(0.55, 0.3, 0.85, 0.55), 4.0)
		draw_line(mid, end, Color(0.42, 0.2, 0.66, 0.4), 2.0)

	# 树屋剪影
	var base := Vector2(w * 0.77, h * 0.80)
	draw_rect(Rect2(base.x - 120, base.y - 40, 250, 150), Color(0.09, 0.075, 0.06))
	draw_rect(Rect2(base.x - 90, base.y - 130, 200, 100), Color(0.11, 0.09, 0.07))
	draw_rect(Rect2(base.x - 90, base.y - 130, 200, 100), Color(0.24, 0.19, 0.12), false, 3.0)
	draw_rect(Rect2(base.x - 120, base.y - 40, 250, 150), Color(0.24, 0.19, 0.12), false, 3.0)
	# 树冠
	draw_circle(Vector2(base.x - 20, base.y - 190), 130, Color(0.07, 0.12, 0.07))
	draw_circle(Vector2(base.x - 110, base.y - 150), 90, Color(0.06, 0.1, 0.06))
	draw_circle(Vector2(base.x + 90, base.y - 140), 86, Color(0.08, 0.13, 0.07))
	# 暖灯
	for i in range(4):
		var lamp := Vector2(base.x - 70 + i * 58, base.y - 92)
		draw_circle(lamp, 16, Color(1.0, 0.78, 0.32, 0.12))
		draw_circle(lamp, 5, Color(1.0, 0.82, 0.42))
	draw_string(FONT, Vector2(base.x - 120, base.y + 140), "树屋：唯一安全区", HORIZONTAL_ALIGNMENT_CENTER, 250, 17, UITheme.MUTED)
