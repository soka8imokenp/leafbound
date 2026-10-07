extends CharacterBody2D
## Anzu: 4-direction walk, picks the closest interactable in front of her.

const SPEED := 52.0
const REACH := {"down": Vector2(0, 7), "up": Vector2(0, -9), "left": Vector2(-10, -2), "right": Vector2(10, -2)}

const FACE_CAMERA_AFTER := 0.35          # s standing still before she turns back to us

var facing := "down"                    # last walking direction (also where she reaches)
var idle_time := 0.0
var busy := false
var target: Area2D = null

@onready var spr: AnimatedSprite2D = $Sprite
@onready var reach: Area2D = $Reach
@onready var prompt: Node2D = $Prompt
@onready var prompt_label: Label = $Prompt/Label
@onready var step_sfx: AudioStreamPlayer2D = $Step


func _ready() -> void:
	spr.frame_changed.connect(_on_frame)
	spr.play("down_idle")


func _physics_process(dt: float) -> void:
	var dir := Vector2.ZERO
	if not busy:
		dir = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * SPEED
	move_and_slide()

	var moving := dir.length() > 0.1
	if moving:
		if absf(dir.x) > absf(dir.y):
			facing = "right" if dir.x > 0 else "left"
		else:
			facing = "down" if dir.y > 0 else "up"
	idle_time = 0.0 if moving else idle_time + dt
	# walking shows the direction; standing still she turns to face the camera
	var look := facing if moving or idle_time < FACE_CAMERA_AFTER else "down"
	var view := "side" if look == "left" or look == "right" else look
	spr.flip_h = look == "left"
	var anim := view + ("_walk" if moving else "_idle")
	if spr.animation != anim:
		spr.play(anim)
	reach.position = REACH[facing]
	_update_target()


func _update_target() -> void:
	target = null
	var best := INF
	for a in reach.get_overlapping_areas():
		if not a.is_in_group("interactable"):
			continue
		var d := reach.global_position.distance_squared_to(a.global_position)
		if d < best:
			best = d
			target = a
	prompt.visible = target != null and not busy
	if target:
		prompt_label.text = target.title


func _unhandled_input(event: InputEvent) -> void:
	if busy or target == null:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().current_scene.interact(target)


func _on_frame() -> void:
	if spr.animation.ends_with("_walk") and spr.frame % 2 == 0:
		step_sfx.pitch_scale = randf_range(0.85, 1.15)
		step_sfx.play()
