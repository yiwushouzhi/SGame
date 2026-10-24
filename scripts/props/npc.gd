extends Node2D
## 树屋 NPC：昆特（拾荒魔方台）与任务看板。

const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

var npc_name: String = "昆特"
var npc_kind: String = "quint"  # quint / board
var prompt_text: String = "与昆特交谈，打开拾荒魔方"
var range_px: float = 88.0

var _near: bool = false
var _own_prompt: String = ""
var _time: float = 0.0

func _ready() -> void:
	add_to_group("npc")
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group("player")
	var near := player != null and is_instance_valid(player) \
		and global_position.distance_to(player.global_position) <= range_px
	if near:
		_own_prompt = "E  " + prompt_text
		GameManager.set_prompt(_own_prompt)
	elif _own_prompt != "" and GameManager.interaction_prompt == _own_prompt:
		GameManager.set_prompt("")
		_own_prompt = ""
	_near = near
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _near or not event.is_action_pressed("interact"):
		return
	match npc_kind:
		"quint":
			var hud := get_tree().get_first_node_in_group("hud")
			if hud != null and hud.has_method("open_craft_panel"):
				hud.open_craft_panel()
		"board":
			GameManager.show_toast(GameManager.get_quest_text())
	get_viewport().set_input_as_handled()

func _draw() -> void:
	var bob := sin(_time * 2.0) * 2.0
	draw_circle(Vector2(0, 18), 20, Color(0, 0, 0, 0.35))
	if npc_kind == "quint":
		# 昆特：兜帽少年 + 悬浮魔方
		draw_circle(Vector2(0, 2), 12, Color(0.35, 0.5, 0.62))
		draw_arc(Vector2(0, 2), 12, 0, TAU, 22, UITheme.BORDER, 3.0)
		draw_circle(Vector2(0, -8), 8, Color(0.86, 0.69, 0.5))
		draw_arc(Vector2(0, -8), 8, 0, TAU, 18, UITheme.BORDER, 2.5)
		# 护目镜
		draw_circle(Vector2(-3, -9), 2.4, Color(0.55, 0.85, 1.0))
		draw_circle(Vector2(3, -9), 2.4, Color(0.55, 0.85, 1.0))
		# 悬浮魔方
		var cube_y := -28.0 + bob
		draw_rect(Rect2(-8, cube_y - 8, 16, 16), Color(0.42, 0.22, 0.72))
		draw_rect(Rect2(-8, cube_y - 8, 16, 16), UITheme.BORDER, false, 2.0)
		draw_line(Vector2(-8, cube_y), Vector2(8, cube_y), Color(0.72, 0.45, 1.0), 1.5)
		draw_circle(Vector2(0, cube_y), 12, Color(0.62, 0.33, 1.0, 0.18))
	else:
		# 看板：木板 + 任务纸
		draw_rect(Rect2(-26, -30, 52, 40), Color(0.42, 0.31, 0.2))
		draw_rect(Rect2(-26, -30, 52, 40), UITheme.BORDER, false, 3.0)
		draw_line(Vector2(-18, 12), Vector2(-14, 28), UITheme.BORDER, 4.0)
		draw_line(Vector2(18, 12), Vector2(14, 28), UITheme.BORDER, 4.0)
		draw_rect(Rect2(-20, -24, 18, 24), Color(0.86, 0.82, 0.68))
		draw_rect(Rect2(-2, -22, 22, 18), Color(0.92, 0.88, 0.7))
		draw_line(Vector2(-18, -18), Vector2(-6, -18), Color(0.35, 0.3, 0.24), 1.5)
		draw_line(Vector2(-18, -13), Vector2(-8, -13), Color(0.35, 0.3, 0.24), 1.5)
		draw_line(Vector2(0, -16), Vector2(17, -16), Color(0.35, 0.3, 0.24), 1.5)
		draw_line(Vector2(0, -11), Vector2(13, -11), Color(0.35, 0.3, 0.24), 1.5)

	draw_string(FONT, Vector2(-60, -40), npc_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 17, UITheme.TEXT)
