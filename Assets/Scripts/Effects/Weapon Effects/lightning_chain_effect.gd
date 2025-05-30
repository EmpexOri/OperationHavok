extends WeaponEffect
class_name LightningChainEffect

@export var max_chains: int = 3 # Max number of enemies hit (initial + chains)
@export var chain_radius: float = 150.0 # How far to look for the next target
@export var damage_per_hit: float = 10.0 # Because we have no projectile, damage is set here
@export var initial_target_cone_angle: float = 60.0 # Degrees, for finding first target
@export var target_collision_mask: int = 2 # Default to mask for layer 2 (e.g., Enemies, again, beacause we have no projectile)
#@export var lightning_arc_drawer_scene: PackedScene = null # TODO Assign LightningArcDrawer.tscn, this will be the effect

func _init():
	effect_name = "Lightning Chain"
	
func override_fire_logic(weapon: Weapon, spawn_position: Vector2, direction: Vector2, projectile_effects_to_apply: Array[ProjectileEffect], space_state: PhysicsDirectSpaceState2D) -> bool:
	call_deferred("_execute_lightning_chain", weapon, spawn_position, direction) # Necessary to get the space state due to multithreading
	return true # Have to return true to override fire logic
	
func _execute_lightning_chain(weapon: Weapon, spawn_position: Vector2, direction: Vector2):
	var targets_hit: Array[Node2D] = []
	var current_source_pos = spawn_position
	var current_direction = direction
	
	var space_state = weapon.get_world_2d().direct_space_state
	
	if space_state == null:
		return
	
	var initial_target = _find_initial_target(space_state, current_source_pos, current_direction, weapon)
	
	if initial_target:
		targets_hit.append(initial_target)
	
func _find_initial_target(space_state, origin: Vector2, aim_dir: Vector2, weapon_node: Weapon) -> Node2D:
	# Find closest enemy within a cone
	var closest_target: Node2D = null # The closest target, will be returned
	var min_dist_sq = INF
	
	# Create a query shape
	var query_shape = CircleShape2D.new() # The circle for finding the first target
	query_shape.radius = chain_radius # Set the radius to our chain radius
	
	# Initialise a query
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
	
	# Conduct a query
	var results = space_state.intersect_shape(query_params) # Conduct the query
	
	var cone_angle_rad = deg_to_rad(initial_target_cone_angle) / 2.0 # Create the cone 
	
	# Iterate through our results to find closest target
	for r in results:
		var body: Node2D = r.collider
		if body == weapon_node.get_parent(): continue # Skip owner
		if not body.has_method("deal_damage"): continue # Not a damageable target
		
		var dir_to_body = (body.global_position - origin).normalized()
		var angle_to_body = aim_dir.angle_to(dir_to_body)
		
		if abs(angle_to_body) <= cone_angle_rad:
			var dist_sq = origin.distance_squared_to(body.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_target = body
				
	# Temp print to console
	if closest_target:
		print("Lightning target found: ", closest_target.name, " at distance: ", sqrt(min_dist_sq))
		print("Line from: ", origin, " to: ", closest_target.global_position)
	else:
		print("No lightning target found in cone")
				
	return closest_target
