extends WeaponEffect
class_name LightningChainEffect

@export var max_chains: int = 3 # Max number of enemies hit (initial + chains)
@export var chain_radius: float = 150.0 # How far to look for the next target
@export var damage_per_hit: float = 10.0 # Because we have no projectile, damage is set here
@export var initial_target_cone_angle: float = 60.0 # Degrees, for finding first target
@export var target_collision_mask: int = 2 # Default to mask for layer 2 (e.g., Enemies)
#@export var lightning_arc_drawer_scene: PackedScene = null # TODO Assign LightningArcDrawer.tscn

func _init():
	effect_name = "Lightning Chain"
	
func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2, projectile_effects_to_apply: Array[ProjectileEffect]) -> bool:
	return true # Have to return true to override fire logic
	
func _find_initial_target(space_state, origin: Vector2, aim_dir: Vector2, weapon_node: Weapon) -> Node2D:
	# Find closest enemy within a cone
	var closest_target: Node2D = null # The closest target, will be returned
	var min_dist_sq = INF
	
	var query_shape = CircleShape2D.new() # The circle for finding the first target
	query_shape.radius = chain_radius # Set the radius to our chain radius
	
	var query_params = PhysicsShapeQueryParameters2D.new() # Create a new query
	query_params.shape = query_shape # Set the queries shape to our circle
	query_params.transform = Transform2D(0, origin) # Centered at weapon origin
	query_params.collision_mask = target_collision_mask # Hacky way to set collision mask as we have no projectile
	var exclusions = [weapon_node]
	if weapon_node.get_parent() is Node2D: # Check if parent exists and is Node2D
		exclusions.append(weapon_node.get_parent())
	query_params.exclude = exclusions # Avoid chainging to self
	query_params.collide_with_areas = true
	query_params.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query_params) # Conduct the query
	
	var cone_angle_rad = deg_to_rad(initial_target_cone_angle) / 2.0
	
	for r in results:
		var body: Node2D = r.collider
		if body == weapon_node.get_parent(): continue # Skip owner
		if not body.has_method("deal_damage"): continue # Not a damageable target
	
	return closest_target
