extends Control
## Hades-style dialogue: painted portrait slides in from the left, parchment box with a gold frame, name plate with a
## title, typewriter text. E / Space / Enter: finish the line, then next.
##
## Line format:  "Анзу: text"  or  "Анзу|happy: text"  (moods: neutral, happy, shy, think).
## A line without a known speaker is narration: no portrait, no plate, italic ink.
## Portraits: res://art/dlg/<dir>_<mood>.png (all moods share one frame); a missing mood falls back to neutral.

signal finished

const SPEAKERS := {
	"Анзу": {"dir": "anzu", "title": "Слушающая Землю", "color": Color(0.74, 0.92, 0.52)},
}
const INK := Color(0.17, 0.13, 0.11)
const INK_NARRATION := Color(0.33, 0.27, 0.22)

var lines: PackedStringArray = []
var index := 0
var tween: Tween
var shown := 0
var voiced := false
var closing := false
var who_now := ""
var portrait_shown := false
var cache := {}

@onready var dim: ColorRect = $Dim
@onready var canvas: Control = $Canvas
@onready var portrait: TextureRect = $Canvas/Portrait
@onready var box: Control = $Canvas/Box
@onready var text: Label = $Canvas/Box/Text
@onready var arrow: Control = $Canvas/Box/Arrow
@onready var plate: Control = $Canvas/Plate
@onready var name_label: Label = $Canvas/Plate/Name
@onready var title_label: Label = $Canvas/Plate/Title
@onready var sprig_green: Control = $Canvas/SprigGreen
@onready var sprig_gold: Control = $Canvas/SprigGold
@onready var blip: AudioStreamPlayer = $Blip
@onready var voice: AudioStreamPlayer = $Voice

var portrait_base := Vector2.ZERO
var hud: Control


func _ready() -> void:
	visible = false
	portrait_base = portrait.position
	hud = get_parent().get_node_or_null("Hud")


func open(new_lines: PackedStringArray) -> void:
	lines = new_lines
	index = 0
	closing = false
	portrait_shown = false
	visible = true
	canvas.modulate.a = 0.0
	dim.color.a = 0.0
	create_tween().set_parallel(true).tween_property(canvas, "modulate:a", 1.0, 0.18)
	create_tween().tween_property(dim, "color:a", 0.5, 0.3)
	if hud:                                          # side panels step aside while somebody is talking
		create_tween().tween_property(hud, "modulate:a", 0.0, 0.2)
	_show_line()


func _parse(line: String) -> Dictionary:
	for who in SPEAKERS:
		if not line.begins_with(who):
			continue
		var rest := line.substr(who.length())
		var mood := "neutral"
		if rest.begins_with("|"):
			var colon := rest.find(":")
			if colon > 0:
				mood = rest.substr(1, colon - 1)
				rest = rest.substr(colon)
		if rest.begins_with(": "):
			return {"who": who, "mood": mood, "text": rest.substr(2)}
	return {"who": "", "mood": "", "text": line}


func _portrait_for(who: String, mood: String) -> Texture2D:
	var dir: String = SPEAKERS[who]["dir"]
	for m in [mood, "neutral"]:
		var path := "res://art/dlg/%s_%s.png" % [dir, m]
		if cache.has(path):
			return cache[path]
		if ResourceLoader.exists(path):
			cache[path] = load(path)
			return cache[path]
	return null


func _show_line() -> void:
	var info := _parse(lines[index])
	var who: String = info["who"]
	var s: String = info["text"]
	var tex: Texture2D = _portrait_for(who, info["mood"]) if who != "" else null

	# --- speaker furniture
	plate.visible = who != ""
	sprig_green.visible = who != ""
	sprig_gold.visible = true
	if who != "":
		name_label.text = who.to_upper()
		title_label.text = SPEAKERS[who]["title"]
		title_label.add_theme_color_override("font_color", SPEAKERS[who]["color"])
		text.add_theme_font_override("font", text.get_meta("font_normal"))
		text.add_theme_color_override("font_color", INK)
	else:
		text.add_theme_font_override("font", text.get_meta("font_italic"))
		text.add_theme_color_override("font_color", INK_NARRATION)

	# --- portrait: slides in the first time, a quick pop when the mood changes
	if tex:
		var changed := portrait.texture != tex
		portrait.texture = tex
		portrait.visible = true
		if not portrait_shown:
			portrait_shown = true
			portrait.modulate.a = 0.0
			portrait.position = portrait_base + Vector2(-140, 0)
			var tw := create_tween().set_parallel(true)
			tw.tween_property(portrait, "modulate:a", 1.0, 0.22)
			tw.tween_property(portrait, "position:x", portrait_base.x, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		elif changed:
			portrait.pivot_offset = Vector2(portrait.size.x * 0.5, portrait.size.y)
			portrait.scale = Vector2(1.025, 1.025)
			create_tween().tween_property(portrait, "scale", Vector2.ONE, 0.18)
	else:
		portrait.visible = false
		portrait_shown = false

	# --- text
	who_now = who
	text.text = s
	text.visible_characters = 0
	shown = 0
	arrow.visible = false
	# Japanese voice for the speaker's lines: res://voice/<md5 of the subtitle>.ogg (tools/voice_gen.py)
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
	var t := Time.get_ticks_msec() * 0.001
	if text.visible_characters > shown:
		shown = text.visible_characters
		if not voiced and shown % 2 == 0 and shown <= text.text.length() and text.text[shown - 1] != " ":
			blip.pitch_scale = randf_range(0.9, 1.1)
			blip.play()
	arrow.position.y = BOX_ARROW_Y + sin(t * 4.5) * 6.0
	if portrait.visible and portrait_shown:          # she breathes
		portrait.position.y = portrait_base.y + sin(t * 1.7) * 3.5


const BOX_ARROW_Y := 168.0


func _input(event: InputEvent) -> void:
	if not visible or closing or not event.is_action_pressed("interact"):
		return
	get_viewport().set_input_as_handled()
	if text.visible_characters < text.text.length() and text.visible_characters != -1:
		tween.kill()
		text.visible_characters = -1
		arrow.visible = true
		return
	index += 1
	if index >= lines.size():
		_close()
	else:
		_show_line()


func _close() -> void:
	closing = true
	voice.stop()
	var tw := create_tween().set_parallel(true)
	tw.tween_property(canvas, "modulate:a", 0.0, 0.16)
	tw.tween_property(dim, "color:a", 0.0, 0.2)
	if hud:
		tw.tween_property(hud, "modulate:a", 1.0, 0.25)
	finished.emit()
	await tw.finished
	if closing:                                      # a new dialog may have opened meanwhile
		visible = false
