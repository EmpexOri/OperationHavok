extends Resource
class_name ProjectileEffect

# This is a base class, to create a new projectile effect you will extend this class
# Do not make changes here

@export var effect_name: String

# Call when initialising an effect, initialised from the projectile
func setup(projectile):
	pass

# Called every frame from projectile
func process_effect(projectile, delta: float, space_state: PhysicsDirectSpaceState2D):
	pass

# Called when projectile has a collision
func on_hit(projectile, body: Node2D, collision: KinematicCollision2D = null):
	null # Override in derived class for different effect - true is destroyed, false is not
