extends "res://Assets/Scripts/Pickups/base_pickup.gd"

func _ready() -> void:
	pickup_range = 30
	pickup_type = "Health"
	pickup_value = 10
	sprite_path = "res://Assets/Art/Pickups/Heart.png"
	super._ready()

func apply_effect():
	#Global.AddHealth(pickup_value)
	pass
