extends CharacterBody2D
class_name BaseEnemy
## 所有怪物父类：追玩家、近战、定身、受击、掉落。
## 子类通过 enemy_type 读取 data/enemy_data.json。

var enemy_type: String = "zombie"
var enemy_name: String = ""
var level: int = 1
var is_elite: bool = false
var is_boss: bool = false
var dormant: bool = false

var max_hp: int = 35
var hp: int = 35
var damage_min: int = 7
var damage_max: int = 9
var attack_interval: float = 0.9
var move_speed: float = 2.8
var exp_reward: int = 12
var attack_range: float = 1.15
var aggro_range: float = 12.0
var min_range: float = 0.0
var armor: float = 0.0
var gold_min: int = 0
var gold_max: int = 0
var night_hp_mod: float = 1.0
var night_damage_mod: float = 1.0
var night_attack_speed_mod: float = 1.0

var target: Node2D = null
var attack_timer: float = 0.0
var root_timer: float = 0.0
var hit_flash: float = 0.0
var attack_anim: float = 0.0
var dead: bool = false

var _night_hp_applied: bool = false
var _lost_target_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	if is_boss:
		add_to_group("boss")
	z_index = 4
	_load_stats()
	if is_elite:
		_apply_elite()
	if enemy_type == "zombie" and DayNightManager.is_night():
		_apply_night_hp_buff()
	DayNightManager.night_started.connect(_on_night_started)
	find_player()
	queue_redraw()

func _load_stats() -> void:
	var data: Dictionary = GameManager.enemy_db.get(enemy_type, {})
	if data.is_empty():
		push_warning("缺少怪物数据: %s" % enemy_type)
		return
	enemy_name = str(data.get("name", enemy_type))
	level = int(data.get("level", 1))
	max_hp = int(data.get("hp", 35))
	hp = max_hp
	damage_min = int(data.get("damage_min", 7))
	damage_max = int(data.get("damage_max", 9))
	var rate: float = max(0.05, float(data.get("attack_rate", 1.0)))
	attack_interval = 1.0 / rate
	move_speed = float(data.get("speed", 2.8))
	attack_range = float(data.get("attack_range", 1.15))
	aggro_range = float(data.get("aggro_range", 12.0))
	min_range = float(data.get("min_range", 0.0))
	exp_reward = int(data.get("exp_reward", 12))
	armor = float(data.get("armor", 0.0))
	gold_min = int(data.get("gold_min", 0))
	gold_max = int(data.get("gold_max", 0))
	night_hp_mod = float(data.get("night_hp_mod", 1.0))
	night_damage_mod = float(data.get("night_damage_mod", 1.0))
	night_attack_speed_mod = float(data.get("night_attack_speed_mod", 1.0))

func _apply_elite() -> void:
	enemy_name = "精英·" + enemy_name
	max_hp = int(round(max_hp * 1.8))
	hp = max_hp
	damage_min = int(round(damage_min * 1.3))
	damage_max = int(round(damage_max * 1.3))
	exp_reward = int(round(exp_reward * 2.0))
	scale = Vector2(1.12, 1.12)

func _apply_night_hp_buff() -> void:
	if _night_hp_applied or night_hp_mod <= 1.0:
		return
	var extra := int(round(max_hp * (night_hp_mod - 1.0)))
	max_hp += extra
	hp += extra
	_night_hp_applied = true

func _on_night_started() -> void:
	if enemy_type == "zombie":
		_apply_night_hp_buff()
		queue_redraw()

func _physics_process(delta: float) -> void:
	attack_timer = max(0.0, attack_timer - delta)
	root_timer = max(0.0, root_timer - delta)
	hit_flash = max(0.0, hit_flash - delta)
	attack_anim = max(0.0, attack_anim - delta)
	queue_redraw()

	if dead or dormant:
		return
	if target == null or not is_instance_valid(target):
		find_player()
		if target == null:
			velocity = Vector2.ZERO
			return
	if target.get("dead") == true:
		velocity = Vector2.ZERO
		return

	if root_timer > 0.0:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var offset: Vector2 = target.global_position - global_position
	var dist := offset.length()
	if dist > aggro_range * GameManager.YARD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var dir := offset.normalized()
	var speed := get_move_speed() * GameManager.YARD
	var desired := Vector2.ZERO
	if min_range > 0.0 and dist < min_range * GameManager.YARD:
		desired = -dir * speed
	elif dist > attack_range * GameManager.YARD * 0.92:
		desired = dir * speed
	velocity = desired + _separation()
	move_and_slide()

	if dist <= attack_range * GameManager.YARD and attack_timer <= 0.0:
		attack_timer = get_attack_interval()
		perform_attack()

