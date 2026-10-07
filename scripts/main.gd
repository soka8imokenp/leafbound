extends Node2D
## Anzu's room: input map, interaction flow, day/evening switch after a nap, camera, radio LED.

@onready var settings: Node = get_node("/root/Settings")

const DAY := Color(0.84, 0.78, 0.74)
const NIGHT := Color(0.36, 0.38, 0.56)

const CLAUDE_FM := "https://claude.fm"

var night := false
var radio_on := false
var fm_on := false

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
@onready var sleeper: Node2D = $World/Bed/Sleeper
@onready var blanket: Sprite2D = $World/Bed/Sleeper/Blanket


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
	if sleeper.visible:                             # slow breathing under the quilt
		blanket.position.y = -1.0 if sin(Time.get_ticks_msec() * 0.0025) > 0.3 else 0.0
	var ms := Time.get_ticks_msec()
	var on := (ms / 90) % 2 == 0 if radio_on else (fm_on or (ms / 1400) % 3 != 0)
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
			await _claude_fm()
		"sleep":
			await _nap()
	await get_tree().process_frame
	player.busy = false


func _claude_fm() -> void:
	## Claude FM is a YouTube live stream: it opens in the browser, the game music pauses meanwhile
	var confirm: Control = $UI/Confirm
	if not fm_on:
		if not await confirm.ask("Включить Claude FM?", "Лоу-фай радио откроется в браузере"):
			return
		if OS.get_environment("LB_AUTOTEST") == "":
			OS.shell_open(CLAUDE_FM)
		else:
			print("would open ", CLAUDE_FM)
		fm_on = true
		settings.music.stream_paused = true
		dialog.open(PackedStringArray(["Радио ловит волну. Где-то играет тёплый лоу-фай.", "Анзу: Музыка! Пико бы понравилось."]))
	else:
		if not await confirm.ask("Выключить Claude FM?", "Вкладку в браузере закрой сам"):
			return
		fm_on = false
		settings.music.stream_paused = false
		dialog.open(PackedStringArray(["Радио снова тихо шипит."]))
	await dialog.finished


func _fade(alpha: float, sec: float) -> void:
	var tw := create_tween()
	tw.tween_property(fade, "color:a", alpha, sec).set_trans(Tween.TRANS_SINE)
	await tw.finished


func _nap() -> void:
	# lie down
	await _fade(1.0, 0.5)
	player.visible = false
	player.position = Vector2(108, 150)            # camera stays on the bed corner
	cam.position = _cam_target()
	sleeper.visible = true
	await _fade(0.0, 0.7)
	await get_tree().create_timer(2.2).timeout
	# time passes
	await _fade(1.0, 1.8)
	_apply_time(not night)
	await get_tree().create_timer(1.0).timeout
	await _fade(0.0, 1.8)
	await get_tree().create_timer(1.4).timeout
	# get up next to the bed
	await _fade(1.0, 0.4)
	sleeper.visible = false
	player.visible = true
	player.facing = "left"
	save()
	await _fade(0.0, 0.5)
	dialog.open(PackedStringArray(["Анзу: Ой... Анзу уснула?", "За окном уже стемнело."]) if night
		else PackedStringArray(["Анзу: Утро! Доброе утро, Рыжик!", "Сквозь окно пробивается тёплый свет."]))
	await dialog.finished


func _apply_time(is_night: bool) -> void:
	night = is_night
	tint.color = NIGHT if night else DAY
	window_light.energy = 0.0 if night else 0.2
	night_glass.color.a = 0.78 if night else 0.0
	dust.emitting = not night
	stove.base_energy = 0.95 if night else 0.5


func _loop_wav(s: AudioStream) -> void:
	if s is AudioStreamWAV:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = int(s.get_length() * s.mix_rate)

