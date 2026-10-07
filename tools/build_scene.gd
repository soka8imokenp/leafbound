extends SceneTree
## Builds scenes/main.tscn (Anzu's room) from the art in res://art.
## godot --headless --path . -s res://tools/build_scene.gd
## Coordinates are room pixels (room_bg.png is 256x256, native pixel size).

var main_root: Node2D


func _init() -> void:
	main_root = Node2D.new()
	main_root.name = "Main"
	main_root.set_script(load("res://scripts/main.gd"))

	var tint := CanvasModulate.new()
	tint.name = "Tint"
	tint.color = Color(0.84, 0.78, 0.74)
	main_root.add_child(tint)

	var bg := Sprite2D.new()
	bg.name = "Room"
	bg.texture = load("res://art/room_bg.png")
	bg.centered = false
	bg.z_index = -10
	main_root.add_child(bg)

	# window panes go dark at night (overlay over the baked bright window)
	var glass := ColorRect.new()
	glass.name = "NightGlass"
	glass.position = Vector2(107, 42)
	glass.size = Vector2(38, 30)
	glass.color = Color(0.08, 0.1, 0.22, 0.0)
	glass.z_index = -9
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	main_root.add_child(glass)

	var led := ColorRect.new()
	led.name = "RadioLed"
	led.position = Vector2(121, 87)
	led.size = Vector2(1, 1)
	led.color = Color(0.55, 1.0, 0.45)
	led.z_index = -9
	main_root.add_child(led)

	var world := Node2D.new()
	world.name = "World"
	world.y_sort_enabled = true
	main_root.add_child(world)

	_walls()
	_props(world)
	world.add_child(_player())
	_interactables()
	_atmosphere()

	var cam := Camera2D.new()
	cam.name = "Camera"
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	main_root.add_child(cam)

	var radio := _sfx2d("RadioStatic", "res://sfx/static.wav", -6.0)
	radio.position = Vector2(114, 88)
	main_root.add_child(radio)

	main_root.add_child(_ui())

	_own(main_root)
	var ps := PackedScene.new()
	var err := ps.pack(main_root)
	if err == OK:
		err = ResourceSaver.save(ps, "res://scenes/main.tscn")
	print("build_scene: ", "ok" if err == OK else "error %d" % err)
	main_root.free()
	quit()


func _own(n: Node) -> void:
	for c in n.get_children():
		c.owner = main_root
		_own(c)


# ---------------------------------------------------------------- helpers
func _rect(size: Vector2) -> RectangleShape2D:
	var s := RectangleShape2D.new()
	s.size = size
	return s


func _body(name: String, pos: Vector2, shape_center: Vector2, shape_size: Vector2) -> StaticBody2D:
	var b := StaticBody2D.new()
	b.name = name
	b.position = pos
	var cs := CollisionShape2D.new()
	cs.name = "Shape"
	cs.shape = _rect(shape_size)
	cs.position = shape_center - pos
	b.add_child(cs)
	return b


func _sprite(tex: String, offset: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.name = "Sprite"
	s.texture = load(tex)
	s.centered = false
	s.position = offset
	return s


func _frames(tex_path: String, w: int, h: int, anims: Array) -> SpriteFrames:
	## anims: [[name, row, count, fps, loop], ...]
	var tex: Texture2D = load(tex_path)
	var sf := SpriteFrames.new()
	sf.remove_animation("default")
	for a in anims:
		sf.add_animation(a[0])
		sf.set_animation_speed(a[0], a[3])
		sf.set_animation_loop(a[0], a[4])
		for i in a[2]:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * w, a[1] * h, w, h)
			sf.add_frame(a[0], at)
	return sf


func _radial(size: int, inner: Color) -> GradientTexture2D:
	var g := Gradient.new()
	g.set_color(0, inner)
	g.set_color(1, Color(inner, 0.0))
	var t := GradientTexture2D.new()
	t.gradient = g
	t.width = size
	t.height = size
	t.fill = GradientTexture2D.FILL_RADIAL
	t.fill_from = Vector2(0.5, 0.5)
	t.fill_to = Vector2(1.0, 0.5)
	return t


func _fade_ramp(c: Color, peak := 0.2) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, Color(c, 0.0))
	g.set_color(1, Color(c, 0.0))
	g.add_point(peak, c)
	return g


