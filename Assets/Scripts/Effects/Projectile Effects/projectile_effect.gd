extends Resource
class_name ProjectileEffect

# This is a base class, to create a new projectile effect you will extend this class
# Do not make changes here

@export var effect_name: String

# Call when initialising an effect, initialised from the projectile
func setup(projectile: Projectile):
	pass

# Called every frame from projectile
func process_effect(projectile: Projectile, delta: float):
	pass

# Called when projectile has a collision
func on_hit(projectile: Projectile, body: Node2D):
	null # Override in derived class for different effect - true is destroyed, false is not
