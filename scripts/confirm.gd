extends Control
## Small yes/no panel in the menu style.  var ok: bool = await $UI/Confirm.ask("Вопрос?", "Подсказка")

signal chosen(ok: bool)

var title: Label
var note: Label
var yes: Button
var no: Button


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	var dim := ColorRect.new()
	dim.color = Color(0.05, 0.07, 0.05, 0.45)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var c := UiKit.canvas("Canvas")
	add_child(c)
	c.add_child(UiKit.panel(Vector2(500, 300), Vector2(920, 420)))
	title = UiKit.label("", 56, Vector2(500, 360), 920, HORIZONTAL_ALIGNMENT_CENTER)
	c.add_child(title)
	note = UiKit.label("", 34, Vector2(500, 450), 920, HORIZONTAL_ALIGNMENT_CENTER)
	c.add_child(note)
	yes = UiKit.button("ДА", Vector2(600, 560), Vector2(320, 96))
	no = UiKit.button("НЕТ", Vector2(1000, 560), Vector2(320, 96))
	yes.pressed.connect(_pick.bind(true))
	no.pressed.connect(_pick.bind(false))
	c.add_child(yes)
	c.add_child(no)


func ask(question: String, hint := "") -> bool:
	title.text = question
	note.text = hint
	visible = true
	yes.grab_focus()
	return await chosen


func _pick(ok: bool) -> void:
	visible = false
	chosen.emit(ok)


func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		_pick(false)
	elif visible and (event.is_action_pressed("move_left") or event.is_action_pressed("move_right")):
		get_viewport().set_input_as_handled()
		(no if yes.has_focus() else yes).grab_focus()