func _sfx2d(name: String, path: String, db: float) -> AudioStreamPlayer2D:
	var p := AudioStreamPlayer2D.new()
	p.name = name
	p.stream = load(path)
	p.volume_db = db
	p.max_distance = 260.0
	p.bus = "SFX"
	return p


# ---------------------------------------------------------------- room
func _walls() -> void:
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	var pts := [Vector2(44, 95), Vector2(208, 95), Vector2(236, 238), Vector2(24, 238)]
	for i in pts.size():
		var seg := SegmentShape2D.new()
		seg.a = pts[i]
		seg.b = pts[(i + 1) % pts.size()]
		var cs := CollisionShape2D.new()
		cs.name = "Edge%d" % i
		cs.shape = seg
		walls.add_child(cs)
	# furniture baked into the background
	for b in [["Nightstand", Vector2(115, 104), Vector2(28, 18)],
			["Shelf", Vector2(216, 130), Vector2(26, 76)],
			["Door", Vector2(214, 234), Vector2(46, 10)]]:
		var cs := CollisionShape2D.new()
		cs.name = b[0]
		cs.shape = _rect(b[2])
		cs.position = b[1]
		walls.add_child(cs)
	main_root.add_child(walls)


func _props(world: Node2D) -> void:
	# bed 64x96, sprite top-left (33,72), sorted by its foot (65,168)
	var bed := _body("Bed", Vector2(65, 168), Vector2(66, 130), Vector2(60, 72))
	bed.add_child(_sprite("res://art/ase/bed_0.png", Vector2(-32, -96)))
	# Anzu asleep: her head on the pillow, the quilt edge pulled up to the chin (hidden until a nap)
	var sleeper := Node2D.new()
	sleeper.name = "Sleeper"
	sleeper.position = Vector2(-32, -96)
	sleeper.visible = false
	var head := _sprite("res://art/anzu_sleep.png", Vector2(0, 9))
	head.name = "Head"
	head.scale = Vector2(0.5, 0.5)
	head.self_modulate = Color(1.12, 1.1, 1.08)
	sleeper.add_child(head)
	var blanket := _sprite("res://art/bed_blanket.png", Vector2(0, 0))
	blanket.name = "Blanket"
	sleeper.add_child(blanket)
	var sz := CPUParticles2D.new()
	sz.name = "Zzz"
	sz.texture = load("res://art/z.png")
	sz.position = Vector2(46, 14)
	sz.amount = 3
	sz.lifetime = 2.6
	sz.direction = Vector2(0.6, -1)
	sz.spread = 12.0
	sz.gravity = Vector2(0, 0)
	sz.initial_velocity_min = 5.0
	sz.initial_velocity_max = 6.0
	sz.scale_amount_min = 0.7
	sz.scale_amount_max = 1.1
	sz.color_ramp = _fade_ramp(Color(1, 1, 1, 0.85), 0.3)
	sleeper.add_child(sz)
	bed.add_child(sleeper)
	world.add_child(bed)

	var table := _body("Table", Vector2(98, 240), Vector2(98, 216), Vector2(92, 36))
	table.add_child(_sprite("res://art/ase/table_0.png", Vector2(-48, -64)))
	world.add_child(table)

	# stove 32x64 at (146,62), fire animation, glow, steam, crackle
	var stove := _body("Stove", Vector2(162, 126), Vector2(162, 110), Vector2(34, 24))
	stove.set_script(load("res://scripts/stove.gd"))
	var fire := AnimatedSprite2D.new()
	fire.name = "Fire"
	fire.sprite_frames = _frames("res://art/stove_fire.png", 32, 64, [["fire", 0, 4, 7.0, true]])
	fire.centered = false
	fire.position = Vector2(-16, -64)
	fire.autoplay = "fire"
	stove.add_child(fire)
	var glow := PointLight2D.new()
	glow.name = "Glow"
	glow.texture = _radial(128, Color(1, 1, 1))
	glow.color = Color(1.0, 0.55, 0.25)
	glow.energy = 0.5
	glow.texture_scale = 0.85
	glow.position = Vector2(-1, -25)
	stove.add_child(glow)
	stove.add_child(_steam("Steam", 24, false))
	stove.add_child(_steam("SteamBurst", 26, true))
	var crackle := _sfx2d("Crackle", "res://sfx/crackle.wav", -4.0)
	crackle.autoplay = true
	stove.add_child(crackle)
	world.add_child(stove)

	# cat 32x32 at (154,124)
	var cat := _body("Cat", Vector2(170, 152), Vector2(170, 141), Vector2(28, 14))
	cat.set_script(load("res://scripts/cat.gd"))
	var cs := AnimatedSprite2D.new()
	cs.name = "Sprite"
	cs.sprite_frames = _frames("res://art/cat_breath.png", 32, 32, [["breath", 0, 4, 1.6, true]])
	cs.centered = false
	cs.position = Vector2(-16, -28)
	cat.add_child(cs)
	var z := CPUParticles2D.new()
	z.name = "Zzz"
	z.texture = load("res://art/z.png")
	z.position = Vector2(-8, -24)
	z.amount = 2
	z.lifetime = 3.2
	z.direction = Vector2(0.5, -1)
	z.spread = 10.0
	z.gravity = Vector2(0, 0)
	z.initial_velocity_min = 4.0
	z.initial_velocity_max = 5.0
	z.scale_amount_min = 0.6
	z.scale_amount_max = 1.0
	z.color_ramp = _fade_ramp(Color(1, 1, 1, 0.75), 0.3)
	cat.add_child(z)
	var hearts := CPUParticles2D.new()
	hearts.name = "Hearts"
	hearts.texture = load("res://art/heart.png")
	hearts.position = Vector2(-2, -20)
	hearts.emitting = false
	hearts.one_shot = true
	hearts.amount = 5
	hearts.lifetime = 1.6
	hearts.explosiveness = 0.6
	hearts.direction = Vector2(0, -1)
	hearts.spread = 50.0
	hearts.gravity = Vector2(0, 6)
	hearts.initial_velocity_min = 14.0
	hearts.initial_velocity_max = 20.0
	hearts.color_ramp = _fade_ramp(Color(1, 1, 1, 1), 0.1)
	cat.add_child(hearts)
	cat.add_child(_sfx2d("Purr", "res://sfx/purr.wav", 0.0))
	world.add_child(cat)


