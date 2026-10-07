extends SceneTree
## Builds scenes/menu.tscn. Everything in "Canvas" uses the 1920x1080 mockup coordinates.
## godot --headless --path . -s res://tools/build_menu.gd

const WIND := """
shader_type canvas_item;
// grass in the lower part sways by whole source pixels
void fragment() {
	vec2 sz = vec2(textureSize(TEXTURE, 0));
	vec2 p = UV * sz;
	float g = smoothstep(730.0, 1010.0, p.y);
	float off = sin(TIME * 1.4 + p.y * 0.05 + p.x * 0.006) * 3.0 * g;
	p.x += floor(off + 0.5);
	COLOR = texture(TEXTURE, p / sz);
}
"""

var menu: Control


func _init() -> void:
	menu = Control.new()
	menu.name = "Menu"
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	menu.set_script(load("res://scripts/menu.gd"))

	var c := Control.new()
	c.name = "Canvas"
	c.size = Vector2(1920, 1080)
	c.scale = Vector2(0.2, 0.2)
	c.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	menu.add_child(c)

	var bg := TextureRect.new()
	bg.name = "Bg"
	bg.texture = load("res://art/menu/bg.png")
	bg.size = Vector2(1920, 1080)
	var sh := Shader.new()
	sh.code = WIND
	var mat := ShaderMaterial.new()
	mat.shader = sh
	bg.material = mat
	c.add_child(bg)

	# logo leaf, pivot on its stem
	var leaf := Sprite2D.new()
	leaf.name = "LogoLeaf"
	leaf.texture = load("res://art/menu/logo_leaf.png")
	leaf.centered = false
	leaf.offset = Vector2(-72, -172)
	leaf.position = Vector2(380 + 72, 80 + 172)
	c.add_child(leaf)

	c.add_child(_motes())
	c.add_child(_leaves())

	var ys := [471, 565, 658, 752]
	var names := ["New", "Continue", "Settings", "Exit"]
	for i in 4:
		var b := TextureButton.new()
		b.name = names[i]
		b.position = Vector2(102, ys[i])
		b.texture_normal = load("res://art/menu/btn%d.png" % i)
		b.texture_hover = load("res://art/menu/btn%d_hover.png" % i)
		b.texture_focused = load("res://art/menu/btn%d_hover.png" % i)
		b.texture_pressed = load("res://art/menu/btn%d_pressed.png" % i)
		b.texture_disabled = load("res://art/menu/btn%d_disabled.png" % i)
		c.add_child(b)
	for i in 4:     # keyboard focus order
		var b: TextureButton = c.get_node(names[i])
		b.focus_neighbor_top = NodePath("../" + names[(i + 3) % 4])
		b.focus_neighbor_bottom = NodePath("../" + names[(i + 1) % 4])

	var marker := Sprite2D.new()
	marker.name = "Marker"
	marker.texture = load("res://art/menu/leaf_big.png")
	marker.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	marker.position = Vector2(78, 513)
	c.add_child(marker)

	var panel := Control.new()
	panel.name = "SettingsPanel"
	panel.set_script(load("res://scripts/settings_panel.gd"))
	menu.add_child(panel)

	var fade := ColorRect.new()
	fade.name = "Fade"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(fade)

	for s in [["Hover", "res://sfx/blip.wav", -12.0], ["Click", "res://sfx/step.wav", -2.0]]:
		var p := AudioStreamPlayer.new()
		p.name = s[0]
		p.stream = load(s[1])
		p.volume_db = s[2]
		p.bus = "SFX"
		menu.add_child(p)

	_own(menu)
	var ps := PackedScene.new()
	var err := ps.pack(menu)
	if err == OK:
		err = ResourceSaver.save(ps, "res://scenes/menu.tscn")
	print("build_menu: ", "ok" if err == OK else "error %d" % err)
	menu.free()
	quit()


func _own(n: Node) -> void:
	for ch in n.get_children():
		ch.owner = menu
		_own(ch)


func _mask(path: String) -> BitMap:
	var bm := BitMap.new()
	bm.create_from_image_alpha((load(path) as Texture2D).get_image())
	return bm


func _fade_ramp(col: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(col, 0.0))
	g.set_color(1, Color(col, 0.0))
	g.add_point(0.25, col)
	g.add_point(0.75, col)
	return g


func _leaves() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Leaves"
	p.local_coords = true
	p.texture = load("res://art/menu/leaf.png")
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.position = Vector2(700, -60)
	p.amount = 12
	p.lifetime = 16.0
	p.preprocess = 16.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(1100, 30)
	p.direction = Vector2(1, 0.7)
	p.spread = 20.0
	p.gravity = Vector2(8, 22)
	p.initial_velocity_min = 50.0
	p.initial_velocity_max = 100.0
	p.angular_velocity_min = -80.0
	p.angular_velocity_max = 80.0
	p.angle_min = 0.0
	p.angle_max = 360.0
	p.scale_amount_min = 5.0
	p.scale_amount_max = 7.0
	p.color_ramp = _fade_ramp(Color(1, 1, 1, 1))
	return p


func _motes() -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = "Motes"
	p.local_coords = true
	p.texture = load("res://art/menu/mote.png")
	p.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	p.position = Vector2(1100, 820)
	p.amount = 34
	p.lifetime = 9.0
	p.preprocess = 9.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(900, 240)
	p.direction = Vector2(0.3, -1)
	p.spread = 30.0
	p.gravity = Vector2(4, -3)
	p.initial_velocity_min = 6.0
	p.initial_velocity_max = 18.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	p.color_ramp = _fade_ramp(Color(1, 0.98, 0.85, 0.7))
	return p
