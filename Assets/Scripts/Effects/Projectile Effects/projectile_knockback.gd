extends ProjectileEffect
class_name KnockbackEffect

@export var knockback_force: float = 300.0

func _init():
	effect_name = "Knockback"

func setup(projectile: Projectile):
	pass

func process_effect(projectile: Projectile, delta: float):
	pass

func on_hit(projectile: Projectile, body: Node2D):
	if body.has_method("apply_knockback"):
		var direction = (body.global_position - projectile.global_position).normalized()
		body.apply_knockback(direction * knockback_force)
		return true # Optionally destroy the projectile
	return false
