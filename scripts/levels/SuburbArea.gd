extends Node2D
## 城郊居民区：原型唯一战斗地图（3200×2000）。
## 刷怪、宝箱、返回传送门、北侧裂隙 Boss 区。

const JACK_SCENE := preload("res://scenes/player/Jack.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const ZOMBIE_SCENE := preload("res://scenes/enemies/Zombie.tscn")
const WRETCH_SCENE := preload("res://scenes/enemies/WingedWretch.tscn")
const BOSS_SCENE := preload("res://scenes/enemies/VineMatriarch.tscn")
const CHEST_SCRIPT := preload("res://scripts/props/chest.gd")
const PORTAL_SCRIPT := preload("res://scripts/props/portal.gd")
const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

const WORLD := Rect2(0, 0, 3200, 2000)
const SPAWN_POINT := Vector2(430, 1620)
const BOSS_POINT := Vector2(1500, 380)

var player: Node = null
var _night_elite_added: bool = false

func _ready() -> void:
	GameManager.register_area("suburb")
	_build_bounds()
	_spawn_player()
	add_child(HUD_SCENE.instantiate())
	_spawn_enemies()
	_spawn_chests()
	_spawn_portal()
	DayNightManager.night_started.connect(_on_night_started)
	queue_redraw()
	GameManager.show_toast("抵达城郊居民区：沿主路向北，深入紫色裂隙")

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

func _spawn_enemy(scene: PackedScene, pos: Vector2, elite: bool = false) -> void:
	var enemy := scene.instantiate()
	if elite:
		enemy.set("is_elite", true)
	enemy.position = pos
	add_child(enemy)

func _spawn_enemies() -> void:
	# 普通僵尸
	var zombie_points: Array[Vector2] = [
		Vector2(760, 1380), Vector2(980, 1500), Vector2(1180, 1300), Vector2(1330, 1600),
		Vector2(900, 1060), Vector2(1720, 1460), Vector2(2050, 1560), Vector2(2350, 1260),
		Vector2(2600, 1650), Vector2(620, 860), Vector2(2200, 820), Vector2(2650, 520),
		Vector2(1880, 1150), Vector2(1400, 1760),
	]
	for pos in zombie_points:
		_spawn_enemy(ZOMBIE_SCENE, pos)
	# 精英僵尸
	_spawn_enemy(ZOMBIE_SCENE, Vector2(1900, 950), true)
	_spawn_enemy(ZOMBIE_SCENE, Vector2(2750, 1400), true)
	_spawn_enemy(ZOMBIE_SCENE, Vector2(1180, 620), true)
	# 飞戾怪
	var wretch_points: Array[Vector2] = [
		Vector2(1250, 980), Vector2(2050, 1150), Vector2(2450, 760), Vector2(1750, 1520),
	]
	for pos in wretch_points:
		_spawn_enemy(WRETCH_SCENE, pos)
	# Boss（已击败则不重复刷新）
	if not GameManager.boss_defeated:
		var boss := BOSS_SCENE.instantiate()
		boss.position = BOSS_POINT
		add_child(boss)

func _spawn_chests() -> void:
	var points: Array[Vector2] = [
		Vector2(780, 1500), Vector2(2350, 980), Vector2(1750, 660),
	]
	for pos in points:
		var chest := Node2D.new()
		chest.set_script(CHEST_SCRIPT)
		chest.position = pos
		chest.set("chest_name", "废弃箱子")
		add_child(chest)

func _spawn_portal() -> void:
	var portal := Node2D.new()
	portal.set_script(PORTAL_SCRIPT)
	portal.position = Vector2(260, 1720)
	portal.set("target_area", "hub")
	add_child(portal)

func _on_night_started() -> void:
	if _night_elite_added:
		return
	_night_elite_added = true
	_spawn_enemy(ZOMBIE_SCENE, Vector2(1290, 560), true)
	_spawn_enemy(ZOMBIE_SCENE, Vector2(1710, 560), true)
	GameManager.show_toast("黑夜中，裂隙精英苏醒了")

# ---------------------------------------------------------------- 地图绘制

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD.size), Color(0.105, 0.128, 0.095))

	# 草坪地块
	var lots: Array[Rect2] = [
		Rect2(40, 40, 430, 360), Rect2(500, 50, 380, 330), Rect2(910, 70, 390, 320),
		Rect2(2080, 60, 470, 350), Rect2(2620, 80, 470, 340),
		Rect2(70, 620, 470, 400), Rect2(650, 600, 460, 380), Rect2(1780, 680, 440, 380),
		Rect2(2320, 640, 600, 420), Rect2(100, 1700, 600, 240), Rect2(1900, 1700, 940, 220),
	]
	for lot in lots:
		draw_rect(lot, Color(0.137, 0.17, 0.115))
		draw_rect(lot, Color(0.18, 0.22, 0.145), false, 2.0)

	# 道路（横向主路 + 纵向支路）
	draw_rect(Rect2(0, 1320, 3200, 220), Color(0.155, 0.155, 0.165))
	draw_rect(Rect2(1400, 470, 180, 1530), Color(0.148, 0.148, 0.158))
	draw_line(Vector2(0, 1320), Vector2(3200, 1320), Color(0.42, 0.38, 0.3, 0.5), 3.0)
	draw_line(Vector2(0, 1540), Vector2(3200, 1540), Color(0.42, 0.38, 0.3, 0.5), 3.0)
	draw_line(Vector2(1400, 470), Vector2(1400, 2000), Color(0.42, 0.38, 0.3, 0.5), 3.0)
	draw_line(Vector2(1580, 470), Vector2(1580, 2000), Color(0.42, 0.38, 0.3, 0.5), 3.0)
	for x in range(40, 3160, 120):
		draw_rect(Rect2(x, 1424, 58, 10), Color(0.62, 0.57, 0.32, 0.5))
	for y in range(520, 1960, 120):
		draw_rect(Rect2(1484, y, 10, 58), Color(0.62, 0.57, 0.32, 0.5))
	# 路面裂纹
	for i in range(30):
		var cx := 120.0 + fmod(float(i) * 397.0, 2900.0)
		var cy := 160.0 + fmod(float(i) * 613.0, 1680.0)
		draw_line(Vector2(cx, cy), Vector2(cx + 20.0, cy + 10.0), Color(0.05, 0.05, 0.05, 0.32), 2.0)

	# 废弃住宅
	_draw_house(Vector2(60, 90), Vector2(330, 200), Color(0.25, 0.17, 0.13))
	_draw_house(Vector2(520, 100), Vector2(300, 180), Color(0.19, 0.2, 0.22))
	_draw_house(Vector2(930, 110), Vector2(320, 190), Color(0.24, 0.2, 0.15))
	_draw_house(Vector2(2100, 110), Vector2(390, 210), Color(0.21, 0.16, 0.14))
	_draw_house(Vector2(2640, 120), Vector2(400, 200), Color(0.18, 0.19, 0.21))
	_draw_house(Vector2(90, 680), Vector2(330, 210), Color(0.22, 0.18, 0.15))
	_draw_house(Vector2(2350, 700), Vector2(420, 220), Color(0.2, 0.17, 0.16))

	# 断掉的围栏
	draw_line(Vector2(360, 560), Vector2(900, 560), Color(0.26, 0.21, 0.14), 5.0)
	for i in range(10):
		draw_line(Vector2(380 + i * 54, 540), Vector2(380 + i * 54, 580), Color(0.28, 0.22, 0.15), 4.0)
	draw_line(Vector2(1860, 610), Vector2(2380, 610), Color(0.26, 0.21, 0.14), 5.0)
	for i in range(9):
		draw_line(Vector2(1880 + i * 56, 590), Vector2(1880 + i * 56, 630), Color(0.28, 0.22, 0.15), 4.0)

	# 废弃汽车
	_draw_car(Vector2(220, 1380))
	_draw_car(Vector2(1080, 1460))
	_draw_car(Vector2(2280, 1450))
	_draw_car(Vector2(2900, 1370))

	# 死树
	_draw_dead_tree(Vector2(640, 560), 120.0)
	_draw_dead_tree(Vector2(1780, 560), 140.0)
	_draw_dead_tree(Vector2(2560, 1520), 110.0)
	_draw_dead_tree(Vector2(330, 1180), 100.0)
	_draw_dead_tree(Vector2(2140, 1720), 130.0)
	_draw_dead_tree(Vector2(2900, 900), 150.0)

	# 空操场
	draw_rect(Rect2(660, 860, 340, 280), Color(0.16, 0.145, 0.12))
	draw_rect(Rect2(660, 860, 340, 280), Color(0.24, 0.21, 0.16), false, 3.0)
	draw_line(Vector2(700, 880), Vector2(700, 1080), Color(0.3, 0.24, 0.15), 6.0)
	draw_line(Vector2(940, 880), Vector2(940, 1080), Color(0.3, 0.24, 0.15), 6.0)
	draw_line(Vector2(700, 880), Vector2(940, 880), Color(0.3, 0.24, 0.15), 6.0)
	draw_line(Vector2(760, 880), Vector2(760, 980), Color(0.22, 0.2, 0.18), 2.0)
	draw_line(Vector2(880, 880), Vector2(880, 980), Color(0.22, 0.2, 0.18), 2.0)
	draw_rect(Rect2(748, 978, 24, 8), Color(0.3, 0.26, 0.2))
	draw_rect(Rect2(868, 978, 24, 8), Color(0.3, 0.26, 0.2))
	# 滑梯
	draw_line(Vector2(880, 1040), Vector2(960, 1120), Color(0.35, 0.26, 0.16), 8.0)
	draw_line(Vector2(960, 1120), Vector2(1000, 1116), Color(0.35, 0.26, 0.16), 8.0)

	# 碎石堆
	_draw_rubble(Vector2(1180, 1180))
	_draw_rubble(Vector2(1960, 900))
	_draw_rubble(Vector2(2460, 1780))
	_draw_rubble(Vector2(1520, 1760))
	_draw_rubble(Vector2(860, 1180))

	# 北侧裂隙（Boss 区）
	draw_circle(BOSS_POINT, 200.0, Color(0.28, 0.12, 0.44, 0.16))
	draw_circle(BOSS_POINT, 120.0, Color(0.4, 0.18, 0.6, 0.18))
	draw_arc(BOSS_POINT, 240.0, 0, TAU, 64, Color(0.55, 0.3, 0.85, 0.35), 5.0)
	for i in range(11):
		var angle := TAU * float(i) / 11.0 + 0.2
		var mid := BOSS_POINT + Vector2(cos(angle), sin(angle)) * (70.0 + float(i % 3) * 26.0)
		var end := BOSS_POINT + Vector2(cos(angle + 0.24), sin(angle + 0.24)) * (150.0 + float(i % 4) * 26.0)
		draw_line(BOSS_POINT, mid, Color(0.55, 0.28, 0.9, 0.5), 4.0)
		draw_line(mid, end, Color(0.4, 0.18, 0.66, 0.4), 2.5)

	# 地图文字标注
	draw_string(FONT, Vector2(1040, 1276), "↑  北侧裂隙 · 藤蔓母怪", HORIZONTAL_ALIGNMENT_LEFT, -1, 22, UITheme.VOID)
	draw_string(FONT, Vector2(180, 1650), "←  返回树屋", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, UITheme.MUTED)
	draw_string(FONT, Vector2(2360, 640), "城郊居民区", HORIZONTAL_ALIGNMENT_LEFT, -1, 26, UITheme.MUTED)

