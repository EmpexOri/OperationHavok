extends Node

# Scripts for each pickup type
var xp_script = preload("res://Assets/Scripts/Pickups/xp.gd")

# The base pickup scene
var pickup_scene = preload("res://Scenes/Pickups/pickup.tscn")

func build_pickup(type: String, position: Vector2) -> Node:
	var pickup = pickup_scene.instantiate()
	pickup.global_position = position
	
	match type:
		"Xp":
			pickup.set_script(xp_script)
	
	return pickup
