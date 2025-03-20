extends "res://Assets/Scripts/Pickups/base_pickup.gd"

func _ready() -> void:
	pickup_range = 10
	pickup_type = "Magnet"
	pickup_value = 0
	sprite_path = "res://Assets/Art/Pickups/Magnet.png"
	super._ready()

func apply_effect():
	for xp in get_tree().get_nodes_in_group("Xp"):
		xp.player_in_range = true
