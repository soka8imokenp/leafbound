extends StaticBody2D
## Wood stove: animated fire, flickering warm light, kettle steam, crackle sound.

@onready var light: PointLight2D = $Glow
@onready var burst: CPUParticles2D = $SteamBurst

var base_energy := 0.9
var t := 0.0


func _process(dt: float) -> void:
	t += dt
	var flick := sin(t * 7.3) * 0.06 + sin(t * 13.1 + 1.7) * 0.05 + randf_range(-0.04, 0.04)
	light.energy = base_energy + flick
	light.texture_scale = 1.0 + flick * 0.4


func stoke() -> void:
	burst.restart()
	burst.emitting = true