func _steam(name: String, amount: int, burst: bool) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.name = name
	p.texture = load("res://art/px2.png")
	p.position = Vector2(-7, -48)            # kettle spout
	p.amount = amount
	p.lifetime = 2.4
	p.one_shot = burst
	p.emitting = not burst
	p.explosiveness = 0.5 if burst else 0.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	p.emission_sphere_radius = 1.0
	p.direction = Vector2(-0.3, -1)
	p.spread = 14.0
	p.gravity = Vector2(1.5, -5)
	p.initial_velocity_min = 5.0 if not burst else 9.0
	p.initial_velocity_max = 9.0 if not burst else 15.0
	p.scale_amount_min = 1.0
	p.scale_amount_max = 2.0
	p.color_ramp = _fade_ramp(Color(1, 1, 1, 0.7), 0.12)
	return p


func _player() -> CharacterBody2D:
	var p := CharacterBody2D.new()
	p.name = "Player"
	p.position = Vector2(128, 186)
	p.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	p.set_script(load("res://scripts/player.gd"))
	var sh := Sprite2D.new()
	sh.name = "Shadow"
	sh.texture = load("res://art/shadow.png")
	sh.position = Vector2(0, -1)
	p.add_child(sh)
	var spr := AnimatedSprite2D.new()
	spr.name = "Sprite"
	# Anzu at her native 128 px art, drawn at half size: every original pixel stays visible
	spr.sprite_frames = _frames("res://art/anzu_sheet_hd.png", 128, 128, [
		["down_idle", 0, 2, 1.5, true], ["down_walk", 1, 4, 8.0, true],
		["up_idle", 2, 2, 1.5, true], ["up_walk", 3, 4, 8.0, true],
		["side_idle", 4, 2, 1.5, true], ["side_walk", 5, 4, 8.0, true]])
	spr.scale = Vector2(0.5, 0.5)
	spr.offset = Vector2(0, -57)              # feet (row 121 of 128) on the node origin
	spr.self_modulate = Color(1.12, 1.1, 1.08)   # keep her colours above the warm room tint
	p.add_child(spr)
	var cs := CollisionShape2D.new()
	cs.name = "Feet"
	cs.shape = _rect(Vector2(10, 5))
	cs.position = Vector2(0, -2)
	p.add_child(cs)
	var reach := Area2D.new()
	reach.name = "Reach"
	reach.collision_layer = 0
	reach.collision_mask = 2
	var rs := CollisionShape2D.new()
	rs.name = "Shape"
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	rs.shape = circle
	reach.add_child(rs)
	p.add_child(reach)
	var prompt := Node2D.new()
	prompt.name = "Prompt"
	prompt.position = Vector2(0, -66)
	prompt.visible = false
	prompt.z_index = 20
	var key := Sprite2D.new()
	key.name = "Key"
	key.texture = load("res://art/key_e.png")
	key.position = Vector2(0, 0)
	prompt.add_child(key)
	var lbl := Label.new()
	lbl.name = "Label"
	lbl.position = Vector2(-40, 5)
	lbl.size = Vector2(80, 10)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_override("font", load("res://fonts/Rubik.ttf"))
	lbl.add_theme_font_size_override("font_size", 6)
	lbl.add_theme_color_override("font_color", Color(1, 0.96, 0.88))
	lbl.add_theme_color_override("font_outline_color", Color(0.18, 0.1, 0.07))
	lbl.add_theme_constant_override("outline_size", 2)
	prompt.add_child(lbl)
	p.add_child(prompt)
	var step := _sfx2d("Step", "res://sfx/step.wav", -10.0)
	p.add_child(step)
	return p


