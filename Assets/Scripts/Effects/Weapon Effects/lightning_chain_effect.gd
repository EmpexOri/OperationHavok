extends WeaponEffect
class_name LightningChainEffect

@export var max_chains: int = 3 # Max number of enemies hit (initial + chains)
@export var chain_radius: float = 150.0 # How far to look for the next target
@export var damage_per_hit: float = 10.0 # Because we have no projectile, damage is set here
@export var initial_target_cone_angle: float = 60.0 # Degrees, for finding first target
@export var target_collision_mask: int = 2 # Default to mask for layer 2 (e.g., Enemies, again, beacause we have no projectile)
@export var lightning_arc_drawer_scene: PackedScene = null # The arc effect

func _init():
	effect_name = "Lightning Chain"

func override_fire_logic(
		weapon: Weapon,
		spawn_position: Vector2,
		direction: Vector2,
		projectile_effects_to_apply: Array[ProjectileEffect],
		space_state: PhysicsDirectSpaceState2D,
		damage_multiplier: float
		) -> bool:
	
	var exclusions = [weapon]
	
	if is_instance_valid(weapon.get_parent()):
		exclusions.append(weapon.get_parent())

	# Call the shared logic from the helper script
	ChainLightningUtility.execute_chain_lightning(
		weapon, # caller_node
		spawn_position, # origin_pos
		direction, # initial_aim_dir
		null, # initial_target (none, will be found by utility),
		space_state,
		max_chains,
		chain_radius,
		damage_per_hit,
		target_collision_mask,
		projectile_effects_to_apply,
		exclusions,
		lightning_arc_drawer_scene
	)
	return true
