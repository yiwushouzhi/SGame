extends BaseEnemy
## 飞戾怪：保持 4.5~7 码距离，喷射酸液。入夜攻击频率 +30%。

const ACID_SCRIPT := preload("res://scripts/skill/acid_projectile.gd")

func _ready() -> void:
	enemy_type = "winged_wretch"
	super._ready()

func _process(_delta: float) -> void:
	queue_redraw()

func perform_attack() -> void:
	if target == null or not is_instance_valid(target):
		return
	attack_anim = 0.22
	var dir: Vector2 = (target.global_position - global_position).normalized()
	var amount := randi_range(damage_min, damage_max)
	amount = int(round(amount * get_damage_multiplier()))
	var projectile := Node2D.new()
	projectile.set_script(ACID_SCRIPT)
	projectile.position = global_position
	projectile.setup(dir, amount, 9.0)
	get_tree().current_scene.add_child(projectile)

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var flap := sin(t * 9.0) * 10.0
	var body := flash_color(Color(0.36, 0.25, 0.32))
	var wing := flash_color(Color(0.26, 0.2, 0.3))
	draw_circle(Vector2(0, 20), 18, Color(0, 0, 0, 0.28))
	draw_elite_aura(20.0)

	# 翅膀
	var left_wing := PackedVector2Array([
		Vector2(-4, -2), Vector2(-30, -10 - flap), Vector2(-38, 6 - flap * 0.4), Vector2(-12, 8)
	])
	var right_wing := PackedVector2Array([
		Vector2(4, -2), Vector2(30, -10 - flap), Vector2(38, 6 - flap * 0.4), Vector2(12, 8)
	])
	draw_colored_polygon(left_wing, wing)
	draw_colored_polygon(right_wing, wing)
	draw_polyline(left_wing, UITheme.BORDER, 2.5)
	draw_polyline(right_wing, UITheme.BORDER, 2.5)

	# 身体
	draw_circle(Vector2(0, 3), 10, body)
	draw_arc(Vector2(0, 3), 10, 0, TAU, 20, UITheme.BORDER, 3.0)
	# 头与紫色眼睛
	draw_circle(Vector2(0, -9), 7, body.lightened(0.08))
	draw_arc(Vector2(0, -9), 7, 0, TAU, 16, UITheme.BORDER, 2.0)
	draw_circle(Vector2(-3, -10), 2.0, Color(0.78, 0.45, 1.0))
	draw_circle(Vector2(3, -10), 2.0, Color(0.78, 0.45, 1.0))
	# 酸液腺
	if attack_anim > 0.0:
		draw_circle(Vector2(0, 5), 4.5, Color(0.55, 0.95, 0.3, 0.9))
	# 尾巴
	draw_line(Vector2(0, 12), Vector2(flap * 0.3, 24), UITheme.BORDER, 3.0)

	draw_root_vines()
	draw_health_bar(22.0, -34.0)
