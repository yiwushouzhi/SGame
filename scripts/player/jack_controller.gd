extends CharacterBody2D
class_name JackController
## 杰克·沙利文：移动、翻滚、近战、Q 燃烧瓶、F 捕兽夹、理智失控。
## 原型数值见 data/ 与 GDD 补充包。1 码 = 32 像素。

const MOLOTOV_SCENE := preload("res://scenes/skills/Molotov.tscn")
const BEAR_TRAP_SCENE := preload("res://scenes/skills/BearTrap.tscn")

const ROLL_CD: float = 4.0
const ROLL_DURATION: float = 0.4
const ROLL_DISTANCE_YARDS: float = 3.0
const ATTACK_INTERVAL: float = 1.0 / 0.75
const MELEE_RANGE_YARDS: float = 1.75
const MELEE_ARC_DEG: float = 110.0
const Q_CD: float = 7.0
const W_CD: float = 9.0
const MAX_TRAPS: int = 2

const BASE_HP: int = 100
const HP_GROWTH: int = 12
const BASE_SANITY: int = 80
const SANITY_GROWTH: int = 5
const BASE_SPEED: float = 4.2
const SPEED_GROWTH: float = 0.15
const BASE_DAMAGE_MIN: float = 12.0
const BASE_DAMAGE_MAX: float = 16.0
const DAMAGE_GROWTH: float = 2.2
const BASE_CRIT: float = 5.0
const CRIT_GROWTH: float = 0.3
const BASE_DODGE: float = 8.0
const DODGE_GROWTH: float = 0.5

## 原型补充：黑夜虚空侵蚀让理智每秒 -1，用于验证理智条与失控机制。
## 若后续需要关闭，只需把该常量改为 0。
const NIGHT_SANITY_DRAIN: float = 1.0

var hp: int = BASE_HP
var max_hp: int = BASE_HP
var sanity: int = BASE_SANITY
var max_sanity: int = BASE_SANITY

var level: int = 1
var exp: int = 0

var attack_cd: float = 0.0
var q_cd: float = 0.0
var w_cd: float = 0.0
var roll_cd: float = 0.0

var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_dir: Vector2 = Vector2.RIGHT
var invincible: bool = false

var facing: Vector2 = Vector2.RIGHT
var root_timer: float = 0.0
var hit_flash: float = 0.0
var attack_anim: float = 0.0

var out_of_control: bool = false
var ooc_timer: float = 0.0
var auto_attack_timer: float = 0.0

var burn_timer: float = 0.0
var poison_timer: float = 0.0

var dead: bool = false
var _traps: Array[Node] = []
var _sanity_signal_connected: bool = false

@onready var camera: Camera2D = $Camera2D

func _ready() -> void:
	add_to_group("player")
	max_hp = _calc_max_hp()
	max_sanity = _calc_max_sanity()
	hp = max_hp
	sanity = max_sanity
	GameManager.apply_saved_state(self)
	InventoryManager.equipment_changed.connect(_on_equipment_changed)
	DayNightManager.night_started.connect(_on_night_started)
	GameManager.register_player(self)
	queue_redraw()

func setup_camera(world_rect: Rect2) -> void:
	if camera == null:
		return
	camera.limit_left = int(world_rect.position.x)
	camera.limit_top = int(world_rect.position.y)
	camera.limit_right = int(world_rect.end.x)
	camera.limit_bottom = int(world_rect.end.y)

func _calc_max_hp() -> int:
	var stats := InventoryManager.get_equipment_stats()
	return BASE_HP + HP_GROWTH * (level - 1) + int(round(float(stats.get("max_hp", 0.0))))

func _calc_max_sanity() -> int:
	var stats := InventoryManager.get_equipment_stats()
	return BASE_SANITY + SANITY_GROWTH * (level - 1) + int(round(float(stats.get("max_sanity", 0.0))))

func _calc_speed() -> float:
	var stats := InventoryManager.get_equipment_stats()
	var speed := BASE_SPEED + SPEED_GROWTH * (level - 1) + float(stats.get("speed", 0.0))
	speed -= DayNightManager.get_player_speed_penalty()
	return max(1.0, speed)

func get_crit_chance() -> float:
	var stats := InventoryManager.get_equipment_stats()
	var chance := BASE_CRIT + CRIT_GROWTH * (level - 1) + float(stats.get("crit", 0.0))
	if hp > max_hp * 0.8:
		chance += 10.0  # 【幻想暴击】被动
	return clamp(chance, 0.0, 95.0)

