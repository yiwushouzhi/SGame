extends Node2D
## 燃烧瓶落地后的灼烧区：半径 3 码，持续 8 秒，每秒 6 点伤害。

var radius_yards: float = 3.0
var duration: float = 8.0
var damage_per_second: float = 6.0

var _life: float = 0.0
var _tick: float = 0.0

func setup(radius: float, active_duration: float, dps: float) -> void:
	radius_yards = radius
	duration = active_duration
	damage_per_second = dps

func _ready() -> void:
	z_index = 2
	queue_redraw()

func _process(delta: float) -> void:
	_life += delta
	_tick += delta
	queue_redraw()
	if _tick >= 1.0:
		_tick -= 1.0
		var radius_px := radius_yards * GameManager.YARD
		for enemy in get_tree().get_nodes_in_group("enemies"):
			if not is_instance_valid(enemy) or enemy.get("dead") == true:
				continue
			if global_position.distance_to(enemy.global_position) <= radius_px:
				enemy.take_damage(int(round(damage_per_second)), null)
	if _life >= duration:
		queue_free()

func _draw() -> void:
	var radius_px := radius_yards * GameManager.YARD
	var fade: float = clamp((duration - _life) / 1.0, 0.0, 1.0)
	var flicker := 0.5 + 0.5 * sin(_life * 18.0)
	draw_circle(Vector2.ZERO, radius_px, Color(0.9, 0.35, 0.08, (0.08 + flicker * 0.05) * fade))
	draw_arc(Vector2.ZERO, radius_px, 0, TAU, 40, Color(1.0, 0.5, 0.15, 0.55 * fade), 3.0)
	for i in range(9):
		var angle := TAU * float(i) / 9.0 + _life * 0.4
		var dist := radius_px * (0.35 + 0.55 * fmod(float(i) * 0.37, 1.0))
		var p := Vector2(cos(angle), sin(angle)) * dist
		var flame_h := 10.0 + sin(_life * 9.0 + i) * 5.0
		draw_circle(p, 4.0, Color(1.0, 0.55, 0.15, 0.55 * fade))
		draw_circle(p + Vector2(0, -flame_h * 0.3), 2.5, Color(1.0, 0.9, 0.4, 0.7 * fade))
