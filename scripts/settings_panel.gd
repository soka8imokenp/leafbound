extends Control
## "SOZLAMALAR": music / sound volume, fullscreen. Esc or ORQAGA closes.

@onready var settings: Node = get_node("/root/Settings")

signal closed

var first: Control
var fs: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.07, 0.05, 0.55)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := UiKit.canvas("Canvas")
	add_child(c)
	c.add_child(UiKit.panel(Vector2(460, 210), Vector2(1000, 660)))
	c.add_child(UiKit.label("SOZLAMALAR", 64, Vector2(460, 260), 1000, HORIZONTAL_ALIGNMENT_CENTER))

	c.add_child(UiKit.label("Musiqa", 44, Vector2(560, 390), 300))
	var mus := UiKit.slider(Vector2(880, 400), 460, settings.music_vol)
	mus.value_changed.connect(_on_music)
	c.add_child(mus)

	c.add_child(UiKit.label("Ovozlar", 44, Vector2(560, 490), 300))
	var sfx := UiKit.slider(Vector2(880, 500), 460, settings.sfx_vol)
	sfx.value_changed.connect(_on_sfx)
	c.add_child(sfx)

	c.add_child(UiKit.label("To'liq ekran", 44, Vector2(560, 590), 320))
	fs = UiKit.button("", Vector2(880, 575), Vector2(300, 84))
	_refresh()
	fs.pressed.connect(_on_fullscreen)
	c.add_child(fs)

	var back := UiKit.button("ORQAGA", Vector2(810, 720), Vector2(300, 90))
	back.pressed.connect(close)
	c.add_child(back)
	first = mus


func _on_music(v: float) -> void:
	settings.music_vol = v
	settings.apply()


func _on_sfx(v: float) -> void:
	settings.sfx_vol = v
	settings.apply()


func _on_fullscreen() -> void:
	settings.toggle_fullscreen()
	_refresh()


func _refresh() -> void:
	fs.text = "YONIQ" if settings.fullscreen else "O'CHIQ"


func open() -> void:
	visible = true
	first.grab_focus()


func close() -> void:
	settings.store()
	visible = false
	closed.emit()


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
