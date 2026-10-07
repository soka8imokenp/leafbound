extends StaticBody2D
## Sleeping cat: slow uneven breathing, drifting "z", hearts + purr when petted.

@onready var spr: AnimatedSprite2D = $Sprite
@onready var zzz: CPUParticles2D = $Zzz
@onready var hearts: CPUParticles2D = $Hearts
@onready var purr: AudioStreamPlayer2D = $Purr

var calm := 0.0


func _ready() -> void:
	spr.play("breath")
	spr.animation_looped.connect(_vary)


func _vary() -> void:
	# every breath a little different, faster for a while after petting
	spr.speed_scale = randf_range(0.8, 1.15) * (1.7 if calm > 0.0 else 1.0)


func _process(dt: float) -> void:
	calm = maxf(calm - dt, 0.0)


func pet() -> void:
	calm = 4.0
	hearts.restart()
	hearts.emitting = true
	purr.play()
