extends Node2D
## 地面掉落物：靠近自动拾取，背包满时留在原地。

const FONT: Font = preload("res://assets/fonts/SmileySans.otf")
const PICKUP_RADIUS: float = 30.0

var item_data: Dictionary = {}
var _time: float = 0.0
var _full_notified: bool = false

func _ready() -> void:
	add_to_group("pickups")
	z_index = 5
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()
	var player := get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	if global_position.distance_to(player.global_position) <= PICKUP_RADIUS:
		if InventoryManager.add_item_instance(item_data):
			var rarity: String = str(item_data.get("rarity", "white"))
			var type: String = str(item_data.get("type", "material"))
			if type == "equipment" or rarity != "white":
				GameManager.show_toast("拾取：%s" % item_data.get("name", "物品"))
			queue_free()
		elif not _full_notified:
			_full_notified = true
			GameManager.show_toast("背包已满")

func _draw() -> void:
	if item_data.is_empty():
		return
	var bob := sin(_time * 3.0) * 3.0
	var color := Color.html(str(item_data.get("color", "#cfc7b8")))
	var rarity: String = str(item_data.get("rarity", "white"))
	var border := Color.html(InventoryManager.rarity_color(rarity))
	var center := Vector2(0, bob)
	draw_circle(center + Vector2(0, 10), 11, Color(0, 0, 0, 0.3))
	draw_circle(center, 10, color.darkened(0.15))
	draw_arc(center, 10, 0, TAU, 18, UITheme.BORDER, 2.5)
	draw_arc(center, 12.5, 0, TAU, 18, border, 1.5)
	var initial := str(item_data.get("name", "?"))
	if initial.length() > 0:
		initial = initial.substr(0, 1)
	draw_string(FONT, center + Vector2(-7, 6), initial, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.9))
	# 品质光柱
	if rarity == "blue":
		draw_line(center + Vector2(0, -14), center + Vector2(0, -22), Color(0.4, 0.6, 1.0, 0.4), 2.0)
	elif rarity == "yellow":
		draw_line(center + Vector2(0, -14), center + Vector2(0, -26), Color(1.0, 0.82, 0.3, 0.55), 3.0)
