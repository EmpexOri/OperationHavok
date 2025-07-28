extends Enemy

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var latch_area: Area2D = $Area2D

const WALL_COLLISION_MASK = (1 << 0) | (1 << 1) | (1 << 2) | (1 << 3)

func _ready():
	super()
	#get_flash_sprite().material = get_flash_sprite().material.duplicate()
	
	latch_area.body_entered.connect(_on_area_2d_body_entered)

	Speed = 60
	Health = 80
	MaxHealth = Health
	Group = "Enemy"
	add_to_group("Support")
	Target = null

func _process(delta):
	super._process(delta)

	if Health <= 0:
		on_death()

func _physics_process(delta):
	if not is_instance_valid(Target) or Target.is_in_group("Armored"):
		find_strongest_target()

	if Target:
		nav.target_position = Target.global_position
		var direction = (nav.get_next_path_position() - global_position).normalized()
		velocity = direction * Speed
		move_and_slide()
	else:
		velocity = Vector2.ZERO

func find_strongest_target():
	var candidates := get_tree().get_nodes_in_group("Enemy")

	# Filter out invalid targets
	var valid_candidates := []
	for enemy in candidates:
		if enemy == self:
			continue
		if enemy.is_in_group("Armored") or enemy.is_in_group("Support"):
			continue
		if enemy.Health <= 0:
			continue
		valid_candidates.append(enemy)

	# If no valid targets, clear the current target
	if valid_candidates.is_empty():
		Target = null
		return

	# Find the enemy with the highest health
	var strongest = valid_candidates[0]
	for enemy in valid_candidates:
		if enemy.Health > strongest.Health:
			strongest = enemy

	Target = strongest

func transfer_health_to(target):
	if not is_instance_valid(target) or target.is_in_group("Armored"):
		return

	# Check line of sight with raycast
	var space_state = get_world_2d().direct_space_state
	var ray_params = PhysicsRayQueryParameters2D.create(global_position, target.global_position)
	ray_params.exclude = [self]
	ray_params.collision_mask = WALL_COLLISION_MASK

	var result = space_state.intersect_ray(ray_params)
	if result and result.collider != target:
		return # Blocked

	if target.has_method("apply_armor_buff"):
		print("Goolum grants armor to:", target.name)
		target.apply_armor_buff(Health)
		on_death()

func get_flash_sprite() -> CanvasItem:
	return sprite

func _on_area_2d_body_entered(body: Node2D) -> void:
	print("Hit something")
	if body.is_in_group("Enemy") and not body.is_in_group("Armored") and body.has_method("apply_armor_buff") and not body.is_in_group("Support"):
		transfer_health_to(body)
		
		print("ADMINISTARED HEALTH KYS NOW")
		
		# Change the enemy's color to blue to show buff
		if body.has_node("AnimatedSprite2D"):
			var sprite = body.get_node("AnimatedSprite2D")
			sprite.modulate = Color(0, 0, 1)  # Pure blue
			
		# Make Goolum disappear after giving buff
		on_death()
