extends Node2D
## 飞戾怪的酸液弹：直线飞行，命中玩家后造成伤害。

var direction: Vector2 = Vector2.RIGHT
var speed: float = 9.0
var damage: int = 10
var life: float = 2.2
var _trail: Array[Vector2] = []

func setup(dir: Vector2, amount: int, speed_yards: float = 9.0) -> void:
	direction = dir.normalized()
	damage = amount
	speed = speed_yards

func _ready() -> void:
	z_index = 6

func _process(delta: float) -> void:
	life -= delta
	_trail.push_front(global_position)
	if _trail.size() > 5:
		_trail.pop_back()
	global_position += direction * speed * GameManager.YARD * delta
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player")
	if player != null and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= 18.0:
			if player.has_method("take_damage"):
				player.take_damage(damage, self)
			queue_free()
			return
	if life <= 0.0:
		queue_free()

func _draw() -> void:
	for i in range(_trail.size()):
		var alpha := 0.35 * (1.0 - float(i) / maxf(1.0, float(_trail.size())))
		var local := to_local(_trail[i])
		draw_circle(local, 5.0 - i * 0.6, Color(0.45, 0.9, 0.25, alpha))
	draw_circle(Vector2.ZERO, 5.0, Color(0.55, 0.95, 0.3))
	draw_arc(Vector2.ZERO, 5.0, 0, TAU, 10, UITheme.BORDER, 1.5)
