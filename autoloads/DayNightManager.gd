extends Node
## 昼夜循环：120 秒完整周期。
## 白天 0~75s / 黄昏预警 75~85s / 黑夜 85~120s。
## 仅在城郊战斗地图推进；树屋与主菜单不计时。

signal dusk_started
signal night_started
signal day_returned

enum TIME_STATE {DAY, DUSK, NIGHT}

const CYCLE_TOTAL: float = 120.0
const DAY_END: float = 75.0
const DUSK_END: float = 85.0

var current_time: float = 0.0
var current_state: TIME_STATE = TIME_STATE.DAY

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _process(delta: float) -> void:
	if GameManager.current_area != "suburb":
		return
	current_time += delta
	if current_time >= CYCLE_TOTAL:
		current_time = fmod(current_time, CYCLE_TOTAL)
	_enter_state_for_time()

func _enter_state_for_time() -> void:
	var next_state := TIME_STATE.DAY
	if current_time >= DUSK_END:
		next_state = TIME_STATE.NIGHT
	elif current_time >= DAY_END:
		next_state = TIME_STATE.DUSK
	if next_state == current_state:
		return
	current_state = next_state
	match current_state:
		TIME_STATE.DAY:
			day_returned.emit()
		TIME_STATE.DUSK:
			dusk_started.emit()
		TIME_STATE.NIGHT:
			night_started.emit()

func reset_cycle() -> void:
	current_time = 0.0
	if current_state != TIME_STATE.DAY:
		current_state = TIME_STATE.DAY
		day_returned.emit()

func is_night() -> bool:
	return current_state == TIME_STATE.NIGHT

func is_dark() -> bool:
	return current_state != TIME_STATE.DAY

func get_state_name() -> String:
	match current_state:
		TIME_STATE.DAY:
			return "白天"
		TIME_STATE.DUSK:
			return "黄昏"
		_:
			return "黑夜"

## 僵尸入夜生命 +30%
func get_zombie_hp_mod() -> float:
	return 1.3 if current_state == TIME_STATE.NIGHT else 1.0

## 僵尸入夜伤害 +25%
func get_zombie_damage_mod() -> float:
	return 1.25 if current_state == TIME_STATE.NIGHT else 1.0

## 飞戾怪入夜攻击频率 +30%（返回间隔倍率，需除以它）
func get_wretch_attack_speed_mod() -> float:
	return 1.3 if current_state == TIME_STATE.NIGHT else 1.0

## 黄昏起怪物移速 +20%
func get_enemy_speed_mod() -> float:
	return 1.2 if is_dark() else 1.0

## 黄昏起杰克移速 -0.4 码/秒
func get_player_speed_penalty() -> float:
	return 0.4 if is_dark() else 0.0

## 兼容早期接口名
func get_night_damage_mod() -> float:
	return get_zombie_damage_mod()

func get_cycle_progress() -> float:
	return current_time / CYCLE_TOTAL

func get_time_label() -> String:
	return "%s  %02d:%02d" % [
		get_state_name(),
		int(current_time) / 60,
		int(current_time) % 60
	]

func get_seconds_until_dusk() -> float:
	if current_state == TIME_STATE.DAY:
		return max(0.0, DAY_END - current_time)
	return 0.0