func _interactables() -> void:
	var items := Node2D.new()
	items.name = "Interactables"
	main_root.add_child(items)
	var data := [
		["Bed", "Кровать", Vector2(66, 136), Vector2(68, 70), "sleep", [
			"Лоскутное одеяло. Каждый лоскут — из чьей-то старой рубашки.",
			"Анзу: Прилягу ненадолго..."]],
		["Radio", "Радио", Vector2(115, 117), Vector2(30, 10), "radio", [
			"Старое радио тихо шипит.",
			"...ш-ш-ш... кх... сиг...нал... ш-ш...",
			"Анзу: Пико говорит, сквозь помехи иногда слышно Землю.",
			"Анзу: ...Сегодня она молчит."]],
		["Window", "Окно", Vector2(137, 100), Vector2(14, 10), "", [
			"За окном — руины города, оплетённые корнями.",
			"Анзу: Если ты слышишь — значит, оно живо."]],
		["StoveUse", "Печка", Vector2(162, 128), Vector2(44, 12), "stove", [
			"Печка потрескивает. Пахнет смолой и травяным чаем.",
			"Анзу: Чайник вот-вот закипит!"]],
		["CatPet", "Рыжик", Vector2(170, 145), Vector2(40, 26), "pet", [
			"Рыжик спит, свернувшись клубком.",
			"Анзу: Рыжик тёплый-тёплый... Мягкий!",
			"Мрр-р-р..."]],
		["ShelfLook", "Полка", Vector2(201, 130), Vector2(10, 76), "", [
			"Склянки с семенами и сушёными травами.",
			"На каждой — подпись детским почерком.",
			"Анзу: Это Анзу подписывала! Красиво же?"]],
		["TableUse", "Стол", Vector2(98, 214), Vector2(104, 46), "", [
			"Хлеб ещё тёплый. И чашка травяного чая.",
			"Анзу отламывает кусочек.",
			"Анзу: М-м! Вкусно!"]],
		["DoorUse", "Дверь", Vector2(212, 224), Vector2(46, 16), "", [
			"Анзу: Пико просил дождаться его дома.",
			"Анзу: ...Ладно. Ещё немного."]],
		["Scarf", "Шарф", Vector2(34, 194), Vector2(16, 30), "", [
			"Тёплый шарф. Его связали очень давно, ещё до Нексара.",
			"Анзу: Пахнет бабушкой..."]],
		["Shoes", "Ботинки", Vector2(162, 217), Vector2(28, 20), "", [
			"Старые ботинки. Уже малы, но выбросить жалко.",
			"Анзу: Анзу тогда была совсем маленькая!"]],
	]
	for d in data:
		var a := Area2D.new()
		a.name = d[0]
		a.position = d[2]
		a.collision_layer = 2
		a.collision_mask = 0
		a.monitoring = false
		a.set_script(load("res://scripts/interactable.gd"))
		a.set("title", d[1])
		a.set("action", d[4])
		a.set("text", "\n".join(PackedStringArray(d[5])))
		var cs := CollisionShape2D.new()
		cs.name = "Shape"
		cs.shape = _rect(d[3])
		a.add_child(cs)
		items.add_child(a)


