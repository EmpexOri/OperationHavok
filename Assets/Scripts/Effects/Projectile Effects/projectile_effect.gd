extends Resource
class_name ProjectileEffect

@export var effect_name: String

# Call when initialising an effect
func setup(projectile: Projectile):
	pass

# Called every frame from projectile
func process_effect(projectile: Projectile, delta: float):
	pass

# Called when projectile has a collision
func on_hit(projectile: Projectile, body: Node2D):
	true # Projectile will be destroyed on hit - override in derived class for different effect
