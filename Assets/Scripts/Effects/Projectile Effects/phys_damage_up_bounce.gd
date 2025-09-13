extends ProjectileEffect
class_name DamageUpOnBounceEffect

@export var damage_multiplier_per_bounce: float = 0.5

func _init():
	effect_name = "Damage Up On Bounce"

func on_hit(projectile, body: Node2D, collision: KinematicCollision2D = null):
	if collision == null:
		return true # Ignore non phys collision
	
	var bounce_effect = _find_bounce_effect(projectile.current_effects) # Get the bounce effect
	
	# Get the current multiplier for the projectile instance and increase by damage_multiplier_per_bounce
	if is_instance_valid(bounce_effect) and bounce_effect.current_bounces < bounce_effect.max_bounces:
		var current_multi: float = projectile.get_damage_multiplier()
		var new_multi: float = current_multi + damage_multiplier_per_bounce
		projectile.set_damage_multiplier(new_multi)
		return true # Not responsible for destruction
	
	return true # Not responsible for destruction

# Helper function to find the bounce effect in the projectile's effect list
func _find_bounce_effect(effects: Array[ProjectileEffect]) -> PhysProjectileBounces:
	for effect in effects:
		if effect is PhysProjectileBounces:
			return effect
	return null
