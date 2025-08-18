extends Camera2D

var shake_strength: float = 0.0
var shake_decay: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.randomize()
	ScreenShake.register_camera(self) # register this camera globally

func _process(delta: float) -> void:
	if shake_strength > 0.01:
		offset = Vector2(
			rng.randf_range(-shake_strength, shake_strength),
			rng.randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerp(shake_strength, 0.0, shake_decay * delta)
	else:
		offset = Vector2.ZERO

func shake(intensity: float = 8.0, duration: float = 0.5) -> void:
	shake_strength = intensity
	shake_decay = 1.0 / max(duration, 0.001)