func get_dodge_chance() -> float:
	return clamp(BASE_DODGE + DODGE_GROWTH * (level - 1), 0.0, 40.0)

func get_move_speed_value() -> float:
	return _calc_speed()

func get_armor_percent() -> float:
	var stats := InventoryManager.get_equipment_stats()
	return clamp(float(stats.get("armor", 0.0)), 0.0, 60.0)

func get_attack_damage_min() -> float:
	var stats := InventoryManager.get_equipment_stats()
	return BASE_DAMAGE_MIN + DAMAGE_GROWTH * (level - 1) + float(stats.get("damage", 0.0))

func get_attack_damage_max() -> float:
	var stats := InventoryManager.get_equipment_stats()
	return BASE_DAMAGE_MAX + DAMAGE_GROWTH * (level - 1) + float(stats.get("damage", 0.0))

func _exp_to_next() -> int:
	return level * 80 + 40

func get_exp_to_next() -> int:
	return _exp_to_next()

# ---------------------------------------------------------------- 主循环

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	if dead:
		velocity = Vector2.ZERO
		return

	if DayNightManager.is_night() and not out_of_control:
		_tick_night_sanity(delta)

	if out_of_control:
		_process_out_of_control(delta)
		queue_redraw()
		return

	if not is_rolling:
		facing = (get_global_mouse_position() - global_position).normalized()
		if facing == Vector2.ZERO:
			facing = Vector2.RIGHT

	if root_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		queue_redraw()
		return

	if is_rolling:
		_process_roll(delta)
		queue_redraw()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_dir.length() > 0.01:
		velocity = input_dir.normalized() * _calc_speed() * GameManager.YARD
	else:
		velocity = Vector2.ZERO
	move_and_slide()

	if Input.is_action_just_pressed("roll") and roll_cd <= 0.0:
		start_roll(input_dir)

	_handle_combat_input()
	_handle_skill_input()
	_handle_potion_input()
	queue_redraw()

func _tick_timers(delta: float) -> void:
	attack_cd = max(0.0, attack_cd - delta)
	q_cd = max(0.0, q_cd - delta)
	w_cd = max(0.0, w_cd - delta)
	roll_cd = max(0.0, roll_cd - delta)
	root_timer = max(0.0, root_timer - delta)
	hit_flash = max(0.0, hit_flash - delta)
	attack_anim = max(0.0, attack_anim - delta)
	burn_timer = max(0.0, burn_timer - delta)
	poison_timer = max(0.0, poison_timer - delta)

func start_roll(input_dir: Vector2) -> void:
	if is_rolling or roll_cd > 0.0 or root_timer > 0.0:
		return
	is_rolling = true
	invincible = true
	roll_timer = ROLL_DURATION
	roll_cd = ROLL_CD
	if input_dir.length() > 0.1:
		roll_dir = input_dir.normalized()
	else:
		roll_dir = facing.normalized()
	if roll_dir == Vector2.ZERO:
		roll_dir = Vector2.RIGHT
	velocity = roll_dir * (ROLL_DISTANCE_YARDS * GameManager.YARD / ROLL_DURATION)
	GameManager.set_prompt("")

func _process_roll(delta: float) -> void:
	roll_timer -= delta
	velocity = roll_dir * (ROLL_DISTANCE_YARDS * GameManager.YARD / ROLL_DURATION)
	move_and_slide()
	if roll_timer <= 0.0:
		is_rolling = false
		invincible = false
		velocity = Vector2.ZERO

# ---------------------------------------------------------------- 战斗

func _handle_combat_input() -> void:
	if Input.is_action_pressed("attack") and attack_cd <= 0.0:
		perform_attack()

func perform_attack() -> void:
	if attack_cd > 0.0:
		return
	attack_cd = ATTACK_INTERVAL
	attack_anim = 0.18
	var range_px := MELEE_RANGE_YARDS * GameManager.YARD
	var half_arc := deg_to_rad(MELEE_ARC_DEG * 0.5)
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		var offset: Vector2 = enemy.global_position - global_position
		if offset.length() > range_px:
			continue
		if facing.angle_to(offset.normalized()) > half_arc:
			continue
		var damage := randf_range(get_attack_damage_min(), get_attack_damage_max())
		var crit := randf() * 100.0 < get_crit_chance()
		if crit:
			damage *= 1.75
		enemy.take_damage(int(round(damage)), self)

