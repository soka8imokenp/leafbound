extends Control
## Esc in the room: PAUZA panel. Saves on "Menyuga" / "Chiqish".

var buttons: Array[Button] = []
var settings_panel: Control


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.07, 0.05, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := UiKit.canvas("Canvas")
	add_child(c)
	c.add_child(UiKit.panel(Vector2(640, 170), Vector2(640, 740)))
	c.add_child(UiKit.label("PAUZA", 64, Vector2(640, 215), 640, HORIZONTAL_ALIGNMENT_CENTER))
	var items := [["DAVOM ETISH", close], ["SOZLAMALAR", _settings], ["MENYUGA", _to_menu], ["CHIQISH", _quit]]
	for i in items.size():
		var b := UiKit.button(items[i][0], Vector2(760, 340 + i * 130), Vector2(400, 100))
		b.pressed.connect(items[i][1])
		c.add_child(b)
		buttons.append(b)
	settings_panel = Control.new()
	settings_panel.set_script(load("res://scripts/settings_panel.gd"))
	add_child(settings_panel)
	settings_panel.closed.connect(func(): buttons[1].grab_focus())


func open() -> void:
	visible = true
	get_tree().paused = true
	buttons[0].grab_focus()


func close() -> void:
	visible = false
	get_tree().paused = false


func _settings() -> void:
	settings_panel.open()


func _to_menu() -> void:
	get_tree().current_scene.save()
	get_tree().paused = false
	get_tree().current_scene.leave("res://scenes/menu.tscn")


func _quit() -> void:
	get_tree().current_scene.save()
	get_tree().quit()


func _input(event: InputEvent) -> void:
	if visible and not settings_panel.visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		close()