func _separation() -> Vector2:
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other):
			continue
		var diff: Vector2 = global_position - other.global_position
		var d := diff.length()
		if d > 0.1 and d < 30.0:
			push += diff.normalized() * (30.0 - d) * 1.8
	return push

func get_move_speed() -> float:
	var speed := move_speed * DayNightManager.get_enemy_speed_mod()
	if is_elite:
		speed *= 1.05
	return speed

func get_attack_interval() -> float:
	var speed_mod := 1.0
	if DayNightManager.is_night():
		speed_mod = night_attack_speed_mod
	return attack_interval / max(1.0, speed_mod)

func get_damage_multiplier() -> float:
	if DayNightManager.is_night():
		return night_damage_mod
	return 1.0

func perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return
	attack_anim = 0.2
	if global_position.distance_to(target.global_position) > attack_range * GameManager.YARD + 6.0:
		return
	var amount := randi_range(damage_min, damage_max)
	amount = int(round(amount * get_damage_multiplier()))
	if target.has_method("take_damage"):
		target.take_damage(amount, self)

func take_damage(amount: int, _source: Node = null) -> void:
	if dead:
		return
	var actual := int(round(amount * (1.0 - armor)))
	actual = max(1, actual)
	hp -= actual
	hit_flash = 0.12
	queue_redraw()
	if hp <= 0:
		die()

func apply_root(duration: float) -> void:
	root_timer = max(root_timer, duration)
	velocity = Vector2.ZERO

func is_rooted() -> bool:
	return root_timer > 0.0

func find_player() -> void:
	target = get_tree().get_first_node_in_group("player")

func die() -> void:
	if dead:
		return
	dead = true
	var player := get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("add_exp"):
		player.add_exp(exp_reward)
	InventoryManager.roll_enemy_drops(enemy_type, global_position, is_elite)
	if gold_max > 0:
		GameManager.add_gold(randi_range(gold_min, gold_max))
	queue_free()

# ---------------------------------------------------------------- 绘制辅助

func flash_color(base: Color) -> Color:
	if hit_flash > 0.0:
		return Color(1, 0.96, 0.9)
	return base

func draw_elite_aura(radius: float) -> void:
	if not is_elite:
		return
	draw_arc(Vector2.ZERO, radius + 5.0, 0, TAU, 28, Color(0.7, 0.3, 1.0, 0.5), 3.0)

func draw_health_bar(half_width: float = 19.0, y: float = -30.0) -> void:
	if hp >= max_hp and not is_elite and not is_boss:
		return
	var bar_w := half_width * 2.0
	var ratio: float = clamp(float(hp) / float(max_hp), 0.0, 1.0)
	draw_rect(Rect2(-half_width - 1, y - 1, bar_w + 2, 7), UITheme.BORDER)
	draw_rect(Rect2(-half_width, y, bar_w, 5), Color(0.1, 0.08, 0.1, 0.9))
	var fill_color := Color(0.82, 0.25, 0.28) if not is_elite else Color(0.72, 0.32, 1.0)
	draw_rect(Rect2(-half_width, y, bar_w * ratio, 5), fill_color)

func draw_root_vines() -> void:
	if root_timer <= 0.0:
		return
	for i in range(4):
		var angle := TAU * float(i) / 4.0
		var p1 := Vector2(cos(angle), sin(angle)) * 14.0
		var p2 := Vector2(cos(angle + 0.4), sin(angle + 0.4)) * 24.0
		draw_line(p1, p2, Color(0.35, 0.65, 0.2, 0.8), 3.0)
