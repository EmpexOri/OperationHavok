extends ProjectileEffect
class_name ExplodeOnMaxBounces

func _init():
	effect_name = "Explode On Max Bounces"

func on_hit(projectile, body: Node2D, collision: KinematicCollision2D = null):
	if collision == null:
		return false # Ignore non phys collision
		
	if projectile.has_method("_explode"):
		var bounce_effect = _find_bounce_effect(projectile.current_effects) # Get the bounce effect
		var should_explode = true
		
		if is_instance_valid(bounce_effect):
			if bounce_effect.current_bounces < bounce_effect.max_bounces:
				should_explode = false # We haven't reached max bounces yet
		
		if should_explode:
			projectile._explode()
			return false # Not responsible for destruction
	
	return false # Not responsible for destruction

# Helper function to find the bounce effect in the projectile's effect list
func _find_bounce_effect(effects: Array[ProjectileEffect]) -> PhysProjectileBounces:
	for effect in effects:
		if effect is PhysProjectileBounces:
			return effect
	return null
