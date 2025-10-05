extends SuperGrenade
class_name PlasmaGrenade

@export var fire_tornado_scene: PackedScene = null

func _do_explosion_effects():
	super._do_explosion_effects()
	
	if not fire_tornado_scene:
		print("PlasmaGrenade: fire_tornado_scene not set")
		return
		
	var tornado_instance = fire_tornado_scene.instantiate()
	
	# Add the tornado to the main scene tree
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(tornado_instance)
		
		# Tornado PhysicsProjectile start() call
		if tornado_instance.has_method("start"):
			# Arguments for the tornado's start method.
			var owner_string = "Player" # We are assuming player fired this
			var effects_array: Array[ProjectileEffect] = []
			var space_state = get_world_2d().direct_space_state
			var damage_mult = 1.0
			
			# Start the tornado at the explosion's location with a random initial direction
			var random_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))
			tornado_instance.start(global_position, random_direction, owner_string, effects_array, space_state, damage_mult)
		else:
			tornado_instance.global_position = global_position
	else:
		print("PlasmaGrenade: Could not find main scene to spawn tornado")
