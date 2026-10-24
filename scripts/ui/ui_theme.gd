class_name UITheme
extends RefCounted
## 原型统一 UI 风格：暗黑底色 + 涂鸦粗描边 + 少年末世配色。

const BG := Color(0.043, 0.039, 0.055, 1.0)
const PANEL_BG := Color(0.082, 0.071, 0.098, 0.97)
const PANEL_BG_SOFT := Color(0.11, 0.094, 0.13, 0.97)
const BORDER := Color(0.04, 0.035, 0.05, 1.0)
const BORDER_LIGHT := Color(0.42, 0.34, 0.5, 1.0)
const TEXT := Color(0.91, 0.87, 0.8, 1.0)
const MUTED := Color(0.6, 0.55, 0.65, 1.0)
const HP := Color(0.78, 0.21, 0.25, 1.0)
const SANITY := Color(0.55, 0.36, 0.96, 1.0)
const EXP := Color(0.88, 0.54, 0.18, 1.0)
const GOLD := Color(0.95, 0.76, 0.31, 1.0)
const VOID := Color(0.71, 0.42, 1.0, 1.0)
const ELITE := Color(0.8, 0.35, 1.0, 1.0)
const DANGER := Color(0.9, 0.28, 0.3, 1.0)

static func panel_style(bg: Color = PANEL_BG, border_color: Color = BORDER, border_width: int = 3, radius: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	return style

static func make_panel(bg: Color = PANEL_BG, border_color: Color = BORDER_LIGHT, border_width: int = 3) -> Panel:
	var panel := Panel.new()
	panel.add_theme_stylebox_override("panel", panel_style(bg, border_color, border_width))
	return panel

static func make_label(text: String, font_size: int = 20, color: Color = TEXT) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", font_size)
	return label

static func make_title(text: String, font_size: int = 34, color: Color = GOLD) -> Label:
	var label := make_label(text, font_size, color)
	label.add_theme_constant_override("outline_size", 6)
	label.add_theme_color_override("font_outline_color", BORDER)
	return label

static func apply_button(button: Button, font_size: int = 22, accent: Color = GOLD) -> void:
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", TEXT)
	button.add_theme_color_override("font_hover_color", accent)
	button.add_theme_color_override("font_pressed_color", BG)
	button.add_theme_color_override("font_disabled_color", MUTED.darkened(0.3))
	button.add_theme_stylebox_override("normal", panel_style(PANEL_BG_SOFT, BORDER, 3, 3))
	button.add_theme_stylebox_override("hover", panel_style(PANEL_BG_SOFT.lightened(0.1), accent, 3, 3))
	button.add_theme_stylebox_override("pressed", panel_style(accent.darkened(0.25), BORDER, 3, 3))
	button.add_theme_stylebox_override("disabled", panel_style(PANEL_BG.darkened(0.15), MUTED.darkened(0.4), 2, 3))
	button.add_theme_stylebox_override("focus", panel_style(Color.TRANSPARENT, accent, 2, 3))

static func make_button(text: String, font_size: int = 22, accent: Color = GOLD) -> Button:
	var button := Button.new()
	button.text = text
	apply_button(button, font_size, accent)
	return button

static func style_progress(bar: ProgressBar, fill_color: Color) -> void:
	var bg := panel_style(Color(0.045, 0.04, 0.055, 0.95), BORDER, 2, 2)
	bg.content_margin_left = 0
	bg.content_margin_right = 0
	bg.content_margin_top = 0
	bg.content_margin_bottom = 0
	var fill := panel_style(fill_color, fill_color.lightened(0.25), 1, 1)
	fill.content_margin_left = 0
	fill.content_margin_right = 0
	fill.content_margin_top = 0
	fill.content_margin_bottom = 0
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	bar.show_percentage = false
