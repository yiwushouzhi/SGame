extends BaseEnemy
## 藤蔓母怪（原型一幕 Boss，固定 Lv5）：藤蔓缠绕 / 刺藤喷射 / 召唤小藤蔓。

const BIND_ZONE_SCRIPT := preload("res://scripts/skill/vine_bind_zone.gd")
const THORN_LINE_SCRIPT := preload("res://scripts/skill/thorn_line.gd")
const VINE_SPAWN_SCENE := preload("res://scenes/enemies/VineSpawn.tscn")

var skills: Dictionary = {}
var activated: bool = false

var bind_cd: float = 3.0
var thorn_cd: float = 7.0
var summon_cd: float = 12.0

var _anim: float = 0.0

func _ready() -> void:
	enemy_type = "vine_matriarch"
	is_boss = true
	dormant = true
	super._ready()
	var data: Dictionary = GameManager.enemy_db.get(enemy_type, {})
	skills = data.get("skills", {})
	bind_cd = 3.0
	thorn_cd = 7.0
	summon_cd = 12.0

func _physics_process(delta: float) -> void:
	_anim += delta
	hit_flash = max(0.0, hit_flash - delta)
	root_timer = max(0.0, root_timer - delta)
	queue_redraw()
	if dead:
		return

	if dormant:
		var player := get_tree().get_first_node_in_group("player")
		if player != null and is_instance_valid(player):
			if global_position.distance_to(player.global_position) <= 10.0 * GameManager.YARD:
				activate()
		return

	if target == null or not is_instance_valid(target):
		find_player()
		if target == null:
			return
	if target.get("dead") == true:
		velocity = Vector2.ZERO
		return

	if root_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	bind_cd = max(0.0, bind_cd - delta)
	thorn_cd = max(0.0, thorn_cd - delta)
	summon_cd = max(0.0, summon_cd - delta)

	var offset: Vector2 = target.global_position - global_position
	var dist := offset.length()
	if dist > 4.0 * GameManager.YARD:
		velocity = offset.normalized() * get_move_speed() * GameManager.YARD
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if dist > 14.0 * GameManager.YARD:
		return
	if bind_cd <= 0.0:
		cast_bind()
	elif thorn_cd <= 0.0:
		cast_thorn()
	elif summon_cd <= 0.0:
		cast_summon()

func activate() -> void:
	if activated:
		return
	activated = true
	dormant = false
	GameManager.register_boss(self)
	GameManager.update_boss_hp(hp, max_hp)
	GameManager.show_toast("藤蔓母怪苏醒了！")

func cast_bind() -> void:
	var data: Dictionary = skills.get("bind", {})
	var zone := Node2D.new()
	zone.set_script(BIND_ZONE_SCRIPT)
	var target_pos: Vector2 = target.global_position
	zone.position = target_pos
	get_tree().current_scene.add_child(zone)
	zone.setup(
		float(data.get("radius", 4.0)),
		float(data.get("delay", 1.0)),
		int(data.get("damage", 14)),
		float(data.get("root", 2.5))
	)
	bind_cd = float(data.get("cd", 10.0))

func cast_thorn() -> void:
	var data: Dictionary = skills.get("thorn", {})
	var thorn := Node2D.new()
	thorn.set_script(THORN_LINE_SCRIPT)
	thorn.position = global_position
	var dir: Vector2 = (target.global_position - global_position).normalized()
	thorn.rotation = dir.angle()
	get_tree().current_scene.add_child(thorn)
	thorn.setup(
		float(data.get("length", 6.0)),
		float(data.get("width", 1.2)),
		float(data.get("delay", 0.8)),
		float(data.get("duration", 3.0)),
		float(data.get("dps", 5.0))
	)
	thorn_cd = float(data.get("cd", 13.0))

func cast_summon() -> void:
	var data: Dictionary = skills.get("summon", {})
	var count: int = int(data.get("count", 4))
	var radius: float = float(data.get("radius", 3.0)) * GameManager.YARD
	for i in range(count):
		var angle := TAU * float(i) / float(count) + randf() * 0.4
		var spawn := VINE_SPAWN_SCENE.instantiate()
		spawn.position = global_position + Vector2(cos(angle), sin(angle)) * radius
		get_tree().current_scene.add_child(spawn)
	summon_cd = float(data.get("cd", 18.0))
	GameManager.show_toast("藤蔓母怪召唤了小藤蔓")

func take_damage(amount: int, source: Node = null) -> void:
	if dead:
		return
	super.take_damage(amount, source)
	if not dead:
		GameManager.update_boss_hp(hp, max_hp)

func die() -> void:
	if dead:
		return
	dead = true
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("add_exp"):
		player.add_exp(exp_reward)
	InventoryManager.roll_boss_drops(global_position)
	GameManager.add_gold(randi_range(max(1, gold_min), max(gold_min, gold_max)))
	GameManager.show_toast("藤蔓母怪被击败了！蓝色改造装备已掉落")
	GameManager.notify_boss_defeated()
	queue_free()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var body := flash_color(Color(0.24, 0.34, 0.16))
	var vine := flash_color(Color(0.18, 0.26, 0.11))
	draw_circle(Vector2(0, 26), 60, Color(0, 0, 0, 0.35))

	# 外围藤蔓
	for i in range(8):
		var angle := TAU * float(i) / 8.0 + t * 0.25
		var start := Vector2(cos(angle), sin(angle)) * 22.0
		var mid := Vector2(cos(angle + 0.5), sin(angle + 0.5)) * (46.0 + sin(t * 2.0 + i) * 6.0)
		var end := Vector2(cos(angle + 1.0), sin(angle + 1.0)) * (60.0 + sin(t * 1.6 + i) * 8.0)
		draw_line(start, mid, vine, 8.0)
		draw_line(mid, end, vine.darkened(0.15), 5.0)
		draw_circle(end, 4.0, Color(0.32, 0.48, 0.18))

	# 主体
	draw_circle(Vector2.ZERO, 42, body)
	draw_arc(Vector2.ZERO, 42, 0, TAU, 44, UITheme.BORDER, 5.0)
	draw_circle(Vector2(0, -6), 30, body.lightened(0.06))
	draw_arc(Vector2(0, -6), 30, 0, TAU, 36, UITheme.BORDER, 3.0)

	# 紫色虚空裂纹
	for i in range(4):
		var a := t * 0.3 + float(i) * 1.4
		var p1 := Vector2(cos(a), sin(a)) * 12.0
		var p2 := Vector2(cos(a + 0.6), sin(a + 0.6)) * 34.0
		draw_line(p1, p2, Color(0.62, 0.33, 1.0, 0.5), 2.0)

	# 眼睛
	var eye_glow := Color(1.0, 0.32, 0.25) if not dormant else Color(0.45, 0.18, 0.15)
	draw_circle(Vector2(-11, -8), 6.0, eye_glow)
	draw_circle(Vector2(11, -8), 6.0, eye_glow)
	draw_circle(Vector2(-11, -8), 2.0, Color(0.1, 0.02, 0.02))
	draw_circle(Vector2(11, -8), 2.0, Color(0.1, 0.02, 0.02))
	# 嘴
	draw_arc(Vector2(0, 12), 14, 0.15, PI - 0.15, 14, UITheme.BORDER, 3.0)

	# 定身藤蔓
	if root_timer > 0.0:
		for i in range(6):
			var angle := TAU * float(i) / 6.0
			draw_line(Vector2(cos(angle), sin(angle)) * 40.0, Vector2(cos(angle + 0.3), sin(angle + 0.3)) * 70.0, Color(0.35, 0.65, 0.2, 0.8), 4.0)
