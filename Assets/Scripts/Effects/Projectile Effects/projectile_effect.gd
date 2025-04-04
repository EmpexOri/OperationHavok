extends Resource
class_name ProjectileEffect

@export var effect_name: String

func process_effect(projectile: Projectile, delta: float):
	pass
	
func on_hit(projectile: Projectile, body: Node2D):
	pass
	
func setup(projectile: Projectile):
	pass
