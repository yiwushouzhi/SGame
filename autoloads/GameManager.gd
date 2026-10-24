extends Node
## 全局状态：玩家存档、场景切换、货币、任务、Boss 引用、暂停与提示。
## Autoload 顺序：GameManager → DayNightManager → InventoryManager → CraftManager

signal player_spawned(player)
signal player_died
signal toast_requested(text)
signal quest_changed
signal boss_changed(boss)
signal boss_hp_changed(hp, max_hp)
signal boss_defeated_event
signal currency_changed
signal area_changed(area_name)

const YARD: float = 32.0
const MAX_LEVEL: int = 10

const MAIN_MENU_SCENE := "res://scenes/main_menu/MainMenu.tscn"
const HUB_SCENE := "res://scenes/levels/TreehouseHub.tscn"
const SUBURB_SCENE := "res://scenes/levels/SuburbArea.tscn"

const WORLD_RECT_HUB := Rect2(0, 0, 1920, 1080)
const WORLD_RECT_SUBURB := Rect2(0, 0, 3200, 2000)

var enemy_db: Dictionary = {}

var current_area: String = ""
var player: Node = null
var active_boss: Node = null

var gold: int = 0
var quest_stage: int = 0
var boss_defeated: bool = false
var free_supply_claimed: bool = false
var player_state: Dictionary = {}

var interaction_prompt: String = ""
var is_ui_paused: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ensure_default_actions()
	enemy_db = _load_json("res://data/enemy_data.json")

func _load_json(path: String) -> Variant:
	if not FileAccess.file_exists(path):
		push_warning("缺少数据文件: %s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	var text := file.get_as_text()
	var parsed: Variant = JSON.parse_string(text)
	if parsed == null:
		push_error("JSON 解析失败: %s" % path)
		return {}
	return parsed

func _ensure_default_actions() -> void:
	# 若项目输入映射被误删，运行时兜底，保证原型仍可操作。
	_add_action_if_missing("move_up", [_key(KEY_W), _key(KEY_UP)])
	_add_action_if_missing("move_down", [_key(KEY_S), _key(KEY_DOWN)])
	_add_action_if_missing("move_left", [_key(KEY_A), _key(KEY_LEFT)])
	_add_action_if_missing("move_right", [_key(KEY_D), _key(KEY_RIGHT)])
	_add_action_if_missing("roll", [_key(KEY_SPACE)])
	_add_action_if_missing("skill_q", [_key(KEY_Q)])
	_add_action_if_missing("skill_w", [_key(KEY_F)])
	_add_action_if_missing("attack", [_mouse(1)])
	_add_action_if_missing("interact", [_key(KEY_E)])
	_add_action_if_missing("inventory", [_key(KEY_B)])
	_add_action_if_missing("craft", [_key(KEY_M)])
	_add_action_if_missing("pause", [_key(KEY_ESCAPE)])
	_add_action_if_missing("use_hp_potion", [_key(KEY_1)])
	_add_action_if_missing("use_sanity_potion", [_key(KEY_2)])
	_add_action_if_missing("return_home", [_key(KEY_T)])

func _add_action_if_missing(action: String, events: Array) -> void:
	if InputMap.has_action(action):
		return
	InputMap.add_action(action)
	for event in events:
		InputMap.action_add_event(action, event)

func _key(code: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = code
	return event

func _mouse(index: MouseButton) -> InputEventMouseButton:
	var event := InputEventMouseButton.new()
	event.button_index = index
	return event

# ---------------------------------------------------------------- 场景切换

func start_new_game() -> void:
	player_state = {}
	gold = 0
	quest_stage = 0
	boss_defeated = false
	free_supply_claimed = false
	active_boss = null
	InventoryManager.reset_inventory()
	DayNightManager.reset_cycle()
	go_to_scene(HUB_SCENE)

func go_to_scene(path: String) -> void:
	capture_player_state()
	get_tree().paused = false
	is_ui_paused = false
	interaction_prompt = ""
	var err := get_tree().change_scene_to_file(path)
	if err != OK:
		push_error("场景切换失败: %s (%d)" % [path, err])

func go_to_hub(restore_full: bool = false) -> void:
	if current_area == "hub":
		return
	if restore_full:
		player_state = {}
	active_boss = null
	go_to_scene(HUB_SCENE)

func go_to_suburb() -> void:
	active_boss = null
	go_to_scene(SUBURB_SCENE)

func go_to_main_menu() -> void:
	capture_player_state()
	active_boss = null
	get_tree().paused = false
	is_ui_paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

# ---------------------------------------------------------------- 玩家状态

func register_player(p: Node) -> void:
	player = p
	player_spawned.emit(p)

func register_area(area: String) -> void:
	current_area = area
	area_changed.emit(area)

func capture_player_state() -> void:
	if is_instance_valid(player) and player.has_method("get_save_state"):
		player_state = player.get_save_state()

func apply_saved_state(p: Node) -> void:
	if player_state.is_empty():
		return
	if p.has_method("apply_save_state"):
		p.apply_save_state(player_state)

func on_player_died() -> void:
	get_tree().paused = true
	player_died.emit()

func respawn_in_hub() -> void:
	player_state = {}
	active_boss = null
	get_tree().paused = false
	is_ui_paused = false
	get_tree().change_scene_to_file(HUB_SCENE)

# ---------------------------------------------------------------- 货币 / 任务

func add_gold(amount: int) -> void:
	gold = max(0, gold + amount)
	currency_changed.emit()

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	currency_changed.emit()
	return true

func get_quest_text() -> String:
	if quest_stage <= 0:
		if current_area == "hub":
			return "主线：从树屋出发，前往城郊居民区"
		return "主线：深入北侧裂隙，击败藤蔓母怪"
	if quest_stage == 1:
		return "主线完成：回树屋向昆特复命"
	return "主线完成"

func notify_quest_changed() -> void:
	quest_changed.emit()

# ---------------------------------------------------------------- Boss

func register_boss(boss: Node) -> void:
	active_boss = boss
	boss_changed.emit(boss)

func update_boss_hp(hp: int, max_hp: int) -> void:
	boss_hp_changed.emit(hp, max_hp)

func clear_boss() -> void:
	active_boss = null
	boss_changed.emit(null)

func notify_boss_defeated() -> void:
	boss_defeated = true
	quest_stage = 1
	clear_boss()
	quest_changed.emit()
	boss_defeated_event.emit()

# ---------------------------------------------------------------- 提示 / 暂停

func show_toast(text: String) -> void:
	toast_requested.emit(text)

func set_prompt(text: String) -> void:
	interaction_prompt = text

func set_ui_paused(paused: bool) -> void:
	is_ui_paused = paused
	get_tree().paused = paused

# ---------------------------------------------------------------- 工具

func yards_to_pixels(yards: float) -> float:
	return yards * YARD

func get_world_rect() -> Rect2:
	if current_area == "hub":
		return WORLD_RECT_HUB
	return WORLD_RECT_SUBURB

func shard_count() -> int:
	return InventoryManager.count_item("void_shard")
