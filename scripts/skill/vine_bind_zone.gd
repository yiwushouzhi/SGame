extends Node2D
## 藤蔓缠绕：红圈预警 1 秒，命中后定身 2.5 秒并造成 14 伤害。

const YARD := 32.0

var radius_yards: float = 4.0
var delay: float = 1.0
var damage: int = 14
var root_seconds: float = 2.5
var _timer: float = 0.0
var _triggered: bool = false
var _fade: float = 0.0

func setup(radius: float, warn_delay: float, amount: int, root_duration: float) -> void:
	radius_yards = radius
	delay = warn_delay
	damage = amount
	root_seconds = root_duration

func _ready() -> void:
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_timer += delta
	queue_redraw()
	if not _triggered and _timer >= delay:
		_triggered = true
		_fade = 0.35
		var player := get_tree().get_first_node_in_group("player")
		if player != null and is_instance_valid(player):
			if global_position.distance_to(player.global_position) <= radius_yards * YARD:
				if player.has_method("take_damage"):
					player.take_damage(damage, self)
				if player.has_method("apply_root"):
					player.apply_root(root_seconds)
	if _triggered:
		_fade -= delta
		if _fade <= 0.0:
			queue_free()

func _draw() -> void:
	var radius_px := radius_yards * YARD
	var pulse := 0.5 + 0.5 * sin(_timer * 12.0)
	if not _triggered:
		draw_circle(Vector2.ZERO, radius_px, Color(0.75, 0.12, 0.15, 0.13 + pulse * 0.08))
		draw_arc(Vector2.ZERO, radius_px, 0, TAU, 40, Color(0.9, 0.2, 0.22, 0.9), 4.0)
		draw_arc(Vector2.ZERO, radius_px * clamp(_timer / max(delay, 0.01), 0.0, 1.0), 0, TAU, 40, Color(1.0, 0.5, 0.35, 0.55), 2.0)
	else:
		draw_circle(Vector2.ZERO, radius_px, Color(0.35, 0.65, 0.2, 0.18))
		draw_arc(Vector2.ZERO, radius_px, 0, TAU, 40, Color(0.5, 0.85, 0.3, 0.6), 3.0)
		for i in range(6):
			var angle := TAU * float(i) / 6.0
			draw_line(Vector2(cos(angle), sin(angle)) * 10.0, Vector2(cos(angle), sin(angle)) * radius_px, Color(0.35, 0.6, 0.2, 0.5), 3.0)
