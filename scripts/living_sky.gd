class_name LivingSky
extends Control
## Living pixel sky: a SubViewport at game-pixel resolution with scripts/pixel_sky.gdshader, shown nearest-filtered.
## Put it anywhere (room window, menu mist, a future outdoor scene) and set `tod` (0 midnight, .25 dawn, .5 noon, .75 dusk).

@export var virtual_size := Vector2i(160, 90)
@export var tod := 0.5: set = set_tod
@export var cloud_amount := 0.55
@export var cloud_scale := 1.0
@export var wind := 1.0
@export var star_amount := 1.0
@export var aurora_amount := 0.0
@export var body_radius := 5.0
@export var glow_amount := 0.55
@export var horizon := 1.0
@export var overlay_only := false
@export var overlay_alpha := 0.6
@export var fade_y := Vector2(0.55, 0.8)
@export var hole_a := Vector4.ZERO
@export var hole_b := Vector4.ZERO
@export var mask: Texture2D

var _mat: ShaderMaterial


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vp := SubViewport.new()
	vp.size = virtual_size
	vp.transparent_bg = true
	vp.disable_3d = true
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	_mat = ShaderMaterial.new()
	_mat.shader = load("res://shaders/pixel_sky.gdshader")
	var rect := ColorRect.new()
	rect.size = Vector2(virtual_size)
	rect.material = _mat
	vp.add_child(rect)
	var tr := TextureRect.new()
	tr.texture = vp.get_texture()
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_SCALE
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(tr)
	_push()


func set_tod(v: float) -> void:
	tod = v
	if _mat:
		_mat.set_shader_parameter("tod", tod)


func _push() -> void:
	_mat.set_shader_parameter("size", Vector2(virtual_size))
	_mat.set_shader_parameter("tod", tod)
	_mat.set_shader_parameter("cloud_amount", cloud_amount)
	_mat.set_shader_parameter("cloud_scale", cloud_scale)
	_mat.set_shader_parameter("wind", wind)
	_mat.set_shader_parameter("star_amount", star_amount)
	_mat.set_shader_parameter("aurora_amount", aurora_amount)
	_mat.set_shader_parameter("body_radius", body_radius)
	_mat.set_shader_parameter("glow_amount", glow_amount)
	_mat.set_shader_parameter("horizon", horizon)
	_mat.set_shader_parameter("overlay_only", overlay_only)
	_mat.set_shader_parameter("overlay_alpha", overlay_alpha)
	_mat.set_shader_parameter("fade_y", fade_y)
	_mat.set_shader_parameter("hole_a", hole_a)
	_mat.set_shader_parameter("hole_b", hole_b)
	_mat.set_shader_parameter("use_mask", mask != null)
	if mask:
		_mat.set_shader_parameter("mask", mask)
