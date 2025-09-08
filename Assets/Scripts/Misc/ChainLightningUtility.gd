class_name ChainLightningUtility

# Find targets and trigger visuals
static func execute_chain_lightning(
		caller_node: Node,
		origin_pos: Vector2,
		initial_aim_dir: Vector2,
		initial_target: Node2D,
		space_state: PhysicsDirectSpaceState2D,
		max_chains: int,
		chain_radius: float,
		damage_per_hit: float,
		target_collision_mask: int,
		effects_to_apply: Array[ProjectileEffect],
		nodes_to_exclude: Array,
		lightning_arc_drawer_scene: PackedScene
		) -> void:
	
	var vfx_parent: Node = caller_node.get_tree().current_scene 
	
	if not is_instance_valid(space_state):
		print("ChainLightningUtility: space_state is null.")
		return
	if not lightning_arc_drawer_scene:
		print("ChainLightningUtility: lightning_arc_drawer_scene is null.")
		return
	if not is_instance_valid(vfx_parent):
		print("ChainLightningUtility: vfx_parent is invalid.")
		return
	
	var targets_hit_this_chain: Array[Node2D] = []
	var arc_visual_points: Array[Vector2] = [origin_pos]
	var current_chain_target: Node2D = initial_target
	var last_hit_pos: Vector2 = origin_pos
	
	# Handle the initial target if one was provided (e.g. from a projectile hit)
	if is_instance_valid(initial_target):
		if not initial_target in nodes_to_exclude:
			targets_hit_this_chain.append(initial_target)
			arc_visual_points.append(initial_target.global_position)
			last_hit_pos = initial_target.global_position
		else:
			current_chain_target = null 
	
	var num_targets_found = targets_hit_this_chain.size()
	
	# Loop to find subsequent chain targets
	for i in range(num_targets_found, max_chains):
		var next_target_in_chain: Node2D = null
		var current_exclusions = nodes_to_exclude + targets_hit_this_chain
		
		if not is_instance_valid(current_chain_target):
			next_target_in_chain = _find_target_in_cone(
			space_state,
			origin_pos,
			initial_aim_dir,
			chain_radius * 1.5,
			60.0,
			target_collision_mask,
			current_exclusions
		)
		if not is_instance_valid(next_target_in_chain):
			# fallback: just grab closest in radius
			next_target_in_chain = _find_closest_target_in_radius(
			space_state,
			origin_pos,
			chain_radius * 1.5,
			target_collision_mask,
			current_exclusions
		)
		
		if is_instance_valid(next_target_in_chain):
			targets_hit_this_chain.append(next_target_in_chain)
			arc_visual_points.append(next_target_in_chain.global_position)
			last_hit_pos = next_target_in_chain.global_position
			current_chain_target = next_target_in_chain
			_apply_damage_and_effects(
				next_target_in_chain,
				damage_per_hit,
				effects_to_apply,
				caller_node
			)
		else:
			break # No more targets found, end the chain
	
	# Instantiate Visuals
	if arc_visual_points.size() >= 2:
		var arc_drawer_instance = lightning_arc_drawer_scene.instantiate()
		vfx_parent.add_child(arc_drawer_instance)
		if arc_drawer_instance.has_method("setup_arcs"):
			arc_drawer_instance.setup_arcs(arc_visual_points)

# Static Helper Methods
static func _apply_damage_and_effects(target: Node2D, damage: float,
	effect_resources: Array[ProjectileEffect], source_node):
	if not is_instance_valid(target):
		return
	
	var hit_occurred := false
	
	if target.has_method("deal_damage"):
		target.deal_damage(damage)
		hit_occurred = true  # Damage actually applied
	
	if effect_resources:
		for effect_res in effect_resources:
			if effect_res:
				var effect_instance = effect_res.duplicate(true)
				if effect_instance.has_method("on_hit"):
					var projectile_source = source_node if source_node is Projectile else null
					effect_instance.on_hit(projectile_source, target)
					hit_occurred = true

	# Play lightning sound only if we hit something
	if hit_occurred:
		GlobalAudioController.PlayFromWeaponSFX(GlobalAudioController.lightning_sfx)

static func _find_target_in_cone(space_state: PhysicsDirectSpaceState2D, origin: Vector2,
		aim_dir: Vector2, search_radius: float, cone_angle_deg: float, mask: int, 
		exclude_list: Array) -> Node2D:
	var closest_target: Node2D = null; var min_dist_sq = INF
	var query_shape = CircleShape2D.new(); query_shape.radius = search_radius
	var query_params = PhysicsShapeQueryParameters2D.new()
	query_params.shape = query_shape; query_params.transform = Transform2D(0, origin)
	query_params.collision_mask = mask; query_params.exclude = exclude_list
	query_params.collide_with_areas = false; query_params.collide_with_bodies = true
	var results = space_state.intersect_shape(query_params)
	var cone_angle_rad = deg_to_rad(cone_angle_deg) / 2.0
	for r in results:
		var body: Node2D = r.collider
		if not body.has_method("deal_damage"): continue
		var dir_to_body = (body.global_position - origin).normalized()
		var angle_to_body = aim_dir.angle_to(dir_to_body)
		if abs(angle_to_body) <= cone_angle_rad:
			var dist_sq = origin.distance_squared_to(body.global_position)
			if dist_sq < min_dist_sq: min_dist_sq = dist_sq; closest_target = body
	return closest_target

static func _find_closest_target_in_radius(space_state: PhysicsDirectSpaceState2D,
		origin: Vector2, search_radius: float, mask: int, exclude_list: Array) -> Node2D:
	
	var closest_target: Node2D = null;
	var min_dist_sq = search_radius * search_radius
	var query_shape = CircleShape2D.new()
	query_shape.radius = search_radius
	var query_params = PhysicsShapeQueryParameters2D.new()
	query_params.shape = query_shape
	query_params.transform = Transform2D(0, origin)
	query_params.collision_mask = mask
	query_params.exclude = exclude_list
	query_params.collide_with_areas = false
	query_params.collide_with_bodies = true
	var results = space_state.intersect_shape(query_params)
	for r in results:
		var body: Node2D = r.collider
		if not body.has_method("deal_damage"): continue
		var dist_sq = origin.distance_squared_to(body.global_position)
		if dist_sq < min_dist_sq: min_dist_sq = dist_sq; closest_target = body
	return closest_target
