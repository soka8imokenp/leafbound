extends Node2D
## Anzu's room: input map, interaction flow, day/evening switch after a nap, camera, radio LED.

@onready var settings: Node = get_node("/root/Settings")

const DAY := Color(0.9, 0.84, 0.78)
const NIGHT := Color(0.36, 0.38, 0.56)

var night := false
var radio_on := false

@onready var player: CharacterBody2D = $World/Player
@onready var cam: Camera2D = $Camera
@onready var dialog: Control = $UI/Dialog
@onready var fade: ColorRect = $UI/Fade
@onready var tint: CanvasModulate = $Tint
@onready var window_light: PointLight2D = $WindowLight
@onready var night_glass: ColorRect = $NightGlass
@onready var dust: CPUParticles2D = $Dust
@onready var stove: Node = $World/Stove
@onready var cat: Node = $World/Cat
@onready var led: ColorRect = $RadioLed
@onready var radio_sfx: AudioStreamPlayer2D = $RadioStatic


func _ready() -> void:
	_loop_wav($World/Stove/Crackle.stream)
	_loop_wav(radio_sfx.stream)
	tint.color = DAY
	if settings.pending_load:
		settings.pending_load = false
		var d: Dictionary = settings.load_game()
		player.position = Vector2(d.get("x", player.position.x), d.get("y", player.position.y))
		_apply_time(d.get("night", false))
	cam.position = _cam_target()
	cam.reset_smoothing()
	create_tween().tween_property(fade, "color:a", 0.0, 0.9)
	if OS.get_environment("LB_AUTOTEST") != "":
		var t := Node.new()
		t.set_script(load("res://scripts/autotest.gd"))
		add_child(t)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and not player.busy and not $UI/Pause.visible:
		get_viewport().set_input_as_handled()
		$UI/Pause.open()


func save() -> void:
	settings.save_game({"x": player.position.x, "y": player.position.y, "night": night})


func leave(scene: String) -> void:
	player.busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.7)
	await tw.finished
	get_tree().change_scene_to_file(scene)


func _process(_dt: float) -> void:
	cam.position = _cam_target()
	var ms := Time.get_ticks_msec()
	var on := (ms / 90) % 2 == 0 if radio_on else (ms / 1400) % 3 != 0
	led.color = Color(0.55, 1.0, 0.45) if on else Color(0.2, 0.35, 0.18)


func _cam_target() -> Vector2:
	return Vector2(128, clampf(player.position.y - 30.0, 108.0, 148.0))


func interact(area: Area2D) -> void:
	player.busy = true
	match area.action:
		"pet":
			cat.pet()
		"stove":
			stove.stoke()
		"radio":
			radio_on = true
			radio_sfx.play()
	dialog.open(area.lines)
	await dialog.finished
	match area.action:
		"radio":
			radio_on = false
			radio_sfx.stop()
		"sleep":
			await _nap()
	await get_tree().process_frame
	player.busy = false


func _nap() -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 1.2)
	await tw.finished
	_apply_time(not night)
	save()
	await get_tree().create_timer(0.8).timeout
	tw = create_tween()
	tw.tween_property(fade, "color:a", 0.0, 1.4)
	await tw.finished
	dialog.open(PackedStringArray(["Анзу немного вздремнула. За окном уже стемнело."]) if night
		else PackedStringArray(["Утро. Сквозь окно пробивается тёплый свет."]))
	await dialog.finished


func _apply_time(is_night: bool) -> void:
	night = is_night
	tint.color = NIGHT if night else DAY
	window_light.energy = 0.05 if night else 0.45
	night_glass.color.a = 0.78 if night else 0.0
	dust.emitting = not night
	stove.base_energy = 1.35 if night else 0.9


func _loop_wav(s: AudioStream) -> void:
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)

