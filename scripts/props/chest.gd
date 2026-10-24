extends Node2D
## 宝箱 / 补给箱：靠近按 E 打开。

const FONT: Font = preload("res://assets/fonts/SmileySans.otf")

var chest_name: String = "补给箱"
var free_supply: bool = false
var opened: bool = false
var range_px: float = 80.0

var _near: bool = false
var _own_prompt: String = ""
var _time: float = 0.0

func _ready() -> void:
	add_to_group("chest")
	z_index = 3
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	var player := get_tree().get_first_node_in_group("player")
	var near := player != null and is_instance_valid(player) \
		and global_position.distance_to(player.global_position) <= range_px
	var can_open := free_supply and not GameManager.free_supply_claimed
	if free_supply:
		can_open = not GameManager.free_supply_claimed
	else:
		can_open = not opened
	if near and can_open:
		_own_prompt = "E  打开%s" % chest_name
		GameManager.set_prompt(_own_prompt)
	elif _own_prompt != "" and GameManager.interaction_prompt == _own_prompt:
		GameManager.set_prompt("")
		_own_prompt = ""
	_near = near
	queue_redraw()

func _unhandled_input(event: InputEvent) -> void:
	if not _near or not event.is_action_pressed("interact"):
		return
	if free_supply:
		if GameManager.free_supply_claimed:
			GameManager.show_toast("补给箱已经空了")
		else:
			GameManager.free_supply_claimed = true
			InventoryManager.add_item("small_hp", 2)
			InventoryManager.add_item("small_sanity", 1)
			InventoryManager.add_item("scrap", 2)
			GameManager.show_toast("领取补给：生命药水×2  理智药水×1  金属废料×2")
	else:
		if opened:
			return
		opened = true
		InventoryManager.roll_chest_drops(global_position)
		GameManager.show_toast("打开%s" % chest_name)
	queue_redraw()
	get_viewport().set_input_as_handled()

func _draw() -> void:
	var is_open := opened or (free_supply and GameManager.free_supply_claimed)
	var glow := 0.4 + 0.25 * sin(_time * 4.0)
	draw_circle(Vector2(0, 12), 22, Color(0, 0, 0, 0.35))
	if not is_open:
		draw_circle(Vector2(0, 0), 30, Color(0.95, 0.78, 0.3, glow * 0.18))
	# 箱体
	draw_rect(Rect2(-22, -8, 44, 28), Color(0.46, 0.32, 0.18))
	draw_rect(Rect2(-22, -8, 44, 28), UITheme.BORDER, false, 3.0)
	if is_open:
		# 打开的盖子
		draw_rect(Rect2(-22, -26, 44, 12), Color(0.36, 0.25, 0.14))
		draw_rect(Rect2(-22, -26, 44, 12), UITheme.BORDER, false, 2.5)
		draw_rect(Rect2(-16, -6, 32, 14), Color(0.12, 0.09, 0.08))
	else:
		draw_rect(Rect2(-22, -18, 44, 12), Color(0.55, 0.39, 0.22))
		draw_rect(Rect2(-22, -18, 44, 12), UITheme.BORDER, false, 2.5)
		# 锁扣
		draw_rect(Rect2(-5, -10, 10, 12), Color(0.82, 0.7, 0.35))
		draw_rect(Rect2(-5, -10, 10, 12), UITheme.BORDER, false, 2.0)
	draw_string(FONT, Vector2(-60, -40), chest_name, HORIZONTAL_ALIGNMENT_CENTER, 120, 16, UITheme.GOLD)
