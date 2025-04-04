extends Resource
class_name ProjectileEffect

@export var effect_name: String

# Call when initialising an effect
func setup(projectile: Projectile):
	pass

# Called every frame
func process_effect(projectile: Projectile, delta: float):
	pass

# Called when projectile has a collision
func on_hit(projectile: Projectile, body: Node2D):
	pass
