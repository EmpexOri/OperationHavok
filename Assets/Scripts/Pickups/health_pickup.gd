extends "res://Assets/Scripts/Pickups/base_pickup.gd"

func _ready() -> void:
	pickup_range = 10
	pickup_type = "Health"
	pickup_value = 10 #This is 'amount' in Global.gd
	sprite_path = "res://Assets/Art/Pickups/Heart.png"
	super._ready()

func apply_effect():
	Global.AddHp(pickup_value)
