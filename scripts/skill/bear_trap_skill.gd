extends Node2D
## 捕兽夹：踩中造成 8 伤害并定身 3 秒；对 Boss 缩短为 1.2 秒。

var triggered: bool = false
var _life: float = 0.0
var _trigger_anim: float = 0.0
var _triggered_enemy: Node = null

func setup() -> void:
	pass

func _ready() -> void:
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_life += delta
	queue_redraw()
	if triggered:
		_trigger_anim -= delta
		if _trigger_anim <= 0.0:
			queue_free()
		return
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy) or enemy.get("dead") == true:
			continue
		if global_position.distance_to(enemy.global_position) <= 22.0:
			_trigger(enemy)
			break

func _trigger(enemy: Node) -> void:
	triggered = true
	_trigger_anim = 1.0
	_triggered_enemy = enemy
	if enemy.has_method("take_damage"):
		enemy.take_damage(8, null)
	var root_duration := 1.2 if enemy.get("is_boss") == true else 3.0
	if enemy.has_method("apply_root"):
		enemy.apply_root(root_duration)
	GameManager.show_toast("捕兽夹触发！")

func _draw() -> void:
	# 弹簧底盘
	draw_circle(Vector2.ZERO, 16, Color(0, 0, 0, 0.3))
	draw_arc(Vector2.ZERO, 15, 0, TAU, 20, UITheme.BORDER, 3.0)
	draw_circle(Vector2.ZERO, 12, Color(0.32, 0.36, 0.4, 0.9))
	# 夹齿
	if triggered:
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var p1 := Vector2(cos(angle), sin(angle)) * 8.0
			var p2 := Vector2(cos(angle + 0.22), sin(angle + 0.22)) * 20.0
			draw_line(p1, p2, Color(0.72, 0.76, 0.8), 3.0)
		draw_arc(Vector2.ZERO, 18, 0, TAU, 20, Color(1.0, 0.85, 0.4, 0.6), 2.0)
	else:
		for i in range(8):
			var angle := TAU * float(i) / 8.0
			var p1 := Vector2(cos(angle), sin(angle)) * 12.0
			var p2 := Vector2(cos(angle + 0.3), sin(angle + 0.3)) * 8.0
			draw_line(p1, p2, Color(0.72, 0.76, 0.8), 3.0)
		var pulse := 0.4 + 0.3 * sin(_life * 5.0)
		draw_arc(Vector2.ZERO, 19, 0, TAU, 20, Color(0.8, 0.85, 0.9, pulse * 0.4), 2.0)
