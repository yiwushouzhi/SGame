extends Node2D
## 刺藤喷射：直线 6 码预警后持续 3 秒，每秒 5 点伤害。

const YARD := 32.0

var length_yards: float = 6.0
var width_yards: float = 1.2
var delay: float = 0.8
var duration: float = 3.0
var dps: float = 5.0

var _timer: float = 0.0
var _active: bool = false
var _tick: float = 0.0
var _active_left: float = 0.0

func setup(length: float, width: float, warn_delay: float, active_duration: float, damage_per_second: float) -> void:
	length_yards = length
	width_yards = width
	delay = warn_delay
	duration = active_duration
	dps = damage_per_second

func _ready() -> void:
	z_index = 3
	_active_left = duration
	queue_redraw()

func _process(delta: float) -> void:
	_timer += delta
	queue_redraw()
	if not _active and _timer >= delay:
		_active = true
	if _active:
		_active_left -= delta
		_tick += delta
		if _tick >= 1.0:
			_tick -= 1.0
			_damage_player()
		if _active_left <= 0.0:
			queue_free()

func _damage_player() -> void:
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	var local := to_local(player.global_position)
	var half_width := width_yards * YARD * 0.5
	if local.x < 0.0 or local.x > length_yards * YARD:
		return
	if absf(local.y) > half_width:
		return
	if player.has_method("take_damage"):
		player.take_damage(int(round(dps)), self)

func _draw() -> void:
	var length_px := length_yards * YARD
	var width_px := width_yards * YARD
	if not _active:
		var alpha := 0.12 + 0.08 * sin(_timer * 14.0)
		draw_rect(Rect2(0, -width_px * 0.5, length_px, width_px), Color(0.8, 0.15, 0.2, alpha))
		draw_line(Vector2(0, -width_px * 0.5), Vector2(length_px, -width_px * 0.5), Color(0.9, 0.25, 0.25, 0.65), 2.0)
		draw_line(Vector2(0, width_px * 0.5), Vector2(length_px, width_px * 0.5), Color(0.9, 0.25, 0.25, 0.65), 2.0)
		draw_line(Vector2(length_px, -width_px * 0.5), Vector2(length_px, width_px * 0.5), Color(0.9, 0.25, 0.25, 0.65), 2.0)
	else:
		draw_rect(Rect2(0, -width_px * 0.5, length_px, width_px), Color(0.4, 0.7, 0.2, 0.2))
		var steps := 9
		for i in range(steps):
			var x := length_px * float(i) / float(steps)
			var wobble := sin(Time.get_ticks_msec() * 0.012 + i) * width_px * 0.35
			draw_line(Vector2(x, -width_px * 0.4 + wobble), Vector2(x + 18.0, width_px * 0.4 + wobble), Color(0.45, 0.8, 0.25, 0.8), 3.0)
