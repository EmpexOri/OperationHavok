extends WeaponEffect
class_name RecoilEffect

@export var recoil_strength: float = 100.0

func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2, projectile_effects: Array[ProjectileEffect], space_state) -> bool:
	var player = weapon.get_owning_entity()
	if player and player.has_method("apply_recoil"):
		player.apply_recoil(-direction.normalized() * recoil_strength)
	return false