func take_damage(amount: int, _source: Node = null) -> void:
	if dead or invincible:
		return
	if randf() * 100.0 < get_dodge_chance():
		return
	var reduced := int(round(amount * (1.0 - get_armor_percent() / 100.0)))
	reduced = max(1, reduced)
	hp = max(0, hp - reduced)
	hit_flash = 0.16
	queue_redraw()
	if hp <= 0:
		die()

func apply_root(duration: float) -> void:
	root_timer = max(root_timer, duration)
	velocity = Vector2.ZERO

func heal(amount: int) -> void:
	if amount <= 0:
		return
	hp = min(max_hp, hp + amount)

func add_sanity(amount: int) -> void:
	if amount <= 0:
		return
	sanity = min(max_sanity, sanity + amount)
	if sanity > 0 and out_of_control:
		out_of_control = false
		ooc_timer = 0.0

func add_exp(amount: int) -> void:
	if level >= GameManager.MAX_LEVEL:
		exp = _exp_to_next()
		return
	exp += amount
	while level < GameManager.MAX_LEVEL and exp >= _exp_to_next():
		exp -= _exp_to_next()
		level += 1
		var old_max_hp := max_hp
		var old_max_sanity := max_sanity
		max_hp = _calc_max_hp()
		max_sanity = _calc_max_sanity()
		hp = min(max_hp, hp + max_hp - old_max_hp)
		sanity = min(max_sanity, sanity + max_sanity - old_max_sanity)
		GameManager.show_toast("升级！杰克达到 Lv.%d" % level)
	if level >= GameManager.MAX_LEVEL:
		exp = _exp_to_next()

func die() -> void:
	if dead:
		return
	dead = true
	out_of_control = false
	velocity = Vector2.ZERO
	GameManager.on_player_died()

func get_save_state() -> Dictionary:
	return {"hp": hp, "sanity": sanity, "level": level, "exp": exp}

func apply_save_state(state: Dictionary) -> void:
	level = int(state.get("level", level))
	max_hp = _calc_max_hp()
	max_sanity = _calc_max_sanity()
	hp = clamp(int(state.get("hp", max_hp)), 1, max_hp)
	sanity = clamp(int(state.get("sanity", max_sanity)), 0, max_sanity)
	exp = int(state.get("exp", exp))
	dead = false

# ---------------------------------------------------------------- 理智 / 失控

func _tick_night_sanity(delta: float) -> void:
	if NIGHT_SANITY_DRAIN <= 0.0:
		return
	_night_sanity_accum += NIGHT_SANITY_DRAIN * delta
	if _night_sanity_accum >= 1.0:
		var whole := int(floor(_night_sanity_accum))
		_night_sanity_accum -= float(whole)
		sanity = max(0, sanity - whole)
	if sanity <= 0 and not out_of_control:
		_enter_out_of_control()

var _night_sanity_accum: float = 0.0
var _ooc_sanity_accum: float = 0.0

func _on_night_started() -> void:
	GameManager.show_toast("黑夜降临：怪物变强，理智持续流失")
	_night_sanity_accum = 0.0

func _enter_out_of_control() -> void:
	if out_of_control or dead:
		return
	out_of_control = true
	ooc_timer = 8.0
	auto_attack_timer = 0.0
	GameManager.show_toast("理智崩溃！杰克失控 8 秒")
	GameManager.set_prompt("")

func _process_out_of_control(delta: float) -> void:
	ooc_timer -= delta
	_ooc_sanity_accum += 5.0 * delta
	if _ooc_sanity_accum >= 1.0:
		var whole := int(floor(_ooc_sanity_accum))
		_ooc_sanity_accum -= float(whole)
		sanity = min(max_sanity, sanity + whole)
	if sanity <= 0:
		sanity = 1
	var nearest := _find_nearest_enemy(6.0 * GameManager.YARD)
	if nearest != null:
		var offset: Vector2 = nearest.global_position - global_position
		facing = offset.normalized()
		if offset.length() > MELEE_RANGE_YARDS * GameManager.YARD * 0.9:
			velocity = facing * _calc_speed() * 0.7 * GameManager.YARD
		else:
			velocity = Vector2.ZERO
		move_and_slide()
		auto_attack_timer -= delta
		if auto_attack_timer <= 0.0:
			auto_attack_timer = ATTACK_INTERVAL
			attack_anim = 0.18
			_perform_melee_auto()
	else:
		velocity = Vector2.ZERO
		move_and_slide()
	if ooc_timer <= 0.0:
		out_of_control = false
		sanity = max(sanity, 5)
		GameManager.show_toast("杰克恢复了意识")

