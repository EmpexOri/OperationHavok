extends ProjectileEffect
class_name DamageOverTimeEffect

@export var damage_per_second: float = 5.0
@export var duration: float = 10.0

func _init() -> void:
	effect_name = "DamageOverTime"

func setup(projectile: Projectile):
	pass

func process_effect(projectile: Projectile, delta: float):
	pass

func on_hit(projectile: Projectile, body: Node2D):
	if body.has_method("apply_dot"):
		body.apply_dot(damage_per_second, duration)
	else:
		print("Warning: Body has no method 'apply_dot'")
	return true
