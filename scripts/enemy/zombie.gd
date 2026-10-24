extends BaseEnemy
## 普通僵尸：缓慢追击，近战抓挠。入夜生命 +30%、伤害 +25%。

func _ready() -> void:
	enemy_type = "zombie"
	super._ready()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var sway := sin(t * 3.0 + position.x * 0.01) * 2.0
	var body := flash_color(Color(0.42, 0.47, 0.38))
	var shirt := flash_color(Color(0.32, 0.38, 0.44))
	draw_circle(Vector2(0, 13), 14, Color(0, 0, 0, 0.35))
	draw_elite_aura(16.0)

	# 腿
	draw_line(Vector2(-4, 6), Vector2(-6 + sway, 16), UITheme.BORDER, 5.0)
	draw_line(Vector2(4, 6), Vector2(6 - sway, 16), UITheme.BORDER, 5.0)
	# 躯干
	draw_circle(Vector2(sway * 0.5, 1), 12, shirt)
	draw_arc(Vector2(sway * 0.5, 1), 12, 0, TAU, 24, UITheme.BORDER, 3.0)
	# 头
	draw_circle(Vector2(sway, -10), 8, body)
	draw_arc(Vector2(sway, -10), 8, 0, TAU, 18, UITheme.BORDER, 2.5)
	# 眼与嘴
	draw_circle(Vector2(sway - 3, -11), 1.8, Color(0.05, 0.03, 0.04))
	draw_circle(Vector2(sway + 3, -11), 1.8, Color(0.05, 0.03, 0.04))
	draw_line(Vector2(sway - 3, -6), Vector2(sway + 3, -6), Color(0.2, 0.05, 0.06), 2.0)
	# 前伸的手
	var reach := 18.0 if attack_anim > 0.0 else 13.0
	draw_line(Vector2(0, 2), Vector2(-reach, 4 + sway), UITheme.BORDER, 5.0)
	draw_line(Vector2(0, 2), Vector2(reach, 3 - sway), UITheme.BORDER, 5.0)
	draw_line(Vector2(0, 2), Vector2(-reach, 4 + sway), body, 3.0)
	draw_line(Vector2(0, 2), Vector2(reach, 3 - sway), body, 3.0)
	if attack_anim > 0.0:
		draw_arc(Vector2.ZERO, reach + 4.0, 0, TAU, 16, Color(0.8, 0.2, 0.2, 0.3), 2.0)

	draw_root_vines()
	draw_health_bar(20.0, -30.0)
