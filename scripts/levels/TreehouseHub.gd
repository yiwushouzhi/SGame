extends Node2D
## 树屋主城：无战斗安全区。昆特魔方台、补给箱、任务看板、出发传送门。

const JACK_SCENE := preload("res://scenes/player/Jack.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const NPC_SCRIPT := preload("res://scripts/props/npc.gd")
const CHEST_SCRIPT := preload("res://scripts/props/chest.gd")
const PORTAL_SCRIPT := preload("res://scripts/props/portal.gd")
const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

const WORLD := Rect2(0, 0, 1920, 1080)
const SPAWN_POINT := Vector2(960, 700)

var player: Node = null

func _ready() -> void:
	GameManager.register_area("hub")
	_build_bounds()
	_spawn_player()
	add_child(HUD_SCENE.instantiate())
	_spawn_props()
	queue_redraw()
	if GameManager.quest_stage >= 1:
		GameManager.show_toast("主线已完成：藤蔓母怪已被击败")
	else:
		GameManager.show_toast("树屋安全区：找昆特合成，准备好就出发")

func _build_bounds() -> void:
	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	add_child(body)
	var walls: Array[Rect2] = [
		Rect2(WORLD.position.x - 40, WORLD.position.y - 40, WORLD.size.x + 80, 40),
		Rect2(WORLD.position.x - 40, WORLD.end.y, WORLD.size.x + 80, 40),
		Rect2(WORLD.position.x - 40, WORLD.position.y, 40, WORLD.size.y),
		Rect2(WORLD.end.x, WORLD.position.y, 40, WORLD.size.y),
	]
	for wall in walls:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = wall.size
		shape.shape = rect
		shape.position = wall.position + wall.size * 0.5
		body.add_child(shape)

func _spawn_player() -> void:
	player = JACK_SCENE.instantiate()
	player.position = SPAWN_POINT
	add_child(player)
	player.setup_camera(WORLD)

func _spawn_props() -> void:
	var quint := Node2D.new()
	quint.set_script(NPC_SCRIPT)
	quint.position = Vector2(620, 560)
	quint.set("npc_name", "昆特")
	quint.set("npc_kind", "quint")
	quint.set("prompt_text", "与昆特交谈，打开拾荒魔方")
	add_child(quint)

	var board := Node2D.new()
	board.set_script(NPC_SCRIPT)
	board.position = Vector2(1250, 540)
	board.set("npc_name", "任务看板")
	board.set("npc_kind", "board")
	board.set("prompt_text", "查看主线任务")
	add_child(board)

	var supply := Node2D.new()
	supply.set_script(CHEST_SCRIPT)
	supply.position = Vector2(790, 770)
	supply.set("chest_name", "补给箱")
	supply.set("free_supply", true)
	add_child(supply)

	var portal := Node2D.new()
	portal.set_script(PORTAL_SCRIPT)
	portal.position = Vector2(1520, 760)
	portal.set("target_area", "suburb")
	add_child(portal)

func _draw() -> void:
	# 森林地面
	draw_rect(Rect2(Vector2.ZERO, WORLD.size), Color(0.068, 0.088, 0.07))
	for i in range(46):
		var x := fmod(float(i) * 271.0 + 40.0, 1920.0)
		var y := fmod(float(i) * 457.0 + 30.0, 1080.0)
		draw_circle(Vector2(x, y), 22.0 + float(i % 5) * 9.0, Color(0.082, 0.108, 0.082, 0.75))

	# 远处虚空裂隙
	draw_circle(Vector2(170, 180), 130, Color(0.26, 0.12, 0.42, 0.18))
	for i in range(6):
		var angle := -0.6 + float(i) * 0.24
		var start := Vector2(170, 180)
		var end := start + Vector2(cos(angle), sin(angle)) * (70.0 + float(i) * 18.0)
		draw_line(start, end, Color(0.55, 0.3, 0.85, 0.5), 3.0)

	# 平台
	draw_rect(Rect2(430, 420, 1060, 430), Color(0.32, 0.235, 0.155))
	draw_rect(Rect2(430, 420, 1060, 430), Color(0.14, 0.1, 0.07), false, 6.0)
	for i in range(12):
		var x := 430.0 + float(i) * 88.0
		draw_line(Vector2(x, 420), Vector2(x, 850), Color(0.21, 0.15, 0.1), 2.0)
	for i in range(5):
		var y := 420.0 + float(i) * 86.0
		draw_line(Vector2(430, y), Vector2(1490, y), Color(0.22, 0.16, 0.105), 1.5)

	# 树屋小屋
	draw_rect(Rect2(560, 300, 330, 190), Color(0.26, 0.19, 0.12))
	draw_rect(Rect2(560, 300, 330, 190), Color(0.12, 0.09, 0.06), false, 5.0)
	var roof := PackedVector2Array([
		Vector2(520, 310), Vector2(725, 210), Vector2(930, 310)
	])
	draw_colored_polygon(roof, Color(0.19, 0.13, 0.08))
	draw_polyline(roof, Color(0.1, 0.07, 0.05), 5.0)
	draw_rect(Rect2(660, 380, 80, 110), Color(0.12, 0.08, 0.06))
	draw_rect(Rect2(600, 340, 60, 50), Color(1.0, 0.78, 0.35, 0.8))
	draw_rect(Rect2(790, 340, 60, 50), Color(1.0, 0.78, 0.35, 0.8))

	# 巨树与树冠
	draw_rect(Rect2(1400, 170, 100, 420), Color(0.18, 0.13, 0.08))
	draw_circle(Vector2(1450, 130), 190, Color(0.07, 0.13, 0.07))
	draw_circle(Vector2(1300, 200), 140, Color(0.06, 0.115, 0.065))
	draw_circle(Vector2(1600, 210), 150, Color(0.078, 0.135, 0.072))

	# 涂鸦墙
	draw_rect(Rect2(1360, 560, 200, 170), Color(0.2, 0.16, 0.1))
	draw_rect(Rect2(1360, 560, 200, 170), Color(0.1, 0.08, 0.055), false, 4.0)
	var tags := [Color(0.85, 0.35, 0.35), Color(0.4, 0.75, 0.55), Color(0.55, 0.45, 0.95)]
	for i in range(3):
		draw_line(Vector2(1378, 590 + i * 30), Vector2(1500 + i * 14, 610 + i * 30), tags[i], 5.0)
		draw_line(Vector2(1378, 620 + i * 24), Vector2(1460, 600 + i * 24), tags[i], 3.0)

	# 路障
	for i in range(4):
		var x := 470.0 + float(i) * 34.0
		draw_line(Vector2(x, 860), Vector2(x + 22, 800), Color(0.3, 0.22, 0.13), 9.0)
	draw_rect(Rect2(455, 786, 150, 24), Color(0.38, 0.28, 0.16))
	draw_rect(Rect2(455, 786, 150, 24), Color(0.14, 0.1, 0.06), false, 3.0)

	# 自制投石机
	draw_line(Vector2(1140, 740), Vector2(1200, 650), Color(0.3, 0.22, 0.14), 10.0)
	draw_line(Vector2(1200, 650), Vector2(1280, 620), Color(0.3, 0.22, 0.14), 8.0)
	draw_circle(Vector2(1280, 620), 16, Color(0.25, 0.2, 0.15))
	draw_line(Vector2(1140, 740), Vector2(1080, 748), Color(0.26, 0.2, 0.13), 8.0)

	# 暖灯与串灯
	for i in range(5):
		var lamp := Vector2(520 + i * 220, 450)
		draw_circle(lamp, 26, Color(1.0, 0.76, 0.32, 0.1))
		draw_circle(lamp, 7, Color(1.0, 0.82, 0.45))
		draw_line(Vector2(lamp.x, 420), Vector2(lamp.x, 444), Color(0.15, 0.11, 0.07), 2.0)
	for i in range(13):
		var x := 500.0 + float(i) * 78.0
		draw_circle(Vector2(x, 850.0 - sin(float(i) * 0.7) * 10.0), 4.0, Color(1.0, 0.85, 0.5, 0.75))

	draw_string(FONT, Vector2(560, 972), "树屋主城 · 安全区", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UITheme.GOLD)
	draw_string(FONT, Vector2(560, 1004), "昆特：拾荒魔方   补给箱：免费药水   看板：主线任务", HORIZONTAL_ALIGNMENT_LEFT, -1, 17, UITheme.MUTED)
