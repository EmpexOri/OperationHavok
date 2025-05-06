extends WeaponEffect
class_name AkimboWeaponEffect

# An offset firing effect for a weapon firing two projectiles

@export var shot_offset: float = 10.0 # The offset distance between the two projectiles

# Initialise the effects name
func _init() -> void:
	effect_name = "AkimboEffect"

# Not neccessary as we are just modifying the firing logic
func modify_parameters(parameters: Dictionary) -> Dictionary:
	return parameters
	
# Override weapon firing logic
func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2, projectile_effects: Array[ProjectileEffect]):
	# Get the direction perpendicular to the firing direction 
	var perp_direction = Vector2(direction.y, -direction.x).normalized()
	
	# Calculate the offset origins - relative to spawn_position
	var origin_1 = spawn_position + perp_direction * (shot_offset / 2.0)
	var origin_2 = spawn_position - perp_direction * (shot_offset / 2.0)
	
	# Calculate the final spawn positions, considering offset
	var final_pos_1 = origin_1 + direction * weapon.fire_offset
	var final_pos_2 = origin_2 + direction * weapon.fire_offset
	
	# Spawn the first projectile
	var proj1 = weapon.projectile_scene.instantiate()
	var main_scene1 = weapon.get_tree().current_scene
	if main_scene1:
		main_scene1.add_child(proj1)
	else:
		if proj1: proj1.queue_free()
		return false
		
	proj1.start(final_pos_1, direction, weapon.owning_entity, projectile_effects.duplicate(true))
	
	# Spawn the second projectile
	var proj2 = weapon.projectile_scene.instantiate()
	var main_scene2 = weapon.get_tree().current_scene
	if main_scene2:
		main_scene2.add_child(proj2)
	else:
		if proj2: proj2.queue_free()
		return true
	
	proj2.start(final_pos_2, direction, weapon.owning_entity, projectile_effects.duplicate(true))
	
	return true # We must return true or this code won't override the base firing logic in the weapon object
