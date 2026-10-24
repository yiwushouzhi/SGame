extends BaseEnemy
## 藤蔓母怪召唤的小藤蔓：低血量近战杂兵。

func _ready() -> void:
	enemy_type = "vine_spawn"
	super._ready()

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var wobble := sin(t * 5.0 + position.x * 0.02) * 3.0
	var body := flash_color(Color(0.28, 0.42, 0.18))
	draw_circle(Vector2(0, 16), 13, Color(0, 0, 0, 0.3))
	draw_elite_aura(14.0)

	for i in range(5):
		var angle := TAU * float(i) / 5.0 + t * 0.4
		var start := Vector2(cos(angle), sin(angle)) * 5.0
		var end := Vector2(cos(angle + wobble * 0.03), sin(angle)) * 18.0 + Vector2(0, 4)
		draw_line(start, end, Color(0.22, 0.32, 0.12), 4.0)
		draw_circle(end, 3.0, Color(0.38, 0.55, 0.2))
	draw_circle(Vector2(0, 2), 11, body)
	draw_arc(Vector2(0, 2), 11, 0, TAU, 20, UITheme.BORDER, 3.0)
	draw_circle(Vector2(-3, -2), 1.8, Color(0.9, 0.3, 0.25))
	draw_circle(Vector2(3, -2), 1.8, Color(0.9, 0.3, 0.25))
	if attack_anim > 0.0:
		draw_arc(Vector2.ZERO, 20.0, 0, TAU, 16, Color(0.5, 0.9, 0.3, 0.35), 2.0)

	draw_root_vines()
	draw_health_bar(16.0, -28.0)
