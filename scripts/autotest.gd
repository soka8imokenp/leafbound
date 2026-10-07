extends Node
## Scripted walkthrough for checking the room without a keyboard.
## LB_AUTOTEST=/path/to/out godot --path .   -> walks, pets the cat, naps, saves PNG snapshots.

var out := ""
var record := false
var frame := 0


func _ready() -> void:
	out = OS.get_environment("LB_AUTOTEST")
	record = OS.get_environment("LB_RECORD") != ""
	get_window().size = Vector2i(1152, 648)
	if OS.get_environment("LB_LOWRES") != "":
		get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
	_run.call_deferred()


func _process(_dt: float) -> void:
	if record:
		get_viewport().get_texture().get_image().save_png("%s/rec_%05d.png" % [out, frame])
		frame += 1


func _hold(action: String, sec: float) -> void:
	Input.action_press(action)
	await get_tree().create_timer(sec).timeout
	Input.action_release(action)


func _press(action: String) -> void:
	var ev := InputEventAction.new()
	ev.action = action
	ev.pressed = true
	Input.parse_input_event(ev)
	await get_tree().process_frame
	ev = InputEventAction.new()
	ev.action = action
	ev.pressed = false
	Input.parse_input_event(ev)
	await get_tree().process_frame


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png("%s/%s.png" % [out, name])
	print("shot ", name)


func _wait(sec: float) -> void:
	await get_tree().create_timer(sec).timeout


func _dialog_through(n: int) -> void:
	## each line: wait for the typewriter to finish, then advance
	var dlg = get_tree().current_scene.get_node("UI/Dialog")
	for i in n:
		await _wait(0.4)
		while dlg.visible and dlg.text.visible_characters != -1 and dlg.text.visible_characters < dlg.text.text.length():
			await get_tree().process_frame
		await _wait(0.5)
		await _press("interact")


func _run() -> void:
	var player = get_tree().current_scene.get_node("World/Player")
	await _wait(1.0)
	await _shot("01_start")
	_hold("move_right", 0.5)
	await _wait(0.25)
	await _shot("02_walk_side")
	await _wait(0.3)
	_hold("move_up", 0.65)
	await _wait(0.3)
	await _shot("03_walk_up")
	await _wait(0.5)
	print("player at ", player.position, " target ", player.target.title if player.target else "-")
	await _press("interact")
	await _wait(0.5)
	await _shot("04_cat_dialog")
	await _dialog_through(3)
	await _wait(0.3)
	_hold("move_left", 1.25)
	await _wait(1.4)
	print("player at ", player.position, " target ", player.target.title if player.target else "-")
	await _shot("05_by_bed")
	await _press("interact")
	await _dialog_through(2)
	await _wait(2.0)
	await _shot("06_sleeping")
	await _wait(6.6)
	await _shot("07_night_sleeping")
	await _wait(2.4)
	await _shot("07b_woke_up")
	await _dialog_through(2)
	_hold("move_down", 0.9)
	await _wait(1.2)
	await _shot("08_night_walk")
	# radio -> Claude FM confirm
	player.position = Vector2(115, 126)
	player.facing = "up"
	await _wait(0.3)
	print("radio target ", player.target.title if player.target else "-")
	await _press("interact")
	await _dialog_through(4)
	await _wait(0.4)
	await _shot("08b_fm_confirm")
	await _press("ui_accept")
	await _wait(0.6)
	await _shot("08c_fm_on")
	await _dialog_through(2)
	await _wait(0.3)
	await _press("pause")
	await _wait(0.5)
	await _shot("09_pause")
	get_tree().quit()
