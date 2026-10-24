extends Node2D
## 燃烧瓶投掷物：飞向目标点后爆炸，造成 24~36 点伤害并留下 8 秒、每秒 6 点的灼烧区。

const FIRE_ZONE_SCRIPT := preload("res://scripts/skill/fire_zone.gd")

var start_pos: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var travel_time: float = 0.5
var timer: float = 0.0
var done: bool = false

func setup(from: Vector2, to: Vector2) -> void:
	start_pos = from
	target_pos = to
	travel_time = clamp(from.distance_to(to) / (10.0 * GameManager.YARD), 0.25, 0.65)

func _ready() -> void:
	z_index = 6
	queue_redraw()

func _process(delta: float) -> void:
	if done:
		return
	timer += delta
	var ratio: float = clamp(timer / travel_time, 0.0, 1.0)
	var flat := start_pos.lerp(target_pos, ratio)
	global_position = flat + Vector2(0, -sin(ratio * PI) * 45.0)
	rotation += delta * 10.0
	queue_redraw()
	if ratio >= 1.0:
		_explode()

func _explode() -> void:
	done = true
	var radius := 3.0 * GameManager.YARD
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		if global_position.distance_to(enemy.global_position) <= radius:
			enemy.take_damage(randi_range(24, 36), null)
	var zone := Node2D.new()
	zone.set_script(FIRE_ZONE_SCRIPT)
	zone.position = global_position
	get_tree().current_scene.add_child(zone)
	zone.setup(3.0, 8.0, 6.0)
	queue_free()

func _draw() -> void:
	# 瓶子
	draw_line(Vector2(-10, 6), Vector2(10, -6), UITheme.BORDER, 9.0)
	draw_line(Vector2(-10, 6), Vector2(10, -6), Color(0.55, 0.68, 0.42), 6.0)
	draw_circle(Vector2(10, -6), 4.0, Color(0.35, 0.55, 0.25))
	# 火苗
	draw_circle(Vector2(-12, 8), 5.0, Color(1.0, 0.6, 0.15, 0.9))
	draw_circle(Vector2(-12, 8), 2.5, Color(1.0, 0.95, 0.5))
	draw_arc(Vector2(-12, 8), 8.0, 0, TAU, 12, Color(1.0, 0.45, 0.1, 0.35), 2.0)
