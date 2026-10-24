extends Node2D
## 裂隙传送门：树屋 ↔ 城郊居民区。

const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

var target_area: String = "suburb"  # suburb / hub
var range_px: float = 96.0
var _near: bool = false
var _own_prompt: String = ""
var _time: float = 0.0

func _ready() -> void:
	add_to_group("portal")
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group("player")
	var near := player != null and is_instance_valid(player) \
		and global_position.distance_to(player.global_position) <= range_px
	if near:
		_own_prompt = "E  " + ("前往城郊居民区" if target_area == "suburb" else "返回树屋")
		GameManager.set_prompt(_own_prompt)
	elif _own_prompt != "" and GameManager.interaction_prompt == _own_prompt:
		GameManager.set_prompt("")
		_own_prompt = ""
	_near = near
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _near or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if target_area == "suburb":
		GameManager.go_to_suburb()
	else:
		GameManager.go_to_hub()

func _draw() -> void:
	var pulse := 1.0 + sin(_time * 3.0) * 0.08
	draw_circle(Vector2(0, 16), 34, Color(0, 0, 0, 0.4))
	# 地面裂纹
	for i in range(6):
		var angle := TAU * float(i) / 6.0
		var start := Vector2(cos(angle), sin(angle)) * 18.0
		var end := Vector2(cos(angle + 0.3), sin(angle + 0.3)) * 44.0
		draw_line(start, end, Color(0.45, 0.22, 0.7, 0.7), 3.0)
	# 裂隙环
	draw_circle(Vector2.ZERO, 30.0 * pulse, Color(0.45, 0.18, 0.75, 0.32))
	draw_arc(Vector2.ZERO, 32.0 * pulse, 0, TAU, 40, UITheme.VOID, 4.0)
	draw_arc(Vector2.ZERO, 23.0 * pulse, _time, _time + PI * 1.4, 28, Color(0.82, 0.62, 1.0, 0.9), 3.0)
	draw_arc(Vector2.ZERO, 14.0 * pulse, -_time * 1.4, -_time * 1.4 + PI * 1.2, 22, Color(0.55, 0.3, 0.9, 0.8), 2.0)
	draw_circle(Vector2.ZERO, 8.0, Color(0.08, 0.03, 0.12))
	draw_string(FONT, Vector2(-90, -50), "裂隙传送门", HORIZONTAL_ALIGNMENT_CENTER, 180, 17, UITheme.VOID)
