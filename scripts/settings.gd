extends Node
## Autoload "Settings": input map, audio buses + volumes, fullscreen, music across scenes, save slot.

const CFG := "user://settings.cfg"
const SAVE := "user://save.cfg"

var music_vol := 0.8
var sfx_vol := 0.9
var fullscreen := false
var pending_load := false      # set by "Davom etish", consumed by the room
var music: AudioStreamPlayer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	for bus in ["Music", "SFX"]:
		if AudioServer.get_bus_index(bus) == -1:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count - 1, bus)
	var cf := ConfigFile.new()
	if cf.load(CFG) == OK:
		music_vol = cf.get_value("audio", "music", music_vol)
		sfx_vol = cf.get_value("audio", "sfx", sfx_vol)
		fullscreen = cf.get_value("video", "fullscreen", fullscreen)
	apply()
	music = AudioStreamPlayer.new()
	music.stream = load("res://audio/reiselust.ogg")
	music.stream.loop = true
	music.bus = "Music"
	music.volume_db = -10.0
	add_child(music)
	music.play()


func apply() -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"), linear_to_db(maxf(music_vol, 0.0001)))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(maxf(sfx_vol, 0.0001)))
	if OS.get_environment("LB_AUTOTEST") == "":
		get_window().mode = Window.MODE_FULLSCREEN if fullscreen else Window.MODE_WINDOWED


func store() -> void:
	var cf := ConfigFile.new()
	cf.set_value("audio", "music", music_vol)
	cf.set_value("audio", "sfx", sfx_vol)
	cf.set_value("video", "fullscreen", fullscreen)
	cf.save(CFG)


func toggle_fullscreen() -> void:
	fullscreen = not fullscreen
	apply()
	store()


func has_save() -> bool:
	return FileAccess.file_exists(SAVE)


func save_game(data: Dictionary) -> void:
	var cf := ConfigFile.new()
	for k in data:
		cf.set_value("game", k, data[k])
	cf.save(SAVE)


func load_game() -> Dictionary:
	var cf := ConfigFile.new()
	var out := {}
	if cf.load(SAVE) == OK:
		for k in cf.get_section_keys("game"):
			out[k] = cf.get_value("game", k)
	return out


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_F11:
		toggle_fullscreen()


func _setup_input() -> void:
	var map := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"interact": [KEY_E, KEY_SPACE, KEY_ENTER],
		"pause": [KEY_ESCAPE],
		"ui_up": [KEY_W], "ui_down": [KEY_S], "ui_accept": [KEY_E],
	}
	for action in map:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in map[action]:
			var ev := InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)
