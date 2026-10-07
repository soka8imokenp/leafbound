extends Control
## Main menu: Yangi hikoya / Davom etish / Sozlamalar / Chiqish, swaying logo leaf, leaf pointer.

@onready var settings: Node = get_node("/root/Settings")

var t := 0.0
var leaving := false
var ready_done := false

@onready var buttons: Array = [$Canvas/New, $Canvas/Continue, $Canvas/Settings, $Canvas/Exit]
@onready var marker: Sprite2D = $Canvas/Marker
@onready var leaf: Sprite2D = $Canvas/LogoLeaf
@onready var fade: ColorRect = $Fade
@onready var panel: Control = $SettingsPanel
@onready var hover_sfx: AudioStreamPlayer = $Hover
@onready var click_sfx: AudioStreamPlayer = $Click


func _ready() -> void:
	get_tree().paused = false
	$Canvas/Continue.disabled = not settings.has_save()
	for b in buttons:
		b.focus_entered.connect(_on_focus)
		b.mouse_entered.connect(_hover.bind(b))
		b.pressed.connect(click_sfx.play)
	$Canvas/New.pressed.connect(_new_game)
	$Canvas/Continue.pressed.connect(_continue)
	$Canvas/Settings.pressed.connect(panel.open)
	$Canvas/Exit.pressed.connect(_exit)
	panel.closed.connect(func(): buttons[2].grab_focus())
	buttons[1 if settings.has_save() else 0].grab_focus()
	fade.color.a = 1.0
	create_tween().tween_property(fade, "color:a", 0.0, 0.9)
	ready_done = true
	if OS.get_environment("LB_AUTOTEST") != "":
		if OS.get_environment("LB_LOWRES") != "":
			get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_VIEWPORT
		_autotest.call_deferred()


func _process(dt: float) -> void:
	t += dt
	leaf.rotation = sin(t * 1.1) * 0.035 + sin(t * 2.9) * 0.01
	var f := get_viewport().gui_get_focus_owner()
	if f in buttons:
		var target := f.position.y + f.size.y * 0.5
		marker.position.y = lerpf(marker.position.y, target, minf(dt * 14.0, 1.0))
		marker.position.x = 78.0 + sin(t * 3.2) * 6.0
		marker.rotation = sin(t * 2.0) * 0.15
	marker.visible = f in buttons and not panel.visible


func _hover(b: TextureButton) -> void:
	if not b.disabled:
		b.grab_focus()


func _on_focus() -> void:
	if ready_done and not leaving:
		hover_sfx.pitch_scale = randf_range(0.9, 1.1)
		hover_sfx.play()


func _new_game() -> void:
	settings.pending_load = false
	_leave("res://scenes/main.tscn")


func _continue() -> void:
	settings.pending_load = true
	_leave("res://scenes/main.tscn")


func _exit() -> void:
	if leaving:
		return
	leaving = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().quit()


func _leave(scene: String) -> void:
	if leaving:
		return
	leaving = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.8)
	await tw.finished
	get_tree().change_scene_to_file(scene)


func _autotest() -> void:
	var out := OS.get_environment("LB_AUTOTEST")
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/00_menu.png")
	buttons[2].grab_focus()
	panel.open()
	await get_tree().create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/00_settings.png")
	panel.close()
	print("shot menu")
	_new_game()