func _perform_melee_auto() -> void:
	var range_px := MELEE_RANGE_YARDS * GameManager.YARD
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		if global_position.distance_to(enemy.global_position) <= range_px:
			var damage := randf_range(get_attack_damage_min(), get_attack_damage_max())
			enemy.take_damage(int(round(damage)), self)

func _find_nearest_enemy(max_distance: float) -> Node2D:
	var best: Node2D = null
	var best_dist := max_distance
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < best_dist:
			best_dist = dist
			best = enemy
	return best

# ---------------------------------------------------------------- 技能 / 药水

func _handle_skill_input() -> void:
	if Input.is_action_just_pressed("skill_q") and q_cd <= 0.0:
		cast_molotov(false)
	if Input.is_action_just_pressed("skill_w") and w_cd <= 0.0:
		cast_bear_trap(false)

func cast_molotov(from_item: bool = false) -> void:
	if dead:
		return
	var molotov := MOLOTOV_SCENE.instantiate()
	var target := get_global_mouse_position()
	var offset := target - global_position
	var max_dist := 7.0 * GameManager.YARD
	if offset.length() > max_dist:
		target = global_position + offset.normalized() * max_dist
	molotov.position = global_position
	get_tree().current_scene.add_child(molotov)
	molotov.setup(global_position, target)
	if not from_item:
		q_cd = Q_CD

func cast_bear_trap(from_item: bool = false) -> void:
	if dead:
		return
	var trap := BEAR_TRAP_SCENE.instantiate()
	trap.position = global_position
	get_tree().current_scene.add_child(trap)
	trap.setup()
	_traps.append(trap)
	trap.tree_exited.connect(func() -> void: _traps.erase(trap))
	while _traps.size() > MAX_TRAPS:
		var oldest: Node = _traps.pop_front()
		if is_instance_valid(oldest):
			oldest.queue_free()
	if not from_item:
		w_cd = W_CD

func use_crafted(item: Dictionary) -> bool:
	if item.get("use", "") == "molotov":
		cast_molotov(true)
		return true
	if item.get("use", "") == "bear_trap":
		cast_bear_trap(true)
		return true
	return false

func _handle_potion_input() -> void:
	if Input.is_action_just_pressed("use_hp_potion"):
		use_quick_potion("small_hp")
	if Input.is_action_just_pressed("use_sanity_potion"):
		use_quick_potion("small_sanity")

func use_quick_potion(id: String) -> bool:
	if InventoryManager.count_item(id) <= 0:
		GameManager.show_toast("没有%s了" % InventoryManager.get_def(id).get("name", "药水"))
		return false
	var def := InventoryManager.get_def(id)
	if id == "small_hp" and hp >= max_hp:
		GameManager.show_toast("生命已满")
		return false
	if id == "small_sanity" and sanity >= max_sanity:
		GameManager.show_toast("理智已满")
		return false
	if not InventoryManager.consume_id(id, 1):
		return false
	heal(int(def.get("heal", 0)))
	add_sanity(int(def.get("sanity", 0)))
	GameManager.show_toast("使用 %s" % def.get("name", ""))
	return true

func consume_item(item: Dictionary) -> bool:
	if item.get("type", "") != "consumable":
		return false
	var use: String = item.get("use", "")
	if use != "":
		if use == "molotov":
			cast_molotov(true)
			return true
		if use == "bear_trap":
			cast_bear_trap(true)
			return true
	if int(item.get("heal", 0)) > 0 and hp >= max_hp:
		GameManager.show_toast("生命已满")
		return false
	if int(item.get("heal", 0)) <= 0 and int(item.get("sanity", 0)) > 0 and sanity >= max_sanity:
		GameManager.show_toast("理智已满")
		return false
	heal(int(item.get("heal", 0)))
	add_sanity(int(item.get("sanity", 0)))
	return true

