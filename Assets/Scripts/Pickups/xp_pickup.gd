extends BasePickup

func _ready() -> void:
	pickup_range = 75
	pickup_type = "Xp"
	pickup_value = 1
	sprite_frames_path = "res://Assets/Art/Effects/XP.tres"
	super._ready()

func apply_effect():
	GlobalPlayer.AddXP(pickup_value)
	GlobalPlayer.AddHp(1)
	GlobalAudioController.PlayXPPickupSound()