func _atmosphere() -> void:
	var wl := PointLight2D.new()
	wl.name = "WindowLight"
	wl.texture = _radial(128, Color(1, 1, 1))
	wl.color = Color(1.0, 0.9, 0.68)
	wl.energy = 0.2
	wl.texture_scale = 1.0
	wl.position = Vector2(122, 132)
	main_root.add_child(wl)
	var dust := CPUParticles2D.new()
	dust.name = "Dust"
	dust.texture = load("res://art/px2.png")
	dust.position = Vector2(120, 132)
	dust.amount = 18
	dust.lifetime = 7.0
	dust.preprocess = 7.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(22, 40)
	dust.direction = Vector2(0.4, 1)
	dust.spread = 60.0
	dust.gravity = Vector2(0, 0.6)
	dust.initial_velocity_min = 0.5
	dust.initial_velocity_max = 2.0
	dust.scale_amount_min = 0.5
	dust.scale_amount_max = 0.5
	dust.color_ramp = _fade_ramp(Color(1, 0.95, 0.75, 0.7), 0.5)
	dust.z_index = 5
	main_root.add_child(dust)


# ---------------------------------------------------------------- UI
func _ui() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.name = "UI"
	var font: Font = load("res://fonts/Rubik.ttf")

	var dlg := Control.new()
	dlg.name = "Dialog"
	dlg.set_script(load("res://scripts/dialog.gd"))
	dlg.set_anchors_preset(Control.PRESET_FULL_RECT)
	dlg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(dlg)

	var box := Panel.new()
	box.name = "Box"
	box.position = Vector2(28, 158)
	box.size = Vector2(328, 50)
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.16, 0.11, 0.08, 0.94)
	sb.border_color = Color(0.72, 0.52, 0.3)
	sb.set_border_width_all(2)
	sb.set_corner_radius_all(3)
	box.add_theme_stylebox_override("panel", sb)
	dlg.add_child(box)

	var text := Label.new()
	text.name = "Text"
	text.position = Vector2(10, 7)
	text.size = Vector2(306, 38)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.add_theme_font_override("font", font)
	text.add_theme_font_size_override("font_size", 9)
	text.add_theme_color_override("font_color", Color(0.98, 0.93, 0.84))
	box.add_child(text)

	var tag := Panel.new()
	tag.name = "NameTag"
	tag.position = Vector2(8, -9)
	tag.size = Vector2(36, 12)
	var sb2 := StyleBoxFlat.new()
	sb2.bg_color = Color(0.55, 0.3, 0.14)
	sb2.border_color = Color(0.72, 0.52, 0.3)
	sb2.set_border_width_all(1)
	sb2.set_corner_radius_all(2)
	tag.add_theme_stylebox_override("panel", sb2)
	box.add_child(tag)
	var nl := Label.new()
	nl.name = "Label"
	nl.position = Vector2(0, 0)
	nl.size = Vector2(36, 12)
	nl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	nl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	nl.add_theme_font_override("font", font)
	nl.add_theme_font_size_override("font_size", 7)
	nl.add_theme_color_override("font_color", Color(1, 0.95, 0.85))
	tag.add_child(nl)

	var arrow := Label.new()
	arrow.name = "Arrow"
	arrow.text = "▼"
	arrow.position = Vector2(314, 36)
	arrow.add_theme_font_override("font", font)
	arrow.add_theme_font_size_override("font_size", 6)
	arrow.add_theme_color_override("font_color", Color(0.85, 0.65, 0.4))
	box.add_child(arrow)

	var blip := AudioStreamPlayer.new()
	blip.name = "Blip"
	blip.stream = load("res://sfx/blip.wav")
	blip.volume_db = -14.0
	blip.bus = "SFX"
	dlg.add_child(blip)
	var voice := AudioStreamPlayer.new()
	voice.name = "Voice"
	voice.bus = "SFX"
	voice.volume_db = 0.0
	dlg.add_child(voice)

	var hint := Label.new()
	hint.name = "Hint"
	hint.text = "WASD / стрелки — ходить     E — действие     Esc — пауза"
	hint.position = Vector2(6, 4)
	hint.add_theme_font_override("font", font)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.55))
	layer.add_child(hint)

	var fade := ColorRect.new()
	fade.name = "Fade"
	fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	fade.color = Color(0, 0, 0, 1)
	fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(fade)

	var confirm := Control.new()
	confirm.name = "Confirm"
	confirm.set_script(load("res://scripts/confirm.gd"))
	layer.add_child(confirm)

	var pause := Control.new()
	pause.name = "Pause"
	pause.set_script(load("res://scripts/pause_menu.gd"))
	layer.add_child(pause)
	return layer