# ---------------------------------------------------------------- 装备响应

func _on_equipment_changed() -> void:
	var old_max_hp := max_hp
	var old_max_sanity := max_sanity
	max_hp = _calc_max_hp()
	max_sanity = _calc_max_sanity()
	hp = clamp(hp + max(0, max_hp - old_max_hp), 1, max_hp)
	sanity = clamp(sanity + max(0, max_sanity - old_max_sanity), 0, max_sanity)
	queue_redraw()

# ---------------------------------------------------------------- 绘制

func _draw() -> void:
	if dead:
		_draw_dead()
		return

	if is_rolling:
		draw_circle(Vector2(0, 13), 15, Color(0, 0, 0, 0.25))
		draw_circle(Vector2.ZERO, 12, Color(0.72, 0.45, 0.22, 0.55))
		draw_arc(Vector2.ZERO, 12, 0, TAU, 24, UITheme.BORDER, 3.0)
		return

	draw_circle(Vector2(0, 14), 14, Color(0, 0, 0, 0.35))
	var body_color := Color(0.74, 0.43, 0.2)
	var hood_color := Color(0.55, 0.3, 0.14)
	if hit_flash > 0.0:
		body_color = Color(1, 0.95, 0.9)
		hood_color = Color(1, 0.9, 0.85)

	# 挥击弧线
	if attack_anim > 0.0:
		var start := facing.angle() - deg_to_rad(55)
		draw_arc(Vector2.ZERO, MELEE_RANGE_YARDS * GameManager.YARD, start, start + deg_to_rad(110), 18, Color(1, 0.9, 0.6, 0.75), 5.0)

	# 身体与兜帽
	draw_circle(Vector2(0, 2), 13, body_color)
	draw_arc(Vector2(0, 2), 13, 0, TAU, 26, UITheme.BORDER, 3.0)
	draw_circle(Vector2(0, -4), 9, hood_color)
	draw_arc(Vector2(0, -4), 9, 0, TAU, 20, UITheme.BORDER, 2.5)
	# 脸
	draw_circle(Vector2(0, -3), 5.5, Color(0.89, 0.7, 0.52))
	draw_arc(Vector2(0, -3), 5.5, 0, TAU, 16, UITheme.BORDER, 1.5)
	# 眼睛
	var eye_color := Color(0.94, 0.25, 0.2) if out_of_control else Color(0.08, 0.06, 0.08)
	draw_circle(Vector2(-2.2, -4), 1.2, eye_color)
	draw_circle(Vector2(2.2, -4), 1.2, eye_color)

	# 钉棒球棍
	var hand := facing * 10.0
	var bat_end := facing * 40.0
	draw_line(hand, bat_end, UITheme.BORDER, 9.0, true)
	draw_line(hand, bat_end, Color(0.55, 0.39, 0.22), 6.0, true)
	for i in range(3):
		var t := 0.75 + i * 0.09
		var nail_pos := hand.lerp(bat_end, t)
		draw_circle(nail_pos + facing.orthogonal() * 4.0, 1.6, Color(0.8, 0.82, 0.85))
	# 滑板
	draw_line(Vector2(0, 13), facing.orthogonal() * 10.0 + Vector2(0, 13), Color(0.2, 0.18, 0.22), 4.0)

	# 定身藤蔓
	if root_timer > 0.0:
		for i in range(4):
			var angle := TAU * float(i) / 4.0 + 0.3
			var p1 := Vector2(cos(angle), sin(angle)) * 14.0
			var p2 := Vector2(cos(angle + 0.5), sin(angle + 0.5)) * 22.0
			draw_line(p1, p2, Color(0.35, 0.65, 0.2, 0.8), 3.0, true)

	# 失控红光
	if out_of_control:
		draw_arc(Vector2.ZERO, 21, 0, TAU, 24, Color(0.9, 0.2, 0.3, 0.5), 2.0)

func _draw_dead() -> void:
	draw_circle(Vector2(0, 8), 16, Color(0, 0, 0, 0.4))
	draw_circle(Vector2.ZERO, 13, Color(0.35, 0.23, 0.18))
	draw_arc(Vector2.ZERO, 13, 0, TAU, 24, UITheme.BORDER, 3.0)
	draw_line(Vector2(-10, 0), Vector2(10, 0), Color(0.8, 0.3, 0.3), 3.0)
