extends "res://Assets/Scripts/Pickups/base_pickup.gd"

func _ready() -> void:
	pickup_range = 75
	pickup_type = "Xp"
	pickup_value = 10
	sprite_path = "res://Assets/Art/Pickups/xp.png"
	super._ready()

func apply_effect():
	GlobalPlayer.AddXP(pickup_value)
