extends WeaponEffect
class_name AkimboWeaponEffect

@export var shot_offset: float = 10.0
@export var barrel_count: int = 2 # Supports 1, 2, or 3 barrels

func _init() -> void:
	effect_name = "AkimboEffect"

func modify_parameters(parameters: Dictionary) -> Dictionary:
	return parameters

func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2, projectile_effects: Array[ProjectileEffect]) -> bool:
	var fire_parameters = {
		"projectile_count": 1,
		"spread_angle": 0,
		"direction": direction
	}

	# Allow other weapon effects to modify parameters, so we can work with iaccruay :D
	for effect in weapon.weapon_effects:
		if effect != self:
			fire_parameters = effect.modify_parameters(fire_parameters)

	var inaccuracy_angle: float = fire_parameters.get("inaccuracy_angle", 0)
	var perp_direction = Vector2(direction.y, -direction.x).normalized()

	# Clamp barrel count between 1 and 3, PLEASE DO NOT ADD MORE
	var clamped_barrel_count = clamp(barrel_count, 1, 3)

	var fire_data = []

	# Calculate origins for each barrel
	for i in range(clamped_barrel_count):
		var offset_index = i - (clamped_barrel_count - 1) / 2.0 # Basically we just move ur fire point depending on barrels
		var offset = offset_index * shot_offset
		var origin = spawn_position + perp_direction * offset

		var dir = direction.normalized()
		if inaccuracy_angle != 0:
			dir = dir.rotated(deg_to_rad(randf_range(-inaccuracy_angle, inaccuracy_angle)))

		var final_pos = origin + dir * weapon.fire_offset
		fire_data.append({ "pos": final_pos, "dir": dir })

	# Fire each projectile
	var main_scene = weapon.get_tree().current_scene
	if not main_scene:
		return false

	for data in fire_data:
		var proj = weapon.projectile_scene.instantiate()
		main_scene.add_child(proj)
		proj.start(data["pos"], data["dir"], weapon.owning_entity, projectile_effects.duplicate(true))

	return true
