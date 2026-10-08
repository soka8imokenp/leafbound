class_name UiKit
## Shared look for menus: moss-stone planks from the menu mockup, dark text.
## Panels live in a 1920x1080 "canvas" scaled to the 384x216 base viewport (scale 0.2).

const TEXT := Color(0.17, 0.21, 0.15)
const FONT := preload("res://fonts/Rubik.ttf")
const PLANK := preload("res://art/menu/plank.png")
const PLANK_HOVER := preload("res://art/menu/plank_hover.png")


static func canvas(name: String) -> Control:
	var c := Control.new()
	c.name = name
	c.size = Vector2(1920, 1080)
	c.scale = Vector2(0.25, 0.25)
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return c


static func plank_box(tex: Texture2D) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = tex
	s.set_texture_margin_all(30)
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.content_margin_left = 30
	s.content_margin_right = 30
	return s


static func panel(pos: Vector2, size: Vector2) -> NinePatchRect:
	var p := NinePatchRect.new()
	p.name = "Panel"
	p.texture = PLANK
	p.patch_margin_left = 34
	p.patch_margin_right = 34
	p.patch_margin_top = 30
	p.patch_margin_bottom = 30
	p.axis_stretch_horizontal = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	p.axis_stretch_vertical = NinePatchRect.AXIS_STRETCH_MODE_TILE_FIT
	p.position = pos
	p.size = size
	return p


static func label(text: String, size: int, pos: Vector2, width: float, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, size * 1.4)
	l.horizontal_alignment = align
	l.add_theme_font_override("font", FONT)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", TEXT)
	return l


static func button(text: String, pos: Vector2, size: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.position = pos
	b.size = size
	b.add_theme_font_override("font", FONT)
	b.add_theme_font_size_override("font_size", 40)
	for c in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, TEXT)
	b.add_theme_color_override("font_disabled_color", Color(TEXT, 0.4))
	b.add_theme_stylebox_override("normal", plank_box(PLANK))
	b.add_theme_stylebox_override("hover", plank_box(PLANK_HOVER))
	b.add_theme_stylebox_override("focus", plank_box(PLANK_HOVER))
	b.add_theme_stylebox_override("pressed", plank_box(PLANK))
	b.add_theme_stylebox_override("disabled", plank_box(PLANK))
	b.mouse_entered.connect(func():
		if not b.disabled:
			b.grab_focus()
	)
	return b


static func slider(pos: Vector2, width: float, value: float) -> HSlider:
	var s := HSlider.new()
	s.position = pos
	s.size = Vector2(width, 40)
	s.min_value = 0.0
	s.max_value = 1.0
	s.step = 0.05
	s.value = value
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.17, 0.21, 0.15, 0.85)
	track.set_corner_radius_all(6)
	track.content_margin_top = 8
	track.content_margin_bottom = 8
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(0.45, 0.62, 0.3)
	fill.set_corner_radius_all(6)
	s.add_theme_stylebox_override("slider", track)
	s.add_theme_stylebox_override("grabber_area", fill)
	s.add_theme_stylebox_override("grabber_area_highlight", fill)
	var g: Texture2D = load("res://art/menu/leaf_big.png")
	s.add_theme_icon_override("grabber", g)
	s.add_theme_icon_override("grabber_highlight", g)
	s.mouse_entered.connect(func(): s.grab_focus())
	return s