func _draw_house(origin: Vector2, house_size: Vector2, roof_color: Color) -> void:
	var body := Rect2(origin, house_size)
	draw_rect(Rect2(origin + Vector2(8, 10), house_size), Color(0, 0, 0, 0.3))
	draw_rect(body, Color(0.16, 0.15, 0.14))
	draw_rect(body, Color(0.09, 0.085, 0.08), false, 3.0)
	var roof := PackedVector2Array([
		origin + Vector2(-16, 2),
		origin + Vector2(house_size.x * 0.5, -house_size.y * 0.5),
		origin + Vector2(house_size.x + 16, 2),
	])
	draw_colored_polygon(roof, roof_color)
	draw_polyline(roof, Color(0.09, 0.08, 0.075), 4.0)
	# 破洞与暗窗
	draw_rect(Rect2(origin.x + house_size.x * 0.55, origin.y + 18, house_size.x * 0.22, 24), Color(0.05, 0.045, 0.055))
	for i in range(3):
		var wx := origin.x + 26.0 + float(i) * (house_size.x * 0.28)
		var wy := origin.y + house_size.y * 0.44
		draw_rect(Rect2(wx, wy, 26, 26), Color(0.09, 0.07, 0.11))
		draw_rect(Rect2(wx, wy, 26, 26), Color(0.5, 0.32, 0.62, 0.3), false, 2.0)
	# 门
	draw_rect(Rect2(origin.x + house_size.x * 0.12, origin.y + house_size.y - 58, 44, 58), Color(0.1, 0.08, 0.07))

