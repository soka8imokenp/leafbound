extends Node2D
## Sky gallery: 9 variants side by side; saves a still (and frames when LB_SKY_FRAMES is set).
## SKY_OUT=/path godot --path . res://scenes/sky_preview.tscn

const VARIANTS := [
	["рассвет", 0.27, 0.45, 0.0], ["день", 0.5, 0.55, 0.0], ["пасмурно", 0.5, 1.0, 0.0],
	["закат", 0.74, 0.5, 0.0], ["вечер", 0.82, 0.45, 0.0], ["ночь", 0.0, 0.25, 0.0],
	["сияние", 0.02, 0.1, 0.9], ["ясная ночь", 0.05, 0.0, 0.0], ["поздний закат", 0.79, 0.7, 0.0],
]
var out := ""
var frame := 0
var frames := false


func _ready() -> void:
	out = OS.get_environment("SKY_OUT")
	frames = OS.get_environment("LB_SKY_FRAMES") != ""
	RenderingServer.set_default_clear_color(Color.BLACK)
	for i in VARIANTS.size():
		var v: Array = VARIANTS[i]
		var s := LivingSky.new()
		s.virtual_size = Vector2i(160, 90)
		s.position = Vector2((i % 3) * 160, (i / 3) * 90)
		s.size = Vector2(160, 90)
		s.tod = v[1]
		s.cloud_amount = v[2]
		s.aurora_amount = v[3]
		add_child(s)
	if out != "":
		_run.call_deferred()


func _process(_dt: float) -> void:
	if frames and out != "" and frame < 160:
		get_viewport().get_texture().get_image().save_png("%s/f_%04d.png" % [out, frame])
	frame += 1


func _run() -> void:
	await get_tree().create_timer(2.5 if not frames else 7.0).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out + "/sky_gallery.png")
	print("saved gallery")
	get_tree().quit()
