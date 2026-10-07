extends Control
## Bottom dialog box with a typewriter effect. E / Space / Enter: finish the line, then next.

signal finished

const SPEAKER := "Анзу: "

var lines: PackedStringArray = []
var index := 0
var tween: Tween
var shown := 0

@onready var text: Label = $Box/Text
@onready var name_tag: Control = $Box/NameTag
@onready var name_label: Label = $Box/NameTag/Label
@onready var arrow: Control = $Box/Arrow
@onready var blip: AudioStreamPlayer = $Blip
@onready var voice: AudioStreamPlayer = $Voice
var voiced := false


func _ready() -> void:
	visible = false


func open(new_lines: PackedStringArray) -> void:
	lines = new_lines
	index = 0
	visible = true
	_show_line()


func _show_line() -> void:
	var s := lines[index]
	var who := ""
	if s.begins_with(SPEAKER):
		who = "Анзу"
		s = s.substr(SPEAKER.length())
	name_tag.visible = who != ""
	name_label.text = who
	text.text = s
	text.visible_characters = 0
	shown = 0
	arrow.visible = false
	# Japanese voice for Anzu's lines: res://voice/<md5 of the subtitle>.ogg (tools/voice_gen.py)
	voice.stop()
	voiced = false
	var duration := s.length() * 0.032
	var path := "res://voice/%s.ogg" % s.md5_text()
	if who != "" and ResourceLoader.exists(path):
		voice.stream = load(path)
		voice.play()
		voiced = true
		duration = clampf(voice.stream.get_length() * 0.85, duration * 0.6, duration * 2.0)
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(text, "visible_characters", s.length(), duration)
	tween.finished.connect(func(): arrow.visible = true)


func _process(_dt: float) -> void:
	if not visible:
		return
	if text.visible_characters > shown:
		shown = text.visible_characters
		if not voiced and shown % 2 == 0 and shown <= text.text.length() and text.text[shown - 1] != " ":
			blip.pitch_scale = randf_range(0.9, 1.1)
			blip.play()
	arrow.position.y = 36 + roundf(sin(Time.get_ticks_msec() * 0.008))


func _input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if text.visible_characters < text.text.length() and text.visible_characters != -1:
		tween.kill()
		text.visible_characters = -1
		arrow.visible = true
		return
	index += 1
	if index >= lines.size():
		voice.stop()
		visible = false
		finished.emit()
	else:
		_show_line()