func _draw_car(pos: Vector2) -> void:
	draw_rect(Rect2(pos.x - 36, pos.y - 18, 72, 36), Color(0.21, 0.23, 0.25))
	draw_rect(Rect2(pos.x - 20, pos.y - 14, 40, 22), Color(0.1, 0.12, 0.13))
	draw_rect(Rect2(pos.x - 36, pos.y - 18, 72, 36), Color(0.1, 0.1, 0.11), false, 3.0)
	draw_circle(pos + Vector2(-20, 20), 7, Color(0.05, 0.05, 0.06))
	draw_circle(pos + Vector2(20, 20), 7, Color(0.05, 0.05, 0.06))
	draw_line(pos + Vector2(-10, -14), pos + Vector2(12, 8), Color(0.35, 0.32, 0.3), 2.0)

func _draw_dead_tree(pos: Vector2, height: float) -> void:
	draw_circle(pos + Vector2(0, 6), 18, Color(0, 0, 0, 0.3))
	draw_line(pos, pos + Vector2(0, -height), Color(0.17, 0.13, 0.09), 10.0)
	draw_line(pos + Vector2(0, -height * 0.6), pos + Vector2(-40, -height * 0.86), Color(0.17, 0.13, 0.09), 6.0)
	draw_line(pos + Vector2(0, -height * 0.72), pos + Vector2(36, -height * 0.94), Color(0.17, 0.13, 0.09), 5.0)
	draw_line(pos + Vector2(0, -height * 0.45), pos + Vector2(28, -height * 0.5), Color(0.17, 0.13, 0.09), 4.0)

func _draw_rubble(pos: Vector2) -> void:
	draw_circle(pos + Vector2(0, 8), 26, Color(0, 0, 0, 0.22))
	draw_circle(pos + Vector2(-10, 0), 12, Color(0.26, 0.25, 0.24))
	draw_circle(pos + Vector2(8, -4), 9, Color(0.31, 0.29, 0.27))
	draw_rect(Rect2(pos.x - 26, pos.y + 4, 40, 10), Color(0.2, 0.19, 0.19))
	draw_line(pos + Vector2(-18, -6), pos + Vector2(2, 4), Color(0.12, 0.11, 0.11), 3.0)
