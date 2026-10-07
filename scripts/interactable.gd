extends Area2D
## Something Anzu can look at / use. One line of `text` = one dialog line;
## lines starting with "Анзу: " get her name tag.
## (stored as one String: PackedStringArray exports came out empty in Godot 4.7 binary scenes)

@export var title := ""
@export_multiline var text := ""
@export var action := ""

var lines: PackedStringArray


func _ready() -> void:
	add_to_group("interactable")
	lines = text.split("\n", false)
