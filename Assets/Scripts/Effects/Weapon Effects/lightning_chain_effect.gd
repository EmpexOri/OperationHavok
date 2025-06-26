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
	
func override_fire_logic(
	weapon: Weapon, spawn_position: Vector2,
	direction: Vector2,
	projectile_effects_to_apply: Array[ProjectileEffect],
	space_state: PhysicsDirectSpaceState2D) -> bool:
	
	if not is_instance_valid(space_state):
		print("Space state invalid in chain lightning")
		
	var targets_hit_this_chain: Array[Node2D] = []
	var current_source_pos_for_next_link = spawn_position
	var current_aim_direction_for_next_link = direction
	var current_chain_target: Node2D = null
	
	for i in range(max_chains):
		var next_target_in_chain: Node2D = null
		var exclusions: Array = []
		exclusions.append(weapon)
		if is_instance_valid(weapon.get_parent()):
			exclusions.append(weapon.get_parent())
		exclusions.append_array(targets_hit_this_chain)
		
		# Find the initial target, cone based
		if i == 0:
			next_target_in_chain = _find_initial_target(
				space_state,
				spawn_position,
				current_aim_direction_for_next_link,
				weapon,
				exclusions)
		
		else:
			if not is_instance_valid(current_chain_target):
				break
			
			next_target_in_chain = _find_next_chain_target(
				space_state,
				current_chain_target.global_position,
				weapon,
				exclusions
			)
		
		# Deal damage if possible
		if is_instance_valid(next_target_in_chain):
			targets_hit_this_chain.append(next_target_in_chain)
			if next_target_in_chain.has_method("deal_damage"):
				next_target_in_chain.deal_damage(damage_per_hit)
				
			# Apply ProjectileEffects 
			for p_effect_resource in projectile_effects_to_apply:
				if p_effect_resource:
					var p_effect_instance = p_effect_resource.duplicate(true)
					if p_effect_instance.has_method("on_hit"):
						p_effect_instance.on_hit(null, next_target_in_chain)
					
			current_chain_target = next_target_in_chain
			current_source_pos_for_next_link = next_target_in_chain.global_position
			
		else:
			break
	
	return true # Have to return true to override fire logic

# Uses a cone based query to ensure that the initial target is somewhere in the direction the user is aiming
func _find_initial_target(
		space_state: PhysicsDirectSpaceState2D,
		origin: Vector2,
		aim_dir: Vector2,
		weapon_node: Weapon,
		current_exclusions: Array
		) -> Node2D:
			
	var closest_target: Node2D = null
	var min_dist_sq = INF
	
	var query_shape = CircleShape2D.new()
	query_shape.radius = chain_radius
	
	var query_params = PhysicsShapeQueryParameters2D.new()
	query_params.shape = query_shape
	query_params.transform = Transform2D(0, origin)
	query_params.collision_mask = target_collision_mask
	query_params.exclude = current_exclusions
	query_params.collide_with_areas = true
	query_params.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query_params)
	var cone_angle_rad = deg_to_rad(initial_target_cone_angle) / 2.0
	
	for r in results:
		var body: Node2D = r.collider
		if is_instance_valid(weapon_node.get_parent()) and body == weapon_node.get_parent(): continue
		if not body.has_method("deal_damage"): continue
		
		var dir_to_body = (body.global_position - origin).normalized()
		var angle_to_body = aim_dir.angle_to(dir_to_body)
		
		if abs(angle_to_body) <= cone_angle_rad:
			var dist_sq = origin.distance_squared_to(body.global_position)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				closest_target = body
				
	return closest_target

# Find the next closest target, regardless of direction
func _find_next_chain_target(
		space_state: PhysicsDirectSpaceState2D,
		current_link_origin: Vector2,
		weapon_node: Weapon,
		current_exclusions: Array
		) -> Node2D:
	
	var closest_target: Node2D = null
	var min_dist_sq = chain_radius * chain_radius
	
	var query_shape = CircleShape2D.new()
	query_shape.radius = chain_radius
	
	var query_params = PhysicsShapeQueryParameters2D.new()
	query_params.shape = query_shape
	query_params.transform = Transform2D(0, current_link_origin)
	query_params.collision_mask = target_collision_mask
	query_params.exclude = current_exclusions
	query_params.collide_with_areas = true
	query_params.collide_with_bodies = true
	
	var results = space_state.intersect_shape(query_params)
	
	for r in results:
		var body: Node2D = r.collider
		if not body.has_method("deal_damage"): continue
		
		var dist_sq = current_link_origin.distance_squared_to(body.global_position)
		if dist_sq < min_dist_sq:
			min_dist_sq = dist_sq
			closest_target = body
	
	return closest_target
